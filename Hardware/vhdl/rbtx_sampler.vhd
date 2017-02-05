-----------------------------------------------------
-- FSM inspiree du model suivante:
-- VHDL FSM (Finite State Machine) modeling
-- (ESD book Figure 2.7)
-- by Weijun Zhang, 04/2001
--
-- Ce fichier contient une entitee compatible avec le mode de sampling adopte
-- par l'IP rb_tx.
-- V0 		: 	entitee d'origine: genere des integer en partant de 0 des que la 
--				fifo peut supporter une insertion
-- V0.1		: 	ajout de la fonctionnalitee de sampling tant que le maitre le demande
-- V0.2		:	ajout de la division de la clock
--				ajout du signal d'entrée
-- V0.3		:	ajout de la selection du trigger
--				ajout du signal d'erreur
-----------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

entity rbtx_sampler is
	port (
		clk					: in std_logic;
		resetn				: in std_logic;
		--signaux de la fifo, cf. circular buffer .vhd
		fifo_out_data		: out std_logic_vector(31 downto 0):= (others => '0');
		fifo_out_rdy		: out std_logic:= '0';
		fifo_out_ack		: in std_logic;

		m_sample 			: in std_logic;--requete du maitre pour le sampling
		m_clk_division		: in std_logic_vector(31 downto 0);--nombre de division de clock entre les samplings
		data_in				: in std_logic;--le signal échantillonné

		trigger_mode		: in std_logic;--0 => front descendant, 1=> front montant

		internal_errors		: out std_logic_vector(7 downto 0);
		--bit 0 à '1' = sampling corrompu car car fifo pleine

		--signaux de debug
		dbg_state			: out std_logic_vector(7 downto 0);
		dbg_clock_counter	: out std_logic_vector(31 downto 0)
	);
end rbtx_sampler;

architecture behavior of rbtx_sampler is

	type state_type is (
		IDLE, 				--attente d'une requete du maitre sur m_sample
		WAIT_TRIGGER_0, 	--attente de la première phase du front montant/descendant
		WAIT_TRIGGER_1, 	--attente de la deuxième phase du front montant/descendant
		SAMPLING
	);

	signal next_state, current_state: state_type := IDLE;
	signal reg_cnt					: std_logic_vector(31 downto 0) := (others => '0');
	--signal de mémorisation du nombre de cycle attendu avant chaque prélèvement
	--d'échantillon
	signal clock_counter			: integer := 0;
	signal xored 					: std_logic;--utilitaire pour les conditions d'attente de front montants/descendants
	signal internal_err_sample		: std_logic:='0';
	signal error_occured			: std_logic:='0';

begin
	--setup des signaux de debug
	dbg_clock_counter <= std_logic_vector(to_unsigned(clock_counter,32));
	dbg_state <= 
			  "00000001" when current_state = IDLE 				else
			  "00000010" when current_state = WAIT_TRIGGER_0	else
			  "00000100" when current_state = WAIT_TRIGGER_1	else
			  "00001000" when current_state = SAMPLING 			else
			  "11111111";

	xored <= data_in xor trigger_mode;-- xor trigger_mode;
	internal_errors <= (0 => error_occured, others => '0');

	--gestion du changement d'état et du signal d'erreur
	process (clk)
	begin
		if rising_edge(clk) then
			if resetn = '0' then
				current_state <= IDLE;
				error_occured <= '0';
			else 
				current_state <= next_state;
				if error_occured = '0' then
					error_occured <= internal_err_sample;
				elsif error_occured = '1' and next_state = WAIT_TRIGGER_0 then
					--réinitialisation du signal d'erreur pour le nouvel 
					--échantillonnage
					error_occured <= '0';
				end if;
			end if;
		end if;
	end process;

	--gestion des signaux en fonction des états
    comb_logic: process(current_state, m_sample,clock_counter,m_clk_division,xored)
	begin
	case current_state is
	    when IDLE =>
			if m_sample = '0' then
				next_state <= IDLE;
			else
				next_state <= WAIT_TRIGGER_0;
			end if;
	    when WAIT_TRIGGER_0 =>
			if xored = '1'  then
				next_state <= WAIT_TRIGGER_1;
			else 
				next_state <= WAIT_TRIGGER_0;
			end if;

	    when WAIT_TRIGGER_1 =>
			if xored = '0' then 
				next_state <= SAMPLING;
			else 
				next_state <= WAIT_TRIGGER_1; 
			end if;
	    when SAMPLING =>
			if m_sample = '0' and clock_counter = to_integer(unsigned(m_clk_division))-1 then
				next_state <= IDLE;
			else
				next_state <= SAMPLING;
			end if;
	    when others => 
			next_state <= IDLE;
	end case;
	end process;


	process(clk,m_sample, fifo_out_ack,current_state,reg_cnt)
	begin
		if rising_edge(clk)  then
			internal_err_sample <= '0';
			case current_state is
				when SAMPLING => 
					fifo_out_data <= (others => '0');
					if fifo_out_ack = '1' and clock_counter = (to_integer(unsigned(m_clk_division))-1) then
						--Insertion d'une valeur
						fifo_out_rdy <= '1';
						reg_cnt <= std_logic_vector(unsigned(reg_cnt) + 1);
						clock_counter <= 0;
						fifo_out_data <= (0=> data_in, others=>'0');
					elsif fifo_out_ack = '0' and clock_counter = (to_integer(unsigned(m_clk_division))-1) then
						--on veut insérer une valeur mais on échoue : 
						--levée d'une erreur pour le processus d'échantillonnage
						--courant (l'erreur sera réinitialisée au lancement du 
						--prochain processus d'échantillonnage).
						--On rentre dans une phase d'attente de libération de la
						--structure de donnée
						fifo_out_rdy <= '0';
						reg_cnt <= reg_cnt;
						clock_counter <= clock_counter;
						internal_err_sample <= '1';
					elsif fifo_out_ack = '1' and clock_counter /= (to_integer(unsigned(m_clk_division))-1) then
						--attente afin de respecter la période d'échantillonnage
						clock_counter <= clock_counter + 1;
						fifo_out_rdy <= '0';
						reg_cnt <= reg_cnt;
					else
						reg_cnt <= reg_cnt;
						fifo_out_rdy <= '0';
						clock_counter <= clock_counter;
					end if;
				when others => 
					fifo_out_data <= (others => '0');
					reg_cnt <= (others => '0');
					fifo_out_rdy <= '0';
			end case;
		end if;
	end process;


end behavior;
