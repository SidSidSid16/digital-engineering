library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- This entity is a simple wrapper for the STUDENT_AREA entity,
--   providing I/Os to the board's LEDs, switches, and 
--   pushbuttons, debounced and clock-synchronised when needed.
-- It also includes a DATA_SOURCE that generates 32-bit unsigned
--   values for manipulation.

entity TOP_LEVEL is
    Generic (disp_delay : natural := 100000000);
    Port ( GCLK : in  STD_LOGIC; -- 100MHz global clock
			  -- Button inputs (4=U, 3=C, 2=R, 1=L, 0=D)
           BTN : in  STD_LOGIC_VECTOR (4 downto 0);
			  -- Board switches
           SW : in  STD_LOGIC_VECTOR (7 downto 0);
			  -- Board LEDs
           LD : out  STD_LOGIC_VECTOR (7 downto 0));
end TOP_LEVEL;

architecture Behavioral of TOP_LEVEL is

-- Debounced button inputs (4=U, 3=C, 2=R, 1=L, 0=D)
signal btn_db_7MHZ, btn_db_100MHZ : STD_LOGIC_VECTOR (4 downto 0); 
-- Internal control signals for the data_source component
signal rst_source, en_source : STD_LOGIC;
signal source_data : STD_LOGIC_VECTOR (31 downto 0);

-- Internal clock signals
signal CLK_7MHZ, CLK_100MHZ : STD_LOGIC;

begin


-- Clock management unit: generates two clocks:
--   - 100MHz for the output logic
--   - 7MHZ for the source unit
Clock_generator : entity work.CLK_GEN
port map
	(-- Clock in ports
	CLK_IN1 => GCLK,
	-- Clock out ports
	CLK_OUT1 => CLK_100MHZ,
	CLK_OUT2 => CLK_7MHZ
);

-- For the follwowing units, the input signals go through
--   two debouncers/synchronisers in series: first they 
--   are synchronised to the (slower) source clock, then to
--   the (faster) output clock. This ensures that each will
--   have a one-pulse duration for either clock domain and
--   that the delay between pulses is constant.

debouncers: for i in 0 to 4 generate
	button_debouncer_7MHZ : entity work.Debouncer 
	PORT MAP(
		CLK => CLK_7MHZ,
		Sig => BTN(i),
		Deb_Sig => btn_db_7MHZ(i) -- (4=U, 3=C, 2=R, 1=L, 0=D)
	);
	button_debouncer_100_MHZ : entity work.Debouncer 
	PORT MAP(
		CLK => CLK_100MHZ,
		Sig => btn_db_7MHZ(i),
		Deb_Sig => btn_db_100MHZ(i) -- (4=U, 3=C, 2=R, 1=L, 0=D)
	);
end generate;


-- This entity will contain the work to be carried out
--   for each task. Note that some I/Os might not be needed.	
STUDENT_AREA_component: entity work.STUDENT_AREA 
GENERIC MAP (disp_delay => disp_delay)
PORT MAP(
	CLK_100MHZ => CLK_100MHZ,
	CLK_7MHZ => CLK_7MHZ,
	USER_PB_7MHZ => btn_db_7MHZ, 		   -- (4=U, 3=C, 2=R, 1=L, 0=D)
	USER_PB_100MHZ => btn_db_100MHZ, 	-- (4=U, 3=C, 2=R, 1=L, 0=D)
	SWITCHES => SW,  	   -- Not debounced
	LED_DISPLAY => LD,
	-- Control signals for the data source
	RST_SOURCE => rst_source,
	EN_SOURCE => en_source,
	SOURCE_DATA => source_data
);

-- This component will generate data for manipulation in the
--   STUDENT_AREA component. Its control signals, including
--   the clock, are generated by the STUDENT_AREA component.
-- Note that the circuit has a maximum operating frequency of
--   7MHZ. The EN input can be used to put the circuit on hold. 
DATA_SOURCE_component: entity work.DATA_SOURCE 
GENERIC MAP (data_size => 16,
				 num_samples => 64)
PORT MAP(
	CLK => CLK_7MHZ,
	RST => rst_source,
	EN => en_source,
	DATA_OUT => source_data
);

end Behavioral;

