library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

-- The efficient debouncer implements a counter which counts to a defined limit
-- whilst the raw input signal is high and doesn't bounce to low, and the limit
-- hasn't been reached. By defining a limit (# of clock cycles), this design can
-- enforce a duration for the raw input signal to be high before the debounced
-- output of high is generated.
entity efficient_debouncer is
-- Adjustable value for the # of clock cycles until the counter resets.
generic (LIMIT : NATURAL := 17);
    Port ( 
           clk : in STD_LOGIC;
           -- The raw user input is mapped
           input_raw : in STD_LOGIC;
           -- The debounced signal output is mapped
           output_debounced : out STD_LOGIC
    );
end efficient_debouncer;

architecture Behavioral of efficient_debouncer is

-- Internal signal for the inverted raw user input.
signal input_raw_inverted : STD_LOGIC;
-- Internal signal bus for the output from the counter.
signal count_out_int : UNSIGNED (log2(LIMIT)-1 downto 0);
-- Internal signal for the output from the counter max value detector.
signal max_detector : STD_LOGIC;
--Internal signal for the counter enable value.
signal counter_enabler : STD_LOGIC;
-- Internal signal for the output from the flip flop.
signal flip_flop_output : STD_LOGIC;

begin
    -- We need to make sure that the counter resets as soon as the raw input
    -- signal bounces from high to low. An inverter is created such that when
    -- the raw input bounces to low, the 'input_raw_inverted' internal signal
    -- will be high, this signal can then be mapped to the reset port of the
    -- counter.
    input_raw_inverted <= not input_raw;
    
    -- The other counter reset condition is when the counter reaches the value
    -- defined by 'LIMIT'. The 'max_detector' internal signal will be set high
    -- as soon as the LIMIT is reached, mapping this signal to the counter's
    -- reset port will complete this logic.
    max_detector <= '1' when count_out_int = LIMIT-1 else
                    '0';
                    
    -- As per the debouncer's logic, the counter need to be enabled when the
    -- raw input signal is high and the 'max_detector' internal signal is low
    -- (when the counter's LIMIT hasn't been reached). The counter needs to be
    -- disabled at all other times. To acheive this logic, the 'max_detector'
    -- signal needs to be inverted, and compared with the raw input signal with
    -- an AND gate.
    counter_enabler <= input_raw AND (not max_detector);
    
    -- The debouncer needs to wait for a number of clock cycles defined by LIMIT
    -- and should only output a debounced high output if there is a high output
    -- from 'max_detector' and a low from the 'max_detector' from the last rising
    -- edge. This is to prevent the debouncer from outputting high due to reaching
    -- the LIMIT value (setting 'max_detector' to high) for two consecutive clock
    -- cycles. This logic is implemented with an AND gate comparing the output from
    -- 'max_detector' and the inverted output from the flip flop.
    output_debounced <= max_detector AND (not flip_flop_output);
                    
    -- The parameterizable counter has been implemented as a separate entity, this
    -- componenent is used to count the number of clock cycles elapsed since the raw
    -- input was set to high.
    parameterizable_counter : entity work.parameterizable_counter
    generic map (
        -- The limit is a parameterizable value allowing for an adjustable number
        -- of clock cycles to count.
        LIMIT => LIMIT
    )
    port map (
        -- (Self explanatory) The clock signal is mapped
        clk => clk,
        -- The counter needs to reset as soon as the raw input bounces to a low.
        rst => input_raw_inverted,
        -- The counter needs to be enabled as per logic defined (and explained)
        -- in the 'counter_enabler' internal signal definition above.
        enable => counter_enabler,
        -- The counter's output needs to be mapped to an internal signal to implement
        -- further logic.
        count_out => count_out_int
    );
    
    --
    d_type_flip_flop : entity work.d_type_flip_flop
    port map (
        -- (Again, self explanatory)
        clk => clk,
        -- The output from the 'max_detector' signal is mapped to the data input
        -- of the flip flop, this is stored until the next clock rising edge.
        data => max_detector,
        -- The data that was stored in the last clock rising edge is outputted
        -- from the flip flop to the 'flip_flop_output' internal signal to
        -- facilitate additional logic for the 'output_debounced' internal signal
        -- as mentioned above.
        output => flip_flop_output
    );

end Behavioral;
