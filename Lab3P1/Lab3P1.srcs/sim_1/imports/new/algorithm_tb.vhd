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
    
    constant clk_period : time := 80ns;  -- Clock period
    constant latency : natural := 3;     -- Circuit latency
    
    -- Defining a record of test patterns to verify the circuit
    type test_vector is record
        InputA : STD_LOGIC_VECTOR(data_size-1 downto 0);
        InputB : STD_LOGIC_VECTOR(data_size-1 downto 0);
        InputC : STD_LOGIC_VECTOR(data_size-1 downto 0);
        InputD : STD_LOGIC_VECTOR(data_size-1 downto 0);
        Output : STD_LOGIC_VECTOR(data_size*2-1 downto 0);
    end record;
    
    type test_vector_array is array
        (natural range <>) of test_vector;
        
    -- Test strategy:
    --
    --  Initialisation:
    --      Outside of this vector, the set_inputs process will
    --      initialise all inputs to x'0000', and D to x'0001'.
    --      After that, the circuit is reset with a 2-clock rst
    --      pulse.
    --
    --  TEST 1 ('large' vector for INT1, D):
    --      The max input for A we can provide without an INT1
    --      overflow is x'FFFF' as INT1 is 18-bit but A in only
    --      16-bit in width. We should see a signal of x'2FFFD'
    --      in INT1. We set D to its highest possible value of
    --      x'FFFF' to isolate all other vectors.
    --
    --  TEST 2 ('large' vector for INT2, INT3, B, C, D):
    --      We can induce a large INT2 vector by inputting the
    --      max value of x'FFFF' to B and C. This will result in
    --      a x'FFFE0001' INT2 vector. As a result this, INT3 will
    --      also be large with x'FFFE0004', we can isolate other
    --      signals by setting D to x'FFFF'
    --
    --  TEST 3 ('large' vector for INT3, INT2, INT1, A, B, C, D):
    --      By inputting a large value for A, B, C and D, we can
    --      induce a large vector for INT3. We need to set either
    --      B or C to x'FFFE' to mitigate INT3 overflow, I've chosen
    --      C as this slightly reduces (isolates) the INT5 vector.
    --      INT3 vector should be x'FFFFFFFF'.
    --
    --  TEST 4 ('large' vector for INT4, INT3, INT2, INT1, B, C, A):
    --      We can induce a large INT4 vector by doing the same as
    --      TEST 3, by setting A and C to max and C to x'FFFE'. We
    --      need to set D to the lowest possible value, this will
    --      result in a INT4 vector of x'7FFFFFFF'
    --
    --  TEST 5 ('large' vector for INT5, Output, INT4, INT3, INT2,
    --              INT1, A, B, C):
    --      By doing the same as TEST 4, a large input to A, B and C,
    --      results in a large INT1, INT2 and INT3. Input D of x'0001
    --      results in a large INT4, and adding that to the already
    --      large C gives us a large INT5. By setting C to x'FFFA'
    --      we can prevent an INT3,4,5,O overflow and thus can expect
    --      as INT5 vector of x'FFFCFFFD'.
    --
    --  TEST 6 ('large' vector for A) [ERRONEOUS TEST]:
    --      We can test a large vector for A, B and C with x'FFFF',
    --      this test will result in an overflow in INT3 and thus
    --      will fail.
    
    constant test_vectors : test_vector_array := (
        -- IN A     IN B     IN C     IN D     Output
        (X"FFFF", X"0001", X"0001", X"FFFF", X"00000009"),  -- TEST 1
        (X"0001", X"FFFF", X"FFFF", X"FFFF", X"00020003"),  -- TEST 2
        (X"FFFF", X"FFFF", X"FFFE", X"FFFF", X"00020004"),  -- TEST 3
        (X"5555", X"FFFF", X"FFFF", X"0002", X"80008004"),  -- TEST 4
        (X"FFFF", X"FFFF", X"FFFA", X"0001", X"FFFD0002"),  -- TEST 5
        (X"FFFF", X"FFFF", X"FFFF", X"0002", X"80018003")   -- TEST 6
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
               " O_observed = " &
               integer'image(to_integer(unsigned(Output))) &
               " O_expected = " & 
               integer'image(to_integer(unsigned(test_vectors(i).Output)))
        severity failure;
        
        report "TEST VECTOR " & integer'image(i) & " PASS."
        severity note;
        wait for clk_period;
    end loop;
    wait;
end process;

end Behavioral;
