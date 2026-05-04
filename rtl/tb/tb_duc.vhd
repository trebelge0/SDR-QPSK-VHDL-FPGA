
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_duc is 
    generic (
        DATA_WIDTH : integer := 12;  -- DAC resolution (bits)
        PHASE_WIDTH : integer := 24;  -- NCO Phase resolution (bits)
        LUT_WIDTH : integer := 10; -- NCO sine LUT size (bits)
        runner_cfg : string
    );
end entity;

architecture Behavioral of tb_duc is 

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- FIR filter to DUC (g_iq_up)
    signal data_dqe : signed(DATA_WIDTH-1 downto 0);
    signal data_die : signed(DATA_WIDTH-1 downto 0);
    signal valid_die : std_logic;
    signal valid_dqe : std_logic;
    signal ready_de : std_logic;
    signal tlast_die : std_logic;
    signal tlast_dqe : std_logic;

    -- DUC to output (tx)
    signal data_ef : signed(DATA_WIDTH - 1 downto 0);  -- To DAC
    signal valid_ef : std_logic;
    signal ready_ef : std_logic;
    signal tlast_ef : std_logic;

begin 

    uut: entity work.duc
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
    
    clk <= not clk after 5 ns;

    -- PROCESS 1: STIMULUS (Injection de valeurs I/Q)
    stim_proc : process
    begin
        wait until rst = '0';
        wait for 50 ns;

        -- Envoi de I=50, Q=0
        -- Cela devrait générer une onde cosinus pure en sortie
        wait until rising_edge(clk);
        data_die  <= to_signed(50, DATA_WIDTH);
        data_dqe  <= to_signed(0, DATA_WIDTH);
        valid_die <= '1';
        valid_dqe <= '1';
        
        wait until ready_de = '1';
        wait until rising_edge(clk);
        valid_die <= '0';
        valid_dqe <= '0';
        
    end process;

    -- PROCESS 2: ORCHESTRATEUR
    main : process
        variable val : signed(DATA_WIDTH - 1 downto 0);
        variable samples_received : integer := 0;
    begin
        test_runner_setup(runner, runner_cfg);
        
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        ready_ef <= '1';

        wait until rising_edge(clk) and valid_ef = '1';
        
        -- Vérification : le signal doit osciller (pas être bloqué à 0)
        -- Si I=50 et Q=0, le signal doit osciller entre amplitude -50 et +50
        for i in 0 to 100 loop
            wait until rising_edge(clk) and valid_ef = '1';
            if data_ef /= 0 then
                samples_received := samples_received + 1;
            end if;
        end loop;
        
        check_equal(samples_received > 50, true, "Le DUC ne produit pas de signal modulé");
        info("DUC : Modulation détectée et validée.");

        -- Check de périodicité
        val := data_ef;
        wait for 160 ns;
        check(val = data_ef, "La fréquence n'est pas de 6.25 MHz");
        
        wait for 500 ns; -- Temps suffisant pour voir plusieurs périodes de la porteuse
        test_runner_cleanup(runner);
    end process;

end Behavioral;