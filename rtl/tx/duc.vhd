
-- Romain Englebert May 2026 --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity duc is
    -- Container for Mixer and NCO
    -- Upconvert (baseband -> IF/RF)
    generic (
        DATA_WIDTH : integer := 12;  -- Output resolution (bits)
        PHASE_WIDTH : integer := 24;  -- Phase resolution (bits)
        LUT_WIDTH : integer := 10  -- Sinus LUT size (bits)
    );
    port (
        clk   : in std_logic;
        rst   : in std_logic;

        -- Slave (from FIR RRC filter)
        sq_axis_tdata  : in  signed(DATA_WIDTH-1 downto 0);  -- Filtered q signal
        si_axis_tdata  : in  signed(DATA_WIDTH-1 downto 0);  -- Filtered i signal
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast : in std_logic;

        -- Master (to output)
        m_axis_tdata  : out signed(DATA_WIDTH - 1 downto 0);  -- Mixed output
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast : out  std_logic
    );
end entity;

architecture Behavioral of duc is

    -- Between NCO and Mixer
    signal sin_data : signed(DATA_WIDTH-1 downto 0);
    signal cos_data : signed(DATA_WIDTH-1 downto 0); 
    signal ready_a : std_logic;
    signal valid_a : std_logic;

    -- FCW = \frac{f_c 2^PHASE_WIDTH}{f_s} to set frequency (increment) : x100000 is for f_s = 100MHz and f_c = 100/16 = 6.25 MHz.
    constant FREQ_6_25_MHZ : unsigned(PHASE_WIDTH-1 downto 0) := x"100000";

begin

    -- Numerically controlled oscillator instance
    nco: entity work.nco
    generic map(
        DATA_WIDTH => DATA_WIDTH,
        PHASE_WIDTH => PHASE_WIDTH,
        LUT_WIDTH => LUT_WIDTH
    )
    port map(
        clk => clk, rst => rst,
        freq_word => FREQ_6_25_MHZ,
        m_axis_sin_tdata => sin_data, m_axis_cos_tdata => cos_data, m_axis_tvalid => valid_a, m_axis_tready => ready_a
    );

    -- Mixer (NCO x FIR) instance
    mixer: entity work.mixer
    generic map(
        DATA_WIDTH => DATA_WIDTH,
        PHASE_WIDTH => PHASE_WIDTH
    )
    port map(
        clk => clk, rst => rst,
        sa_axis_sin_tdata => sin_data, sa_axis_cos_tdata => cos_data, sa_axis_tvalid => valid_a, sa_axis_tready => ready_a,
        sb_axis_i_tdata => si_axis_tdata, sb_axis_q_tdata => sq_axis_tdata, sb_axis_tvalid => s_axis_tvalid, sb_axis_tready => s_axis_tready, sb_axis_tlast => s_axis_tlast,
        m_axis_tdata => m_axis_tdata, m_axis_tvalid => m_axis_tvalid, m_axis_tready => m_axis_tready, m_axis_tlast => m_axis_tlast
        );

    s_axis_tready <= m_axis_tready;  -- Backpressure

end architecture;