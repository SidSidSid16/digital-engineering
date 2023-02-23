library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- This entity implements the control logic for the BIST system. 
-- It is based on a simple two-state FSM that enters a TEST state 
--   when the user presses the B_TEST button. In this state, the
--   unit outputs the test patterns stored in an internal RAM in
--   sequence, one per clock cycle and checks that the output 
--   matches the known-good value (stored in the RAM along with 
--   the test patterns).
-- If no fault is detected, the FSM goes back to the NORMAL state
--   and the UUT returns to standard operation.
-- If a fault is detected, the FSM freezes in the TEST state and
--   outputs a faulty signal along with a fault ID (the address of
--   the test pattern for which the fault was detected). Only the
--   global reset can then take the FSM out of this state.
entity BIST_Ctrl is
Port ( CLK : in  STD_LOGIC;
       B_RST : in  STD_LOGIC;
       -- (Debounced) user button that activates test mode
       B_TEST : in  STD_LOGIC;
       -- The (one-bit) output of the UUT
       UUT_OUT : in  STD_LOGIC;
       -- The (6-bit) test pattern to be sent to the UUT
       TEST : out  STD_LOGIC_VECTOR (5 downto 0);
       -- '1' when the system is in test mode, '0' otherwise
       -- Used in the top level to de-gate the UUT 
       MODE : out  STD_LOGIC;
       -- '1' when a fault has been detected, '0' otherwise
       L_ERR : out  STD_LOGIC;
       -- ID (RAM address) of the test pattern that detected
       --  the fault. Note that this is "don't care" if L_ERR='0'
       L_ID : out  STD_LOGIC_VECTOR (3 downto 0));
end BIST_Ctrl;

architecture Behavioral of BIST_Ctrl is

-- FSM states:
--  NORMAL_MODE: the circuit is operating normally
--  TEST_MODE: the circuit is in test mode
type state is (NORMAL_MODE, TEST_MODE);
-- present and next state signals for the FSM 
signal present_state, next_state : state; 
-- keeping track of current pattern ID (used as RAM address) 
signal L_ID_counter : UNSIGNED(3 downto 0); 
-- '1' if all patterns tested 
signal test_complete : STD_LOGIC; 
-- '1' if UUT output differes from expected output, '0' otherwise
signal err_detected : STD_LOGIC; 
-- RAM output - test inputs (6:1=A:F) and expected output (0:0=L) 
signal test_vector : STD_LOGIC_VECTOR (6 downto 0); 

-- Number of test patterns in the RAM
constant test_patterns_number : integer := 7;

	-- Xilinx compiler directives to prevent signal from being
	-- removed or renamed during the synthesis process so ILA
	-- can be used to analyse the logic.
	attribute mark_debug : string;
    attribute mark_debug of present_state : signal is "true";
    attribute mark_debug of L_ID_counter : signal is "true";

begin

-- FSM state assignment process
present_state_register : process (CLK) 
begin 
  if(rising_edge(CLK)) then 
    if(B_RST='1') then 
      present_state <= NORMAL_MODE; 
    else 
      present_state <= next_state;  	 	
    end if; 
  end if; 
end process; 

-- FSM transition process
next_state_logic : process (present_state,B_TEST,err_detected,test_complete) 
begin 
  case(present_state) is  	 	
    when NORMAL_MODE =>  	 	 	
      if (B_TEST='1') then  	 	 	--circuit enters test mode 
        next_state <= TEST_MODE; 
      else 
        next_state  <= present_state; 
      end if; 
    when TEST_MODE =>
      -- if all patterns have been tested and no error has been
      --  detected, go back to normal mode.
      if (test_complete='1' and err_detected='0') then 	 	 	
       	next_state <= NORMAL_MODE; 
 	  else 
        next_state  <= present_state;    
	  end if; 
    when others =>  -- just in case something has gone wrong	 	 	
      next_state <= NORMAL_MODE; 
  end case; 
end process; 

-- FSM output signals
-- Flags the presence of an error when the circuit is in test mode
L_ERR <= '1' when present_state=TEST_MODE and err_detected='1' else
         '0';
-- Outputs the current state of the control FSM
MODE <= '1' when present_state=TEST_MODE else
        '0';
        
---------------------------------------------------------
-- NOTE: the following entity instantiation assumes that
--       your RAM has been named "Test_Pattern_RAM" in the
--       core generator. If you picked a different name,
--       you will need to update the code below. 
---------------------------------------------------------
            
-- RAM that stores the test patterns (6:1) and the known-good
--   output (0:0)
-- Normally, this would be a ROM but asynchronous ROMs have been
--   known to cause problems in the Xilinx tools.
TestVectorRAM : entity work.Test_Pattern_RAM 
  PORT MAP ( 
    a  	=> std_logic_vector(L_ID_counter),     
	 d  	=> (others => '0'),--tying data input to 0 
    clk  	=> CLK,     
	 we  	=> '0',--so RAM behaves like ROM. 
    spo  	=> test_vector 
  ); 


counter_process : process(clk) 
begin 
  if (rising_edge(clk)) then 
    --synchronous reset 
    if (B_RST='1') then 
      L_ID_counter <= (others => '0'); 
    else 
    -- freeze if a fault has been detected or if not in test mode
      if (present_state=TEST_MODE and err_detected='0') then
        -- back to 0 if limit reached (all patterns sent)
        if (test_complete='1') then
          L_ID_counter <= (others => '0');
        else
          L_ID_counter <= L_ID_counter + 1;     
        end if;
      end if; 
    end if;
  end if;
end process; 
 	
-- Flag if all test patterns have been sent
test_complete <= '1' when L_ID_counter=test_patterns_number-1 else
                 '0';
-- Detect if UUT output and known-good output are different
--   (only used in test mode)
err_detected <= UUT_OUT XOR test_vector(0); 
 
-- Mapping internal signals to outputs
--   Test pattern for the UUT
TEST <= test_vector(6 downto 1);
--   Error ID (only used if L_ERR = '1')
L_ID <= std_logic_vector(L_ID_counter); 


end Behavioral;
