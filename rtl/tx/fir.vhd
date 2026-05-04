library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir is
    generic (
        DATA_WIDTH  : integer := 12;
        COEFF_WIDTH : integer := 16;
        L : integer := 4
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        s_axis_tdata  : in  signed(1 downto 0); -- Ton entrée 2 bits
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        m_axis_tdata  : out signed(DATA_WIDTH-1 downto 0); -- Sortie 12 bits
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast : out  std_logic
    );
end entity;

architecture rtl of fir is
    type coeff_array is array (0 to 16) of signed(COEFF_WIDTH-1 downto 0);
    constant COEFFS : coeff_array := (
    x"FFAD",    x"FFE1",    x"0058",    x"0087",    x"0019",    x"FF79",    x"FF85",    x"007F",
    x"015C",    x"007F",    x"FD99",    x"FAFA",    x"FC9A",    x"0506",    x"1288",    x"1F35",
    x"2466"
    );

    -- Ici : On garde la taille de l'entrée (2 bits) pour le registre
    type shift_reg_array is array (0 to 32) of signed(1 downto 0);
    signal shift_reg : shift_reg_array := (others => (others => '0'));
    
    -- Accumulateur large pour éviter tout overflow
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
            case state is

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
                    
                    else
                        count <= 0;
                        shift_reg   <= (others => (others => '0'));
                        acc <= (others => '0');
                    end if;
                    
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

    -- TRUNCATION : 
    -- Ton accumulation monte à ~20 bits. Pour retrouver 12 bits, 
    -- on sélectionne les bits significatifs.
    -- Ajuste l'offset (ex: 18 downto 7) selon le gain réel de ton filtre.
    m_axis_tdata  <= acc(18 downto 7); 
    s_axis_tready <= m_axis_tready;

end architecture;