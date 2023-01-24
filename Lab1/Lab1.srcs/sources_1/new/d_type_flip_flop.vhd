library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity d_type_flip_flop is
    Port ( clk, data : in STD_LOGIC;
           output : out STD_LOGIC);
end d_type_flip_flop;

architecture Behavioral of d_type_flip_flop is

begin

    DFF: process(clk)
    begin
        if (rising_edge(clk)) then
            output <= data;
        end if;
    end process DFF;

end Behavioral;
