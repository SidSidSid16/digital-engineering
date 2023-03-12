library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

-- This is where your work goes. Of course, you will have to put
--   your own comments in, to describe your work.

entity STUDENT_AREA is
  Generic (disp_delay : natural := 100000000);
  Port ( 
    CLK : in  STD_LOGIC;
    RST : in  STD_LOGIC;
    USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
    SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
    LEDS : out  STD_LOGIC_VECTOR (7 downto 0);
    DATA_FROM_SPI : in  STD_LOGIC_VECTOR (7 downto 0);
    DATA_TO_SPI : out  STD_LOGIC_VECTOR (7 downto 0);
    EN_SPI : out  STD_LOGIC;
    SPI_WR_REQ : out STD_LOGIC;
    SPI_WR_ACK : in STD_LOGIC;
    SPI_RD_REQ : out STD_LOGIC;
    SPI_RD_ACK : in STD_LOGIC;
    SRAM_ADDRESS : in STD_LOGIC_VECTOR(23 downto 0)
  );
end STUDENT_AREA;

architecture Behavioral of STUDENT_AREA is

signal PBA_pressed, PBB_pressed, PBC_pressed: STD_LOGIC;


begin

PBA_pressed <= USER_PB(1);
PBB_pressed <= USER_PB(3);
PBC_pressed <= USER_PB(2);




end Behavioral;

