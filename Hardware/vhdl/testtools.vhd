--------------------------------------------------------------------------------
--	Utilitaire pour les tests
--	trace: simple message d'info.
--	my_test: test customisé
--------------------------------------------------------------------------------
library STD;
use STD.textio.all;                     -- basic I/O

package TestTools is
	procedure print( msg: in String);
	procedure trace( msg: in String);
	procedure my_test(cond : in boolean;  msg: in String);
end TestTools;

package body TestTools is
	procedure print( msg: in String)
	is 
	variable l : line;
	begin
		write(l,msg); 
		writeline(output,l);
	end print;

	procedure trace( msg: in String)
	is 
	begin
		print("[TRACE]"&msg);
	end trace;

	procedure my_test(cond : in boolean;  msg: in String)
	is
	variable l : line;
	begin
		if cond then
			print( "[PASS]"& msg);
		else
			print( "[FAIL]"& msg);
		end if;

	end my_test;

end TestTools;
