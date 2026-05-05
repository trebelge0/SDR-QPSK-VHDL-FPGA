
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir is
    -- Filter RRC for ISI minimization and band reduction
    -- NEEDS AT LEAST 16 SAMPLES (16/L = 2 SYMBOLS) TO WORK
    generic (
        N : integer := 65;
        DATA_WIDTH  : integer := 12;  -- Filter resolution (bits)
        COEFF_WIDTH : integer := 16;  -- FIR coefficient size (bits)
        L : integer := 4  -- Upsampler zero-padding length (bits)
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        s_axis_tdata  : in  signed(1 downto 0); -- Input (-2, -1, 0, 1)
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        m_axis_tdata  : out signed(DATA_WIDTH-1 downto 0); -- Output
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast : out  std_logic
    );
end entity;

architecture rtl of fir is

    -- From rrc_fir_generator.py script
    type coeff_array is array (0 to (N-1)/2) of signed(COEFF_WIDTH-1 downto 0);
    constant COEFFS : coeff_array := (
    x"0058",    x"0057",    x"004E",    x"003C",    x"0020",    x"FFFB",    x"FFCE",    x"FF9B",
    x"FF65",    x"FF30",    x"FEFF",    x"FED7",    x"FEBC",    x"FEB3",    x"FEBF",    x"FEE4",
    x"FF25",    x"FF82",    x"FFFD",    x"0094",    x"0144",    x"020A",    x"02E2",    x"03C4",
    x"04AB",    x"058F",    x"0668",    x"072F",    x"07DD",    x"086B",    x"08D5",    x"0916",
    x"092C"
    );

    type shift_reg_array is array (0 to N-1) of signed(1 downto 0);
    signal shift_reg : shift_reg_array := (others => (others => '0'));
    
    signal acc : signed(N-1 downto 0); 
    signal valid_delay : unsigned((N-1)/2 downto 0) := (others => '0');

    type state_type is (INIT, FILTER, LAST);
    signal state : state_type := INIT;

    signal count : integer range 0 to (N-1)/2+L := 0; 


begin

    process(clk)

        procedure filter is
        variable sum : signed(N-1 downto 0);
        begin 
            shift_reg(0) <= s_axis_tdata;
            for i in 1 to N-1 loop
                shift_reg(i) <= shift_reg(i-1);
            end loop;
            sum := (others => '0');
            for i in 0 to (N-1)/2-1 loop
                sum := sum + ( (resize(shift_reg(i), 3) + resize(shift_reg(N-1-i), 3)) * COEFFS(i) );
            end loop;
            acc <= sum + (resize(shift_reg((N-1)/2), 3) * COEFFS((N-1)/2));
        end procedure;

        begin

        if rising_edge(clk) then

            -- Filter introduces latency, this FSM manage the slave/master valid signals according to it
            case state is

                -- Output not valid yet, filling register during filter's latency
                when INIT =>
                    m_axis_tlast <= '0';
                    m_axis_tvalid <= '0';
                    if s_axis_tvalid = '1' then

                        if count = (N-1)/2-1 then
                            state <= FILTER;
                            m_axis_tvalid <= '1';
                        end if;
                        
                        filter;

                        count <= count + 1;
                    
                    else -- No valid input
                        count <= 0;
                        shift_reg   <= (others => (others => '0'));
                        acc <= (others => '0');
                    end if;
                    
                -- Output valid, filtering until the last symbol
                when FILTER =>
                    if s_axis_tvalid = '1' then

                        m_axis_tvalid <= '1';

                        if s_axis_tlast = '1' then
                            state <= LAST;
                            m_axis_tlast <= '1';
                            count <= 0;
                        end if;

                        filter;

                    end if;

                -- During the last symbol, the output is still valid during the filter's latency after symbol's reception
                when LAST =>
                    -- Counter
                    if count = (N-1)/2-1+L then
                        state <= INIT;
                        count <= 0;
                        m_axis_tvalid <= '0';
                        m_axis_tlast <= '0';
                    end if;
                    
                    filter;

                    count <= count + 1;
                    
            end case;
        end if;
    end process;

    -- Truncation : To adapt (avoid saturation and avoid resolution loss)
    m_axis_tdata  <= acc(18 downto 7); 
    s_axis_tready <= m_axis_tready;

end architecture;