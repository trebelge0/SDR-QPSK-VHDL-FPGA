
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity encoder is
    -- Map Parrallel input onto symbols (QPSK)
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Interface "Slave"
        s_axis_tdata  : in  std_logic_vector(1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        -- Interface "Master"
        m_axis_tdata  : out std_logic_vector(3 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast : out  std_logic
    );
end entity;

architecture Behavioral of encoder is

begin
    process(clk, rst)
    begin
        if rst = '1' then
            m_axis_tdata <= (others => '0');
            m_axis_tvalid <= '0';

        elsif rising_edge(clk) then

            if (s_axis_tvalid = '1' and m_axis_tready = '1') then
                m_axis_tlast <= s_axis_tlast;
                m_axis_tvalid <= '1';
                case s_axis_tdata is
                    when "00" =>
                        m_axis_tdata <= "1111";
                    when "01" =>
                        m_axis_tdata <= "1101";
                    when "10" =>
                        m_axis_tdata <= "0111";
                    when "11" =>    
                        m_axis_tdata <= "0101";
                    when others =>
                        m_axis_tdata <= "0000";
                end case;
                
            else
                m_axis_tvalid <= '0';
                m_axis_tlast <= '0';       
                m_axis_tdata <= (others => '0');
            end if;

        end if;
    end process;

    s_axis_tready <= m_axis_tready;

end architecture;