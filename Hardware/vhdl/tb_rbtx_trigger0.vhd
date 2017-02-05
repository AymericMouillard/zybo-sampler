---------------------------------------------------------------
--Test bench pour le sampler compatible rbtx.
--On configure des signaux prédéfinis qui génèreront des échantillons prédictibles.
--Ensuite on compare les échantillons obtenus avec les échantillons attendus.
--Spécificité de ce test : le trigger est sur le front descendant.
---------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
USE ieee.numeric_std.ALL;

use work.testtools.all;



entity TB_RBTX_TRIGGER0 is			-- empty entity
end TB_RBTX_TRIGGER0;

---------------------------------------------------------------

architecture TB of TB_RBTX_TRIGGER0 is
    signal clk: std_logic:='0';
    signal reset: std_logic:='0';
	constant HALF_CLK : time := 5000 ns;
	constant FULL_CLK : time := 2*HALF_CLK;
	constant DATA_TEST_SIZE : integer := 6;

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
	signal m_clk_division	: std_logic_vector(31 downto 0):= (0=>'1', 1=>'0',others=>'0');--nombre de division de clock entre les samplings
	signal data_in				: std_logic:='1';
	
	signal trigger_mode		:  std_logic:= '0';--0 => front descendant, 1=> front montant

	signal internal_errors	: std_logic_vector(7 downto 0);

	signal dbg_state			: std_logic_vector(7 downto 0);
	signal dbg_clock_counter	: std_logic_vector(31 downto 0);

	type mem_type is array (0 to DATA_TEST_SIZE-1) of std_logic_vector(31 downto 0);
	signal expected_data : mem_type := (	
											0 => X"00000000", 
											1 => X"FFFFFFFF",
											2 => X"F0F0F0F0",
											3 => X"0F0F0F0F",
											4 => X"AAAAAAAA",
											5 => X"55555555",
											others => X"10000000"
										);
	signal sampled_data : std_logic_vector(31 downto 0) := X"00000000";
	signal sampled_buf : std_logic_vector(31 downto 0) := X"00000000";
	signal counter : integer := 0;
	signal counter_data : integer := 0;
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

	data_gen : process
		variable i : integer := 0;
		variable j : integer := 0;
	begin
		wait for HALF_CLK;--desyn signal and clock...otherwise the sampling si messy
		wait for 10*FULL_CLK;
		data_in <= '0';--trigger
		wait for FULL_CLK;
		while j < DATA_TEST_SIZE loop
			i:=31;
			while i >= 0 loop
				data_in <= expected_data(j)(i);
				wait for FULL_CLK;
				i := i - 1;
			end loop;
			j := j + 1;
		end loop;
		my_test(internal_errors = X"00", "no internal errors occured");
		wait;
	end process;

	master : process
	begin
		reset <= '1';
		wait for FULL_CLK;
		reset<= '0';
		wait for 5*FULL_CLK;
		m_sample <= '1';
		fifo_out_ack <= '1';
		wait;
	end process;

	process(clk)
	begin
		if rising_edge(clk) and fifo_out_rdy = '1' and counter_data < DATA_TEST_SIZE then
			if counter = 31 then
				counter <= 0;
				sampled_data <= sampled_buf(31 downto 1) & fifo_out_data(0);
				my_test(sampled_buf(31 downto 1) & fifo_out_data(0)=expected_data(counter_data), "expected data" & integer'image(counter_data));
				counter_data <= counter_data + 1;
			else
				sampled_buf(31-counter) <= fifo_out_data(0);
				counter <=counter + 1;
			end if;
		end if;
	end process;


end TB;

----------------------------------------------------------------
configuration CFG_TB of TB_RBTX_TRIGGER0 is
	for TB
	end for;
end CFG_TB;
-----------------------------------------------------------------
