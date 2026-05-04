library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   

entity tb is 
    generic (
        TX_RES : integer := 12
    );
end entity;

architecture Behavioral of tb is 

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal out_sin : signed(TX_RES - 1 downto 0);
signal out_cos : signed(TX_RES - 1 downto 0);
signal out_valid : std_logic;
signal out_ready : std_logic := '1';
constant FREQ_10MHZ : unsigned(23 downto 0) := x"19999A";

begin 

    uut: entity work.nco
        generic map (
            DATA_WIDTH => TX_RES
        )
        port map (
            clk => clk,
            rst => rst,
            freq_word => FREQ_10MHZ,
            m_axis_sin_tdata => out_sin,
            m_axis_cos_tdata => out_cos,
            m_axis_tvalid => out_valid,
            m_axis_tready => out_ready
        );
    
    clk <= not clk after 10 ns;

    process
    begin
        -- 1. Reset initial
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        
        wait for 500 ns;
        wait; -- Suspend le process pour toujours
    end process;
end Behavioral;