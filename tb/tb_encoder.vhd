
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_encoder is 
    generic (
        TX_RES : integer := 12;
        runner_cfg : string
    );
end entity;

architecture Behavioral of tb_encoder is 

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    -- Buffer to encoder
    signal data_ab : std_logic_vector(1 downto 0);  -- From input
    signal valid_ab : std_logic;
    signal ready_ab : std_logic;
    signal tlast_ab : std_logic;

    -- Encoder to upsampler (iq)
    signal data_bc : std_logic_vector(3 downto 0);
    signal valid_bc : std_logic;
    signal ready_bc : std_logic;
    signal tlast_bc : std_logic;

begin 

    uut: entity work.encoder
        port map (
        clk      => clk, rst => rst,
        s_axis_tdata   => data_ab, s_axis_tvalid => valid_ab, s_axis_tready => ready_ab, s_axis_tlast => tlast_ab, -- Entrée venant de A
        m_axis_tdata   => data_bc, m_axis_tvalid => valid_bc, m_axis_tready => ready_bc, m_axis_tlast => tlast_bc   -- Sortie vers C
    );
    
    clk <= not clk after 10 ns;

    -- PROCESS 1: STIMULUS (Envoi des 4 combinaisons QPSK)
    stim_proc : process
        procedure send_symbol(val : std_logic_vector(1 downto 0); last : std_logic := '0') is
        begin
            wait until rising_edge(clk);
            data_ab  <= val;
            valid_ab <= '1';
            tlast_ab <= last;
            loop
                wait until rising_edge(clk);
                exit when ready_ab = '1';
            end loop;
            valid_ab <= '0';
            tlast_ab <= '0';
        end procedure;
    begin
        wait until rst = '0';
        wait for 20 ns;

        -- Test des 4 symboles QPSK
        send_symbol("00");
        send_symbol("01");
        send_symbol("10");
        send_symbol("11", '1'); -- Dernier symbole
        
        wait;
    end process;

    -- PROCESS 2: CONTRÔLE (Backpressure)
    ctrl_proc : process
    begin
        ready_bc <= '1';
        wait for 60 ns;
        
        -- Simulation d'un upsampler saturé
        info("Backpressure activé sur sortie encodeur");
        ready_bc <= '0';
        wait for 50 ns;
        
        ready_bc <= '1';
        wait;
    end process;

    -- PROCESS 3: ORCHESTRATEUR 
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        
        wait for 100 ns;

        check(data_bc = "1111", "Erreur mapping 00");
        wait for 40 ns;
        check(data_bc = "1101", "Erreur mapping 01");
        wait for 40 ns;
        check(data_bc = "0111", "Erreur mapping 10");
        wait for 40 ns;
        check(data_bc = "0101", "Erreur mapping 11");
        test_runner_cleanup(runner);
    end process;
end Behavioral;