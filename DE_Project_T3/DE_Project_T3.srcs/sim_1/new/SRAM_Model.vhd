library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This entity is a partial and non-synthesizable model of the Microchip
--   23A1024/23LC1024 1Mbit (128kx8) SPI serial SRAM.
-- The model only supports standard full-duplex single SPI mode and two 
--  commands: BYTE READ and BYTE WRITE
-- BYTE READ: Read data from memory array beginning at selected address
--   Sequence:
--     1- Instruction (00000011)
--     2- 3 address bytes, MSB first. The top 7 bits are discarded.
--     3- Every 8 SPI_CLK cycles, a byte is sent on the MISO line
--        (address auto-increments)
-- BYTE WRITE: Write data to memory array beginning at selected address
--   Sequence:
--     1- Instruction (00000010)
--     2- 3 address bytes, MSB first. The top 7 bits are discarded.
--     3- Every 8 SPI_CLK cycles, a byte sent serially on the MOSI line
--        is stored in the RAM (address auto-increments)

entity SRAM_Model is
  Port ( 
  -- SPI_CLK has to be sent in sequences of 8. Error checking is not available
  --  and the circuit will enter an unstable state that requires reset. 
  SPI_SCK : in STD_LOGIC;
  SPI_HOLD_INV : in STD_LOGIC; -- not implemented (tie to 0)
  -- Active-low Chip Select (acts as active-high reset)
  SPI_CS_INV : in STD_LOGIC;
  -- Master-Out Slave-In serial data line (write + command + address)
  SPI_MOSI : in STD_LOGIC;
  -- Master-In Slave-Out serial data line (read)
  SPI_MISO : out STD_LOGIC);
end SRAM_Model;

architecture Behavioral of SRAM_Model is

signal CLK, RST: STD_LOGIC;

-- FSM states (see code)
type spi_state_type is (idle, rec_cmd, rec_addr_1, rec_addr_2, 
                        rec_addr_3, sending, receiving, error);
signal spi_state, spi_next_state: spi_state_type;

-- SERDES and SPI registers
signal spi_MOSI_reg  : STD_LOGIC_VECTOR(7 downto 0);
signal cmd_reg  : STD_LOGIC_VECTOR(7 downto 0);
signal addr_reg  : STD_LOGIC_VECTOR(16 downto 0); -- 17 bits for 128kx8 memory

-- Signals for the control of the SERDES registers
signal byte_done : STD_LOGIC;
signal count, count_del : UNSIGNED(2 downto 0);
signal load_en, SPI_MISO_int : STD_LOGIC;

-- RAM (128kx8)
type ram_type is array (0 to 131071) of std_logic_vector(7 downto 0);
-- Reset to UNDEFINED (useful for simulation/verification)
signal my_ram: ram_type := (others => "UUUUUUUU");

signal P_data_to_SPI  : STD_LOGIC_VECTOR(7 downto 0);

begin

-- Signal renaming (for sanity)
CLK <= SPI_SCK;
RST <= SPI_CS_INV; -- unit is reset if CS is not active

-- NOTE: all processes require asynchronous reset since the unit 
--  only receives a clock signal when active


-- FSM state assignment
spi_state_assignment: process (CLK, RST) is
begin
  if (RST = '1') then 
    spi_state <= idle;  
  else   
    if rising_edge(CLK) then
        spi_state <= spi_next_state;
    end if;
  end if;
end process spi_state_assignment;

-- FSM transition process 
fsm_process: process (spi_state, cmd_reg, byte_done) is
begin
  case spi_state is
    -- IDLE (reset state). The first SPI_CLK rising edge takes the FSM
    --  to the rec_cmd state (as long as CS is active)
    when idle =>
         spi_next_state <= rec_cmd;
    -- The first byte received is the command (read or write)
    when rec_cmd =>
      if byte_done = '1' then     
         spi_next_state <= rec_addr_1;
      else
         spi_next_state <= spi_state; 
      end if;
    -- The next three bytes are the 24-bit address (in reality, only 17
    --   bits are valid but the interface only works with 8-bit sequences)
    when rec_addr_1 =>
      if byte_done = '1' then     
         spi_next_state <= rec_addr_2;
      else
         spi_next_state <= spi_state; 
      end if;
    when rec_addr_2 =>
      if byte_done = '1' then     
         spi_next_state <= rec_addr_3;
      else
         spi_next_state <= spi_state; 
      end if;
    -- When the last (3rd) address byte is received, the units starts
    --  sending or receiving depending on the command
    when rec_addr_3 =>
      if byte_done = '1' then
         if cmd_reg = "00000010" then     
            spi_next_state <= receiving;
         elsif cmd_reg = "00000011" then     
            spi_next_state <= sending;
         else
            spi_next_state <= error; -- in case of an invalid command
         end if;
      else
         spi_next_state <= spi_state; 
      end if;
    -- Keep sending or receiving until the CS line is deactivated (reset)
    when receiving =>
      spi_next_state <= spi_state; 
    when sending =>
      spi_next_state <= spi_state; 
    -- Dead-end state for invalid commands
    when error =>
      spi_next_state <= spi_state; 

  end case;
end process;		


------------- SPI Interface ------------- 

-- SERDES MOSI shift register: receives data from the master and latches it on the
--  rising edge of the SPI_CLK.
spi_MOSI_reg_proc: process (CLK, RST) is
begin
  if (RST = '1') then
    spi_MOSI_reg <= (others => '0');
  else 
    if rising_edge(CLK) then
      -- Shift data in while the SRAM is in receive mode (including command
      --  and address), starting at the very first clock edge (IDLE to REC_CMD
      --  transition)
      if (spi_state = idle and spi_next_state = rec_cmd) or
          spi_state = rec_cmd or spi_state = rec_addr_1 or
          spi_state = rec_addr_2 or spi_state = rec_addr_3 or
          spi_state = receiving then  
              spi_MOSI_reg <= spi_MOSI_reg(6 downto 0) & SPI_MOSI;
      end if;
    end if;
  end if;
end process;

-- Counter to 8 to keep track of the number of SPI_SCK rising edges
byte_count_proc: process (CLK, RST) is
begin
  if (RST = '1') then
    count <= (others => '0');
  elsif rising_edge(CLK) then
       count <= count + 1;
  end if;
end process byte_count_proc;

-- Down-counter from 8 to keep track of the number of SPI_SCK pulses
--   when sending (falling edge) - slaved to "count"
byte_count_proc_del: process (CLK, RST) is
begin
  if (RST = '1') then
    count_del <= (others => '0');
  elsif falling_edge(CLK) then
       count_del <= 7-count;
  end if;
end process byte_count_proc_del;

-- Signals when a full byte has been received/sent (needs a one-cycle
--   delay for synchronisation)
byte_done_proc: process (CLK, RST) is
begin
  if (RST = '1') then
    byte_done <= '0';
  elsif rising_edge(CLK) then
    if count=7 then
       byte_done <= '1';
    else
       byte_done <= '0';
    end if;
  end if;
end process byte_done_proc;

-- Stores the command into a register once it has been received
Latch_cmd_from_SPI: process (CLK, RST) is
begin
  if (RST = '1') then
    cmd_reg <= (others => '0');
  elsif falling_edge(CLK) then
    if (spi_state = rec_cmd and byte_done = '1') then
	  cmd_reg <= spi_MOSI_reg;
    end if;
  end if;
end process;

-- Stores the (24-bit) address into a register, then increments
--  the register every time a new byte is sent/received
Latch_addr_from_SPI: process (CLK, RST) is
begin
  if (RST = '1') then
    addr_reg <= (others => '0');
  elsif falling_edge(CLK) then
    if (spi_state = rec_addr_1 and byte_done = '1') then
      addr_reg(16) <= spi_MOSI_reg(0); -- only 17 bits of address are used
    elsif (spi_state = rec_addr_2 and byte_done = '1') then
      addr_reg(15 downto 8) <= spi_MOSI_reg;
    elsif (spi_state = rec_addr_3 and byte_done = '1') then
      addr_reg(7 downto 0) <= spi_MOSI_reg;
    elsif (spi_state = receiving or spi_state = sending) and byte_done = '1' then
      addr_reg <= std_logic_vector(unsigned(addr_reg)+1);
    end if;
  end if;
end process;


-- Standard RAM implementation (synchronous write, asynchronous read) 
P_data_to_SPI <=  my_ram(to_integer(unsigned(Addr_reg)));

RAM_write: process (CLK)
begin
 if (falling_edge(CLK)) then
  -- stores each byte of data in the RAM
  if (spi_state = receiving and byte_done = '1') then
     my_ram(to_integer(unsigned(Addr_reg))) <= spi_MOSI_reg;
  end if;
 end if;
end process;

-- A mux is used to select which bit of the data read form the memory is sent
--  to the master when in sending mode. 
-- Note that the high-impedance state is not strictly necessary in this
--  implementation but would be when not in full duplex mode. 
SPI_MISO_int<= P_data_to_SPI(to_integer(count_del)) when spi_next_state = sending else 'Z';
-- Introduces a constant delay when sending to emulate propagation delay. 
SPI_MISO <= SPI_MISO_int after 12ns;


end Behavioral;
