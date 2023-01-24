library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity input_debouncer is
    Port ( clk : in STD_LOGIC;
           input_raw : in STD_LOGIC;
           output_debounced : out STD_LOGIC);
end input_debouncer;

architecture Behavioral of input_debouncer is

signal Q0, Q1, Q2 : STD_LOGIC;

begin

    process(clk) is
    begin
        if rising_edge(clk) then
            Q0 <= input_raw;
            Q1 <= Q0;
            Q2 <= Q1;
        end if;
    end process;
    
    output_debounced <= Q0 and Q1 and (not Q2);

end Behavioral;