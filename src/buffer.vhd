
-- Romain Englebert May 2026 --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 


entity buf is
    -- Parrallelize Serial input with width=SYM_WIDTH
    generic (
        SYM_WIDTH : integer := 2 -- Symbol width
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Slave (from input)
        s_axis_tdata : in std_logic; -- Input bit
        s_axis_tvalid : in std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        -- Master (to encoder)
        m_axis_tdata : out std_logic_vector(SYM_WIDTH - 1 downto 0); -- Symbol
        m_axis_tvalid : out std_logic;
        m_axis_tready : in std_logic;
        m_axis_tlast : out std_logic
    
    );
end entity;

architecture Behavioral of buf is

    signal counter : integer range 0 to SYM_WIDTH - 1 := 0;
    signal m_axis_tdata_reg : std_logic_vector(SYM_WIDTH - 1 downto 0) := (others => '0'); -- To avoid changing output in transitions

begin
    process(clk, rst)
    begin

        if rst = '1' then
            m_axis_tvalid <= '0';
            counter <= 0;
            m_axis_tdata_reg <= (others => '0');

        elsif rising_edge(clk) then

            if m_axis_tready = '1' then  -- If encoder block is ready

                if s_axis_tvalid = '1' then  -- If input data is valid
                                 
                    m_axis_tlast <= s_axis_tlast; 

                    if counter = SYM_WIDTH - 1 then
                        counter <= 0;
                        m_axis_tvalid <= s_axis_tvalid;
                        m_axis_tdata <= s_axis_tdata & m_axis_tdata_reg(counter-1 downto 0);
                    else
                        m_axis_tvalid <= '0';
                        counter <= counter + 1;
                        m_axis_tdata_reg(counter) <= s_axis_tdata;
                    end if;
                
                else -- If no input data
                    m_axis_tvalid <= '0';
                    m_axis_tlast <= '0';
                end if;
            end if;

        end if;
    end process;

    s_axis_tready <= m_axis_tready;  -- Backpressure

end architecture;