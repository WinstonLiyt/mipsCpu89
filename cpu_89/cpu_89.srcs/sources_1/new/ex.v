/* -----------------------------------------
Func：依据译码阶段的结果，对源操作1，2进行运算。
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module ex(

	input rst,
	
	input [`AluOpBus] aluc,  			// aluc操作类型
	input [`AluSelBus] alucSelect,  	// 指令类型
	input [`RegBus] op1, op2,			// 操作数1，2

	input [`RegAddrBus] EXE_waddr,		// 写目标寄存器地址
	input EXE_wena,						// 写使能信号
	input [`RegBus] instr,				// 指令码
	input [31:0] exceptionType,			// 异常类型
	input [`RegBus] curInstrAddr,   	// 当前指令地址

	input [`RegBus] regHI, regLO,		// HI/LO寄存器输入
	// 回写阶段的指令是否要写HI、IO，用于检测HI、LO寄存器带来的数据相关问题
	input [`RegBus] WB_HI, WB_LO,		// HI/LO寄存器写入（WB）
	input WB_HILO_ena,					// HI/LO写使能（WB）
	// 访存阶段的指令是否要写HI、IO，用于检测HI、LO寄存器带来的数据相关问题
	input [`RegBus] MEM_HI, MEM_LO, 	// HI/LO寄存器输入（MEM）
	input MEM_HILO_ena,					// HI/LO写使能（MEM）
	input [`DoubleRegBus] HILO_tmp,		// HI/LO临时值（乘累加、乘累减指令）
	input [1:0] HILOCnt,				// 当前处于执行阶段的第几个时钟周期

	input [`DoubleRegBus] DIVRes,		// 除法res
	input DIVIsReady,					// 除法结构是否ok的信号
	input [`RegBus] jumpAddr,			// 链接地址（用于跳转和分支指令）
	input isInDelaySlot,				// 是否在延迟槽中

	// 访存/回写阶段的指令是否要写CP0中的寄存器，用来检测数据相关
 	input mem_cp0_wena,					// CP0寄存器写使能（MEM）
	input [4:0] mem_cp0_waddr,			// CP0寄存器写地址（MEM）
	input [`RegBus] mem_cp0_data,		// CP0寄存器写数据（MEM）
 	input wb_cp0_wena,					// CP0寄存器写使能（WB）
	input [4:0] wb_cp0_waddr,			// CP0寄存器写地址（WB）
	input [`RegBus] wb_cp0_data,		// CP0寄存器写数据（WB）
	input [`RegBus] cp0_dataIn,			// 读取CP0寄存器数据

	output [`AluOpBus] alucOut,			// aluc操作数
	output [`RegBus] mem_addr_out,		// 加载、存储指令对应的存储器地址
	output [`RegBus] op2_out,			// 存储指令要存储的数据，或者lwl、lwr指令要加载到的目的寄存器的原始值
	output [31:0] exceptionTypeOut,		// 异常类型
	output  isInDelaySlotOut,			// 是否在延迟槽中
	output [`RegBus] curInstrAddrOut,	// 当前指令地址
	output reg stallOut,				// 暂停信号		

	output reg [4:0] cp0_reg_addr_out,  // CP0寄存器读取地址
	output reg cp0_reg_wena_out,		// CP0寄存器写使能
	output reg [4:0] cp0_reg_waddr_out,	// CP0寄存器写地址
	output reg [`RegBus] cp0_reg_data_out,	// CP0寄存器读取数据
	
	output reg [`RegAddrBus] wd_out,	// 目标寄存器地址
	output reg reg_wena,				// 寄存器写使能
	output reg [`RegBus] wdata_out,		// 写数据	

	// 处于执行阶段的指令对HI、LO寄存器的写操作请求
	output reg HILO_ena_out,						// HI/LO写使能
	output reg [`RegBus] HIOut, LOOut,				// HI/LO寄存器输出
	output reg [`DoubleRegBus] HILO_tmp_out,		// HI/LO临时值
	output reg [1:0] cntOut,						// 当前处于执行阶段的第几个时钟周期

	output reg [`RegBus] DIV_op1_out, DIV_op2_out,	// 除法操作数
	output reg DIV_start_out,						// 除法开始信号
	output reg DIV_ifSigned_out						// 是否为有符号除法
);

 	assign alucOut = aluc;
	assign isInDelaySlotOut = isInDelaySlot;
	assign curInstrAddrOut = curInstrAddr;

	// 以下为逻辑运算、移位运算、移动运算、算术运算、乘法运算的结果
	reg[`RegBus] logicRes, shiftRes, movRes, arithRes;
	reg[`DoubleRegBus] mulRes;

	// 定义与操作数相关的辅助信号
	wire[`RegBus] sumRes;				// 加法运算结果
	wire overflow;						// 溢出信号
	reg isOverflow;						// 溢出标志
	reg isTrap;							// 陷阱标志
	wire[`RegBus] reg1_not, reg2_mux;	// 操作数取反和操作数选择信号
	wire reg1_eq_reg2, reg1_lt_reg2;	// reg1 相等/小于 reg2
	wire[`RegBus] mult_op1, mult_op2;	// 乘法操作数
	reg[`RegBus] HI, LO;				// HI/LO寄存器的最新值
	wire[`DoubleRegBus] HILI_tmp_out;	// 临时HI/LO结果
	reg[`DoubleRegBus] HILO_tmp1;		// 用于MADD、MSUB指令	
	reg stall_madd_msub;				// MADD、MSUB暂停信号		
	reg stall_div_divu;					// DIV、DIVU暂停信号

	// 加载、存储指令对应的存储器地址
 	assign mem_addr_out = op1 + {{16{instr[15]}}, instr[15:0]};

	// 存储指令要存储的数据，或者lwl、lwr指令要加载到的目的寄存器的原始值，
	assign op2_out = op2;

	// 执行阶段输出的异常信息就是译码阶段的异常信息加上自陷异常、溢出异常的信息，其中第10bit表示是否有自陷异常，第11bit表示是否有溢出异常
	assign exceptionTypeOut = {exceptionType[31:12], isOverflow, isTrap, exceptionType[9:8], 8'h00};

	/*************************** 逻辑运算 **************************/
	always @ (*) begin
		if (rst == `RstEnable)
			logicRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_OR_OP:
					logicRes <= op1 | op2;
				`EXE_AND_OP:
					logicRes <= op1 & op2;
				`EXE_NOR_OP:
					logicRes <= ~(op1 |op2);
				`EXE_XOR_OP:
					logicRes <= op1 ^ op2;
				default:
					logicRes <= `ZeroWord;
			endcase
		end
	end

	/*************************** 移位运算 **************************/
	always @ (*) begin
		if (rst == `RstEnable)
			shiftRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_SLL_OP: 
					shiftRes <= op2 << op1[4:0];
				`EXE_SRL_OP:
					shiftRes <= op2 >> op1[4:0];
				`EXE_SRA_OP:
					shiftRes <= ({32{op2[31]}} << (6'd32-{1'b0, op1[4:0]})) | op2 >> op1[4:0];
				default:
					shiftRes <= `ZeroWord;
			endcase
		end
	end

	/* 如果是减法或者有符号比较运算，那么reg2_mux等于第二个操作数op2的补码，否则reg2_mux就等于第二个操作数op2 */
	assign reg2_mux = ((aluc == `EXE_SUB_OP) || (aluc == `EXE_SUBU_OP) || 
                   	   (aluc == `EXE_SLT_OP) || (aluc == `EXE_SLTU_OP)) ? (~op2 + 1) : op2;

	/* 加法；减法；有符号比较【这里用法比较巧妙】 */
	assign sumRes = op1 + reg2_mux;

	/* 加法；减法都有可能溢出 */								 
	assign overflow = ((op1[31] == reg2_mux[31]) && (sumRes[31] != op1[31]));

	/* op1取反 */
	assign reg1_not = ~op1;

	/* 看op1是否小于op2 */
	assign reg1_lt_reg2 = ((aluc == `EXE_SLT_OP) || (aluc == `EXE_TLT_OP) ||
							(aluc == `EXE_TLTI_OP) || (aluc == `EXE_TGE_OP) || 
							(aluc == `EXE_TGEI_OP)) ? ((op1[31] && !op2[31]) || 
							(!op1[31] && !op2[31] && sumRes[31]) || 
							(op1[31] && op2[31] && sumRes[31])) : (op1 < op2);

	/* 取得乘法运算的被乘数，如果是有符号乘法且被乘数是负数，那么取补码 */
	assign mult_op1 = (((aluc == `EXE_MUL_OP) || (aluc == `EXE_MULT_OP) ||
						(aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) & 
						(op1[31] == 1'b1)) ? (~op1 + 1) : op1;

	/* 取得乘法运算的乘数，如果是有符号乘法且被乘数是负数，那么取补码 */
	assign mult_op2 = (((aluc == `EXE_MUL_OP) || (aluc == `EXE_MULT_OP) ||
						(aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) && 
						(op2[31] == 1'b1)) ? (~op2 + 1) : op2;

	assign HILI_tmp_out = mult_op1 * mult_op2;	

	/************ 依据不同的算术运算类型，给arithRes赋值 ***********/				
	always @ (*) begin
		if (rst == `RstEnable)
			arithRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_SLT_OP, `EXE_SLTU_OP:
					arithRes <= reg1_lt_reg2 ;
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUB_OP, `EXE_SUBU_OP:
					arithRes <= sumRes; 
				`EXE_CLZ_OP:
                	arithRes <= op1[31] ? 0 : op1[30] ? 1 : op1[29] ? 2 : 
								op1[28] ? 3 : op1[27] ? 4 : op1[26] ? 5 :
								op1[25] ? 6 : op1[24] ? 7 : op1[23] ? 8 : 
								op1[22] ? 9 : op1[21] ? 10 : op1[20] ? 11 :
								op1[19] ? 12 : op1[18] ? 13 : op1[17] ? 14 : 
								op1[16] ? 15 : op1[15] ? 16 : op1[14] ? 17 : 
								op1[13] ? 18 : op1[12] ? 19 : op1[11] ? 20 :
								op1[10] ? 21 : op1[9] ? 22 : op1[8] ? 23 : 
								op1[7] ? 24 : op1[6] ? 25 : op1[5] ? 26 : 
								op1[4] ? 27 : op1[3] ? 28 : op1[2] ? 29 : 
								op1[1] ? 30 : op1[0] ? 31 : 32 ;
            	`EXE_CLO_OP:
                // 对于CLO，首先取反op1，然后使用与CLZ相同的方法计算
					arithRes <= (reg1_not[31] ? 0 : reg1_not[30] ? 1 : reg1_not[29] ? 2 :
								reg1_not[28] ? 3 : reg1_not[27] ? 4 : reg1_not[26] ? 5 :
								reg1_not[25] ? 6 : reg1_not[24] ? 7 : reg1_not[23] ? 8 : 
								reg1_not[22] ? 9 : reg1_not[21] ? 10 : reg1_not[20] ? 11 :
								reg1_not[19] ? 12 : reg1_not[18] ? 13 : reg1_not[17] ? 14 : 
								reg1_not[16] ? 15 : reg1_not[15] ? 16 : reg1_not[14] ? 17 : 
								reg1_not[13] ? 18 : reg1_not[12] ? 19 : reg1_not[11] ? 20 :
								reg1_not[10] ? 21 : reg1_not[9] ? 22 : reg1_not[8] ? 23 : 
								reg1_not[7] ? 24 : reg1_not[6] ? 25 : reg1_not[5] ? 26 : 
								reg1_not[4] ? 27 : reg1_not[3] ? 28 : reg1_not[2] ? 29 : 
								reg1_not[1] ? 30 : reg1_not[0] ? 31 : 32) ;
				default:
					arithRes <= `ZeroWord;
			endcase
		end
	end

	/****************** 判断是否发生自陷异常 *****************/
	always @ (*) begin
		if (rst == `RstEnable)
			isTrap <= `TrapNotAssert;
		else begin
			isTrap <= `TrapNotAssert;
			case (aluc)
				`EXE_TEQ_OP, `EXE_TEQI_OP: begin
					if (op1 == op2 )
						isTrap <= `TrapAssert;
				end
				`EXE_TGE_OP, `EXE_TGEI_OP, `EXE_TGEIU_OP, `EXE_TGEU_OP: begin
					if (~reg1_lt_reg2)
						isTrap <= `TrapAssert;
				end
				`EXE_TLT_OP, `EXE_TLTI_OP, `EXE_TLTIU_OP, `EXE_TLTU_OP: begin
					if (reg1_lt_reg2)
						isTrap <= `TrapAssert;
				end
				`EXE_TNE_OP, `EXE_TNEI_OP: begin
					if (op1 != op2)
						isTrap <= `TrapAssert;
				end
				default:
					isTrap <= `TrapNotAssert;
			endcase
		end
	end																

	/************ 依据不同的乘法运算类型，给mulRes赋值 ***********/
	always @ (*) begin
		if (rst == `RstEnable)
			mulRes <= {`ZeroWord, `ZeroWord};
		else if ((aluc == `EXE_MULT_OP) || (aluc == `EXE_MUL_OP) || (aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) begin
			// 被乘数和乘数的符号位不同
			if (op1[31] ^ op2[31] == 1'b1)
				mulRes <= ~HILI_tmp_out + 1;
			// 被乘数和乘数的符号位相同
			else
				mulRes <= HILI_tmp_out;
		end 
		// multu
		else
			mulRes <= HILI_tmp_out;
	end

	/****** 得到最新的HI、LO寄存器的值，此处要解决数据相关问题 *******/
	always @ (*) begin
		if (rst == `RstEnable)
			{HI, LO} <= {`ZeroWord, `ZeroWord};
		// 访存阶段的指令要写HI、LO寄存器
		else if (MEM_HILO_ena == `WriteEnable)
			{HI, LO} <= {MEM_HI, MEM_LO};
		// 回写阶段的指令要写HI、LO寄存器
		else if(WB_HILO_ena == `WriteEnable)
			{HI, LO} <= {WB_HI, WB_LO};
		else
			{HI, LO} <= {regHI, regLO};			
	end	

	/**************** 暂停流水线 *****************/
	always @ (*) begin
		stallOut = stall_madd_msub || stall_div_divu;
	end

	/**************** MADD、MADDU，MSUB、MSUBU指令 *****************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			HILO_tmp_out <= {`ZeroWord, `ZeroWord};
			cntOut <= 2'b00;
			stall_madd_msub <= `NoStop;
		end
		else begin
			HILO_tmp_out <= {`ZeroWord, `ZeroWord};
			cntOut <= 2'b00;
			stall_madd_msub <= `NoStop;

			// 根据ALU操作选择不同的处理逻辑
			case (aluc) 
				`EXE_MADD_OP, `EXE_MADDU_OP, `EXE_MSUB_OP, `EXE_MSUBU_OP: begin
					// 执行阶段第一个时钟周期
					if (HILOCnt == 2'b00) begin
						// 对于MSUB和MSUBU，取反加一，MADD和MADDU直接赋值
						HILO_tmp_out <= (aluc == `EXE_MSUB_OP || aluc == `EXE_MSUBU_OP) ? (~mulRes + 1) : mulRes;
						cntOut <= 2'b01;
						stall_madd_msub <= `Stop;
					end
					// 执行阶段第二个时钟周期
					else if (HILOCnt == 2'b01) begin
						cntOut <= 2'b10;
						// 对于第二周期，统一处理HILO_tmp1的更新
						HILO_tmp1 <= HILO_tmp + {HI, LO};
					end
				end
			endcase
		end
	end	

	/*********************** DIV、DIVU指令 *****************************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			stall_div_divu <= `NoStop;
			DIV_op1_out <= `ZeroWord;
			DIV_op2_out <= `ZeroWord;
			DIV_start_out <= `DivStop;
			DIV_ifSigned_out <= 1'b0;
		end
		else begin
			// 默认状态设置
			stall_div_divu <= `NoStop;
			DIV_op1_out <= op1;
			DIV_op2_out <= op2;
			DIV_start_out <= `DivStop; // 默认停止除法操作
			DIV_ifSigned_out <= 1'b0; // 默认为无符号除法
			
			case (aluc)
				`EXE_DIV_OP, `EXE_DIVU_OP: begin
					if (DIVIsReady == `DivResultNotReady) begin
						// 如果除法结果尚未准备好，则启动除法操作
						DIV_start_out <= `DivStart;
						DIV_ifSigned_out <= (aluc == `EXE_DIV_OP); // DIV为有符号，DIVU为无符号
						stall_div_divu <= `Stop; // 发出暂停信号
					end else if (DIVIsReady == `DivResultReady) begin
						// 如果除法结果已经准备好，则不需要再次启动
						DIV_start_out <= `DivStop;
						DIV_ifSigned_out <= (aluc == `EXE_DIV_OP);
						stall_div_divu <= `NoStop; // 清除暂停信号
					end
				end
				default: begin
					// 对于非除法操作，保持默认状态
				end
			endcase
		end
	end

	/**************** MFHI、MFLO、MOVN、MOVZ指令 *****************/
	always @ (*) begin
		if (rst == `RstEnable)
			movRes <= `ZeroWord;
		else begin
			movRes <= `ZeroWord;
			case (aluc)
				`EXE_MFHI_OP: movRes <= HI;
				`EXE_MFLO_OP: movRes <= LO;
				`EXE_MOVZ_OP, `EXE_MOVN_OP: movRes <= op1;
				`EXE_MFC0_OP: begin
					cp0_reg_addr_out <= instr[15:11];
					// 对于MFC0，直接读取CP0寄存器的数据。但要考虑是否有数据相关
					movRes <= (mem_cp0_wena && mem_cp0_waddr == instr[15:11]) ? mem_cp0_data :
							(wb_cp0_wena && wb_cp0_waddr == instr[15:11]) ? wb_cp0_data :
							cp0_dataIn;
				end
				default : begin
				end
			endcase
		end
	end

	/****** 依据alucSelect指示的运算类型，选择一个运算结果作为最终结果 *******/
 	always @ (*) begin
		wd_out <= EXE_waddr;	// 要写的目的寄存器地址
		reg_wena <= ((aluc == `EXE_ADD_OP || aluc == `EXE_ADDI_OP || aluc == `EXE_SUB_OP) && overflow) ? `WriteDisable : EXE_wena;
    	isOverflow <= (aluc == `EXE_ADD_OP || aluc == `EXE_ADDI_OP || aluc == `EXE_SUB_OP) && overflow;
		
		case (alucSelect) 
			`EXE_RES_LOGIC: wdata_out <= logicRes;
			`EXE_RES_SHIFT: wdata_out <= shiftRes;
			`EXE_RES_MOVE: wdata_out <= movRes;
			`EXE_RES_ARITHMETIC: wdata_out <= arithRes;
			`EXE_RES_MUL: wdata_out <= mulRes[31:0];
			`EXE_RES_JUMP_BRANCH: wdata_out <= jumpAddr;
			default: wdata_out <= `ZeroWord;
	 	endcase
 	end	

	/********************* HO/LO寄存器 **********************/
	always @ (*) begin
		case (1'b1)
			(rst == `RstEnable): begin
				HILO_ena_out <= `WriteDisable;
				HIOut <= `ZeroWord;
				LOOut <= `ZeroWord;
			end
			default: begin
				case (aluc)
					`EXE_MULT_OP, `EXE_MULTU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= mulRes[63:32];
						LOOut <= mulRes[31:0];
					end
					`EXE_MADD_OP, `EXE_MADDU_OP,
					`EXE_MSUB_OP, `EXE_MSUBU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= HILO_tmp1[63:32];
						LOOut <= HILO_tmp1[31:0];
					end
					`EXE_DIV_OP, `EXE_DIVU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= DIVRes[63:32];
						LOOut <= DIVRes[31:0];
					end
					`EXE_MTHI_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= op1;
						LOOut <= LO;
					end
					`EXE_MTLO_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= HI;
						LOOut <= op1;
					end
					default: begin
						HILO_ena_out <= `WriteDisable;
						HIOut <= `ZeroWord;
						LOOut <= `ZeroWord;
					end
				endcase
			end
		endcase
	end

	/****************** 给出mtc0指令的执行结果 *******************/
	always @ (*) begin
		cp0_reg_waddr_out <= 5'b00000;
		cp0_reg_wena_out <= `WriteDisable;
		cp0_reg_data_out <= `ZeroWord;

		// 处理复位和`MTC0`指令
		if (!rst && aluc == `EXE_MTC0_OP) begin
			cp0_reg_waddr_out <= instr[15:11];
			cp0_reg_wena_out <= `WriteEnable;
			cp0_reg_data_out <= op1;
		end
	end
	
endmodule