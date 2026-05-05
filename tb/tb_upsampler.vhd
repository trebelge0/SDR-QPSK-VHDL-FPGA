
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_upsample is 
    generic (
        L : integer := 4;
        runner_cfg : string
    );
end entity;

architecture Behavioral of tb_upsample is 

signal clk : std_logic := '0';
signal rst : std_logic := '0';

-- Encoder to upsampler (iq)
signal data_bc : std_logic_vector(3 downto 0);
signal valid_bc : std_logic;
signal ready_bc : std_logic;
signal tlast_bc : std_logic;

-- Upsampler to FIR filter (iq_up)
signal data_cd : std_logic_vector(3 downto 0);
signal valid_cd : std_logic;
signal ready_cd : std_logic;
signal tlast_cd : std_logic;

begin 

    uut: entity work.upsample
        generic map (
            L => L
        )
        port map (
            clk      => clk, rst => rst,
            s_axis_tdata   => data_bc, s_axis_tvalid => valid_bc, s_axis_tready => ready_bc, s_axis_tlast => tlast_bc, -- Entrée venant de B
            m_axis_tdata   => data_cd, m_axis_tvalid => valid_cd, m_axis_tready => ready_cd, m_axis_tlast => tlast_cd   -- Sortie vers D
        );
    
    clk <= not clk after 10 ns;

    -- PROCESS 1: STIMULUS
    stim_proc : process
        procedure send_sample(val : std_logic_vector(3 downto 0)) is
        begin
            wait until rising_edge(clk);
            data_bc  <= val;
            valid_bc <= '1';
            loop
                wait until rising_edge(clk);
                exit when ready_bc = '1';
            end loop;
            valid_bc <= '0';
        end procedure;
    begin
        wait until rst = '0';
        wait for 20 ns;

        send_sample("1010");
        send_sample("0101");
        
        wait;
    end process;

    -- PROCESS 2: MONITEUR
    monitor_proc : process
        variable expected_val : std_logic_vector(3 downto 0);
        variable sample_val : std_logic_vector(3 downto 0);
    begin
        wait until rst = '0';
        
        -- On boucle sur le nombre d'échantillons envoyés
        for s in 0 to 1 loop

            -- 1. Attendre l'échantillon réel
            wait until rising_edge(clk) and valid_cd = '1';
            if s = 0 then sample_val := "1010"; else sample_val := "0101"; end if;
            
            check_equal(data_cd, sample_val, "Erreur: Echantillon de donnée incorrect");

            -- 2. Attendre les L-1 zéros insérés
            for i in 1 to L-1 loop
                wait until rising_edge(clk) and valid_cd = '1';
                check_equal(data_cd, std_logic_vector'("0000"), "Erreur: Le stuffing devrait être à 0");
            end loop;
        end loop;
        
        info("Upsampling vérifié avec succès pour L=" & integer'image(L));
        wait;
    end process;

    -- PROCESS 3: ORCHESTRATEUR
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        
        wait for 500 ns;
        test_runner_cleanup(runner);
    end process;
end Behavioral;