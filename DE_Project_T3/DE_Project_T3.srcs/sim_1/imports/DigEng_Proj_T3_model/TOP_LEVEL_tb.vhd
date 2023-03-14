LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 

ENTITY TOP_LEVEL_tb IS
END TOP_LEVEL_tb;
 
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

    SW <= "00000000";
    BTN <= "00000";
    wait for GCLK_period*18;
    BTN(0) <= '1';
    wait for GCLK_period*36;
    BTN(0) <= '0';
       
    wait;
  end process;

END;
