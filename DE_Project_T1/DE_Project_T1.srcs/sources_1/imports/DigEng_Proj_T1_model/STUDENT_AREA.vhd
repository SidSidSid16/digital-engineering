library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

entity STUDENT_AREA is
    Generic (
        disp_delay : natural := 100000000;
        total_bytes : natural := 4
    );
    Port ( CLK_100MHZ : in  STD_LOGIC;
           -- Debounced button inputs (4=U, 3=C, 2=R, 1=L, 0=D)
           USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
           -- Board switches (not debounced)
           SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
			  -- Board LEDs
           LED_DISPLAY : out  STD_LOGIC_VECTOR (7 downto 0);
			  -- Control signals for the data source
           RST_SOURCE : out  STD_LOGIC;
           EN_SOURCE : out  STD_LOGIC;
           SOURCE_DATA : in  STD_LOGIC_VECTOR (31 downto 0)
			  );
end STUDENT_AREA;

architecture Behavioral of STUDENT_AREA is

signal EN, RST, CLK : STD_LOGIC;
type state_type is (IDLE, DISP, BSEL);  -- The FSM states
signal state, next_state: state_type;   -- The states as signals

-- Internal signals for the counters enable and resets
signal DISP_CNT_OUT : UNSIGNED (log2(disp_delay)-1 downto 0);
signal BSEL_CNT_OUT : UNSIGNED (log2(total_bytes)-1 downto 0);
signal DISP_CNT_EN, BSEL_CNT_EN, DISP_CNT_RST, BSEL_CNT_RST : STD_LOGIC;

begin

RST <= USER_PB(1);
EN <= USER_PB(3);
CLK <= CLK_100MHZ;
RST_SOURCE <= RST;

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




-- Port map for the display delay counter
DISP_CNT: entity work.parameterizable_counter 
GENERIC MAP (LIMIT => disp_delay)
PORT MAP(
	clk => clk,
	rst => DISP_CNT_RST,
	enable => DISP_CNT_EN,
	count_out => DISP_CNT_OUT
);

-- Port map for the byte select counter
BSEL_CNT: entity work.parameterizable_counter 
GENERIC MAP (LIMIT => total_bytes)
PORT MAP(
	clk => clk,
	rst => BSEL_CNT_RST,
	enable => BSEL_CNT_EN,
	count_out => BSEL_CNT_OUT
);

fsm_process : process (state, en, rst, DISP_CNT_OUT, BSEL_CNT_OUT)
begin
    case state is
        when IDLE => 
            if en = '1' then
                next_state <= DISP;
            else 
                next_state <= state;
            end if;
        when DISP =>
            -- When all of the bytes has been displayed and the delay has been completed,
            -- we can go back to the IDLE state to wait for the next enable signal.
            if ((DISP_CNT_OUT = disp_delay-1 and BSEL_CNT_OUT = total_bytes - 1) or rst = '1') then
                next_state <= IDLE;
            -- If the display delay has completed but there are still more bytes to be
            -- displayed, the next state can be set to BSEL (byte select), where the
            -- BSEL counter is incremented.
            elsif (DISP_CNT_OUT = disp_delay-1 and BSEL_CNT_OUT < total_bytes - 1) then
                next_state <= BSEL;
            else 
                next_state <= state;
            end if;
        when BSEL =>
            -- Once the BSEL counter is incremented once, we can go back to the DISP state
            -- so the next byte can be displayed.
            if (rst = '1') then
                next_state <= IDLE;
            else
                next_state <= DISP;
            end if;
    end case;
end process fsm_process;









-- We want the display delay counter to be reset only when the state turns IDLE or BSEL
DISP_CNT_RST <= '1' when state = IDLE or state = BSEL else
                '0';
-- The byte select counter needs to be reset only at IDLE state.
BSEL_CNT_RST <= '1' when state = IDLE else
                '0';
-- The display delay counter needs to be enabled at the DISP state so the logic can hold
-- the LED display so it's visible to the user.
DISP_CNT_EN <= '1' when state = DISP else
               '0';
-- The byte select counter needs to be enabled only at the BSEL state so the counter can
-- increment so that the DISP state logic can use the counter value as an index for which
-- byte to display.
BSEL_CNT_EN <= '1' when state = BSEL else
               '0';
               
-- Once the DISP state has been reached with the delay and byte select counter at zero,
-- the data source needs to be enabled so the next value can be computed and displayed.
EN_SOURCE <= '1' when state = DISP and DISP_CNT_OUT = 0 and BSEL_CNT_OUT = 0 else
             '0';

-- The correct byte needs to displayed via the LED display. In the DISP state, the BSEL
-- counter is used as an index and the bytes are displayed.
LED_DISPLAY <= SOURCE_DATA(31 downto 24) when state = DISP and BSEL_CNT_OUT = 0 else
               SOURCE_DATA(23 downto 16) when state = DISP and BSEL_CNT_OUT = 1 else
               SOURCE_DATA(15 downto 8) when state = DISP and BSEL_CNT_OUT = 2 else
               SOURCE_DATA(7 downto 0) when state = DISP and BSEL_CNT_OUT = 3 else
               "00000000";

end Behavioral;
