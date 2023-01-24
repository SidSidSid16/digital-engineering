library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

-- counter to LIMIT (o to LIMIT-1) with sychronous reset and enable
entity parameterizable_counter is 
generic (LIMIT : NATURAL := 17);
port (
    clk, rst, enable : in STD_lOGIC;
    count_out : out UNSIGNED (log2(LIMIT)-1 downto 0)
);

end parameterizable_counter;


architecture Behavioural of parameterizable_counter is
    signal count_int : UNSIGNED (log2(LIMIT)-1 downto 0);

begin
counter: process (clk)
begin
    -- When there's a rising clock edge:
    --  If the reset pin is high;
    --      the counter resets to 0
    --  If enable is high:
    --      if the counter output is less than the limit - 1:
    --          then the counter increments.
    --      if the counter output is equal to limit - 1;
    --          the counter resets to 0
    if rising_edge(clk) then
        if (rst = '1') then
            count_int <= (others => '0');
        elsif (enable = '1') then
            if (count_int = LIMIT-1) then
                count_int <= (others => '0');
            else
                count_int <= count_int + 1;
            end if;
        end if;
    end if;
end process counter;

count_out <= count_int;

end Behavioural;