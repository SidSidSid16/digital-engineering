library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fibonacci_8bit_sequence is
    -- Adjustable value for the # of clock cycles the debouncer counts for.
    -- Default set to 50x10^6 for a debounce of approx. 0.5 seconds for a
    -- 100MHz processor.
    generic (LIMIT : NATURAL := 50000000);
    Port ( clk : in STD_LOGIC;
           --  Count raw user input, translates to 'enable' signal close to the counter
           count : in STD_LOGIC;
           --  Raw user input that when presses will reset the sequence
           reset : in STD_LOGIC;
           --  Fibonacci output that is read from ROM
           output : out STD_LOGIC_VECTOR (7 downto 0));
end fibonacci_8bit_sequence;

architecture Behavioral of fibonacci_8bit_sequence is

-- Internal signals containing the debounced signals for the raw user inputs
signal reset_debounced : STD_LOGIC;
signal enable_debounced : STD_LOGIC;

-- Internal signal containing the output of the counter
-- This output points to a specific location in ROM
signal counter_output_address : UNSIGNED (3 downto 0);

begin
    --  This debouncer is used to debounce the count button input.
    --  When the user clicks the count button, it is debounced and
    --  inputted into the counter as enable.
    enable_input_debouncer : entity work.efficient_debouncer
    generic map (
        LIMIT => LIMIT
    )
    port map (
        clk => clk,
        --  Raw signal is inputted
        input_raw => count,
        --  Debounced signal outputted
        output_debounced => enable_debounced
    );
    
    
    --  This debouncer is used to debounce the reset button input.
    --  When the user clicks the reset button, it is debounced and
    --  inputted to the counter as reset.
    reset_input_debouncer : entity work.efficient_debouncer
    generic map (
        LIMIT => LIMIT
    )
    port map (
        clk => clk,
        --  Raw user input is inputted
        input_raw => reset,
        --  DEbounced signal is outputted
        output_debounced => reset_debounced
    );


    --  The debounced reset and count signals are inputted as reset and count.
    --  When count is pressed, the debounced signal comes in as enable and enables
    --  the counter allowing it to increment. When the debounced reset is inputted,
    --  the counter resets back to zero.
    sync_enable_4bit_counter : entity work.sync_enable_4bit_counter 
    port map (
        clk => clk,
        --  The debounced signals are inputted (not raw user inputs)
        rst => reset_debounced,
        en => enable_debounced,
        --  The output is mapped to the counter address internal signal
        cnt_out => counter_output_address
    );
    
    --  The ROM stores the first 14 elements of the Fibonacci sequence.
    --  The output from the counter is inputted as the address into the ROM,
    --  the data at that address is then outputted by the ROM into the output bus.
    fibonacci_8bit_sync_read_rom : entity work.fibonacci_8bit_async_read_rom
    port map (
        --  Output of 4-bit counter is used to access memory item
        address => counter_output_address,
        --  Memory item is outputted into DataOut bus (8-bit Fibonacci sequence)
        DataOut => output
    );

end Behavioral;
