//@func   : 
//@time   : 
//@author :

`include "defines.vh"
`timescale 1ns / 1ps

module docpu(
	input wire 					   clk,
	input wire					   rst,
	
    input wire[5:0] 			   externalInterrupts,
	
	input wire[`RegBus]            rom_data_i,
	output wire[`RegBus]		   rom_addr_o,
	output wire         		   rom_ce_o,
	
    //�������ݴ洢��data_ram
	input wire[`RegBus]            ram_data_i,
	output wire[`RegBus]           ram_addr_o,
	output wire[`RegBus]           ram_data_o,
	output wire                    ram_we_o,
	output wire[3:0]               ram_sel_o,
	output wire[3:0]               ram_ce_o,
	
	output wire                    timerInterruptOut
	
);

	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//��������׶�IDģ��������ID/EXģ�������
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;	
    wire[`RegBus] id_inst_o;
    wire[31:0] id_excepttype_o;
    wire[`RegBus] id_current_inst_address_o;
	
	//����ID/EXģ��������ִ�н׶�EXģ�������
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;	
    wire[`RegBus] ex_link_address_i;	
    wire[`RegBus] ex_inst_i;
    wire[31:0] ex_excepttype_i;	
    wire[`RegBus] ex_current_inst_address_i;	
	
	//����ִ�н׶�EXģ��������EX/MEMģ�������
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

	//����EX/MEMģ��������ô�׶�MEMģ�������
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
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

	//���ӷô�׶�MEMģ��������MEM/WBģ�������
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
	
	//����MEM/WBģ���������д�׶ε�����	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] WB_HI;
	wire[`RegBus] WB_LO;
	wire WB_HILO_ena;	
	wire wb_LLbit_value_i;
	wire wb_LLbit_we_i;	
	wire wb_cp0_reg_we_i;
	wire[4:0] wb_cp0_reg_write_addr_i;
	wire[`RegBus] wb_cp0_reg_data_i;		
	wire[31:0] wb_excepttype_i;
	wire wb_is_in_delayslot_i;
	wire[`RegBus] wb_current_inst_address_i;
	
	//��������׶�IDģ����ͨ�üĴ���Regfileģ��
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;

	//����ִ�н׶���hiloģ����������ȡHI��LO�Ĵ���
	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;

   //����ִ�н׶���ex_regģ�飬���ڶ����ڵ�MADD��MADDU��MSUB��MSUBUָ��
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
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;

	wire[5:0] stall;
	wire idStall;	
	wire exeStall;

	wire LLbit_o;

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
  
    //pc_reg����
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
	
    assign rom_addr_o = pc;

    //IF/IDģ������
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
		.if_pc(pc),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	//����׶�IDģ��
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.instr(id_inst_i),

        .ex_aluop_i(ex_aluop_o),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

        //����ִ�н׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

        //���ڷô�׶ε�ָ��Ҫд���Ŀ�ļĴ�����Ϣ
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

        .isInDelaySlot(isInDelaySlot),

		//�͵�regfile����Ϣ
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//�͵�ID/EXģ�����Ϣ
		.aluc_out(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.op2_out(id_reg2_o),
		.wd_out(id_wd_o),
		.reg_wena(id_wreg_o),
		.exceptionTypeOut(id_excepttype_o),
		.inst_o(id_inst_o),

	 	.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),       
		.link_addr_o(id_link_address_o),
		
		.isInDelaySlotOut(id_is_in_delayslot_o),
		.curInstrAddrOut(id_current_inst_address_o),
		
		.stallOut(idStall)		
	);

    //ͨ�üĴ���Regfile����
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

	//ID/EXģ��
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		.flush(flush),
		
		//������׶�IDģ�鴫�ݵ���Ϣ
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),		
		.id_inst(id_inst_o),		
		.id_excepttype(id_excepttype_o),
		.id_current_inst_address(id_current_inst_address_o),
	
		//���ݵ�ִ�н׶�EXģ�����Ϣ
		.exe_aluc_op(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.exe_op2(ex_reg2_i),
		.exe_waddr(ex_wd_i),
		.exe_reg_wena(ex_wreg_i),
		.ex_link_address(ex_link_address_i),
        .exeInDelaySlot(ex_is_in_delayslot_i),
		.isInDelaySlotOut(isInDelaySlot),
		.ex_inst(ex_inst_i),
		.exeExceptionType(ex_excepttype_i),
		.exeCurInstrAddr(ex_current_inst_address_i)		
	);		
	
	//EXģ��
	ex ex0(
		.rst(rst),
	
		//�͵�ִ�н׶�EXģ�����Ϣ
		.aluc(ex_aluop_i),
		.alucSelect(ex_alusel_i),
		.op1(ex_reg1_i),
		.op2(ex_reg2_i),
		.EXE_waddr(ex_wd_i),
		.EXE_wena(ex_wreg_i),
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

		//�ô�׶ε�ָ���Ƿ�ҪдCP0����������������
        .mem_cp0_wena(mem_cp0_reg_we_o),
		.mem_cp0_waddr(mem_cp0_reg_write_addr_o),
		.mem_cp0_data(mem_cp0_reg_data_o),
	
		//��д�׶ε�ָ���Ƿ�ҪдCP0����������������
        .wb_cp0_wena(wb_cp0_reg_we_i),
		.wb_cp0_waddr(wb_cp0_reg_write_addr_i),
		.wb_cp0_data(wb_cp0_reg_data_i),

		.cp0_reg_data_in(cp0_data_o),
		.cp0_reg_addr_out(cp0_raddr_i),
		
		//����һ��ˮ�����ݣ�����дCP0�еļĴ���
		.cp0_reg_wena_out(ex_cp0_reg_we_o),
		.cp0_reg_waddr_out(ex_cp0_reg_write_addr_o),
		.cp0_reg_data_out(ex_cp0_reg_data_o),	  
			  
        //EXģ��������EX/MEMģ����Ϣ
		.wd_out(ex_wd_o),
		.reg_wena(ex_wreg_o),
		.wdata_out(ex_wdata_o),

		.HI_out(ex_hi_o),
		.LO_out(ex_lo_o),
		.HILO_ena_out(ex_whilo_o),

		.HILO_tmp_out(HILO_tmp_out),
		.cntOut(cntOut),

		.DIV_op1_out(div_opdata1),
		.DIV_op2_out(div_opdata2),
		.DIV_start_out(div_start),
		.DIV_ifSigned_out(signed_div),	

		.aluc_out(ex_aluop_o),
		.mem_addr_out(ex_mem_addr_o),
		.op2_out(ex_reg2_o),
		
		.exceptionTypeOut(ex_excepttype_o),
		.isInDelaySlotOut(ex_is_in_delayslot_o),
		.curInstrAddrOut(ex_current_inst_address_o),	
		
		.stallOut(exeStall)     				
		
	);

    //EX/MEMģ��
    ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	  
        .stall(stall),
        .flush(flush),
	  
		//����ִ�н׶�EXģ�����Ϣ	
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

		//�͵��ô�׶�MEMģ�����Ϣ
		.mem_waddr(mem_wd_i),
		.mem_wena(mem_wreg_i),
		.mem_data(mem_wdata_i),
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
	
    //MEMģ������
	mem mem0(
		.rst(rst),
	
		//����EX/MEMģ�����Ϣ	
		.EXE_waddr(mem_wd_i),
		.EXE_wena(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.regHI(MEM_HI),
		.regLO(MEM_LO),
		.whilo_i(MEM_HILO_ena),		

        .aluc(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.op2(mem_reg2_i),
	
		//����memory����Ϣ
		.mem_data_i(ram_data_i),

		//LLbit_i��LLbit�Ĵ�����ֵ
		.LLbit_i(LLbit_o),
		//����һ��������ֵ����д�׶ο���ҪдLLbit�����Ի�Ҫ��һ���ж�
		.wb_LLbit_we_i(wb_LLbit_we_i),
		.wb_LLbit_value_i(wb_LLbit_value_i),

		.cp0_reg_we_i(mem_cp0_reg_we_i),
		.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
		.cp0_reg_data_in(mem_cp0_reg_data_i),

        .exceptionType(mem_excepttype_i),
		.isInDelaySlot(mem_is_in_delayslot_i),
		.curInstrAddr(mem_current_inst_address_i),	
		
		.cp0_status_i(cp0_status),
		.cp0_cause_i(cp0_cause),
		.cp0EPCValue(cp0_epc),
		
		//��д�׶ε�ָ���Ƿ�ҪдCP0����������������
        .wb_cp0_wena(wb_cp0_reg_we_i),
		.wb_cp0_waddr(wb_cp0_reg_write_addr_i),
		.wb_cp0_data(wb_cp0_reg_data_i),	  

		.LLbit_we_o(mem_LLbit_we_o),
		.LLbit_value_o(mem_LLbit_value_o),

		.cp0_reg_wena_out(mem_cp0_reg_we_o),
		.cp0_reg_waddr_out(mem_cp0_reg_write_addr_o),
		.cp0_reg_data_out(mem_cp0_reg_data_o),			
	  
		//�͵�MEM/WBģ�����Ϣ
		.wd_out(mem_wd_o),
		.reg_wena(mem_wreg_o),
		.wdata_out(mem_wdata_o),
		.HI_out(mem_hi_o),
		.LO_out(mem_lo_o),
		.HILO_ena_out(mem_whilo_o),
		
		//�͵�memory����Ϣ
		.mem_addr_out(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o),
		
		.exceptionTypeOut(mem_excepttype_o),
		.cp0_epc_o(latest_epc),
		.isInDelaySlotOut(mem_is_in_delayslot_o),
		.curInstrAddrOut(mem_current_inst_address_o)		
	);

    //MEM/WBģ��
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

        .stall(stall),
        .flush(flush),

		//���Էô�׶�MEMģ�����Ϣ	
		.mem_waddr(mem_wd_o),
		.mem_wena(mem_wreg_o),
		.mem_data(mem_wdata_o),
		.mem_HI(mem_hi_o),
		.mem_LO(mem_lo_o),
		.mem_HILO_ena(mem_whilo_o),		

		.mem_LLbit_we(mem_LLbit_we_o),
		.mem_LLbit_value(mem_LLbit_value_o),	
	
		.mem_cp0_wena(mem_cp0_reg_we_o),
		.mem_cp0_waddr(mem_cp0_reg_write_addr_o),
		.mem_cp0_data(mem_cp0_reg_data_o),					
	
		//�͵���д�׶ε���Ϣ
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(WB_HI),
		.wb_lo(WB_LO),
		.wb_whilo(WB_HILO_ena),

		.wb_LLbit_we(wb_LLbit_we_i),
		.wb_LLbit_value(wb_LLbit_value_i),
		
		.wb_cp0_wena(wb_cp0_reg_we_i),
		.wb_cp0_waddr(wb_cp0_reg_write_addr_i),
		.wb_cp0_data(wb_cp0_reg_data_i)						
									       	
	);

	//HILO register
	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		//д�˿�
		.we(WB_HILO_ena),
		.regHI(WB_HI),
		.regLO(WB_LO),
	
		//���˿�1
		.HI_out(hi),
		.LO_out(lo)	
	);
	
	//ctrl module
	ctrl ctrl0(
		.rst(rst),
	
        .exceptionType(mem_excepttype_o),
        .cp0EPCValue(latest_epc),
 
		.idStall(idStall),
	
        //����ִ�н׶ε���ͣ����
		.exeStall(exeStall),
        .pcNew(pcNew),
        .flush(flush),
		.stall(stall)       	
	);

	//divider module
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

	//LLbit register
	LLbit_reg LLbit_reg0(
		.clk(clk),
		.rst(rst),
        .flush(flush),
	  
		//д�˿�
		.LLbit_i(wb_LLbit_value_i),
		.we(wb_LLbit_we_i),
	
		//���˿�1
		.LLbit_o(LLbit_o)
	
	);

	//CP0 register
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