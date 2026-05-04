
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity upsample is
    -- Introduces L-1 bits after each input, to better connect to the FIR filter
    generic (
        L : integer := 4 -- Zero-padding length (bits)
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Slave (from encoder)
        s_axis_tdata  : in  std_logic_vector(3 downto 0);  -- Concatenated IQ (signed)
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        -- Master (to FIR filter)
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

                if s_axis_tvalid = '1' and counter = 0 then  -- New input available and ready
                    m_axis_tdata <= s_axis_tdata; 
                    counter <= 1;
                    m_axis_tvalid <= '1'; 
                    m_axis_tlast <= s_axis_tlast;
                    
                elsif counter > 0 then -- Zero padding insertion
                    if counter < L then
                        counter <= counter + 1;
                        m_axis_tdata <= (others => '0'); -- On envoie des zéros entre les données
                        m_axis_tvalid <= '1';
                    else
                        if s_axis_tvalid = '1' then  -- Skip a cycle -> Continuous output between samples
                            m_axis_tdata <= s_axis_tdata;
                            counter <= 1;
                            m_axis_tvalid <= '1';
                            m_axis_tlast <= s_axis_tlast;
                        else  -- End of transmission
                            counter <= 0;
                            m_axis_tdata <= (others => '0');
                            m_axis_tvalid <= '0'; 
                            m_axis_tlast <= '0';
                        end if;
                    end if;
                end if;
            else -- No data 
                m_axis_tvalid <= '0';
                counter <= 0;
                m_axis_tlast <= '0';
                
            end if;
        end if;
    end process;

    s_axis_tready <= m_axis_tready when counter = 0 or counter > L-2 else '0'; -- Backpressure and anticipation for data to be ready after each sample padding

end architecture;