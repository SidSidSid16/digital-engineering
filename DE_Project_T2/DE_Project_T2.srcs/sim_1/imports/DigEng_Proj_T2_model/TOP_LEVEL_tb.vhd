LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
ENTITY TOP_LEVEL_tb IS
END TOP_LEVEL_tb;

-- TEST STRATEGY
--  
--  Global Reset & Initialisation:
--      Outside of this vector, all btn inputs will initialise
--      to zeros, followed by a reset button click.
--
--  TEST 1:
--      Cycle through the first 5 values, this is the ensure that
--      all logic within this circuit is functioning properly.
--
--  TEST 2:
--      Following from Test 1, once the last byte has been output,
--      we need to verify that the LEDs output zeros.
--
--  TEST 3:
--      Following from TEST 1, a reset will be inputted via the
--      pushbutton. This is the verify that the circuit resets
--      properly and goes back to the initial state.
--
--  TEST 4:
--      Cycle through the first 5 values just like in TEST 1, but
--      the enable button will be pressed while the logic is in
--      operation (after the 1st input). This test will verify
--      that the enable input will be ignored.
--
--  TEST 5:
--      Continue from TEST 3, the reset button will be toggled after
--      the 4th input, this will verify that the circuit can be reset
--      while the FSM is in operation.
--
--  TEST 6:
--      Cycle through the first 5 values just like in TEST 3, but
--      the switches will be changed while the FSM is operation
--      (after the 2nd input). This test will verify that changing
--      the switches will be ignored when the FSM is in operation.
--
--  TEST 7:
--      Cycle through as many inputs as it takes to cause the FIFO
--      to become full, verify that the circuit can still function
--      as designed and handle the FIFO becoming full.

ARCHITECTURE behavior OF TOP_LEVEL_tb IS 
   --Inputs
   signal GCLK : std_logic;
   signal BTN : std_logic_vector(4 downto 0);
   signal SW : std_logic_vector(7 downto 0);

 	--Outputs
   signal LD : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant GCLK_period : time := 10 ns;
   
   -- Defining a record of valid outputs to verify the circuit.
   -- The inputs to this circuit (via pushbuttons) will be done
   -- outside of the test vector array.
   type valid_output_array is array (natural range <>) of STD_LOGIC_VECTOR(7 downto 0);
   constant valid_outputs : valid_output_array := (
       -- OUTPUT 1 (4800C00B)
       (X"48"),
       (X"00"),
       (X"C0"),
       (X"0B"),
       -- OUTPUT 2 (0000CA5F)
       (X"00"),
       (X"00"),
       (X"CA"),
       (X"5F"),
       -- OUTPUT 3 (0000570E)
       (X"00"),
       (X"00"),
       (X"57"),
       (X"0E"),
       -- OUTPUT 4 (0380DFAD)
       (X"03"),
       (X"80"),
       (X"DF"),
       (X"AD"),
       -- OUTPUT 5 (0000006C)
       (X"00"),
       (X"00"),
       (X"00"),
       (X"6C")
    );
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.TOP_LEVEL 
   GENERIC MAP (disp_delay => 30)
   PORT MAP (
          GCLK => GCLK,
          BTN => BTN,
          SW => SW,
          LD => LD
   );

   -- Clock process definitions
   GCLK_process :process
   begin
		GCLK <= '0';
		wait for GCLK_period/2;
		GCLK <= '1';
		wait for GCLK_period/2;
   end process;
 

   -- Stimulus process
   set_inputs: process
   begin		
    -- hold reset state for at least 2000 ns.
    wait for 2500 ns;	
	wait until falling_edge(GCLK);

    -- TEST 0:
    --  Global Reset & Initialisation
    --  Duration: 248 clock periods
    BTN <= "00000";
    SW <= "00000000";
    wait for GCLK_period*18;
    BTN(1) <= '1';
    wait for GCLK_period*30;
    BTN(1) <= '0';
    -- Wait for at least 200 clock periods after
    -- each reset.
    wait for GCLK_period*200;
    
    -- TEST 1:
    --  Duration: 761.5 clock periods
    SW <= "00000101";
    BTN(3) <= '1';
    wait for GCLK_period*30;
    BTN(3) <= '0';
    
    wait for GCLK_period*765;
    
    -- TEST 2:
    --  Duration: 150 clock periods
    wait for GCLK_period*150;
    
    -- TEST 3:
    --  Duration: 230 clock periods
    BTN(1) <= '1';
    wait for GCLK_period*30;
    BTN(1) <= '0';
    wait for GCLK_period*200;
    
    wait for GCLK_period*150;
    
    -- TEST 4:
    --  Duration: 761.5 clock periods
    SW <= "00000101";
    BTN(3) <= '1';
    wait for GCLK_period*30;
    BTN(3) <= '0';
    -- wait until the end of first output display for enable toggle.
    wait for GCLK_period*162.51;
    BTN(3) <= '1';
    wait for GCLK_period*30;
    BTN(3) <= '0';
    
    -- TEST 5:
    -- wait until the end of third output display for reset toggle.
    wait for GCLK_period*210;
    BTN(1) <= '1';
    wait for GCLK_period*30;
    BTN(1) <= '0';
    
    wait for GCLK_period*200;
    
    -- TEST 6:
    SW <= "00000101";
    BTN(3) <= '1';
    wait for GCLK_period*30;
    BTN(3) <= '0';
    -- wait until 2nd output has been fully displayed
    wait for GCLK_period*304.5;
    SW <= "00000011";
    
    -- TEST 7
    wait for GCLK_period*800;
    BTN(1) <= '1';
    wait for GCLK_period*30;
    BTN(1) <= '0';
    wait for GCLK_period*200;
    SW <= "00100011";
    BTN(3) <= '1';
    wait for GCLK_period*30;
    BTN(3) <= '0';
    
    wait;
end process;


check_outputs : process
begin
    -- hold reset state for at least 2000 ns.
    wait for 2500 ns;    
    wait until falling_edge(GCLK);
    -- Wait for Test 0 (resets) to complete
    wait for GCLK_period*248;
    
    -- TEST 1:
    --  The outputs start displaying as soon as the 
    --  OUTPUT FSM goes to FSM state, which takes 69.5
    --  clock periods. We will start checking from 72
    --  clock cycles so that the LEDs would've output
    --  2.5 clock periods before.
    wait for GCLK_period*72;
    test_1_check_loop : for i in 0 to 19 loop
        -- Check if the LED output matches the array of known valid output at
        -- the end of every enable btn toggle, as soon as the btn is depressed.
        -- Notify if it's a pass or fail. I'm using severity warning to ensure
        -- that the simulation doesn't halt as soon as a vector fails like it
        -- does for severity failure.
        assert (( LD = valid_outputs(i) ))
        report "TEST 1 VECTOR " & integer'image(i) &
        " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
        " Expected LED Output = " & integer'image(to_integer(unsigned(valid_outputs(i))))
        severity warning;
        report "TEST 1 VECTOR " & integer'image(i) & " PASS."
        severity note;
        -- LEDs display for 30 clk cycles, 
        wait for GCLK_period*30;
    end loop;
    wait for GCLK_period*94;
    
    -- TEST 2:
    --  The sequence has finished, the LEDs should be outputting 0, we need to check this.
    assert (( LD = x"00" ))
    report "TEST 2 " &
    " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
    " Expected LED Output = 0"
    severity warning;
    report "TEST 2 PASS."
    severity note;
    
    wait for GCLK_period*149;
    
    -- TEST 3:
    --  The LEDs should stay at zeros after the reset. We need to wait for
    --  230 clock periods for the reset to complete and an additional 5
    --  periods so we can read the output.
    wait for GCLK_period*235;
    assert (( LD = x"00" ))
    report "TEST 3 " &
    " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
    " Expected LED Output = 0"
    severity warning;
    report "TEST 3 PASS."
    severity note;
    
    wait for GCLK_period*175;
    
    
    -- TEST 4:
    --  Check if the enable button is ignored when the logic is in operation.
    --  It takes 72.5 clk periods to go from en high to an output, we can wait
    --  an additional 2.5 periods then measure.
    wait for GCLK_period*75;
    test_4_check_loop : for i in 0 to 11 loop
        -- Check if the LED output matches the array of known valid output at
        -- the end of every enable btn toggle, as soon as the btn is depressed.
        -- Notify if it's a pass or fail. I'm using severity warning to ensure
        -- that the simulation doesn't halt as soon as a vector fails like it
        -- does for severity failure.
        assert (( LD = valid_outputs(i) ))
        report "TEST 4 VECTOR " & integer'image(i) &
        " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
        " Expected LED Output = " & integer'image(to_integer(unsigned(valid_outputs(i))))
        severity warning;
        report "TEST 4 VECTOR " & integer'image(i) & " PASS."
        severity note;
        -- LEDs display for 30 clk cycles, 
        wait for GCLK_period*30;
    end loop;
    
    -- TEST 5
    wait for GCLK_period*30;
    assert (( LD = x"00" ))
    report "TEST 5 " &
    " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
    " Expected LED Output = 00"
    severity warning;
    report "TEST 5 PASS."
    severity note;
    
    wait for GCLK_period*200;
    
    
    -- TEST 6
    wait for GCLK_period*67;
    test_6_check_loop : for i in 0 to 19 loop
        -- Check if the LED output matches the array of known valid output at
        -- the end of every enable btn toggle, as soon as the btn is depressed.
        -- Notify if it's a pass or fail. I'm using severity warning to ensure
        -- that the simulation doesn't halt as soon as a vector fails like it
        -- does for severity failure.
        assert (( LD = valid_outputs(i) ))
        report "TEST 6 VECTOR " & integer'image(i) &
        " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
        " Expected LED Output = " & integer'image(to_integer(unsigned(valid_outputs(i))))
        severity warning;
        report "TEST 6 VECTOR " & integer'image(i) & " PASS."
        severity note;
        -- LEDs display for 30 clk cycles, 
        wait for GCLK_period*30;
    end loop;
    
    wait;
end process;


END;
