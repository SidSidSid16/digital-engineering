----------------------------------------------------------------------------------
-- Company: University of York
-- Engineer: Gianluca Tempesti
-- 
-- Module Name:    Algorithm - Behavioral 
-- Project Name:   Digital Engineering Labs 2-3
-- Target Devices: Any device - Tested on:
--                   XC6SLX45-3CSG32
--                   ZedBoard
--                   Pynq Z2
-- Tool versions:  Tested on ISE 14.2 / Vivado 2017.4.1
-- Description:    Base circuit for pipeline labs
--
-- Revision: 
-- Revision 0.01 - File Created 25/10/2012 
-- Revision 0.02 - File updated 04/12/2015
-- Revision 0.03 - Vivado update and test on Zedboard 06/12/2018
-- Revision 0.04 - Updated and tested on Pynq Z2 08/12/2020
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entity description:
-- The entity implements, with no optimization, a sequence of operations:
--	 O <= (A*3 + B*C)/D + C + 5
-- where A,B,C, and D are UNSIGNED vectors of parameterizable size

-- Note 1: There is no particular "meaning" to the equation - it is designed for
--  experimentation with logic optimization for performance
-- Note 2: There is no provision for overflow. Some input vectors can cause
--  overflow and the result will be incorrect.
-- Note 3: Inputs and outputs are registered (rising edge, synchronous reset).
--  This introduces a latency of 2 clock cycles between inputs and outputs.
-- Note 4: D is the divisor in one of the operations, so can never have value 0

entity algorithm is
    generic (data_size : integer := 16); -- defines the size of the data
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           -- The four (parameterizable) data inputs
           A : in  STD_LOGIC_VECTOR (data_size-1 downto 0); 
           B : in  STD_LOGIC_VECTOR (data_size-1 downto 0);
           C : in  STD_LOGIC_VECTOR (data_size-1 downto 0);
           D : in  STD_LOGIC_VECTOR (data_size-1 downto 0);
           -- Output = (A*3 + B*C)/D + C +5
           O : out  STD_LOGIC_VECTOR (data_size*2-1 downto 0) 
           );
end algorithm;

architecture Behavioral of algorithm is

-- Registered inputs
signal INTA, INTB, INTC, INTD : UNSIGNED (data_size-1 downto 0);
-- Internal signals for intermediate operations (note the sizes)
signal INT1 : UNSIGNED (data_size+1 downto 0);   -- INTA + 3
signal INT2 : UNSIGNED (data_size*2-1 downto 0); -- INTB * INTC
signal INT3 : UNSIGNED (data_size*2-1 downto 0); -- INT1 + INT2
signal INT4 : UNSIGNED (data_size*2-1 downto 0); -- INT3 / INTD
-- INT5 needs to be resized to match INTC+1, as this vector size
-- is larger than the required vector size for a decimal '5'
signal INT5 : UNSIGNED (data_size downto 0);   -- [UPDATED] INTC + 5
-- INTO needs to be resized to match INT4, as this is the larger
-- vector size compared to INT5 as we updated that to be smaller
signal INTO : UNSIGNED (data_size*2-1 downto 0); -- [UPDATED] INT4 + INT5

-- We need to define internal signals for after the pipeline stage,
-- these signals will be physically identical to the original ones
-- before the pipeline.
signal INT3_pipe1 : UNSIGNED (data_size*2-1 downto 0);  -- Pipeline 1 output
signal INTD_pipe1 : UNSIGNED (data_size-1 downto 0);    -- Pipeline 1 output
signal INT5_pipe1 : UNSIGNED (data_size downto 0);      -- Pipeline 1 output
signal INT4_pipe2 : UNSIGNED (data_size*2-1 downto 0);  -- Pipeline 2 output
signal INT5_pipe2 : UNSIGNED (data_size downto 0);      -- Pipeline 2 output
signal INT1_pipe3 : UNSIGNED (data_size+1 downto 0);    -- Pipeline 3 output   
signal INT2_pipe3 : UNSIGNED (data_size*2-1 downto 0);  -- Pipeline 3 output
signal INT5_pipe3 : UNSIGNED (data_size downto 0);      -- Pipeline 3 output
signal INTD_pipe3 : UNSIGNED (data_size-1 downto 0);    -- Pipeline 3 output

-- We need an array of INT5 signals for the for-generate pipeline flip flop
-- array.
type INT5_pipeArr is array (0 to 34) of UNSIGNED(data_size downto 0);
signal INT5_pipeArr_int : INT5_pipeArr;
-- Store the output of the pipeline array to this output signal.
signal INT5_pipeArr_out : UNSIGNED (data_size downto 0);

-- Divider IP component instantiation
component divider
port (
    clk : in STD_LOGIC;
    sclr : in STD_LOGIC;
    rfd : out STD_LOGIC;
    dividend : in STD_LOGIC_VECTOR(31 downto 0);
    divisor : in STD_LOGIC_VECTOR(15 downto 0);
    quotient : out STD_LOGIC_VECTOR(31 downto 0);
    fractional : out STD_LOGIC_VECTOR(15 downto 0)
);
end component;

begin
-- Port map the IP divider block
my_divider : divider
port map (
    clk => clk,
    sclr => rst,
    dividend => STD_LOGIC_VECTOR(INT3_pipe1),
    divisor => STD_LOGIC_VECTOR(INTD_pipe1),
    unsigned(quotient) => INT4
);

-- Input registers (D-type, rising edge, synchronous reset)
input_regs: process (clk) is
begin
  if rising_edge(clk) then
    if rst = '1' then 
      INTA <= (others => '0');
      INTB <= (others => '0');
      INTC <= (others => '0');
      INTD <= to_unsigned(1,INTD'length); -- type conversion notation
    else
      INTA <= unsigned(A);
      INTB <= unsigned(B);
      INTC <= unsigned(C);
      INTD <= unsigned(D);
    end if;
  end if;
end process input_regs;

-- Pipeline 1 resgisters (D-type, rising edge, synchronous reset)
pipe1_regs: process (clk) is
begin
  if rising_edge(clk) then
    if rst = '1' then 
      INT3_pipe1 <= (others => '0');
      INTD_pipe1 <= to_unsigned(1,INTD_pipe3'length); -- type conversion notation
      INT5_pipe1 <= (others => '0');
    else
      INT3_pipe1 <= INT3;
      INTD_pipe1 <= INTD_pipe3;
      INT5_pipe1 <= INT5_pipe3;
    end if;
  end if;
end process pipe1_regs;


-- Pipeline 2 resgisters (D-type, rising edge, synchronous reset)
pipe2_regs: process (clk) is
begin
  if rising_edge(clk) then
    if rst = '1' then 
      INT4_pipe2 <= (others => '0');
      INT5_pipe2 <= (others => '0');
    else
      INT4_pipe2 <= INT4;
      INT5_pipe2 <= INT5_pipeArr_out;
    end if;
  end if;
end process pipe2_regs;

-- Pipeline 3 resgisters (D-type, rising edge, synchronous reset)
pipe3_regs: process (clk) is
begin
  if rising_edge(clk) then
    if rst = '1' then 
      INT1_pipe3 <= (others => '0');
      INT2_pipe3 <= (others => '0');
      INT5_pipe3 <= (others => '0');  
      INTD_pipe3 <= (others => '0');
    else
      INT1_pipe3 <= INT1;
      INT2_pipe3 <= INT2;
      INT5_pipe3 <= INT5;
      INTD_pipe3 <= INTD;
    end if;
  end if;
end process pipe3_regs;

-- For-Generate Loop to add a delay for INT5_pipe1 to match the
-- latency of the divider with an array of 34 pipelines. First
-- we need to link INT5_pipe1 to the first signal bus in
-- INT5_pipe1_array_int, then the last signal of INT5_pipe1_array_int
-- to the output INT5_pipeArr.
INT5_pipeArr_int(0) <= INT5_pipe1;
pipeline_array : for i in 1 to 34 generate
    pipeline: process (clk) is
    begin
      if rising_edge(clk) then
        if rst = '1' then 
          INT5_pipeArr_int(i) <= (others => '0');
        else
          INT5_pipeArr_int(i) <= INT5_pipeArr_int(i-1);
        end if;
      end if;
    end process pipeline;
end generate;
INT5_pipeArr_out <= INT5_pipeArr_int(34);   -- Map the output to signal

-- Mathematical operations on the data (combinational)
INT1 <= INTA * to_unsigned(3, 2);
INT2 <= INTB * INTC;
INT3 <= INT1_pipe3 + INT2_pipe3;
-- This logic has been moved forward along side the multiplication 
-- so that the adders aren't exactly one after the other operations 
-- in INT1 and INT2. In the previous design, this logic would've 
-- been carried out by INTO, we need to make sure that the to_unsigned 
-- function has the correct size parameter (width of INTC + 1)
INT5 <= INTC + to_unsigned(5, INTC'length+1);
-- Bringing the INT5 logic forward needs to be implemented, therefore
-- INTO has been adapted to take into account this change. Critical 
-- path is reduced as the INT5 adder is along side the rest of the
-- logic, INTO doesn't have to wait for INT5 like before in the
-- pre-modifications design.
INTO <= INT4_pipe2 + INT5_pipe2;

-- Input registers (D-type, rising edge, synchronous reset)
output_regs: process (clk) is
begin
  if rising_edge(clk) then
    if rst = '1' then 
      O <= (others => '0');
    else
      O <= std_logic_vector(INTO);
    end if;
  end if;
end process output_regs;


end Behavioral;

