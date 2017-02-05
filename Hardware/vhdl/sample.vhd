-- vim:ts=3:noexpandtab:
-- For now a simple counter to produce deterministic values !

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sample is
	port (
		clk				: in std_logic;
		reset			: in std_logic;
		fifo_in_data	: out std_logic_vector(31 downto 0);
		fifo_in_rdy		: in std_logic;
		fifo_in_ack		: out std_logic:='0';
		m_sample		: in std_logic;
		f_manager_sample: in std_logic
	);
end sample;

architecture behavior of sample is

	signal reg_cnt			: std_logic_vector(31 downto 0) := (others => '0');
	signal clk_cnt			:integer := 0;

begin

	process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				reg_cnt <= (others => '0');
			else 
			   if fifo_in_rdy = '1' and m_sample = '1' and f_manager_sample = '1' then
				   if clk_cnt = 15 then
						reg_cnt <= std_logic_vector(unsigned(reg_cnt) + 1);
						fifo_in_ack <= '1';
						clk_cnt <= 0;
					else
						clk_cnt <= clk_cnt + 1;
						fifo_in_ack <= '0';
				   end if;
				else
					fifo_in_ack <= '0';
				end if;
			end if;
		end if;
	end process;

	fifo_in_data <=reg_cnt;

end behavior;
