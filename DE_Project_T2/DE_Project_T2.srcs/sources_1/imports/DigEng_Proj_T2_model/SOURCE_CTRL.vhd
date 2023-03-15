library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;


entity SOURCE_CTRL is
    -- Max value that the board switches can represent stored as a
    -- Generic.
    Generic (switch_limit : natural := 256); 
    Port ( CLK : in  STD_LOGIC;
           USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
           SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
           FIFO_FULL : in  STD_LOGIC;
           FIFO_WR_EN : out  STD_LOGIC;
           TO_OUTPUT : out  STD_LOGIC;
           FROM_OUTPUT : in  STD_LOGIC;
           RST_SOURCE : out  STD_LOGIC;
           EN_SOURCE : out  STD_LOGIC
    );
end SOURCE_CTRL;

architecture Behavioral of SOURCE_CTRL is

signal EN, RST : STD_LOGIC;
type state_type is (IDLE, COMP, HOLD);  -- The FSM states
signal state, next_state: state_type;   -- The states as signals

-- Internal signal for the board switch limit counter.
--  This counter limits the maximum number of outputs based on
--  the switches on the board. There are 8 switches on the board,
--  so a maximum of 256 values can be represented.
signal LIMT_CNT_OUT : UNSIGNED (log2(switch_limit)-1 downto 0);
signal LIMT_CNT_EN, LIMT_CNT_RST : STD_LOGIC;
-- To ignore any changes in the SWITCHES we need to store the value
-- of switches in an internal signal when the enablle button is
-- pressed during the IDLE state.
signal LIMT_REG_EN : STD_LOGIC;
signal LIMT_REG_RST : STD_LOGIC;
signal LIMT_REG_OUT : STD_LOGIC_VECTOR (7 downto 0);

begin

EN <= USER_PB(3);
RST <= USER_PB(1);
RST_SOURCE <= RST;

-- Port map for the value limit counter
LIMT_CNT : entity work.parameterizable_counter 
GENERIC MAP (LIMIT => switch_limit)
PORT MAP(
	clk => clk,
	rst => LIMT_CNT_RST,
	enable => LIMT_CNT_EN,
	count_out => LIMT_CNT_OUT
);

-- A register to store the value of SWITCHES when enabled.
switch_register : process (clk) is
begin
    if rising_edge(clk) then
        if LIMT_REG_RST = '1' then
            LIMT_REG_OUT <= (others => '0');
        elsif LIMT_REG_EN = '1' then
            LIMT_REG_OUT <= SWITCHES;
        end if;
    end if;
end process switch_register;

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

fsm_process : process (state, en, rst, LIMT_CNT_OUT, FIFO_FULL, FROM_OUTPUT, LIMT_REG_OUT)
begin
    case state is
        when IDLE =>
            -- Start computing values as soon as the enable button is pressed and
            -- the output has finished displaying.
            if en = '1' and FROM_OUTPUT = '0' then
                next_state <= COMP;
            else 
                next_state <= state;
            end if;
        when COMP =>
            -- When the FIFO is full, we want to wait until the OUTPUT logic
            -- pops some values and frees some space.
            if FIFO_FULL = '1' then
                next_state <= HOLD;
            -- As soon as the limit set by the switches have been reached, the
            -- logic should stop.
            elsif LIMT_CNT_OUT = to_integer(unsigned(LIMT_REG_OUT))-1 then
                next_state <= IDLE;
            else 
                next_state <= state;
            end if;
        when HOLD =>
            -- In this state, we wait until the OUTPUT logic pops values and
            -- frees up some space from the FIFO. Once the FIFO is no longer full,
            -- more values can be computed until the switch limit is reached.
            if FIFO_FULL = '0' then
                next_state <= COMP;
            else 
                next_state <= state;
            end if;
    end case;
end process fsm_process;

-- We want to reset the max value counter to 0 only in IDLE state.
LIMT_CNT_RST <= '1' when state = IDLE else
                '0';
-- The counter should only increment when in COMP state so it can
-- synchronise with the next outputs being generated. FIFO must not
-- full as well.
LIMT_CNT_EN <= '1' when state = COMP and FIFO_FULL = '0' else
               '0';
-- The source is enabled and generates the next value only when in
-- the compute state (COMP) and when the FIFO is not full. We need
-- the source to be enabled as soon as the enable button is clicked
-- during the IDLE state so that the first value can be computed
-- as soon as FIFO write is enabled.
EN_SOURCE <= '1' when state = COMP and FIFO_FULL = '0' else
             '1' when state = IDLE and en = '1' and FROM_OUTPUT = '0' else
             '0';
-- FIFO write needs to be enabled in the COMP state so that the
-- newly computed values are stored, FIFO should not be full.
FIFO_WR_EN <= '1' when state = COMP and FIFO_FULL = '0' else
              '0';
-- We store the value of SWITCHES when the state is IDLE and when the
-- user enables the logic, this way the logic will not change when the
-- SWITCH values are changed during operation.
LIMT_REG_EN <= '1' when state = IDLE and en = '1' else
               '0';
LIMT_REG_RST <= '1' when (state = IDLE and en = '0') or RST = '1' else
                '0';

end Behavioral;

