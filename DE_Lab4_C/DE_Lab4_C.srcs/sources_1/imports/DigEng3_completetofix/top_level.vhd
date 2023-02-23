library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top level entity for the BIST system. The circuit implements a 
--   combinational UUT with 5 input and 1 output STD_LOGIC signals.
--   The unit includes fault injection logic for three stuck-at faults.
-- Until the B_TST button is pressed, the UUT operates normally on
--   the inputs set by the user using board switches.
-- When the use presses the B_TST button, the circuit de-gates the
--   switch inputs and performs a self-test by sending a set of test
--   patterns to the UUT (one per clock cycle) and comparing the output
--   of the UUT to the known-good response.
-- If no fault is detected, the unit exits test mode and resumes 
--   normal operation.
-- If a fault is detected, the circuit freezes, sets the L_ERR output
--   to '1' and outputs the address of the test pattern that detected
--   the fault on the L_ID lines.
-- Note: to prevent collisions, the selected fault is "locked" during
--   the test process.
entity top_level is
Port ( GCLK : in  STD_LOGIC; -- 100MHz global clock
       -- Active-high global reset (BTNL button)
       B_RST : in  STD_LOGIC; 
       -- User inputs to the UUT (switches 5:0)
       INPUTS : in  STD_LOGIC_VECTOR (5 downto 0);
       -- Active-high input that starts BIST (BTNC button)
       B_TEST : in  STD_LOGIC;
       -- Select fault to be injected (switches 7:6)
       --   00 = no fault
       --   01 = E s-a-1
       --   10 = H s-a-0
       --   11 = F s-a-0
       B_F : in  STD_LOGIC_VECTOR (1 downto 0);
       L_OUT : out  STD_LOGIC; -- Output of the UUT (LED0)
       -- Signal goes high when the BIST detects an error (LED2)
       L_ERR : out  STD_LOGIC;
       -- Outputs ID of the error, i.e. the address of the test
       --   pattern that has detected the error (LED7:4)
       L_ID : out  STD_LOGIC_VECTOR (3 downto 0));
end top_level;

architecture Behavioral of top_level is

    -- An internal signal for the 25MHz clock from the clk manager
    -- needs to be instantiated
    signal CLK_25MHz : STD_LOGIC;
    -- Test patterns generated by the BIST unit
	signal TEST : STD_LOGIC_VECTOR (5 downto 0);
	-- Inputs to the UUT: user inputs during normal operation 
	--   or test patterns during test 
	signal VECTOR : STD_LOGIC_VECTOR (5 downto 0);
	-- Fault selection (locked during test)
	signal B_F_SET : STD_LOGIC_VECTOR (1 downto 0);
	-- Flag for the operating mode of the circuit:
	--   '0' during normal operation
	--   '1' during test
	signal MODE: STD_LOGIC;
	-- Debounced control inputs
	signal B_RST_DB, B_TEST_DB: STD_LOGIC;
	-- Output of the UUT
	signal UUT_OUT: STD_LOGIC;
	
	-- Xilinx compiler directives to prevent signal from being
	-- removed or renamed during the synthesis process so ILA
	-- can be used to analyse the logic.
	attribute mark_debug : string;
    attribute mark_debug of B_TEST_DB : signal is "true";
    attribute mark_debug of B_RST_DB : signal is "true";
    attribute mark_debug of VECTOR : signal is "true";
    attribute mark_debug of UUT_OUT : signal is "true";
    attribute mark_debug of B_F_SET : signal is "true";
    attribute mark_debug of L_ERR : signal is "true";
    attribute mark_debug of L_ID : signal is "true";
    
    
begin

-- Instantiate the clock manager for the 25MHz clk
dcm_mgr : entity work.clock_manager
PORT MAP (
    -- 100MHz clock input
    CLK_IN1 => GCLK,
    -- 25MHz clock output
    CLK_OUT2 => CLK_25MHz
);

-- Debouncers for the reset and test buttons.
Inst_Debouncer_RST: entity work.Debouncer PORT MAP(
  CLK => CLK_25MHz,
  Sig => B_RST,
  Deb_Sig => B_RST_DB
);
Inst_Debouncer_TEST: entity work.Debouncer PORT MAP(
  CLK => CLK_25MHz,
  Sig => B_TEST,
  Deb_Sig => B_TEST_DB
);

-- This register "locks" the fault selected by the B_F switches when
--  the B_TEST button is pressed and does not allow any changes until
--  the test is complete. 
-- Note that if the BIST detects a fault, this will lock "mode" to '1'
--  and the register will only be cleared by the global reset.
SET_FLT: process (CLK_25MHz) is
begin
  if rising_edge(CLK_25MHz) then
    if B_RST_DB = '1' then
      B_F_SET <= (others => '0');
    elsif B_TEST_DB = '1' and MODE = '0' then 
      B_F_SET <= B_F;
    end if;
  end if;
end process SET_FLT;

-- Circuit that contains the UUT, including fault injection logic.
Inst_UUT: entity work.UUT PORT MAP(
  FLT => B_F_SET,
  INPUTS => VECTOR,
  OUTPUT => UUT_OUT
);

-- This entity implements the BIST subsystem.
Inst_BIST: entity work.BIST_Ctrl PORT MAP(
  CLK => CLK_25MHz,
  B_RST => B_RST_DB,
  B_TEST => B_TEST_DB,
  UUT_OUT => UUT_OUT,
  TEST => TEST,
  MODE => MODE,
  L_ERR => L_ERR,
  L_ID => L_ID
);

-- Mux used to de-gate the inputs when the circuit is in test mode.
-- User inputs will be replaced by the test patterns output by the 
--   BIST unit.
VECTOR <= TEST WHEN MODE = '1' ELSE INPUTS;

-- Maps the output of the UUT to one of the LEDs.
L_OUT <= UUT_OUT;
	
end Behavioral;

