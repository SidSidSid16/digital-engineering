library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

Library xpm;
use xpm.vcomponents.all;

use work.DigEng.all;

entity STUDENT_AREA is
    Generic (disp_delay : natural := 100000000);
    Port ( CLK_100MHZ : in  STD_LOGIC;
		   CLK_7MHZ : in  STD_LOGIC;
           -- 7MHZ Debounced button inputs (4=U, 3=C, 2=R, 1=L, 0=D)
		   USER_PB_7MHZ : in  STD_LOGIC_VECTOR (4 downto 0);
           -- 100MHZ Debounced button inputs (4=U, 3=C, 2=R, 1=L, 0=D)
	  	   USER_PB_100MHZ : in  STD_LOGIC_VECTOR (4 downto 0);
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

signal FIFO_data_out : STD_LOGIC_VECTOR (7 downto 0);
signal FIFO_wr_en, FIFO_rd_en, FIFO_full, FIFO_empty : STD_LOGIC;

signal source_to_output, output_to_source : STD_LOGIC;
signal source_to_output_sync, output_to_source_sync : STD_LOGIC;


begin


-- Dual-clock FIFO for clock domain crossing
--   depth = 32 32-bit words.
--   32-bit write port (connected to the 7MHZ clock)
--   4-bit read port (connected to the 125MHZ clock)
--   First-Word-Fall-Through
Synchronization_FIFO : entity work.DUAL_CLOCK_FIFO
PORT MAP (
   rst => USER_PB_7MHZ(1),
   wr_clk => CLK_7MHZ,
   rd_clk => CLK_100MHZ,
   din => SOURCE_DATA,
   wr_en => FIFO_wr_en,
   rd_en => FIFO_rd_en,
   dout => FIFO_data_out,
   full => FIFO_full,
   empty => FIFO_empty
);

-- 2-DFF Clock Domain Crossing Single-bit Synchronizer
-- Note: The input data must be sampled two or more times by the 
--  destination clock
Sync_output_FSM_state: entity work.Single_bit_synchroniser 
PORT MAP(
	CLK => CLK_7MHZ,
	S_IN => output_to_source,
	S_OUT => output_to_source_sync
);

-- xpm_cdc_single: Clock Domain Crossing Single-bit Synchronizer
-- Xilinx Parameterized Macro, Version 2016.4
-- Note: The input data must be sampled two or more times by the 
--  destination clock
Sync_source_FSM_state: xpm_cdc_single
GENERIC MAP (
  DEST_SYNC_FF => 2,   -- integer; range: 2-10
  SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 
                       --          1=enable simulation messages
  SRC_INPUT_REG => 0   -- integer; 0=do not register input, 
                       --          1=register input
)
PORT MAP (
  src_clk => CLK_7MHZ,    -- used only when SRC_INPUT_REG = 1
  src_in => source_to_output, 
  dest_clk => CLK_100MHZ,
  dest_out => source_to_output_sync
);

SOURCE_CONTROL_LOGIC: entity work.SOURCE_CTRL 
PORT MAP(
	CLK => CLK_7MHZ,
	USER_PB => USER_PB_7MHZ,
	SWITCHES => SWITCHES,
	FIFO_FULL => FIFO_full,
	FIFO_WR_EN => FIFO_wr_en,
	TO_OUTPUT => source_to_output,
	FROM_OUTPUT => output_to_source_sync,
	RST_SOURCE => RST_SOURCE,
	EN_SOURCE => EN_SOURCE
);


OUTPUT_CONTROL_LOGIC: entity work.OUTPUT_CTRL 
GENERIC MAP (disp_delay => disp_delay)
PORT MAP(
	CLK => CLK_100MHZ,
	USER_PB => USER_PB_100MHZ,
	SWITCHES => SWITCHES,
	FROM_SOURCE => source_to_output_sync,
	TO_SOURCE => output_to_source,
	DATA_FROM_FIFO => FIFO_data_out,
	LEDS => LED_DISPLAY,
	FIFO_RD_EN => FIFO_rd_en,
	FIFO_EMPTY => FIFO_empty
);

end Behavioral;

