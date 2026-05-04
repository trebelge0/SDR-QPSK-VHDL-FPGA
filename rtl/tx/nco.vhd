library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_pkg.all;

entity nco is
    generic (
        PHASE_WIDTH : integer := 24; -- Précision de la frequence
        LUT_WIDTH : integer := 10;
        DATA_WIDTH  : integer := 12  -- Précision de l'amplitude
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Contrôle (Entrée)
        freq_word : in unsigned(PHASE_WIDTH - 1 downto 0); -- Fréquence de sortie

        -- Interface Master (vers le Mixeur)
        m_axis_sin_tdata  : out signed(DATA_WIDTH - 1 downto 0);
        m_axis_cos_tdata  : out signed(DATA_WIDTH - 1 downto 0);
        m_axis_tvalid     : out std_logic;
        m_axis_tready     : in  std_logic
    
        );
end entity;

architecture Behavioral of nco is

    signal phase_acc : unsigned(PHASE_WIDTH - 1 downto 0) := (others => '0');
    constant LUT_MAX : integer := (2**LUT_WIDTH) - 1;

begin

    -- 1. Phase accumulator (L'accumulateur tourne toujours, peu importe tready)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                phase_acc <= (others => '0');
            else
                phase_acc <= phase_acc + freq_word;
            end if;
        end if;
    end process;
    
    -- Valid est toujours à '1' car le NCO ne s'arrête jamais
    m_axis_tvalid <= '1'; 

    -- 2. La LUT (Combinatoire)
    process(phase_acc)
        variable p : integer;
    begin
        -- On extrait l'adresse locale (0 à 1023)
        p := to_integer(phase_acc(PHASE_WIDTH-3 downto PHASE_WIDTH - LUT_WIDTH - 2));

        case phase_acc(PHASE_WIDTH-1 downto PHASE_WIDTH-2) is
            when "00" => -- 0 à 90°
                m_axis_sin_tdata <=  SINE_LUT(p);
                m_axis_cos_tdata <=  SINE_LUT(LUT_MAX - p);
            when "01" => -- 90 à 180°
                m_axis_sin_tdata <=  SINE_LUT(LUT_MAX - p);
                m_axis_cos_tdata <= -SINE_LUT(p);
            when "10" => -- 180 à 270°
                m_axis_sin_tdata <= -SINE_LUT(p);
                m_axis_cos_tdata <= -SINE_LUT(LUT_MAX - p);
            when "11" => -- 270 à 360°
                m_axis_sin_tdata <= -SINE_LUT(LUT_MAX - p);
                m_axis_cos_tdata <=  SINE_LUT(p);
            when others => null;
        end case;
    end process;

end architecture;