@echo off
set xv_path=D:\\LenovoSoftstore\\Xilinx\\Vivado\\2016.2\\bin
call %xv_path%/xelab  -wto 5993a65e5c21406696cad3c13af8014a -m64 --debug typical --relax --mt 2 -L dist_mem_gen_v8_0_10 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot docpu_top_tb_behav xil_defaultlib.docpu_top_tb xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
