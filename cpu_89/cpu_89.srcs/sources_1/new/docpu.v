/* -------------------------------
Func：cpu总台。
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module docpu(
	input clk,
	input rst,
	
    input [5:0] externalInterrupts,	// 6个外部硬件中断信号
	
	input [`RegBus] rom_data_i,		// 从指令存储器取得的指令
	output [`RegBus] rom_addr_o,	// 输出到指令存储器的地址
	output rom_ce_o,				// 指令存储器使能信号
	
	input [`RegBus] ram_data_i,		// 从数据存储器取得的数据
	output [`RegBus] ram_addr_o,	// 输出到数据存储器的地址
	output [`RegBus] ram_data_o,	// 输出到数据存储器的数据
	output ram_we_o,				// 是否是对数据存储器的写操作，为1表示是写操作
	output [3:0] ram_sel_o,			// 字节选择信号
	output [3:0] ram_ce_o,			// 数据存储器写使能信号
	
	output timerInterruptOut		// 定时器中断信号
);

	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	// 连接译码阶段ID模块的输出与ID/EX模块的输入
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire idInDelaySlots_o;
    wire[`RegBus] idJumpAddr_o;	
    wire[`RegBus] id_inst_o;
    wire[31:0] id_excepttype_o;
    wire[`RegBus] id_current_inst_address_o;
	
	// 连接ID/EX模块的输出与执行阶段EX模块的输入
	wire[`AluOpBus] exe_aluc;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire exe_waddr_in;
	wire[`RegAddrBus] exe_wd_in;
	wire ex_is_in_delayslot_i;	
    wire[`RegBus] ex_link_address_i;	
    wire[`RegBus] ex_inst_i;
    wire[31:0] ex_excepttype_i;	
    wire[`RegBus] ex_current_inst_address_i;	
	
	// 连接执行阶段EX模块的输出与EX/MEM模块的输入
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	wire ex_cp0_reg_we_o;
	wire[4:0] ex_cp0_reg_write_addr_o;
	wire[`RegBus] ex_cp0_reg_data_o; 	
	wire[31:0] ex_excepttype_o;
	wire[`RegBus] ex_current_inst_address_o;
	wire ex_is_in_delayslot_o;

	// 连接EX/MEM模块的输出与访存阶段MEM模块的输入
	wire mem_waddr_in;
	wire[`RegAddrBus] mem_wd_in;
	wire[`RegBus] mem_data_in;
	wire[`RegBus] MEM_HI;
	wire[`RegBus] MEM_LO;
	wire MEM_HILO_ena;		
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;		
	wire mem_cp0_reg_we_i;
	wire[4:0] mem_cp0_reg_write_addr_i;
	wire[`RegBus] mem_cp0_reg_data_i;	
	wire[31:0] mem_excepttype_i;	
	wire mem_is_in_delayslot_i;
	wire[`RegBus] mem_current_inst_address_i;	

	// 连接访存阶段MEM模块的输出与MEM/WB模块的输入
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;	
	wire mem_LLbit_value_o;
	wire mem_LLbit_we_o;
	wire mem_cp0_reg_we_o;
	wire[4:0] mem_cp0_reg_write_addr_o;
	wire[`RegBus] mem_cp0_reg_data_o;	
	wire[31:0] mem_excepttype_o;
	wire mem_is_in_delayslot_o;
	wire[`RegBus] mem_current_inst_address_o;			
	
	// 连接MEM/WB模块的输出与回写阶段的输入	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] WB_HI;
	wire[`RegBus] WB_LO;
	wire WB_HILO_ena;	
	wire wb_LLbit_ValIn;
	wire wb_LLbit_wenaIn;	
	wire wb_cp0_reg_we_i;
	wire[4:0] wb_cp0_reg_write_addr_i;
	wire[`RegBus] wb_cp0_reg_data_i;		
	wire[31:0] wb_excepttype_i;
	wire wb_is_in_delayslot_i;
	wire[`RegBus] wb_current_inst_address_i;
	
	// 连接译码阶段ID模块与通用寄存器Regfile模块
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;

	// 连接执行阶段与hilo模块的输出，读取HI、LO寄存器
	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;

   // 连接执行阶段与ex_reg模块，用于多周期的MADD、MADDU、MSUB、MSUBU指令
	wire[`DoubleRegBus] HILO_tmp_out;
	wire[1:0] cntOut;
	
	wire[`DoubleRegBus] HILO_tmp;
	wire[1:0] HILOCnt;

	wire[`DoubleRegBus] div_result;
	wire div_ready;
	wire[`RegBus] div_opdata1;
	wire[`RegBus] div_opdata2;
	wire div_start;
	wire div_annul;
	wire signed_div;

	wire isInDelaySlot;
	wire isInDelaySlotOut;
	wire nxtInstrInDelaySlotsOut;
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;

	wire[5:0] stall;
	wire idStall;	
	wire exeStall;

	wire LLbitOut;

    wire[`RegBus] cp0_data_o;
    wire[4:0] cp0_raddr_i;
    
    wire flush;
    wire[`RegBus] pcNew;

	wire[`RegBus] cp0_count;
	wire[`RegBus]	cp0_compare;
	wire[`RegBus]	cp0_status;
	wire[`RegBus]	cp0_cause;
	wire[`RegBus]	cp0_epc;
	wire[`RegBus]	cp0_config;
	wire[`RegBus]	cp0_prid; 

    wire[`RegBus] latest_epc;
  
    // pc_reg例化
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
        .pcNew(pcNew),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),		
		.pc(pc),
		.ce(rom_ce_o)	
	);
	
    assign rom_addr_o = pc;		// 指令存储器的输入地址就是pc的值

    // IF/ID模块例化
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
		.if_pc(pc),
		.ifInstr(rom_data_i),
		.id_pc(id_pc_i),
		.idInstr(id_inst_i)      	
	);
	
	// 译码阶段ID模块
	id id0(
		.rst(rst),
		.pcIn(id_pc_i),
		.instr(id_inst_i),

        .exe_aluc(ex_aluop_o),

		.op1_in(reg1_data),
		.op2_in(reg2_data),

        // 处于执行阶段的指令要写入的目的寄存器信息
		.exe_waddr_in(ex_wreg_o),
		.exe_data_in(ex_wdata_o),
		.exe_wd_in(ex_wd_o),

        // 处于访存阶段的指令要写入的目的寄存器信息
		.mem_waddr_in(mem_wreg_o),
		.mem_data_in(mem_wdata_o),
		.mem_wd_in(mem_wd_o),

        .isInDelaySlot(isInDelaySlot),

		// 送到regfile的信息
		.op1_rena(reg1_read),
		.op2_rena(reg2_read), 	  

		.op1AddrOut(reg1_addr),
		.op2AddrOut(reg2_addr), 
	  
		// 送到ID/EX模块的信息
		.alucOut(id_aluop_o),
		.alucSelOut(id_alusel_o),
		.op1_out(id_reg1_o),
		.op2_out(id_reg2_o),
		.wd_out(id_wd_o),
		.reg_wena(id_wreg_o),
		.exceptionTypeOut(id_excepttype_o),
		.inst_out(id_inst_o),

	 	.nxtInstrInDelaySlotsOut(nxtInstrInDelaySlotsOut),	
		.isBranch(id_branch_flag_o),
		.branchAddr(branch_target_address),       
		.linkAddr(idJumpAddr_o),
		
		.isInDelaySlotOut(idInDelaySlots_o),
		.curInstrAddrOut(id_current_inst_address_o),
		
		.stallOut(idStall)		
	);

    // 通用寄存器Regfile例化
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	// ID/EX模块
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		.flush(flush),
		
		// 从译码阶段ID模块传递的信息
		.id_aluc(id_aluop_o),
		.id_alucSel(id_alusel_o),
		.id_op1(id_reg1_o),
		.id_op2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wena(id_wreg_o),
		.idJumpAddr(idJumpAddr_o),
		.idInDelaySlots(idInDelaySlots_o),
		.nxtInstrInDelaySlots(nxtInstrInDelaySlotsOut),		
		.idInstr(id_inst_o),		
		.idExceptionType(id_excepttype_o),
		.idCurInstrAddr(id_current_inst_address_o),
	
		// 传递到执行阶段EX模块的信息
		.exe_aluc_op(exe_aluc),
		.exe_alucSel(ex_alusel_i),
		.exe_op1(ex_reg1_i),
		.exe_op2(ex_reg2_i),
		.exe_waddr(exe_wd_in),
		.exe_reg_wena(exe_waddr_in),
		.exeJumpAddr(ex_link_address_i),
        .exeInDelaySlot(ex_is_in_delayslot_i),
		.isInDelaySlotOut(isInDelaySlot),
		.exeInstr(ex_inst_i),
		.exeExceptionType(ex_excepttype_i),
		.exeCurInstrAddr(ex_current_inst_address_i)		
	);		
	
	// EX模块
	ex ex0(
		.rst(rst),
	
		// 送到执行阶段EX模块的信息
		.aluc(exe_aluc),
		.alucSelect(ex_alusel_i),
		.op1(ex_reg1_i),
		.op2(ex_reg2_i),
		.EXE_waddr(exe_wd_in),
		.EXE_wena(exe_waddr_in),
		.regHI(hi),
		.regLO(lo),
		.instr(ex_inst_i),

        .WB_HI(WB_HI),
        .WB_LO(WB_LO),
        .WB_HILO_ena(WB_HILO_ena),
        .MEM_HI(mem_hi_o),
        .MEM_LO(mem_lo_o),
        .MEM_HILO_ena(mem_whilo_o),

        .HILO_tmp(HILO_tmp),
        .HILOCnt(HILOCnt),

		.DIVRes(div_result),
		.DIVIsReady(div_ready), 

        .jumpAddr(ex_link_address_i),
		.isInDelaySlot(ex_is_in_delayslot_i),	  
		
		.exceptionType(ex_excepttype_i),
		.curInstrAddr(ex_current_inst_address_i),

		// 访存阶段的指令是否要写CP0，用来检测数据相关
        .mem_cp0_wena(mem_cp0_reg_we_o),
		.mem_cp0_waddr(mem_cp0_reg_write_addr_o),
		.mem_cp0_data(mem_cp0_reg_data_o),
	
		// 回写阶段的指令是否要写CP0，用来检测数据相关
        .wb_cp0_wena(wb_cp0_reg_we_i),
		.wb_cp0_waddr(wb_cp0_reg_write_addr_i),
		.wb_cp0_data(wb_cp0_reg_data_i),

		.cp0_dataIn(cp0_data_o),
		.cp0_reg_addr_out(cp0_raddr_i),
		
		// 向下一流水级传递，用于写CP0中的寄存器
		.cp0_reg_wena_out(ex_cp0_reg_we_o),
		.cp0_reg_waddr_out(ex_cp0_reg_write_addr_o),
		.cp0_reg_data_out(ex_cp0_reg_data_o),	  
			  
        // EX模块的输出到EX/MEM模块信息
		.wd_out(ex_wd_o),
		.reg_wena(ex_wreg_o),
		.wdata_out(ex_wdata_o),

		.HIOut(ex_hi_o),
		.LOOut(ex_lo_o),
		.HILO_ena_out(ex_whilo_o),

		.HILO_tmp_out(HILO_tmp_out),
		.cntOut(cntOut),

		.DIV_op1_out(div_opdata1),
		.DIV_op2_out(div_opdata2),
		.DIV_start_out(div_start),
		.DIV_ifSigned_out(signed_div),	

		.alucOut(ex_aluop_o),
		.mem_addr_out(ex_mem_addr_o),
		.op2_out(ex_reg2_o),
		
		.exceptionTypeOut(ex_excepttype_o),
		.isInDelaySlotOut(ex_is_in_delayslot_o),
		.curInstrAddrOut(ex_current_inst_address_o),	
		
		.stallOut(exeStall)     				
		
	);

    // EX/MEM模块
    ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	  
        .stall(stall),
        .flush(flush),
	  
		//来自执行阶段EX模块的信息	
		.exe_waddr(ex_wd_o),
		.exe_reg_wena(ex_wreg_o),
		.exe_wdata(ex_wdata_o),
		.exe_HI(ex_hi_o),
		.exe_LO(ex_lo_o),
		.exe_HILO_ena(ex_whilo_o),		

        .exe_aluc_op(ex_aluop_o),
		.exe_addr(ex_mem_addr_o),
		.exe_op2(ex_reg2_o),			
	
		.exe_cp0_wena(ex_cp0_reg_we_o),
		.exe_cp0_waddr(ex_cp0_reg_write_addr_o),
		.exe_cp0_data(ex_cp0_reg_data_o),	

        .exeExceptionType(ex_excepttype_o),
		.exeInDelaySlot(ex_is_in_delayslot_o),
		.exeCurInstrAddr(ex_current_inst_address_o),	

		.HILOLast(HILO_tmp_out),
		.HILOCnt(cntOut),	

		// 送到访存阶段MEM模块的信息
		.mem_waddr(mem_wd_in),
		.mem_wena(mem_waddr_in),
		.mem_data(mem_data_in),
		.mem_HI(MEM_HI),
		.mem_LO(MEM_LO),
		.mem_HILO_ena(MEM_HILO_ena),
	
		.mem_cp0_wena(mem_cp0_reg_we_i),
		.mem_cp0_waddr(mem_cp0_reg_write_addr_i),
		.mem_cp0_data(mem_cp0_reg_data_i),

        .mem_aluc_op(mem_aluop_i),
		.mem_addr(mem_mem_addr_i),
		.mem_op2(mem_reg2_i),
		
		.memExceptionType(mem_excepttype_i),
        .memInDelaySlot(mem_is_in_delayslot_i),
		.memCurInstrAddr(mem_current_inst_address_i),
				
		.HILOOut(HILO_tmp),
		.cntOut(HILOCnt)
						       	
	);
	
    // MEM模块例化
	mem mem0(
		.rst(rst),
	
		// 来自EX/MEM模块的信息	
		.EXE_waddr(mem_wd_in),
		.EXE_wena(mem_waddr_in),
		.EXE_wdata(mem_data_in),
		.regHI(MEM_HI),
		.regLO(MEM_LO),
		.HILO_wena(MEM_HILO_ena),		

        .aluc(mem_aluop_i),
		.memAddrIn(mem_mem_addr_i),
		.op2(mem_reg2_i),
	
		// 来自memory的信息
		.memDataIn(ram_data_i),

		// LLbit_i是LLbit寄存器的值
		.LLbitIn(LLbitOut),
		// 但不一定是最新值，回写阶段可能要写LLbit，所以还要进一步判断
		.wb_LLbit_wenaIn(wb_LLbit_wenaIn),
		.wb_LLbit_ValIn(wb_LLbit_ValIn),

		.cp0_wenaIn(mem_cp0_reg_we_i),
		.cp0_waddrIn(mem_cp0_reg_write_addr_i),
		.cp0_dataIn(mem_cp0_reg_data_i),

        .exceptionType(mem_excepttype_i),
		.isInDelaySlot(mem_is_in_delayslot_i),
		.curInstrAddr(mem_current_inst_address_i),	
		
		.cp0_statusIn(cp0_status),
		.cp0_causeIn(cp0_cause),
		.cp0EPCValue(cp0_epc),
		
		// 回写阶段的指令是否要写CP0，用来检测数据相关
        .wb_cp0_wena(wb_cp0_reg_we_i),
		.wb_cp0_waddr(wb_cp0_reg_write_addr_i),
		.wb_cp0_data(wb_cp0_reg_data_i),	  

		.LLbit_wena_out(mem_LLbit_we_o),
		.LLbit_val_out(mem_LLbit_value_o),

		.cp0_reg_wena_out(mem_cp0_reg_we_o),
		.cp0_reg_waddr_out(mem_cp0_reg_write_addr_o),
		.cp0_reg_data_out(mem_cp0_reg_data_o),			
	  
		// 送到MEM/WB模块的信息
		.wd_out(mem_wd_o),
		.reg_wena(mem_wreg_o),
		.wdata_out(mem_wdata_o),
		.HIOut(mem_hi_o),
		.LOOut(mem_lo_o),
		.HILO_ena_out(mem_whilo_o),
		
		// 送到memory的信息
		.mem_addr_out(ram_addr_o),
		.mem_wena_out(ram_we_o),
		.memSelOut(ram_sel_o),
		.memDataOut(ram_data_o),
		.mem_ce_out(ram_ce_o),
		
		.exceptionTypeOut(mem_excepttype_o),
		.cp0EPCOut(latest_epc),
		.isInDelaySlotOut(mem_is_in_delayslot_o),
		.curInstrAddrOut(mem_current_inst_address_o)		
	);

    // MEM/WB模块
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

        .stall(stall),
        .flush(flush),

		// 来自访存阶段MEM模块的信息	
		.mem_waddr(mem_wd_o),
		.mem_wena(mem_wreg_o),
		.mem_data(mem_wdata_o),
		.mem_HI(mem_hi_o),
		.mem_LO(mem_lo_o),
		.mem_HILO_ena(mem_whilo_o),		

		.mem_LLbit_wena(mem_LLbit_we_o),
		.mem_LLbit(mem_LLbit_value_o),	
	
		.mem_cp0_wena(mem_cp0_reg_we_o),
		.mem_cp0_waddr(mem_cp0_reg_write_addr_o),
		.mem_cp0_data(mem_cp0_reg_data_o),					
	
		// 送到回写阶段的信息
		.wb_waddr(wb_wd_i),
		.wb_wena(wb_wreg_i),
		.wb_data(wb_wdata_i),
		.wb_HI(WB_HI),
		.wb_LO(WB_LO),
		.wb_HILO_ena(WB_HILO_ena),

		.wb_LLbit_wena(wb_LLbit_wenaIn),
		.wb_LLbit(wb_LLbit_ValIn),
		
		.wb_cp0_wena(wb_cp0_reg_we_i),
		.wb_cp0_waddr(wb_cp0_reg_write_addr_i),
		.wb_cp0_data(wb_cp0_reg_data_i)						
									       	
	);

	// HILO register
	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		//写端口
		.wena(WB_HILO_ena),
		.regHI(WB_HI),
		.regLO(WB_LO),
	
		//读端口1
		.HIOut(hi),
		.LOOut(lo)	
	);
	
	// ctrl module
	ctrl ctrl0(
		.rst(rst),
	
        .exceptionType(mem_excepttype_o),
        .cp0EPCValue(latest_epc),
 
		.idStall(idStall),
	
        //来自执行阶段的暂停请求
		.exeStall(exeStall),
        .pcNew(pcNew),
        .flush(flush),
		.stall(stall)       	
	);

	// divider module
	div div0(
		.clk(clk),
		.rst(rst),
	
		.isSignedDivision(signed_div),
		.dividend(div_opdata1),
		.divisor(div_opdata2),
		.startDivision(div_start),
		.cancelDivision(flush),
	
		.res(div_result),
		.resReady(div_ready)
	);

	// LLbit register
	LLbit_reg LLbit_reg0(
		.clk(clk),
		.rst(rst),
        .flush(flush),
	  
		//写端口
		.LLbitIn(wb_LLbit_ValIn),
		.wena(wb_LLbit_wenaIn),
	
		//读端口1
		.LLbitOut(LLbitOut)
	
	);

	// CP0 register
	cp0_reg cp0_reg0(
		.clk(clk),
		.rst(rst),
		
		.wena(wb_cp0_reg_we_i),
		.waddr(wb_cp0_reg_write_addr_i),
		.raddr(cp0_raddr_i),
		.data(wb_cp0_reg_data_i),
		
		.exceptionType(mem_excepttype_o),
		.externalInterrupts(externalInterrupts),
		.currentInstructionAddr(mem_current_inst_address_o),
		.isInDelaySlot(mem_is_in_delayslot_o),
		
		.dataOut(cp0_data_o),
		.cntOut(cp0_count),
		.cmpOut(cp0_compare),
		.statusOut(cp0_status),
		.causeOut(cp0_cause),
		.epcOut(cp0_epc),
		.configOut(cp0_config),
		.processorIDOut(cp0_prid),
		
		.timerInterruptOut(timerInterruptOut)  			
	);
	
endmodule