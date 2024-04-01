# 
# Synthesis run script generated by Vivado
# 

set_param simulator.modelsimInstallPath D:/LenovoSoftstore/modelsim_10.4c/ModelSim/win32pe
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7a100tcsg324-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir C:/Users/Liyt/Desktop/cpu_89/cpu_89.cache/wt [current_project]
set_property parent.project_path C:/Users/Liyt/Desktop/cpu_89/cpu_89.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
add_files C:/Users/Liyt/Desktop/cpu_89/test.coe
add_files -quiet c:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/ip/dist_mem_gen_0/dist_mem_gen_0.dcp
set_property used_in_implementation false [get_files c:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/ip/dist_mem_gen_0/dist_mem_gen_0.dcp]
read_verilog C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/defines.vh
read_verilog -library xil_defaultlib {
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/cp0_reg.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/regfile.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/pc_reg.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/mem_wb.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/mem.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/LLbit_reg.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/if_id.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/id_ex.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/id.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/hilo_reg.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/ex_mem.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/ex.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/div.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/ctrl.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/imem.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/docpu.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/dmem.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/docpu_top.v
  C:/Users/Liyt/Desktop/cpu_89/cpu_89.srcs/sources_1/new/docpu_top_tb.v
}
foreach dcp [get_files -quiet -all *.dcp] {
  set_property used_in_implementation false $dcp
}

synth_design -top docpu_top_tb -part xc7a100tcsg324-1


write_checkpoint -force -noxdef docpu_top_tb.dcp

catch { report_utilization -file docpu_top_tb_utilization_synth.rpt -pb docpu_top_tb_utilization_synth.pb }