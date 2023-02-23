library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fibonacci_8bit_async_read_rom is
    Port ( Address : in UNSIGNED (3 downto 0);  -- Address of data to be retrieved
           DataOut : out STD_LOGIC_VECTOR (7 downto 0)); -- Data that is retrieved
end fibonacci_8bit_async_read_rom;













architecture Behavioral of fibonacci_8bit_async_read_rom is
--  With 8-bits, a maximum of 14 sequence elements can be stored,
--  any larger (144 + 233) requires more bits.
type ROM_Array is array (0 to 15) of std_logic_vector(7 downto 0);
    constant Content: ROM_Array := (
    0 =>  X"00",                  --  0     
    1 =>  X"01",                  --  1     
    2 =>  X"01",                  --  1     
    3 =>  X"02",                  --  2     
    4 =>  X"03",                  --  3     
    5 =>  X"05",                  --  5     
    6 =>  X"08",                  --  8     
    7 =>  X"0D",                  --  13    
    8 =>  X"15",                  --  21    
    9 =>  X"22",                  --  34        
    10 => X"37",                  --  55    
    11 => X"59",                  --  89    
    12 => X"90",                  --  144   
    13 => X"E9",                  --  233   
    others => X"00");             --  0

begin
    DataOut <= Content(to_integer(Address));
end Behavioral;
