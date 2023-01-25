library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

-- counter to LIMIT (0 to LIMIT-1) with sychronous reset and enable
entity parameterizable_counter is
-- Adjustable value to count to before the counter resets.
-- The counter will count from 0 to LIMIT-1.
generic (LIMIT : NATURAL := 17);
port (
    -- 'rst' to reset counter when set high.
    -- 'enable' must be high for counter to count.
    clk, rst, enable : in STD_lOGIC;
    -- A data bus to facilitate an output, bus width is dynamic
    -- based on the 'LIMIT' defined above.
    count_out : out UNSIGNED (log2(LIMIT)-1 downto 0)
);

end parameterizable_counter;


architecture Behavioural of parameterizable_counter is
    -- Internal signal for the internal output of the counter
    -- used to count and reset.
    signal count_int : UNSIGNED (log2(LIMIT)-1 downto 0);

begin
counter: process (clk)
begin
    -- When there's a rising clock edge:
    --  If the reset pin is high;
    --      the counter resets to 0
    --  If enable is high:
    --      if the counter output is less than the LIMIT - 1:
    --          then the counter increments.
    --      if the counter output is equal to LIMIT - 1;
    --          the counter resets (rolls-over) to 0
    if rising_edge(clk) then
        if (rst = '1') then                     -- Reset condition
            count_int <= (others => '0');
        elsif (enable = '1') then               -- Enable condition:
            if (count_int = LIMIT-1) then
                count_int <= (others => '0');       -- Roll-over
            else
                count_int <= count_int + 1;         -- Count up
            end if;
        end if;
    end if;
end process counter;

-- The internal signal bus is mapped to the output signal bus.
count_out <= count_int;

end Behavioural;