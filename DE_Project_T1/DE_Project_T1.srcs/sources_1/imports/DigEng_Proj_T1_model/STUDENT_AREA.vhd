library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.DigEng.all;

-- This is where your work goes. Of course, you will have to put
--   your own comments in, to describe your work.

entity STUDENT_AREA is
    Generic (disp_delay : natural := 100000000);
    Port ( CLK_100MHZ : in  STD_LOGIC;
           -- Debounced button inputs (4=U, 3=C, 2=R, 1=L, 0=D)
           USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
           -- Board switches (not debounced)
           SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
			  -- Board LEDs
           LED_DISPLAY : out  STD_LOGIC_VECTOR (7 downto 0);
			  -- Control signals for the data source
           RST_SOURCE : out  STD_LOGIC;
           EN_SOURCE : out  STD_LOGIC;
           SOURCE_DATA : in  STD_LOGIC_VECTOR (31 downto 0)
			  );
end STUDENT_AREA;

architecture Behavioral of STUDENT_AREA is

signal EN, RST, CLK : STD_LOGIC;


begin

RST <= USER_PB(1);
EN <= USER_PB(3);
CLK <= CLK_100MHZ;



end Behavioral;

