-- Romain Englebert, May 2026
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_buffer is 
  generic (runner_cfg : string);
end entity;

architecture Behavioral of tb_buffer is 

    -- Signaux généraux
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- Signaux Interface Entrée (Source)
    signal in_data  : std_logic := '0';
    signal in_valid : std_logic := '0';
    signal in_ready : std_logic;
    signal in_tlast : std_logic := '0';

    -- Signaux Interface Sortie (Sink / Aval)
    signal data_ab  : std_logic_vector(1 downto 0);
    signal valid_ab : std_logic;
    signal ready_ab : std_logic := '1'; -- Par défaut, on accepte les données
    signal tlast_ab : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin 

    -- Instance du Buffer (UUT)
    uut: entity work.buf
        port map (
            clk           => clk, 
            rst           => rst,
            s_axis_tdata  => in_data, 
            s_axis_tvalid => in_valid, 
            s_axis_tready => in_ready, 
            s_axis_tlast  => in_tlast,
            m_axis_tdata  => data_ab, 
            m_axis_tvalid => valid_ab, 
            m_axis_tready => ready_ab, 
            m_axis_tlast  => tlast_ab
        );
    
    clk <= not clk after CLK_PERIOD/2;

    -- PROCESS 1: STIMULUS (Générateur de données)
    -- Ce processus envoie des données et attend que le buffer soit prêt
    stim_proc : process
        procedure send_bit(val : std_logic; last : std_logic := '0') is
        begin
            wait until rising_edge(clk);
            in_data  <= val;
            in_valid <= '1';
            in_tlast <= last;
            -- Attente du ready (Handshake)
            loop
                wait until rising_edge(clk);
                exit when in_ready = '1';
            end loop;
            in_valid <= '0';
            in_tlast <= '0';
        end procedure;
    begin
        wait until rst = '0';
        wait for 20 ns;

        -- Envoi d'un premier paquet de 4 bits (soit 2 symboles)
        send_bit('1', '0');
        send_bit('0', '0'); -- Symbole 1 (10)
        send_bit('0', '0');
        send_bit('1', '1'); -- Symbole 2 (01) avec TLAST
        
        wait; -- Fin du processus stimulus
    end process;

    -- PROCESS 2: CONTRÔLE (Simulation de la Backpressure)
    -- Ce processus décide si l'aval accepte ou non les données
    ctrl_proc : process
    begin
        ready_ab <= '1';
        wait for 50 ns;
        
        -- On bloque l'aval pour tester si le buffer encaisse
        info("Application de la Backpressure...");
        ready_ab <= '0';
        wait for 100 ns; 
        
        -- On libère
        info("Release de la Backpressure.");
        ready_ab <= '1';
        wait;
    end process;

    -- PROCESS 3: ORCHESTRATEUR (VUnit)
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        
        rst <= '1';
        wait for 40 ns;
        rst <= '0';

        wait for 185 ns;

        -- If the backpressure blocks the input properly, the t_last is expected to rise at t=175ms during a clock period.
        check(tlast_ab = '1', "TLAST devrait être présent à la fin du transfert");
        
        test_runner_cleanup(runner);
    end process;

end Behavioral;