library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bist_tb is
end bist_tb;

architecture Behavioral of bist_tb is

-- Instantiating the signals
signal GCLK, B_RST, B_TEST, L_OUT, L_ERR : STD_LOGIC;
signal INPUTS : STD_LOGIC_VECTOR (5 downto 0);
signal B_F : STD_LOGIC_VECTOR (1 downto 0);
signal L_ID : STD_LOGIC_VECTOR (3 downto 0);

constant clk_period : time := 10ns;

begin

UUT : entity work.top_level
    -- Mapping the signals to for the UUT
    PORT MAP (
        GCLK => GCLK,
        B_RST => B_RST,
        B_TEST => B_TEST,
        L_OUT => L_OUT,
        L_ERR => L_ERR,
        INPUTS => INPUTS,
        B_F => B_F,
        L_ID => L_ID
    );
    
    clk_process : process
    begin
        GCLK <= '0';
        wait for clk_period/2;
        GCLK <= '1';
        wait for clk_period/2;
    end process;
    
    --  TEST STRATEGY
    --      GLOBAL RESET
    --      Test 1: No faults test with two manual inputs.
    --      Test 2: No faults test with memory stored vectors.
    --      Test 3: Cycle stored vectors for each 3 faults. 
    test : process
    begin
        wait for 500ns;
        wait until falling_edge(GCLK);
        
        -- GLOBAL RESET
        B_RST <= '0';
        B_TEST <= '0';
        B_F <= "00";
        INPUTS <= "000000";
        wait for clk_period*12;
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;
        
        -- Test 1:
        --  Initialise B_F=00 (no fault) and test with 000000 inputs
        --  then 111111 inputs.
        B_F <= "00";
        B_TEST <= '0';
        INPUTS <= "000000";
        wait for clk_period*24;
        --  Reset
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;
        
        B_F <= "00";
        B_TEST <= '0';
        INPUTS <= "111111";
        wait for clk_period*24;
        --  Reset
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;
        
        -- Reset back to 0, not necessary but
        -- helps with reducing distractions
        -- when reading the other waveforms
        INPUTS <= "000000";
        
        -- Test 2:
        --  Initialise B_F=00 (no fault)
        B_F <= "00";
        B_TEST <= '1';
        wait for clk_period*12;
        B_TEST <= '0';
        wait for clk_period*24;
        --  Reset
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;
        
        -- Test 3:
        --  Initialise B_F=01 (Es-a-1)
        B_F <= "01";
        B_TEST <= '1';
        wait for clk_period*12;
        B_TEST <= '0';
        wait for clk_period*24;
        --  Reset
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;
        
        --  Initialise B_F=10 (Hs-a-0)
        B_F <= "10";
        B_TEST <= '1';
        wait for clk_period*12;
        B_TEST <= '0';
        wait for clk_period*24;
        --  Reset
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;
        
        --  Initialise B_F=11 (Fs-a-0)
        B_F <= "11";
        B_TEST <= '1';
        wait for clk_period*12;
        B_TEST <= '0';
        wait for clk_period*24;
        --  Reset
        B_RST <= '1';
        wait for clk_period*12;
        B_RST <= '0';
        wait for clk_period*24;

        wait;
    end process;

end Behavioral;
