
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library vunit_lib;
context vunit_lib.vunit_context;  

entity tb_nco is 
    generic (
        DATA_WIDTH : integer := 12;
        runner_cfg : string
    );
end entity;

architecture Behavioral of tb_nco is 

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal out_sin : signed(DATA_WIDTH - 1 downto 0);
signal out_cos : signed(DATA_WIDTH - 1 downto 0);
signal out_valid : std_logic;
signal out_ready : std_logic := '1';
constant FREQ_10MHZ : unsigned(23 downto 0) := x"100000";

begin 

    uut: entity work.nco
        generic map (
            DATA_WIDTH => DATA_WIDTH
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
    
    clk <= not clk after 5 ns;

    main : process
        variable samples_counted : integer := 0;
        variable val : signed(DATA_WIDTH - 1 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        
        wait for 100 ns;

        for i in 0 to 100 loop
            wait until rising_edge(clk) and out_valid = '1';
            
            -- Le signal ne doit pas être bloqué à 0
            if out_sin /= 0 then
                samples_counted := samples_counted + 1;
            end if;
        end loop;
        
        check_equal(samples_counted > 50, true, "Le signal sinus ne semble pas osciller correctement");
        info("NCO : Test d'oscillation réussi.");

        -- Check de périodicité
        val := out_sin;
        wait for 160 ns;
        check(val = out_sin, "La fréquence n'est pas de 6.25 MHz");
        
        test_runner_cleanup(runner);
    end process;
end Behavioral;