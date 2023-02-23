library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- The entity implements a combinational logic circuit with 5 input and 
--   1 output STD_LOGIC signals.
-- The circuit includes fault injection logic for three stuck-at faults.
entity UUT is
Port ( -- Select fault to be injected
       --   00 = no fault
       --   01 = E s-a-1
       --   10 = H s-a-0
       --   11 = F s-a-0
       FLT : in  STD_LOGIC_VECTOR (1 downto 0);
       -- Circuit inputs (A=5, B=4, C=3, D=2, E=1, F=0)
       INPUTS : in  STD_LOGIC_VECTOR (5 downto 0);
       -- Circuit output (L)
       OUTPUT : out  STD_LOGIC);
end UUT;

architecture Behavioral of UUT is

signal A,B,C,D,E,F,G,H,I,J,K,L,Ef,Ff,Hf,Jf,Esa1,Hsa0,Fsa0 : STD_LOGIC;

begin

-- Active-high fault enable
Esa1 <= '1' when (FLT = "01") else '0';
Hsa0 <= '1' when (FLT = "10") else '0';
Fsa0 <= '1' when (FLT = "11") else '0';

-- Combinational logic (including fault injection)
A <= INPUTS(5);
B <= INPUTS(4);
C <= INPUTS(3);
D <= INPUTS(2);
E <= INPUTS(1);
 Ef <= E OR Esa1; -- E s-a-1
F <= INPUTS(0);
 Ff <= F AND NOT Fsa0; -- F s-a-0
G <= A AND B;
H <= C AND D;
 Hf <= H AND NOT Hsa0; -- H s-a-0
I <= Ef OR Hf;
J <= G NOR I;
K <= I OR Ff;
L <= J OR K;

OUTPUT <= L;

end Behavioral;

