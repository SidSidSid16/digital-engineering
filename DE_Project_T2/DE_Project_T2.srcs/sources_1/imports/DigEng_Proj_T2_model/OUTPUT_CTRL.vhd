library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

entity OUTPUT_CTRL is
    Generic (disp_delay : natural := 100000000);
    Port ( CLK : in  STD_LOGIC;
           USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
           SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
           FROM_SOURCE : in  STD_LOGIC;
           TO_SOURCE : out  STD_LOGIC;
           DATA_FROM_FIFO : in  STD_LOGIC_VECTOR (7 downto 0);
           LEDS : out  STD_LOGIC_VECTOR (7 downto 0);
           FIFO_RD_EN : out  STD_LOGIC;
           FIFO_EMPTY : in  STD_LOGIC);
end OUTPUT_CTRL;

architecture Behavioral of OUTPUT_CTRL is

signal RST, EN : STD_LOGIC;


begin

RST <= USER_PB(1);
EN <= USER_PB(3);

end Behavioral;

