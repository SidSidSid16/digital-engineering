library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fibonacci_8bit_sequence_tb is
generic (LIMIT : NATURAL := 6);
end fibonacci_8bit_sequence_tb;

architecture Behavioral of fibonacci_8bit_sequence_tb is

signal clk, reset, count : STD_LOGIC;
signal output : STD_LOGIC_VECTOR (7 downto 0);

constant clk_period : time := 5ns;

begin

    UUT : entity work.fibonacci_8bit_sequence
        GENERIC MAP (
            LIMIT => LIMIT
        )
        PORT MAP (
            clk => clk,
            count => count,
            reset => reset,
            output => output
        );
        
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
        
    --  TEST STRATEGY
    --      TEST 1:
    --      After a reset, a 'for' loop will be used to toggle the enable
    --      signal 19 times, allowing the counter to counter to count to 16,
    --      reset then count up twice. This is to test the counting behaviour
    --      and the reset transition.
    --
    --      TEST 2:
    --      Following from test 1, a reset signal will be sent to the counter,
    --      the counter should reset back to 0, and the first value of the
    --      fibonacci sequence should output.
    --
    --      TEST 3:
    --      Following from test 2, the counter will be toggled with another
    --      'for' loop 10 times, this is to verify whether the counter can
    --      count up even after a reset.
    --
    --      TEST 4:
    --      Following from test 3, this test will toggle the reset and count
    --      inputs at the same time.

    test : process
    begin
        wait for 100ns;
        wait until falling_edge(clk);
        
        --  Initialise counter
        reset <= '0';
        count <= '0';
        
        wait for clk_period;
        
        -- Reset counter
        reset <= '1';
        count <= '0';
        
        wait for clk_period*20;
        
        --  TEST 1
        count_to_18 : for i in 0 to 18 loop
            reset <= '0';
            count <= '0';
            wait for clk_period*10;
            reset <= '0';
            count <= '1';
            wait for clk_period*10;
        end loop count_to_18;
        
        --  TEST 2
        reset <= '1';
        count <= '0';
        
        wait for clk_period*10;
        
        --  TEST 3
        count_to_12 : for i in 0 to 12 loop
            reset <= '0';
            count <= '0';
            wait for clk_period*10;
            reset <= '0';
            count <= '1';
            wait for clk_period*10;
        end loop count_to_12;
        
        --  TEST 4
        reset <= '1';
        count <= '1';
        
        wait for clk_period*20;
        
        reset <= '0';
        count <= '0';
        
        wait;

    end process;


end Behavioral;
