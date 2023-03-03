library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity SOURCE_CTRL is
    Port ( CLK : in  STD_LOGIC;
           USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
           SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
           FIFO_FULL : in  STD_LOGIC;
           FIFO_WR_EN : out  STD_LOGIC;
           TO_OUTPUT : out  STD_LOGIC;
           FROM_OUTPUT : in  STD_LOGIC;
           RST_SOURCE : out  STD_LOGIC;
           EN_SOURCE : out  STD_LOGIC);
end SOURCE_CTRL;

architecture Behavioral of SOURCE_CTRL is

signal EN, RST : STD_LOGIC;


begin

EN <= USER_PB(3);
RST <= USER_PB(1);


				 
end Behavioral;

