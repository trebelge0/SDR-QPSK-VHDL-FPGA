
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir is
    generic (
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
    type coeff_array is array (0 to 16) of signed(COEFF_WIDTH-1 downto 0);
    constant COEFFS : coeff_array := (
    x"00AF",    x"009D",    x"0040",    x"FF9C",    x"FECB",    x"FDFF",    x"FD7A",    x"FD80",
    x"FE4B",    x"FFFA",    x"0286",    x"05C0",    x"0950",    x"0CC8",    x"0FAF",    x"119E",
    x"124B"
    );

    type shift_reg_array is array (0 to 32) of signed(1 downto 0);
    signal shift_reg : shift_reg_array := (others => (others => '0'));
    
    signal acc : signed(32 downto 0); 
    signal valid_delay : unsigned(15 downto 0) := (others => '0');

    type state_type is (INIT, FILTER, LAST);
    signal state : state_type := INIT;

    signal count : integer range 0 to 16+L := 0; 


begin

    process(clk)
        variable sum : signed(32 downto 0);
        begin
        if rising_edge(clk) then

            -- Filter introduces latency, this FSM manage the slave/master valid signals according to it
            case state is

                -- Output not valid yet, filling register during filter's latency
                when INIT =>
                    m_axis_tlast <= '0';
                    m_axis_tvalid <= '0';
                    if s_axis_tvalid = '1' then

                        if count = 15 then
                            state <= FILTER;
                            m_axis_tvalid <= '1';
                        end if;
                        
                        shift_reg(0) <= s_axis_tdata;
                        for i in 1 to 32 loop
                            shift_reg(i) <= shift_reg(i-1);
                        end loop;
                        sum := (others => '0');
                        for i in 0 to 15 loop
                            sum := sum + ( (resize(shift_reg(i), 3) + resize(shift_reg(32-i), 3)) * COEFFS(i) );
                        end loop;
                        acc <= sum + (resize(shift_reg(16), 3) * COEFFS(16));

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

                        shift_reg(0) <= s_axis_tdata;
                        for i in 1 to 32 loop
                            shift_reg(i) <= shift_reg(i-1);
                        end loop;
                        sum := (others => '0');
                        for i in 0 to 15 loop
                            sum := sum + ( (resize(shift_reg(i), 3) + resize(shift_reg(32-i), 3)) * COEFFS(i) );
                        end loop;
                        acc <= sum + (resize(shift_reg(16), 3) * COEFFS(16));

                    end if;

                -- During the last symbol, the output is still valid during the filter's latency after symbol's reception
                when LAST =>
                    -- Counter
                    if count = 15+L then
                        state <= INIT;
                        count <= 0;
                        m_axis_tvalid <= '0';
                        m_axis_tlast <= '0';
                    end if;
                    
                    shift_reg(0) <= s_axis_tdata;
                    for i in 1 to 32 loop
                        shift_reg(i) <= shift_reg(i-1);
                    end loop;
                    sum := (others => '0');
                    for i in 0 to 15 loop
                        sum := sum + ( (resize(shift_reg(i), 3) + resize(shift_reg(32-i), 3)) * COEFFS(i) );
                    end loop;
                    acc <= sum + (resize(shift_reg(16), 3) * COEFFS(16));

                    count <= count + 1;
                    
            end case;
        end if;
    end process;

    -- Truncation : To adapt (avoid saturation and avoid resolution loss)
    m_axis_tdata  <= acc(18 downto 7); 
    s_axis_tready <= m_axis_tready;

end architecture;