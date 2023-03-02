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
--      Following from TEST 1, a reset will be inputted via the
--      pushbutton. This is the verify that the circuit resets
--      properly and goes back to the initial state.
--
--  TEST 3:
--      Cycle through the first 5 values just like in TEST 1, but
--      the enable button will be pressed while the FSM is in the
--      DISP state (after the 2nd input). This test will verify
--      that the enable input will be ignored when the FSM is not
--      in IDLE state.
--
--  TEST 4:
--      Continue from TEST 3, the reset button will be toggled after
--      the 4th input, this will verify that the circuit can be reset
--      while the FSM is in operation.
ARCHITECTURE behavior OF TOP_LEVEL_tb IS 
    --Inputs
    signal GCLK : STD_LOGIC;
    signal BTN : STD_LOGIC_VECTOR(4 downto 0);
    signal SW : STD_LOGIC_VECTOR(7 downto 0);
    --Outputs
    signal LED : STD_LOGIC_VECTOR(7 downto 0);
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
        LED => LED
    );
    
    -- Clock process definitions
    GCLK_process : process
    begin
        GCLK <= '0';
        wait for GCLK_period/2;
        GCLK <= '1';
        wait for GCLK_period/2;
    end process;
    
    -- Stimulus process
    set_inputs : process
    begin		
        -- hold reset state for 100 ns.
        wait for 100 ns;	
        
        -- TEST 1:
        --  Global Reset & Initialisation
        --  Duration: 24 clock cycles
        BTN <= "00000";
        SW <= "00000000";
        wait for GCLK_period*18;
        BTN(1) <= '1';
        wait for GCLK_period*6;
        BTN(1) <= '0';
        
        wait for GCLK_period*18;
        
        -- TEST 1
        --  Duration:
        --      5 vectors * (132 clk cycles)
        --      660 clock cycles
        test_1_loop : for i in 0 to 4 loop
            BTN(3) <= '1';
            wait for GCLK_period*6;
            BTN(3) <= '0';
            -- We need to wait for 124 clock cycles as we need to
            -- account for 4x DISP (30 clk cycles) + 3x BSEL (1 clk cycle)
            -- plus 3 clock cycles for the IDLE state
            wait for GCLK_period*126;
        end loop;
        
        -- TEST 2
        --  Duration: 6 clock period
        BTN(1) <= '1';
        wait for GCLK_period*6;
        BTN(1) <= '0';
        
        wait for GCLK_period*18;
        
        -- TEST 3
        --  Duration:
        --      5 vectors * (132 clk cycles)
        --      660 clock cycles
        test_3_loop : for i in 0 to 3 loop
            BTN(3) <= '1';
            wait for GCLK_period*6;
            BTN(3) <= '0';
            
            -- Toggle enable after the 2nd vector has been passed.
            if (i = 1) then
                wait for GCLK_period*25;
                BTN(3) <= '1';
                wait for GCLK_period*6;
                BTN(3) <= '0';
                wait for GCLK_period*95;
            elsif (i /= 3) then
                -- We need to wait for 124 clock cycles as we need to
                -- account for 4x DISP (30 clk cycles) + 3x BSEL (1 clk cycle)
                -- plus 3 clock cycles for the IDLE state
                wait for GCLK_period*126;
            end if;
        end loop;
        
        -- TEST 4
        --  Duration: 31 clock period
        wait for GCLK_period*25;
        BTN(1) <= '1';
        wait for GCLK_period*6;
        BTN(1) <= '0';
        
        wait for GCLK_period*18;
        
        wait;
    end process;
    
    check_outputs : process
    begin
        -- Wait for hold reset state.
        wait for 100 ns;
        -- Wait for Global Reset & Initialisation
        wait for GCLK_period*42;
        
        -- TEST 1
        test_1_test_check_loop : for i in 0 to 19 loop
            -- Wait for the enable signal to toggle
            wait for GCLK_period*6;
            -- Check if the LED output matches the array of known valid output at
            -- the end of every enable btn toggle, as soon as the btn is depressed.
            -- Notify if it's a pass or fail. I'm using severity warning to ensure
            -- that the simulation doesn't halt as soon as a vector fails like it
            -- does for severity failure.
            assert (( LED = valid_outputs(i) ))
            report "TEST VECTOR " & integer'image(i) &
                    " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LED))) & 
                    " Expected LED Output = " & integer'image(to_integer(unsigned(valid_outputs(i))))
            severity warning;
            report "TEST VECTOR " & integer'image(i) & " PASS."
            severity note;
            wait for GCLK_period*25;
            -- Wait for an additional 8 clk periods at the end of the 4 LED bytes
            -- display to synchronise with the next input.
            if ( (i+1) mod 4 = 0 ) then
                wait for GCLK_period*8;
            end if;
        end loop;
        
        -- TEST 2
        --  wait for 6 clk periods for the push button to finish toggling
        wait for GCLK_period*6;
        assert (( LED = X"00" ))
        report "TEST 2 " &
                " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LED))) & 
                " Expected LED Output = 0"
        severity warning;
        report "TEST 2 PASS."
        severity note;
        
        wait for GCLK_period*18;
        
        
        
        
        
        
        
        
        
        
        
        
        
        -- TEST 3
        test_3_test_check_loop : for i in 0 to 11 loop
            -- Wait for the enable signal to toggle
            wait for GCLK_period*6;
            -- Check if the LED output matches the array of known valid output at
            -- the end of every enable btn toggle, as soon as the btn is depressed.
            -- Notify if it's a pass or fail. I'm using severity warning to ensure
            -- that the simulation doesn't halt as soon as a vector fails like it
            -- does for severity failure.
            assert (( LED = valid_outputs(i) ))
            report "TEST VECTOR " & integer'image(i) &
                    " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LED))) & 
                    " Expected LED Output = " & integer'image(to_integer(unsigned(valid_outputs(i))))
            severity warning;
            report "TEST VECTOR " & integer'image(i) & " PASS."
            severity note;
            wait for GCLK_period*25;
            -- Wait for an additional 8 clk periods at the end of the 4 LED bytes
            -- display to synchronise with the next input.
            if ( (i+1) mod 4 = 0 ) then
                wait for GCLK_period*8;
            end if;
        end loop;
        
        -- TEST 4
        -- wait for 6 clk periods for the push button to finish toggling
        wait for GCLK_period*6;
        -- wait for reset to be toggled
        wait for GCLK_period*31;
        assert (( LED = valid_outputs(0) ))
        report "TEST 4 " &
                " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LED))) & 
                " Expected LED Output = " & integer'image(to_integer(unsigned(valid_outputs(0))))
        severity warning;
        report "TEST 4 PASS."
        severity note;
        
        wait;
    end process;
END;
