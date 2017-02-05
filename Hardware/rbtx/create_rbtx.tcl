create_project rbtx . -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
import_files -norecurse {../vhdl/rb_tx_v1_0_M00_AXI.vhd ../vhdl/rbtx_sampler.vhd ../vhdl/circbuf_sync.vhd ../vhdl/rb_tx_v1_0.vhd ../vhdl/rb_tx_v1_0_S00_AXI.vhd}
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project -root_dir ./rbtx/rbtx.srcs/sources_1/imports/srcs -vendor xilinx.com -library user -taxonomy /UserIP
