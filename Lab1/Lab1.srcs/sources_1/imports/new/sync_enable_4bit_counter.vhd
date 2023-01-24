library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sync_enable_4bit_counter is
    Port ( clk : in STD_LOGIC;
           -- Debounced reset and enable signals (count)
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           -- Output of the counter, this is the memory
           -- location of the next item in the sequence
           -- in the ROM.
           cnt_out : out UNSIGNED (3 downto 0));  
end sync_enable_4bit_counter;    
                 
architecture Behavioral of sync_enable_4bit_counter is

-- Internal signal which is used for the counter
signal CNT_int : UNSIGNED (3 downto 0);

begin

    -- This is the process for the 4-bit synchronous counter with enable
    CNT_SYNC_ENABLE: process(CLK)
    begin
        -- When there's a rising clock edge:
        --  if reset is high:
        --      the output becomes 0000b
        --  otherwise if enable is high:
        --      1 is added to the output
        --  As the ROM is only 8-bits, only 14 values
        --  of the Fibonacci sequence can be stored.
        --  Therefore, the counter should only count
        --  from 0 to 13. If the reset is high and the
        --  CNT_int output bus is already at 13, the counter
        --  is reset.
        if (rising_edge(CLK)) then
            if (RST = '1') then
                CNT_int <= (others => '0');
            else
                if (EN = '1') then
                    if (CNT_int = 13) then 
                        CNT_int <= (others => '0');
                    else
                        CNT_int <= (CNT_int + 1);
                    end if;
                end if;
            end if;
        end if;
    end process CNT_SYNC_ENABLE;
    cnt_out <= CNT_int;

end Behavioral;
