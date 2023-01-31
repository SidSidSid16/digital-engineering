library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity algorithm_tb is
    generic (data_size : integer := 16);
end algorithm_tb;

architecture Behavioral of algorithm_tb is

    -- Inputs
    signal InputA : STD_LOGIC_VECTOR(data_size-1 downto 0);
    signal InputB : STD_LOGIC_VECTOR(data_size-1 downto 0);
    signal InputC : STD_LOGIC_VECTOR(data_size-1 downto 0);
    signal InputD : STD_LOGIC_VECTOR(data_size-1 downto 0);
    signal clk, rst : STD_LOGIC;
    
    -- Output
    signal Output : STD_LOGIC_VECTOR(data_size*2-1 downto 0);
    
    constant clk_period : time := 120ns; -- Clock period
    constant latency : natural := 2;     -- Circuit latency
    
    -- Defining a record of test patters to verify the circuit
    type test_vector is record
        InputA : STD_LOGIC_VECTOR(data_size-1 downto 0);
        InputB : STD_LOGIC_VECTOR(data_size-1 downto 0);
        InputC : STD_LOGIC_VECTOR(data_size-1 downto 0);
        InputD : STD_LOGIC_VECTOR(data_size-1 downto 0);
        Output : STD_LOGIC_VECTOR(data_size*2-1 downto 0);
    end record;
    
    type test_vector_array is array
        (natural range <>) of test_vector;
    constant test_vectors : test_vector_array := (
        -- A        B        C        D        O
        (X"FFF0", X"FFF0", X"FFF0", X"0002", X"7FF2805D"),
        (X"1100", X"1100", X"1100", X"1101", X"0CCCF333"),
        (X"1110", X"1110", X"1110", X"1111", X"0CCCF333"),
        (X"1111", X"1111", X"1111", X"1111", X"0CCCF333"),
        (X"1111", X"1111", X"1111", X"1111", X"0CCCF333")
    );
    
begin


UUT : entity work.algorithm
    PORT MAP (
        clk => clk,
        rst => rst,
        A => InputA,
        B => InputB,
        C => InputC,
        D => InputD,
        O => Output
    );


clk_process : process
begin
    clk <= '0';
    wait for clk_period/2; 
    clk <= '1';
    wait for clk_period/2; 
end process;

set_inputs: process
begin
    wait for 500ns;
    wait until falling_edge(clk);
    
    -- Initialise inputs
    rst <= '0';
    InputA <= X"0000";
    InputB <= X"0000";
    InputC <= X"0000";
    InputD <= X"0001";
    
    -- Initial global reset
    wait for clk_period*2;
    rst <= '1';
    wait for clk_period*2;
    rst <= '0';
    
    -- Test pattern input loop, inputting at every clock cycle
    for i in test_vectors'range loop
        InputA <= test_vectors(i).InputA;
        InputB <= test_vectors(i).InputB;
        InputC <= test_vectors(i).InputC;
        InputD <= test_vectors(i).InputD;
        wait for clk_period;    
    end loop;                           
    wait;
end process;

check_outputs: process
begin
    wait for 500ns;
    wait until falling_edge(clk);
    
    wait for clk_period*latency;
    
    wait for clk_period*2;
    wait for clk_period*2;
    
    -- Test pattern check loop, checking at every clock cycle
    for i in test_vectors'range loop
        assert (( Output = test_vectors(i).Output ))
        report "TEST VECTOR " & integer'image(i) &
               " A = " & 
               integer'image(to_integer(unsigned(InputA))) & 
               " B = " & 
               integer'image(to_integer(unsigned(InputB))) & 
               " C = " & 
               integer'image(to_integer(unsigned(InputC))) & 
               " D = " & 
               integer'image(to_integer(unsigned(InputD))) & 
               " O = " & 
               integer'image(to_integer(unsigned(Output)))
        severity failure;
        
        report "TEST VECTOR " & integer'image(i) & " PASS."
        severity note;
        wait for clk_period;
    end loop;
    wait;
end process;

end Behavioral;
