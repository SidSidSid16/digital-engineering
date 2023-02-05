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
signal INT5 : UNSIGNED (data_size*2-1 downto 0); -- INTC + INT4
signal INTO : UNSIGNED (data_size*2-1 downto 0); -- INT5 + 5

begin

-- Input registers (D-type, rising edge, synchronous reset)
input_regs: process (clk) is
begin
  if rising_edge(clk) then
    if rst = '1' then 
      INTA <= (others => '0');
      INTB <= (others => '0');
      INTC <= (others => '0');
--    INTD <= (0 => '1', others => '0');  -- aggregate notation
      INTD <= to_unsigned(1,INTD'length); -- type conversion notation
    else
      INTA <= unsigned(A);
      INTB <= unsigned(B);
      INTC <= unsigned(C);
      INTD <= unsigned(D);
    end if;
  end if;
end process input_regs;

-- Mathematical operations on the data (combinational)
INT1 <= INTA * to_unsigned(3, 2);
INT2 <= INTB * INTC;
INT3 <= INT1 + INT2;
INT4 <= INT3 / INTD;
INT5 <= INTC + INT4;
INTO <= INT5 + to_unsigned(5, INT5'length);

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
