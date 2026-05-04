library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity mixer is
    generic (
        PHASE_WIDTH : integer := 24; -- Précision de la phase
        DATA_WIDTH  : integer := 12  -- Précision de l'amplitude
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

       -- Interface Slave (du NCO)
        sa_axis_sin_tdata  : in signed(DATA_WIDTH - 1 downto 0);
        sa_axis_cos_tdata  : in signed(DATA_WIDTH - 1 downto 0);
        sa_axis_tvalid     : in std_logic;
        sa_axis_tready     : out  std_logic;

        -- Interface Slave (du filtre)
        sb_axis_i_tdata  : in signed(DATA_WIDTH-1 downto 0);
        sb_axis_q_tdata  : in signed(DATA_WIDTH-1 downto 0);
        sb_axis_tvalid     : in std_logic;
        sb_axis_tready     : out  std_logic;
        sb_axis_tlast     : in  std_logic;

        -- Interface Master (vers le DUC)
        m_axis_tdata  : out signed(DATA_WIDTH - 1 downto 0);
        m_axis_tvalid     : out std_logic;
        m_axis_tready     : in  std_logic;
        m_axis_tlast     : out  std_logic
    );
end entity;

architecture Behavioral of mixer is
begin

    process(clk)
    variable icos : signed(DATA_WIDTH*2-1 downto 0) := (others => '0');
    variable qsin : signed(DATA_WIDTH*2-1 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if rst = '1' then
                m_axis_tvalid <= '0';
                m_axis_tdata <= (others => '0');
            elsif sa_axis_tvalid = '1' and sb_axis_tvalid = '1' and m_axis_tready = '1' then
                icos := sa_axis_cos_tdata * sb_axis_i_tdata;
                qsin := sa_axis_sin_tdata * sb_axis_q_tdata;
                m_axis_tdata <= icos(18 downto 7) + qsin(18 downto 7);
                m_axis_tvalid <= '1';
            else
                m_axis_tvalid <= '0';
                m_axis_tdata <= (others => '0');
            end if;
        end if;
    end process;

    sa_axis_tready <= m_axis_tready;
    sb_axis_tready <= m_axis_tready;
    m_axis_tlast <= sb_axis_tlast;

end architecture;