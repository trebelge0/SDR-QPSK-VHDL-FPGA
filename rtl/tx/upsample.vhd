library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity upsample is
    generic (
        L : integer := 4 -- Facteur d'interpolation (ex: 4)
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Interface Slave
        s_axis_tdata  : in  std_logic_vector(3 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        -- Interface Master
        m_axis_tdata  : out std_logic_vector(3 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast : out  std_logic
    );
end entity;

architecture Behavioral of upsample is
    signal reg_data : std_logic_vector(3 downto 0) := (others => '0');
    signal counter    : integer range 0 to L := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            
            if rst = '1' then
                counter <= 0;
                m_axis_tvalid <= '0';
                reg_data <= (others => '0');

            elsif m_axis_tready = '1' then

                if s_axis_tvalid = '1' and counter = 0 then  -- Nouvelle donnée disponible et on n'est pas en train d'envoyer une série
                    m_axis_tdata <= s_axis_tdata; -- Capture de la donnée d'entrée
                    counter <= 1;
                    m_axis_tvalid <= '1'; 
                    m_axis_tlast <= s_axis_tlast;
                    
                elsif counter > 0 then -- On est en train d'envoyer une série de données
                    if counter < L then
                        counter <= counter + 1;
                        m_axis_tdata <= (others => '0'); -- On envoie des zéros entre les données
                        m_axis_tvalid <= '1';
                    else
                        if s_axis_tvalid = '1' then -- Nouvelle donnée disponible, on recommence la série
                            m_axis_tdata <= s_axis_tdata; -- Capture de la nouvelle donnée d'entrée
                            counter <= 1;
                            m_axis_tvalid <= '1';
                            m_axis_tlast <= s_axis_tlast;
                        else -- Pas de nouvelle donnée, on termine la série actuelle
                            counter <= 0;
                            m_axis_tdata <= (others => '0'); -- On envoie des zéros entre les données
                            m_axis_tvalid <= '0'; -- Fin de la série, on attend la prochaine donnée
                            m_axis_tlast <= '0';
                        end if;
                    end if;
                end if;
            else -- Pas de donnée à envoyer
                m_axis_tvalid <= '0';
                counter <= 0;
                m_axis_tlast <= '0';
                
            end if;
        end if;
    end process;
    
    s_axis_tready <= m_axis_tready when counter = 0 or counter > L-2 else '0';

end architecture;