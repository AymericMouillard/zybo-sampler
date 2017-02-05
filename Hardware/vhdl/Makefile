.PHONY: mux sampler test dff fifomanager master show_fails
TARGETS=testtools mux sampler circbuf_sync master fifomanager sample rbtx_sampler
TEST_BENCHS= tb_mux tb_sampler tb_sampler_err tb_buf tb_master tb_fifomanager tb_fifo_manager tb_rbtx_sampler tb_rbtx_sampler01 \
	tb_rbtx_clkdiv \
	tb_rbtx_trigger0 \
	tb_rbtx_trigger0 \
	tb_rbtx_errs \


ANALYSIS=ghdl -a --ieee=synopsys 
ELABORATION=ghdl -e --ieee=synopsys 
RUN=ghdl -r
WAVE_FOLDER=waves/
DEFAULT_SIMU_TIME=1000ns

all:
	$(ANALYSIS) 	testtools.vhd
	$(ANALYSIS) 	rbtx_sampler.vhd
	$(ANALYSIS) 	tb_rbtx_sampler.vhd
	$(ANALYSIS) 	tb_rbtx_sampler01.vhd
	$(ANALYSIS) 	tb_rbtx_trigger0.vhd
	$(ANALYSIS) 	tb_rbtx_clkdiv.vhd
	$(ANALYSIS) 	tb_rbtx_errs.vhd
	$(ELABORATION)	rbtx_sampler
	$(ELABORATION)	tb_rbtx_sampler
	$(ELABORATION)	tb_rbtx_sampler01
	$(ELABORATION)	tb_rbtx_trigger0
	$(ELABORATION)	tb_rbtx_clkdiv
	$(ELABORATION)	tb_rbtx_errs
	#$(RUN) tb_rbtx_sampler		--stop-time=10000000ns --vcd=$(WAVE_FOLDER)/tb_rbtx_sampler.vcd
	#$(RUN) tb_rbtx_sampler01	--stop-time=10000000ns --vcd=$(WAVE_FOLDER)/tb_rbtx_sampler01.vcd
	#$(RUN) tb_rbtx_trigger0		--stop-time=10000000ns --vcd=$(WAVE_FOLDER)/tb_rbtx_trigger0.vcd
	#$(RUN) tb_rbtx_clkdiv		--stop-time=10000000ns --vcd=$(WAVE_FOLDER)/tb_rbtx_clkdiv.vcd
	#$(RUN) tb_rbtx_errs			--stop-time=10000000ns --vcd=$(WAVE_FOLDER)/tb_rbtx_errs.vcd
	@$(RUN) tb_rbtx_sampler		--stop-time=10000000ns
	@$(RUN) tb_rbtx_sampler01	--stop-time=10000000ns 
	@$(RUN) tb_rbtx_trigger0		--stop-time=10000000ns 
	@$(RUN) tb_rbtx_clkdiv		--stop-time=10000000ns 
	@$(RUN) tb_rbtx_errs			--stop-time=10000000ns 

clean:
	rm -f *.o *.cf $(TARGETS) $(TEST_BENCHS)
