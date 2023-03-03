
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 

 
ENTITY TOP_LEVEL_tb IS
END TOP_LEVEL_tb;
 
ARCHITECTURE behavior OF TOP_LEVEL_tb IS 
 
   --Inputs
   signal GCLK : std_logic;
   signal BTN : std_logic_vector(4 downto 0);
   signal SW : std_logic_vector(7 downto 0);

 	--Outputs
   signal LD : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant GCLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.TOP_LEVEL 
   GENERIC MAP (disp_delay => 12)
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
   stim_proc: process
   begin		
    -- hold reset state for 2000 ns.
    wait for 2000 ns;	
	wait until falling_edge(GCLK);


    wait;
   end process;

END;
