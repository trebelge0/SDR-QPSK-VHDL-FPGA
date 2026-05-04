library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top_tx is
    generic (
        L : integer := 4;
        DATA_WIDTH : integer := 12;
        PHASE_WIDTH : integer := 24;
        LUT_WIDTH : integer := 10
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        in_data : in std_logic;
        in_valid : in std_logic;
        in_ready : out std_logic;
        in_tlast : in std_logic;

        out_data : out signed(DATA_WIDTH - 1 downto 0);
        out_valid : out std_logic;
        out_ready : in std_logic

    );
end entity;

architecture Behavioral of top_tx is 

    -- buffer
    signal data_ab : std_logic_vector(1 downto 0);
    signal valid_ab : std_logic;
    signal ready_ab : std_logic;
    signal tlast_ab : std_logic;

    -- iq
    signal data_bc : std_logic_vector(3 downto 0);
    signal valid_bc : std_logic;
    signal ready_bc : std_logic;
    signal tlast_bc : std_logic;

    -- iq_up
    signal data_cd : std_logic_vector(3 downto 0);
    signal valid_cd : std_logic;
    signal ready_cd : std_logic;
    signal tlast_cd : std_logic;

    -- g_iq_up
    signal data_dqe : signed(DATA_WIDTH-1 downto 0);
    signal data_die : signed(DATA_WIDTH-1 downto 0);
    signal valid_die : std_logic;
    signal valid_dqe : std_logic;
    signal ready_de : std_logic;
    signal tlast_die : std_logic;
    signal tlast_dqe : std_logic;

    -- tx
    signal data_ef : signed(DATA_WIDTH - 1 downto 0);
    signal valid_ef : std_logic;
    signal ready_ef : std_logic;
    signal tlast_ef : std_logic;

begin

    -- Block A (Le Bufferizer)
    block_a: entity work.buf
    port map (
        clk      => clk, rst => rst,
        s_axis_tdata   => in_data, s_axis_tvalid => in_valid, s_axis_tready => in_ready, s_axis_tlast => in_tlast, -- Entrée externe
        m_axis_tdata   => data_ab, m_axis_tvalid => valid_ab, m_axis_tready => ready_ab, m_axis_tlast => tlast_ab   -- Sortie vers B
    );

    -- Block B (L'Encoder)
    block_b: entity work.encoder
    port map (
        clk      => clk, rst => rst,
        s_axis_tdata   => data_ab, s_axis_tvalid => valid_ab, s_axis_tready => ready_ab, s_axis_tlast => tlast_ab, -- Entrée venant de A
        m_axis_tdata   => data_bc, m_axis_tvalid => valid_bc, m_axis_tready => ready_bc, m_axis_tlast => tlast_bc   -- Sortie vers C
    );

    -- Block C (L'Upsampler)
    block_c: entity work.upsample
        generic map (
            L => L
        )
        port map (
            clk      => clk, rst => rst,
            s_axis_tdata   => data_bc, s_axis_tvalid => valid_bc, s_axis_tready => ready_bc, s_axis_tlast => tlast_bc, -- Entrée venant de B
            m_axis_tdata   => data_cd, m_axis_tvalid => valid_cd, m_axis_tready => ready_cd, m_axis_tlast => tlast_cd   -- Sortie vers D
        );

    -- Block Di (Le Filtre i)
    block_di: entity work.fir
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            L => L
        )
        port map (
            clk      => clk, rst => rst,
            s_axis_tdata   => signed(data_cd(1 downto 0)), s_axis_tvalid => valid_cd, s_axis_tready => ready_cd, s_axis_tlast => tlast_cd, -- Entrée venant de C
            m_axis_tdata   => data_die, m_axis_tvalid => valid_die, m_axis_tready => ready_de, m_axis_tlast => tlast_die   -- Sortie vers E
        );

    -- Block Dq (Le Filtre q)
    block_dq: entity work.fir
        generic map(
            DATA_WIDTH => DATA_WIDTH,
            L => L
        )
        port map (
            clk      => clk, rst => rst,
            s_axis_tdata   => signed(data_cd(3 downto 2)), s_axis_tvalid => valid_cd, s_axis_tready => ready_cd, s_axis_tlast => tlast_cd, -- Entrée venant de C
            m_axis_tdata   => data_dqe, m_axis_tvalid => valid_dqe, m_axis_tready => ready_de, m_axis_tlast => tlast_dqe   -- Sortie vers E
        );


    -- Block E (L'Upconverter)
    block_e: entity work.duc
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            PHASE_WIDTH => PHASE_WIDTH,
            LUT_WIDTH => LUT_WIDTH
        )
        port map (
            clk => clk, rst => rst,
            si_axis_tdata => data_die, sq_axis_tdata => data_dqe, -- Entrée venant de Di et Dq
            s_axis_tvalid => valid_die and valid_dqe, s_axis_tready => ready_de, s_axis_tlast => tlast_dqe and tlast_die, 
            m_axis_tdata => data_ef, m_axis_tvalid => valid_ef, m_axis_tready => ready_ef, m_axis_tlast => tlast_ef -- Sortie vers F
        );

    out_data <= data_ef;
    out_valid <= valid_ef;
    ready_ef <= out_ready;

end Behavioral;