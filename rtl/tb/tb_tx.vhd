
-- Romain Englebert May 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   
library vunit_lib;
context vunit_lib.vunit_context;


entity tb_tx is 
    -- Global test
    generic (
        DATA_WIDTH : integer := 12;
        LUT_WIDTH : integer := 10;
        PHASE_WIDTH : integer := 24;
        L : integer := 8;
        INPUT_WIDTH : integer := 32;
        INPUT_DATA : std_logic_vector(INPUT_WIDTH-1 downto 0) := "11000110011101011000011110111011";
        runner_cfg : string
    );
end entity;

architecture Behavioral of tb_tx is 

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal in_data : std_logic;
signal in_valid : std_logic := '0';
signal in_ready : std_logic;
signal in_tlast : std_logic := '0';
signal out_data : signed(DATA_WIDTH - 1 downto 0);
signal out_valid : std_logic;
signal out_ready : std_logic := '1';

begin 

    uut: entity work.top_tx
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            PHASE_WIDTH => PHASE_WIDTH,
            LUT_WIDTH => LUT_WIDTH,
            L => L
        )
        port map (
            clk => clk,
            rst => rst,
            in_data => in_data,
            in_valid => in_valid,
            in_ready => in_ready,
            in_tlast => in_tlast,
            out_data => out_data,
            out_valid => out_valid,
            out_ready => out_ready
        );
    
    clk <= not clk after 5 ns;

    -- Processus de test
    main : process
    begin
    test_runner_setup(runner, runner_cfg);

        -- 1. Reset
        rst <= '1';
        in_valid <= '0';
        in_data  <= '0';
        wait for 20 ns;
        rst <= '0';
        wait until rising_edge(clk);

        -- 2. Data
        for i in 0 to INPUT_WIDTH-1 loop
            in_valid <= '1';
            in_data  <= INPUT_DATA(i);
            if i = INPUT_WIDTH-1 then
                in_tlast <= '1';
            else
                in_tlast <= '0';
            end if;
            loop
                wait until rising_edge(clk);
                exit when in_ready = '1';
            end loop;
        end loop;

        -- 3. End
        in_tlast <= '0';
        in_valid <= '0';
        in_data  <= '0';
        
        wait for 2000 ns;
    test_runner_cleanup(runner);
    end process;
end Behavioral;