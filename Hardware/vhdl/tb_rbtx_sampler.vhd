---------------------------------------------------------------
--Test bench pour le sampler compatible rbtx
--Spécificité du test: simplicité, on ne regarde que les fonctions basique de commande d'échantillonnage
---------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
USE ieee.numeric_std.ALL;

use work.testtools.all;



entity TB_RBTX_SAMPLER is			-- empty entity
end TB_RBTX_SAMPLER;

---------------------------------------------------------------

architecture TB of TB_RBTX_SAMPLER is
    signal clk: std_logic:='0';
    signal reset: std_logic:='0';
	constant HALF_CLK : time := 5 ns;
	constant FULL_CLK : time := 2*HALF_CLK;

	procedure my_clock(signal cc : inout std_logic)
	is
	begin
		cc <= not cc;
		wait for HALF_CLK;
		cc <= not cc;
		wait for HALF_CLK;
	end my_clock;

	component rbtx_sampler is
		port (
			clk				: in std_logic;
			resetn			: in std_logic;
			fifo_out_data	: out std_logic_vector(31 downto 0);
			fifo_out_rdy	: out std_logic;
			fifo_out_ack	: in std_logic;

			m_sample 		:in std_logic;--requete du maitre pour le sampling
			m_clk_division	: in std_logic_vector(31 downto 0);--nombre de division de clock entre les samplings
			data_in				: in std_logic;

			trigger_mode		: in std_logic;--0 => front descendant, 1=> front montant

			internal_errors		: out std_logic_vector(7 downto 0);

			dbg_state			: out std_logic_vector(7 downto 0);
			dbg_clock_counter	: out std_logic_vector(31 downto 0)
		);
	end component;

	signal resetn			: std_logic;
	signal fifo_out_data	: std_logic_vector(31 downto 0);
	signal fifo_out_rdy		: std_logic;
	signal fifo_out_ack		: std_logic:= '0';

	signal m_sample 		: std_logic:='0';--requete du maitre pour le sampling
	signal m_clk_division	: std_logic_vector(31 downto 0):= (0=>'0', 1=>'1',others=>'0');--nombre de division de clock entre les samplings
	signal data_in				: std_logic;

	signal trigger_mode		:  std_logic:= '1';--0 => front descendant, 1=> front montant

	signal internal_errors	: std_logic_vector(7 downto 0);

	signal dbg_state			: std_logic_vector(7 downto 0);
	signal dbg_clock_counter	: std_logic_vector(31 downto 0);
begin
	resetn <= '0' when reset = '1' else '1';

	rbtx_sampler_inst: rbtx_sampler
	port map(
		clk					=> clk,
		resetn				=>resetn,
		fifo_out_data		=>fifo_out_data,
		fifo_out_rdy		=>fifo_out_rdy,
		fifo_out_ack		=>fifo_out_ack,

		m_sample 			=> m_sample,
		m_clk_division		=> m_clk_division,
		data_in				=> data_in,

		trigger_mode		=> trigger_mode,

		internal_errors		=> internal_errors,

		dbg_state			=>dbg_state,
		dbg_clock_counter	=>dbg_clock_counter
	);

	myclock : process
	begin
		while(true) loop
			my_clock(clk);
		end loop;
	end process;

	--génération d'un simple signal carré périodique
	data_gen : process
		variable i : integer := 0;
	begin
		wait for 2 ns;
		while i < 1000 loop
			data_in <= '1';
			wait for FULL_CLK;
			data_in <= '0';
			wait for FULL_CLK;
		end loop;
		wait;
	end process;

	master : process
	begin
		reset <= '1';
		wait for FULL_CLK;
		reset<= '0';
		my_test(fifo_out_rdy = '0', "initial out rdy = '0'");
		wait for FULL_CLK*5;
		m_sample <= '1';
		my_test(fifo_out_rdy = '0', "wait for fifo open");
		wait for FULL_CLK*2;
		fifo_out_ack <= '1';
		wait for FULL_CLK*50;
		fifo_out_ack <= '0';
		wait for FULL_CLK*10;
		fifo_out_ack <= '1';
		wait for FULL_CLK*50;
		m_sample <= '0';
		wait for FULL_CLK;
		my_test(fifo_out_rdy = '0', "sampling ended");
		my_test(internal_errors = X"00", "no internal errors occured");

		wait;
	end process;


end TB;

----------------------------------------------------------------
configuration CFG_TB of TB_RBTX_SAMPLER is
	for TB
	end for;
end CFG_TB;
-----------------------------------------------------------------
