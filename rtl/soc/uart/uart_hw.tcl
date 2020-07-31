# TCL File Generated by Component Editor 17.0
# Fri Jul 31 12:26:36 CST 2020
# DO NOT MODIFY


# 
# uart "uart" v17.0
# Sorgelig 2020.07.31.12:26:36
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module uart
# 
set_module_property DESCRIPTION ""
set_module_property NAME uart
set_module_property VERSION 17.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR Sorgelig
set_module_property DISPLAY_NAME uart
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL uart
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file uart.v VERILOG PATH uart.v TOP_LEVEL_FILE
add_fileset_file gh_DECODE_3to8.vhd VHDL PATH gh_DECODE_3to8.vhd
add_fileset_file gh_baud_rate_gen.vhd VHDL PATH gh_baud_rate_gen.vhd
add_fileset_file gh_binary2gray.vhd VHDL PATH gh_binary2gray.vhd
add_fileset_file gh_counter_down_ce_ld.vhd VHDL PATH gh_counter_down_ce_ld.vhd
add_fileset_file gh_counter_down_ce_ld_tc.vhd VHDL PATH gh_counter_down_ce_ld_tc.vhd
add_fileset_file gh_counter_integer_down.vhd VHDL PATH gh_counter_integer_down.vhd
add_fileset_file gh_edge_det.vhd VHDL PATH gh_edge_det.vhd
add_fileset_file gh_edge_det_XCD.vhd VHDL PATH gh_edge_det_XCD.vhd
add_fileset_file gh_fifo_async16_rcsr_wf.vhd VHDL PATH gh_fifo_async16_rcsr_wf.vhd
add_fileset_file gh_fifo_async16_sr.vhd VHDL PATH gh_fifo_async16_sr.vhd
add_fileset_file gh_gray2binary.vhd VHDL PATH gh_gray2binary.vhd
add_fileset_file gh_jkff.vhd VHDL PATH gh_jkff.vhd
add_fileset_file gh_parity_gen_Serial.vhd VHDL PATH gh_parity_gen_Serial.vhd
add_fileset_file gh_register_ce.vhd VHDL PATH gh_register_ce.vhd
add_fileset_file gh_shift_reg_PL_sl.vhd VHDL PATH gh_shift_reg_PL_sl.vhd
add_fileset_file gh_shift_reg_se_sl.vhd VHDL PATH gh_shift_reg_se_sl.vhd
add_fileset_file gh_uart_16550.vhd VHDL PATH gh_uart_16550.vhd
add_fileset_file gh_uart_Rx_8bit.vhd VHDL PATH gh_uart_Rx_8bit.vhd
add_fileset_file gh_uart_Tx_8bit.vhd VHDL PATH gh_uart_Tx_8bit.vhd


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point io
# 
add_interface io avalon end
set_interface_property io addressUnits SYMBOLS
set_interface_property io associatedClock clock
set_interface_property io associatedReset reset
set_interface_property io bitsPerSymbol 8
set_interface_property io burstOnBurstBoundariesOnly false
set_interface_property io burstcountUnits WORDS
set_interface_property io explicitAddressSpan 0
set_interface_property io holdTime 0
set_interface_property io linewrapBursts false
set_interface_property io maximumPendingReadTransactions 0
set_interface_property io maximumPendingWriteTransactions 0
set_interface_property io readLatency 1
set_interface_property io readWaitStates 0
set_interface_property io readWaitTime 0
set_interface_property io setupTime 0
set_interface_property io timingUnits Cycles
set_interface_property io writeWaitTime 0
set_interface_property io ENABLED true
set_interface_property io EXPORT_OF ""
set_interface_property io PORT_NAME_MAP ""
set_interface_property io CMSIS_SVD_VARIABLES ""
set_interface_property io SVD_ADDRESS_GROUP ""

add_interface_port io address address Input 3
add_interface_port io read read Input 1
add_interface_port io readdata readdata Output 8
add_interface_port io write write Input 1
add_interface_port io writedata writedata Input 8
set_interface_assignment io embeddedsw.configuration.isFlash 0
set_interface_assignment io embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment io embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment io embeddedsw.configuration.isPrintableDevice 0


# 
# connection point serial
# 
add_interface serial conduit end
set_interface_property serial associatedClock clock
set_interface_property serial associatedReset ""
set_interface_property serial ENABLED true
set_interface_property serial EXPORT_OF ""
set_interface_property serial PORT_NAME_MAP ""
set_interface_property serial CMSIS_SVD_VARIABLES ""
set_interface_property serial SVD_ADDRESS_GROUP ""

add_interface_port serial br_clk br_clk Input 1
add_interface_port serial rx rx Input 1
add_interface_port serial tx tx Output 1
add_interface_port serial cts_n cts_n Input 1
add_interface_port serial dcd_n dcd_n Input 1
add_interface_port serial dsr_n dsr_n Input 1
add_interface_port serial ri_n ri_n Input 1
add_interface_port serial rts_n rts_n Output 1
add_interface_port serial br_out br_out Output 1
add_interface_port serial dtr_n dtr_n Output 1


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint ""
set_interface_property interrupt_sender associatedClock clock
set_interface_property interrupt_sender associatedReset reset
set_interface_property interrupt_sender bridgedReceiverOffset ""
set_interface_property interrupt_sender bridgesToReceiver ""
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""

add_interface_port interrupt_sender irq irq Output 1

