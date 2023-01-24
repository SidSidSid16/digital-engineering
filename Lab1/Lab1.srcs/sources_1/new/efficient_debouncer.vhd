library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

entity efficient_debouncer is
generic (LIMIT : NATURAL := 50000000);
    Port ( clk : in STD_LOGIC;
           input_raw : in STD_LOGIC;
           output_debounced : out STD_LOGIC);
end efficient_debouncer;

architecture Behavioral of efficient_debouncer is

signal input_raw_inverted : STD_LOGIC;
signal count_out_ext : UNSIGNED (log2(LIMIT)-1 downto 0);
signal max_detector : STD_LOGIC;
signal counter_enabler : STD_LOGIC;
signal flip_flop_output : STD_LOGIC;

begin
    --
    input_raw_inverted <= not input_raw;
    
    --
    max_detector <= '1' when count_out_ext = LIMIT-1 else
                    '0';
                    
    --
    counter_enabler <= input_raw AND (not max_detector);
    
    --
    output_debounced <= max_detector AND (not flip_flop_output);
                    
    --  
    parameterizable_counter : entity work.parameterizable_counter
    generic map (
        --
        LIMIT => LIMIT
    )
    port map (
        --
        clk => clk,
        --  
        rst => input_raw_inverted,
        --  
        enable => counter_enabler,
        --
        count_out => count_out_ext
    );
    
    --
    d_type_flip_flop : entity work.d_type_flip_flop
    port map (
        --
        clk => clk,
        --
        data => max_detector,
        --
        output => flip_flop_output
    );

end Behavioral;
