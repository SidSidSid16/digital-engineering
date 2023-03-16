library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

entity OUTPUT_CTRL is
    Generic (disp_delay : natural := 100000000);
    Port ( CLK : in  STD_LOGIC;
           USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
           SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
           FROM_SOURCE : in  STD_LOGIC;
           TO_SOURCE : out  STD_LOGIC;
           DATA_FROM_FIFO : in  STD_LOGIC_VECTOR (7 downto 0);
           LEDS : out  STD_LOGIC_VECTOR (7 downto 0);
           FIFO_RD_EN : out  STD_LOGIC;
           FIFO_EMPTY : in  STD_LOGIC);
end OUTPUT_CTRL;

architecture Behavioral of OUTPUT_CTRL is

signal RST, EN : STD_LOGIC;
type state_type is (IDLE, DISP);        -- The FSM states
signal state, next_state: state_type;   -- The states as signals

-- Internal signals for the counters enable and resets, this is the
-- LED delay logic, it holds the value for a number of clock periods.
signal DISP_CNT_OUT : UNSIGNED (log2(disp_delay)-1 downto 0);
signal DISP_CNT_EN, DISP_CNT_RST : STD_LOGIC;

begin

RST <= USER_PB(1);
EN <= USER_PB(3);

-- Port map for the display delay counter
DISP_CNT: entity work.parameterizable_counter 
GENERIC MAP (LIMIT => disp_delay)
PORT MAP(
	clk => clk,
	rst => DISP_CNT_RST,
	enable => DISP_CNT_EN,
	count_out => DISP_CNT_OUT
);

--  Sets the state as IDLE (reset state) when the reset input is set high.
--  At each clock cycle if the reset isn't high, the state is set to the next
--  state.
state_assignment : process (clk) is
begin
    if rising_edge(clk) then
        if (rst = '1') then
            state <= IDLE;
        else
            state <= next_state;
        end if;
    end if; 
end process state_assignment;



fsm_process : process (state, FIFO_EMPTY)
begin
    case state is
        -- Start displaying as soon as the FIFO is no longer empty.
        when IDLE =>
            if FIFO_EMPTY = '0' then
                next_state <= DISP;
            else 
                next_state <= state;
            end if;
        -- As soon as the FIFO is empty we can stop displaying.
        when DISP =>
            if FIFO_EMPTY = '1' then
                next_state <= IDLE;
            else 
                next_state <= state;
            end if;
    end case;
end process fsm_process;

-- We can reset the value of the counter in the IDLE state so
-- when the logic resumes, the delays will be constant.
DISP_CNT_RST <= '1' when state = IDLE else
                '0';
-- The counter needs to be enabled in the DISP state, so that
-- the logic knows when to enable FIFO read to pull the new
-- values in, as the counter will roll-over.
DISP_CNT_EN <= '1' when state = DISP else
               '0';
-- When the logic is not displaying, we need the LEDs to be off.
LEDS <= DATA_FROM_FIFO when state = DISP else
        "00000000";
-- We only want the FIFO to be read from when the state is DISP
-- and when the counter is at 0.
FIFO_RD_EN <= '1' when state = DISP and DISP_CNT_OUT = disp_delay - 1 else
              '0';
-- This OUTPUT logic will always be active as long as the FIFO is not
-- empty, we can invert the FIFO_EMPTY signal so that when OUTPUT is
-- active (displaying all values via LEDs) this OUTPUT_ACTIVE signal
-- will be high. This signal can be passed to the SOURCE logic.
TO_SOURCE <= '1' when state = DISP else
             '0';

end Behavioral;

