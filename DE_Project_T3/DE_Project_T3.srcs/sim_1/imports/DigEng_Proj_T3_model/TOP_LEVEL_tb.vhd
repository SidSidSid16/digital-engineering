LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY TOP_LEVEL_tb IS
END TOP_LEVEL_tb;

-- TEST STRATEGY
--  
--  Global Reset & Initialisation:
--      Outside of this vector, all inputs will initialise to
--      zeros, followed by a reset button click.
--
--  TEST 1 (verify by inspecting waveform):
--      Enter WRITE mode by pressing the write btn, ensure all
--      handshaking aspects of the SPI is working correctly,
--      mainly SPI enables, reqs are sent, acks are received and
--      the correct data is sent.
--
--  TEST 2 (verify by inspecting waveform):
--      Following from Test 1, exit WRITE mode by toggling the
--      write btn. The logic should be able to deactivate the SPI
--      and return back to IDLE.
--
--  TEST 3 (verify by inspecting waveform):
--      Toggle the READ btn to try to enter read mode. This will be blocked
--      by the logic as you can only enter read mode after storing 1 or more
--      values into the SRAM in the write mode.
--
--  TEST 4 (verify by inspecting waveform):
--      Following from TEST 2, toggle the write button again to enter
--      WRITE mode, then store 10 switch values, starting from h"00" and
--      incrementing by 1 each time. Then exit WRITE mode in preparation
--      for the next test. This test should verify that the SPI handshaking
--      logic works when writing data to the SRAM.
--
--  TEST 5 (verify by inspecting waveform):
--      Toggle the WRITE btn to try to enter write mode again. This should be
--      blocked by the logic which prevents write mode to be entered after
--      writing 1 or more values and exiting beforehand.
--
--  TEST 6 (verify by inspecting self-check console output):
--      As we've stored 10 (more than 0) switch values and exited WRITE
--      mode in the previous test, the circuit should now be in RDHOLD
--      state, waiting for the user to toggle the READ btn. As soon as
--      that btn is toggled, the circuit should read and display the
--      exact values that we're previously written, and should stop as
--      soon as all values previously written have been displayed. This
--      test will verify that the circuit can perform this function.










ARCHITECTURE behavior OF TOP_LEVEL_tb IS 
    
    --Inputs
    signal GCLK : std_logic := '0';
    signal BTN : std_logic_vector(4 downto 0);
    signal SW : std_logic_vector(7 downto 0);
    
    --Outputs
    signal LD : std_logic_vector(7 downto 0);
    
    -- Internal SPI signals
    signal SPI_MISO: STD_LOGIC;
    signal SPI_MOSI: STD_LOGIC;
    signal SPI_CS_INV: STD_LOGIC;
    signal SPI_HOLD_INV: STD_LOGIC;
    signal SPI_SCK: STD_LOGIC;
    
    -- Clock period definitions
    constant GCLK_period : time := 10 ns;
 
BEGIN
 
-- Instantiate the Unit Under Test (UUT)
uut: entity work.TOP_LEVEL 
GENERIC MAP (disp_delay => 30)
PORT MAP (
    GCLK => GCLK,
    BTN => BTN,
    SW => SW,
    LD => LD,
    SPI_MISO => SPI_MISO,
    SPI_SCK => SPI_SCK,
    SPI_CS_INV => SPI_CS_INV,
    SPI_HOLD_INV => SPI_HOLD_INV,
    SPI_MOSI => SPI_MOSI
);

-- Clock process definitions
GCLK_process :process
begin
    GCLK <= '0';
    wait for GCLK_period/2;
    GCLK <= '1';
    wait for GCLK_period/2;
end process;
 
SRAM: entity work.SRAM_Model
PORT MAP (
    SPI_MISO => SPI_MISO,
    SPI_SCK => SPI_SCK,
    SPI_CS_INV => SPI_CS_INV,
    SPI_HOLD_INV => SPI_HOLD_INV,
    SPI_MOSI => SPI_MOSI
);

-- Stimulus process
set_inputs: process
begin		
    -- hold reset state for 1000 ns.
    wait for 1000 ns;
    
    ----------------------------    
    -- Global Reset & Initialisation
    --------
    
    SW <= "00000000";
    BTN <= "00000";
    wait for GCLK_period*18;
    BTN(0) <= '1';              -- toggle the RESET btn
    wait for GCLK_period*36;
    BTN(0) <= '0';
    
    wait for GCLK_period*120;
    
    ----------------------------    
    -- TEST 1
    --------
    
    BTN(1) <= '1';              -- toggle the WRITE btn
    wait for GCLK_period*36;
    BTN(1) <= '0';
                                -- check if WRITE mode is
    wait for GCLK_period*500;   -- entered by verifying SPI
                                -- handshaking int. signals.
                                  
    ----------------------------    
    -- TEST 2
    --------
    
    BTN(1) <= '1';              -- toggle the WRITE btn
    wait for GCLK_period*36;
    BTN(1) <= '0';
                                -- check if WRITE mode is
    wait for GCLK_period*100;   -- exited.
    
    ----------------------------    
    -- TEST 3
    --------
    
    BTN(2) <= '1';              -- toggle the READ btn
    wait for GCLK_period*36;
    BTN(2) <= '0';
                                -- check if READ mode request
    wait for GCLK_period*100;   -- is ignored.
                              
    ----------------------------    
    -- TEST 4
    --------
    
    BTN(1) <= '1';              -- toggle the WRITE btn to
    wait for GCLK_period*36;    -- enter WRITE MODE
    BTN(1) <= '0';
                                -- Wait for logic to init
    wait for GCLK_period*450;   -- the SPI and enter WRHOLD
                                -- before entering vals.
    
    
    
    
    
    
    
    test_4_input_loop : for i in 0 to 9 loop
        SW <= STD_LOGIC_VECTOR(
                to_unsigned(i, SW'length)
              );                    -- SW set to for-loop counter value
        BTN(3) <= '1';              -- toggle the ENTER btn to enter the
        wait for GCLK_period*36;    -- switch val to SRAM
        BTN(3) <= '0';              
        wait for GCLK_period*120;   -- wait before next input.
    end loop;
    
    BTN(1) <= '1';              -- toggle the WRITE btn to
    wait for GCLK_period*36;    -- exit WRITE MODE, prepping
    BTN(1) <= '0';              -- for TEST 4.
    
    wait for GCLK_period*100;
    
    ----------------------------    
    -- TEST 5
    --------
    
    BTN(1) <= '1';              -- toggle the WRITE btn
    wait for GCLK_period*36;
    BTN(1) <= '0';
                                -- check if WRITE mode request
    wait for GCLK_period*100;   -- is ignored.
    
    ----------------------------    
    -- TEST 6
    --------
                                -- toggle the READ btn to enter READ
    BTN(2) <= '1';              -- mode. The circuit will send the
    wait for GCLK_period*36;    -- correct instructions to the SPI and
    BTN(2) <= '0';              -- will read values until all inputted 
                                -- are read.
    wait;
end process;

check_outputs : process
begin

    -- Wait for hold and the global reset
    wait for GCLK_period*274;
    -- Wait for TEST 1, 2, 3, 4 and 5
    wait for GCLK_period*536;
    wait for GCLK_period*136;
    wait for GCLK_period*136;
    wait for GCLK_period*2182;
    wait for GCLK_period*136;
    
    
    
    
    
    
    
    
    
    
    
    
    
    -- Wait until logic starts displaying to the LED + a few clock
    -- cycles (~12 clock cycles).
    wait for GCLK_period*455;
    test_6_check_loop : for i in 0 to 9 loop
        -- Check if correct LED outputs are displayed.
        assert (( LD = STD_LOGIC_VECTOR(to_unsigned(i, SW'length)) ))
        report "TEST 6 VECTOR " & integer'image(i) &
        " FAIL. Observed LED Output = " & integer'image(to_integer(unsigned(LD))) &
        " Expected LED Output = " & integer'image(to_integer(to_unsigned(i, SW'length)))
        severity warning;
        report "TEST 6 VECTOR " & integer'image(i) & " PASS."
        severity note;
        -- It takes 119 clock cycles between each LEDOUT state
        wait for GCLK_period*119;
    end loop;
    
    wait;
end process;

END;