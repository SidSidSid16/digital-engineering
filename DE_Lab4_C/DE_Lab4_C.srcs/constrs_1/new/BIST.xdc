# CLK mapped to 100MHz clock source
set_property PACKAGE_PIN Y9 [get_ports GCLK]
set_property IOSTANDARD LVCMOS18 [get_ports GCLK]
# RST mapped to south button (BTNL)
set_property PACKAGE_PIN N15 [get_ports B_RST]
set_property IOSTANDARD LVCMOS18 [get_ports B_RST]
# INPUTS[5:0] mapped to switches 5:0
set_property PACKAGE_PIN F22 [get_ports {INPUTS[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {INPUTS[0]}]
set_property PACKAGE_PIN G22 [get_ports {INPUTS[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {INPUTS[1]}]
set_property PACKAGE_PIN H22 [get_ports {INPUTS[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {INPUTS[2]}]
set_property PACKAGE_PIN F21 [get_ports {INPUTS[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {INPUTS[3]}]
set_property PACKAGE_PIN H19 [get_ports {INPUTS[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {INPUTS[4]}]
set_property PACKAGE_PIN H18 [get_ports {INPUTS[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {INPUTS[5]}]
# TEST mode button mapped to centre button (BTNC)
set_property PACKAGE_PIN P16 [get_ports B_TEST]
set_property IOSTANDARD LVCMOS18 [get_ports B_TEST]
# Fault selection (B_F[1:0]) mapped to switches [7:6]
set_property PACKAGE_PIN H17 [get_ports {B_F[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {B_F[0]}]
set_property PACKAGE_PIN M15 [get_ports {B_F[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {B_F[1]}]
# L_OUT mapped to LED0
set_property PACKAGE_PIN T22 [get_ports L_OUT]
set_property IOSTANDARD LVCMOS18 [get_ports L_OUT]
# L_ERR mapped to LED2
set_property PACKAGE_PIN U22 [get_ports L_ERR]
set_property IOSTANDARD LVCMOS18 [get_ports L_ERR]
# L_ID[3:0] mapped to LED 7:4
set_property PACKAGE_PIN V22 [get_ports {L_ID[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {L_ID[0]}]
set_property PACKAGE_PIN W22 [get_ports {L_ID[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {L_ID[1]}]
set_property PACKAGE_PIN U19 [get_ports {L_ID[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {L_ID[2]}]
set_property PACKAGE_PIN U14 [get_ports {L_ID[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {L_ID[3]}]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list dcm_mgr/inst/clk_out2]]
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {Inst_BIST/L_ID_counter[0]} {Inst_BIST/L_ID_counter[1]} {Inst_BIST/L_ID_counter[2]} {Inst_BIST/L_ID_counter[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe1]
set_property port_width 6 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {VECTOR[0]} {VECTOR[1]} {VECTOR[2]} {VECTOR[3]} {VECTOR[4]} {VECTOR[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {L_ID_OBUF[0]} {L_ID_OBUF[1]} {L_ID_OBUF[2]} {L_ID_OBUF[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe3]
set_property port_width 2 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {B_F_SET[0]} {B_F_SET[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list B_RST_DB]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list B_TEST_DB]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list L_ERR_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list Inst_BIST/present_state]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list UUT_OUT]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets CLK_25MHz]
