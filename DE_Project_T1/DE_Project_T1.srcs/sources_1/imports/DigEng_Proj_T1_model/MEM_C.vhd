library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 64x16 asynchronous read ROM
entity MEM_C is
    Port ( a : in  UNSIGNED (5 downto 0); -- Address
           spo : out  STD_LOGIC_VECTOR (15 downto 0)); -- Data out
end MEM_C;

architecture Behavioral of MEM_C is

type ROM_Array is array (0 to 63) of std_logic_vector(15 downto 0);

constant Content: ROM_Array := (
x"C000",
x"201F",

begin

spo <= Content(to_integer(a));

end Behavioral;
