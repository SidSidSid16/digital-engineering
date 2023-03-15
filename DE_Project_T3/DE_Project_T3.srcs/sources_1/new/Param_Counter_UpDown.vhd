library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.DigEng.all;

entity Param_Counter_UpDown is
    generic (
        LIMIT : NATURAL := 17
    );
    port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        en_up : in STD_LOGIC;
        en_down : in STD_LOGIC;
        count_out : out UNSIGNED (log2(LIMIT)-1 downto 0)
    );
end Param_Counter_UpDown;

architecture Behavioral of Param_Counter_UpDown is

signal count_int : UNSIGNED (log2(LIMIT)-1 downto 0);

begin

-- An up-down counter without roll-over with two synchronous enables
-- (one for increment and another for decrement) and a synchronous
-- reset. When en_up is high, the counter will increment up to the
-- value set by LIMIT without rolling over to 0. When en_down is high
-- the counter will decrement until 0 is reached without rolling over
-- to LIMIT.
counter: process (clk)
begin
    if rising_edge(CLK) then 
        if (rst = '1') then 
            count_int <= (others => '0');       -- Counter resets.
        elsif (en_up = '1') then
            if (count_int < LIMIT) then         -- Increment when en_up until
                count_int <= count_int + 1;     -- LIMIT is reached.
            end if;
        elsif (en_down = '1') then
            if (count_int > 0) then             -- Decrement when en_down until
                count_int <= count_int - 1;     -- 0 is reached.
            end if;
        end if;
    end if;
end process counter;

-- Maps the internal counter value to the output signal.
count_out <= count_int;

end Behavioral;
