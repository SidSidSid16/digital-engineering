library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.DigEng.all;

entity STUDENT_AREA is
    Generic (
        disp_delay : natural := 100000000
    );
    Port ( 
        CLK : in  STD_LOGIC;
        RST : in  STD_LOGIC;
        USER_PB : in  STD_LOGIC_VECTOR (4 downto 0);
        SWITCHES : in  STD_LOGIC_VECTOR (7 downto 0);
        LEDS : out  STD_LOGIC_VECTOR (7 downto 0);
        DATA_FROM_SPI : in  STD_LOGIC_VECTOR (7 downto 0);
        DATA_TO_SPI : out  STD_LOGIC_VECTOR (7 downto 0);
        EN_SPI : out  STD_LOGIC;
        SPI_WR_REQ : out STD_LOGIC;
        SPI_WR_ACK : in STD_LOGIC;
        SPI_RD_REQ : out STD_LOGIC;
        SPI_RD_ACK : in STD_LOGIC;
        SRAM_ADDRESS : in STD_LOGIC_VECTOR(23 downto 0)
    );
end STUDENT_AREA;

architecture Behavioral of STUDENT_AREA is
-- Signals for the btn assignments, I've renamed them so they're
-- more readable.
signal WRITE, ENTER, READ: STD_LOGIC;
-- We need to store the limit of how many inputs we can enter in
-- the SRAM during WRITE mode. While the SRAM datasheet states a
-- 128K x 8-bit organisation where we can store 128K bytes, we will
-- set a limit of 255.
constant input_limit : integer := 255;
-- Defining the FSM states and instantiating the state signals, a
-- grand total of 24 states have been designed for this circuit. 
type state_type is (
    IDLE,       -- The usual IDLE state
    WRINST_REQ, -- WRITE instruction is transmit and WR ACK goes high
    WRINST_ACK, -- Wait for WR ACK to go back to low
    WADDR1_REQ, -- Byte 1 of address is sent and WR ACK goes high
    WADDR1_ACK, -- Wait for WR ACK to go back to low
    WADDR2_REQ, -- Byte 2 of address is sent and WR ACK goes high
    WADDR2_ACK, -- Wait for WR ACK to go back to low
    WADDR3_REQ, -- Byte 3 of address is sent and WR ACK goes high
    WADDR3_ACK, -- Wait for WR ACK to go back to low
    WRHOLD,     -- Wait for ENTER btn toggle before writing to SRAM
    WRSWCH_REQ, -- Send SWITCHES and ACK goes high
    WRSWCH_ACK, -- Wait for WR ACK to go back to low
    RDHOLD,     -- WRITE mode exited, waiting for READ btn toggle
    RDINST_REQ, -- READ instruction is transmit and WR ACK goes high
    RDINST_ACK, -- Wait for WR ACK to go back to low
    RADDR1_REQ, -- Byte 1 of address is sent and WR ACK goes high
    RADDR1_ACK, -- Wait for WR ACK to go back to low
    RADDR2_REQ, -- Byte 2 of address is sent and WR ACK goes high
    RADDR2_ACK, -- Wait for WR ACK to go back to low
    RADDR3_REQ, -- Byte 3 of address is sent and WR ACK goes high
    RADDR3_ACK, -- Wait for WR ACK to go back to low
    RDOUTP_REQ, -- Send READ request, and RD ACK goes high
    RDOUTP_ACK, -- Wait for RD ACK to go back to low
    LEDOUT      -- Displays byte that's read via the LEDS
);
signal state, next_state : state_type;
-- Internal signal instantiation for the up-down counter that
-- tracks how many values that've been written to the SRAM and
-- how many values that've been read.
signal INPT_CNT_OUT : UNSIGNED (log2(input_limit)-1 downto 0);
signal INPT_CNT_EN_UP, INPT_CNT_EN_DOWN, INPT_CNT_RST : STD_LOGIC;

begin

WRITE <= USER_PB(1);
ENTER <= USER_PB(3);
READ <= USER_PB(2);

-- Instantiate the up-down counter which will be used to track
-- a count of values that have been written to SRAM and read 
-- (popped) from the SRAM.
INPT_CNT : entity work.Param_Counter_UpDown
GENERIC MAP (LIMIT => input_limit)
PORT MAP(
	clk => clk,
	rst => INPT_CNT_RST,
	en_up => INPT_CNT_EN_UP,
    en_down => INPT_CNT_EN_DOWN,
	count_out => INPT_CNT_OUT
);


--  Sets the state as IDLE (reset state) when the reset input is set high.
--  At each clock cycle if the reset isn't high, the state is set to the next
--  state.
state_assignment : process (clk) is
begin
    if rising_edge(clk) then
        if (rst = '1') then
            state <= IDLE;
        else
            state <= next_state;
        end if;
    end if; 
end process state_assignment;


fsm_process : process (state, WRITE, ENTER, READ, SPI_WR_ACK, SPI_RD_ACK, INPT_CNT_OUT)
begin
    case STATE is
        
        when IDLE =>
            -- From IDLE the only state we can go to is the states for WRITE mode. We
            -- therefore wait for the WRITE button to be pressed.
            if (WRITE = '1') then
                state <= WRINST_REQ;
            end if;
            
            
        
        ----------------------------    
        -- WRITE TRANSACTION LOGIC    
        --------
        
        when WRINST_REQ =>
            -- Once the WRITE button is pressed from the IDLE state, we enter WRITE mode.
            -- In this state, we send the WRITE instruction to the SPI, when the WR_ACK
            -- line goes high, we then enter the WRINST_ACK state where we wait for the
            -- ACK line to go low again.
            if (SPI_WR_ACK = '1') then
                state <= WRINST_ACK;
            end if;
        when WRINST_ACK =>
            -- We have to wait until the SPI ACK line goes back to low again before we
            -- send the next instruction/value to the SPI. This state essentially waits
            -- for this to happen before it lets the circuit go to the next state. Please
            -- note that any state that ends with '_REQ' will have a state following that
            -- ends with '_ACK' that repeats this same logic - this will prevent repeated
            -- comments. The next state will be one where the first byte of the address is
            -- sent to the SPI.
            if (SPI_WR_ACK = '0') then
                state <= WADDR1_REQ;
            end if;
            
        when WADDR1_REQ =>
            -- Here, the first byte of the SRAM address is sent as part of the WRITE mode
            -- transaction.
            if (SPI_WR_ACK = '1') then
                state <= WADDR1_ACK;
            end if;
        when WADDR1_ACK =>
            -- Wait for the SPI ACK to go low before going to the next FSM state. 
            -- address.
            if (SPI_WR_ACK = '0') then
                state <= WADDR2_REQ;
            end if;
            
        when WADDR2_REQ =>
            -- Here, the second byte of the SRAM address is sent.
            if (SPI_WR_ACK = '1') then
                state <= WADDR2_ACK;
            end if;
        when WADDR2_ACK =>
            -- Wait for ACK line to go low before continuing.
            if (SPI_WR_ACK = '0') then
                state <= WADDR3_REQ;
            end if;
            
        when WADDR3_REQ =>
            -- Here, the third and final byte of the SRAM address is sent.
            if (SPI_WR_ACK = '1') then
                state <= WADDR3_ACK;
            end if;
        when WADDR3_ACK =>
            -- Wait for ACK line to go low before continuing.
            if (SPI_WR_ACK = '0') then
                state <= WRHOLD;
            end if;
            
        when WRHOLD =>
            -- This state is reached once the WRITE transaction has been initialised
            -- i.e., the instruction was sent and received and all three bytes of the
            -- 24-bit SRAM address was sent and received. Now, we wait for the user to
            -- set the switches on the board and press the ENTER button to store a value
            -- or for the user to toggle ENTER to exit WRITE mode. If the user enters
            -- values and exits WRITE mode, then the logic can assume that the user will
            -- enter READ mode next. If the user exits WRITE without writing anything,
            -- we need to return back to IDLE.
            if (ENTER = '1') then
                state <= WRSWCH_REQ;                        -- User wants to enter values
            elsif (WRITE = '1' and INPT_CNT_OUT = 0) then
                state <= IDLE;                              -- Nothing was written
            elsif (WRITE = '1' and INPT_CNT_OUT > 0) then
                state <= RDHOLD;                            -- Something was written
            end if;
            
        when WRSWCH_REQ =>
            -- The value set by SWITCHES needs to be written to SRAM, so a WR req. is
            -- sent.
            if (SPI_WR_ACK = '1') then
                state <= WRSWCH_ACK;
            end if;
        when WRSWCH_ACK =>
            -- Wait for ACK low before returning back to WRHOLD so the user can enter
            -- another value into the SRAM or exit WRITE mode.
            if (SPI_WR_ACK = '0') then
                state <= WRHOLD;
            end if;
            
            
        
        ----------------------------    
        -- READ TRANSACTION LOGIC    
        --------
        
        when RDHOLD =>
            -- This state is reached when the user enters values into SRAM (INPT_CNT
            -- was incremented and the output is not equal to zero) and exits WRITE
            -- mode. Here we wait for the user to enter READ mode by toggling READ
            -- before we can send the READ instructions to the SPI.
            if (READ = '1') then
                state <= RDINST_REQ;
            end if;
            
        when RDINST_REQ =>
            -- Send the READ instruction to the SPI and wait for WR ACK.
            if (SPI_WR_ACK = '1') then
                state <= RDINST_ACK;
            end if;
        when RDINST_ACK =>
            -- Wait for RD ACK to return low.
            if (SPI_WR_ACK = '1') then
                state <= RADDR1_REQ;
            end if;
            
        when RADDR1_REQ =>
            -- Here, the first byte of the SRAM address is sent as part of the READ mode
            -- transaction.
            if (SPI_WR_ACK = '1') then
                state <= RADDR1_ACK;
            end if;
        when RADDR1_ACK =>
            -- Wait for the SPI ACK to go low before going to the next FSM state. 
            -- address.
            if (SPI_WR_ACK = '0') then
                state <= RADDR2_REQ;
            end if;
            
        when RADDR2_REQ =>
            -- Here, the second byte of the SRAM address is sent.
            if (SPI_WR_ACK = '1') then
                state <= RADDR2_ACK;
            end if;
        when RADDR2_ACK =>
            -- Wait for ACK line to go low before continuing.
            if (SPI_WR_ACK = '0') then
                state <= RADDR3_REQ;
            end if;
            
        when RADDR3_REQ =>
            -- Here, the third and final byte of the SRAM address is sent.
            if (SPI_WR_ACK = '1') then
                state <= RADDR3_ACK;
            end if;
        when RADDR3_ACK =>
            -- Wait for ACK line to go low before continuing.
            if (SPI_WR_ACK = '0') then
                state <= RDOUTP_REQ;
            end if;
            
        when RDOUTP_REQ =>
            -- We send a RD req. to the SPI so we can return the value that was
            -- previously written to the SRAM.
            if (SPI_RD_ACK = '1') then
                state <= RDOUTP_ACK;
            end if;
        when RDOUTP_ACK =>
            -- Wait for the RD ACK to return to low before going to next state to
            -- display the output via the LEDS.
            if (SPI_RD_ACK = '0') then
                state <= LEDOUT;
            end if;
            
        when LEDOUT =>
            -- If there are still more values which needs to be read from the SRAM
            -- (i.e., the INPT_CNT hasn't been decremented to 0) then we return back
            -- to the RDOUTP_REQ state where we send a request to the SPI to read
            -- the next value from SRAM. If all values have been read and displayed
            -- (i.e., the counter has returned back to 0) then we can return back to
            -- the IDLE state, ready to enter WRITE mode again and write more values
            -- into the SRAM.
            if (INPT_CNT_OUT > 0) then
                state <= RDOUTP_REQ;
            elsif (INPT_CNT_OUT = 0) then
                state <= IDLE;
            end if;
    end case;
end process fsm_process;


end Behavioral;

