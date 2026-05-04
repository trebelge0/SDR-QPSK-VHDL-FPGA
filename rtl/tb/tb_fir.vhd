-- Romain Englebert, May 2026
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_fir is
  generic (
        L : integer := 8;
        DATA_WIDTH : integer := 12;
        runner_cfg : string
    );
end entity;

architecture test of tb_fir is
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    -- Entrées
    signal data_cd : std_logic_vector(3 downto 0) := (others => '0');
    signal valid_cd : std_logic := '0';
    signal ready_cd : std_logic;
    signal tlast_cd : std_logic := '0';

    -- Sorties
    signal data_die : signed(DATA_WIDTH-1 downto 0);
    signal valid_die : std_logic;
    signal ready_de : std_logic := '1'; 
    signal tlast_die : std_logic;

begin
  -- Instance de l'UUT
  uut : entity work.fir
    generic map(DATA_WIDTH => DATA_WIDTH, L => L)
    port map (
        clk      => clk, rst => rst,
        s_axis_tdata   => signed(data_cd(1 downto 0)), -- On cast en signed pour le filtre
        s_axis_tvalid  => valid_cd, 
        s_axis_tready  => ready_cd, 
        s_axis_tlast   => tlast_cd,
        m_axis_tdata   => data_die, 
        m_axis_tvalid  => valid_die, 
        m_axis_tready  => ready_de, 
        m_axis_tlast   => tlast_die
    );

  clk <= not clk after 5 ns;

  -- 1. STIMULUS : Envoi d'une impulsion
  stim_proc : process
  begin
    wait until rst = '0';
    wait for 20 ns;

    -- Envoi d'un symbole "1" (Impulsion)
    wait until rising_edge(clk);
    data_cd  <= "0001"; -- Tes données d'entrée
    valid_cd <= '1';
    
    wait until rising_edge(clk) and ready_cd = '1';
    valid_cd <= '0';
    
    -- On envoie ensuite une série de 0 pour laisser le filtre "se vider"
    for i in 0 to 20 loop
        wait until rising_edge(clk);
        data_cd <= "0000";
        valid_cd <= '1';
    end loop;
    
    wait;
  end process;

  -- 2. MONITOR : Vérification de la sortie
  monitor_proc : process
  begin
    wait until rst = '0';
    
    -- On attend que le valid de sortie soit actif
    wait until rising_edge(clk) and valid_die = '1';
    info("FIR a commencé à produire des données.");

    -- Ici, tu peux checker que la sortie est non-nulle
    -- Typiquement, le premier échantillon de réponse impulsionnelle 
    -- correspond au premier coefficient du filtre.
    check_equal(data_die /= to_signed(0, DATA_WIDTH), true, "La sortie devrait être non-nulle");
    
    wait;
  end process;

  -- 3. ORCHESTRATEUR
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait for 500 ns;
    test_runner_cleanup(runner);
  end process;
end architecture;