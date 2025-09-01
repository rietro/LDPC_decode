//////////////////////////////////////////////////////////////////////////////////
// Company: IICNS, ZJU
// Engineer: Wenzhuo Zou
// 
// Create Date: 2022/10
// Design Name: Multi code project
// Module Name: LDPC_dec_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// V2.0
// Additional Comments:
// 
`include "Decoder_Parameters.v"
`include "Top_Parameters.v"

// -----------------------------------------------------------------------------
 // 顶层模块接口说明（端口一览）
 //   clk, rst_n               ：时钟与低有效复位
 //   decoder_id[1:0]          ：译码器编号/并行实例区分
 //   APPmsg_ini_subx_[0..5]   ：初始化 APP LLR 分片（每片 Zc*VWidth）
 //   APPmsg_ini_sub_x[1:0]    ：当前输入分片索引（0..3）
 //   buffer_valid/start/last  ：输入装载握手
 //   iLs, jLs, P              ：层/行参数与并行度
 //   APP_addr_max/rd_max      ：APP 寻址上限 深度
 //   buffer_ready             ：可接收下一帧信号
 //   decode_valid/cnt         ：译码完成指示与计数
 //   APPmsg_decode_out        ：最终译码输出（打包）
 // -----------------------------------------------------------------------------
module LDPC_Dec(
    input clk,
	input rst_n,

	input [1:0] decoder_id,

	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_0, //
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_1,
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_2,
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_3,
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_4,
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_5,
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_6,
	input [`Zc*`VWidth-1:0] APPmsg_ini_subx_7,

	input [1:0] APPmsg_ini_sub_x, //控制第几段数据 7/8码率[0,1,2] 2/3码率[0,1,2,3] 如果第4段需要特殊处理
	input buffer_valid, //输入有效 //深度16
	input buffer_start, //输入开始 //深度16
	input buffer_last, //输入完成

	input [2:0] iLs,
	input [2:0] jLs,
	input [5:0] P,
	input [`APP_addr_width-1:0] APP_addr_max, //输入深度16 宽度5
	input [`APP_addr_width-2:0] APP_addr_rd_max, //最大地址15 宽度4

	output reg   			buffer_ready,
	output reg  			decode_valid,
	output reg [3:0]		decode_valid_cnt,
	output [`Zc*`DecOut_lifting-1:0] APPmsg_decode_out

);

//开始整理时序：


wire [5:0] P_1;
assign P_1 = P-1'b1;
// reg [3:0] iternum;

// =============================================================================
 // 状态/流程控制相关信号
 // - totalLayernum：一个码字在所选 BG/ lifting 下的总层数；
 // - update_start_*/update_end_*：层起止打拍；
 // - share_flag：资源复用/跨层共享标志（若有）；
 // ============================================================================= 

wire [5:0] totalLayernum;
assign totalLayernum = `TotalLayernum;

//meici diedai gengxing xinhao
reg update_start_D0,update_start_D1,update_start_D2;
reg update_end_D0;
reg share_flag;//

// =============================================================================
 // 移位/拓扑（来自 HROM）
 // - shift_addr_rd1_ini/shift_addr_rd1：HROM 读地址；
 // - bg1_shift/bg1_shift_0：某一 BG 的聚合移位域；
 // - shift_*：每一列/行对应的循环移位量与使能（最高位为屏蔽）。
 // =============================================================================
reg [8:0] shift_addr_rd1_ini;
reg [8:0] shift_addr_rd1;
reg [`HROM_Width-1:0] bg1_shift;

wire [`HROM_Width-1:0] bg1_shift_0;

wire [`HijWidth-1:0] shift_0,shift_1,shift_2,shift_3,shift_4,shift_5,shift_6,shift_7,shift_8,shift_9,
    shift_10,shift_11,shift_12,shift_13,shift_14,shift_15,shift_16,shift_17,shift_18,shift_19,
    shift_20,shift_21,shift_22,shift_23,shift_24,shift_25;
	
wire [`HijWidth-2:0]  shift_nsign_0,shift_nsign_1,shift_nsign_2,shift_nsign_3,shift_nsign_4,shift_nsign_5,shift_nsign_6,shift_nsign_7,shift_nsign_8,shift_nsign_9,
    shift_nsign_10,shift_nsign_11,shift_nsign_12,shift_nsign_13,shift_nsign_14,shift_nsign_15,shift_nsign_16,shift_nsign_17,shift_nsign_18,shift_nsign_19,
    shift_nsign_20,shift_nsign_21,shift_nsign_22,shift_nsign_23,shift_nsign_24,shift_nsign_25;
reg HROM_rd_en;

// =============================================================================
 // APPRam 地址/读写控制
 // - APP_rd_en / APP_rd_end / APP_rd_en_cnt：译码读遍历控制；
 // - APP_addr_rd_* / APP_addr_wr_*：分片/层对齐的读写地址生成；
 // - *_max：当前码长/ lifting 环境下允许的最大地址；
 // ============================================================================= 
wire [`APP_addr_width-1:0] APP_addr_wr_max;
reg APP_rd_en;
reg APP_rd_D0,APP_rd_D1,APP_rd_D2;
reg [`APP_addr_width-2:0] APP_rd_en_cnt;
reg APP_rd_end;
reg APP_rd_endD0,APP_rd_endD1,APP_rd_endD2,APP_rd_endD3,APP_rd_endD4,APP_rd_endD5,APP_rd_endD6,APP_rd_endD7,APP_rd_endD8,APP_rd_endD9,
    APP_rd_endD10,APP_rd_endD11,APP_rd_endD12,APP_rd_endD13,APP_rd_endD14,APP_rd_endD15,APP_rd_endD16;
wire [`APP_addr_width-2:0]  APP_addr_rd_ini_0,APP_addr_rd_ini_1,APP_addr_rd_ini_2,APP_addr_rd_ini_3,APP_addr_rd_ini_4,APP_addr_rd_ini_5,APP_addr_rd_ini_6,APP_addr_rd_ini_7,APP_addr_rd_ini_8,APP_addr_rd_ini_9,
           APP_addr_rd_ini_10,APP_addr_rd_ini_11,APP_addr_rd_ini_12,APP_addr_rd_ini_13,APP_addr_rd_ini_14,APP_addr_rd_ini_15,APP_addr_rd_ini_16,APP_addr_rd_ini_17,APP_addr_rd_ini_18,APP_addr_rd_ini_19,
           APP_addr_rd_ini_20,APP_addr_rd_ini_21,APP_addr_rd_ini_22,APP_addr_rd_ini_23,APP_addr_rd_ini_24,APP_addr_rd_ini_25,APP_addr_rd_ini_26;	
reg [`APP_addr_width-2:0]  APP_addr_rd_0,APP_addr_rd_1,APP_addr_rd_2,APP_addr_rd_3,APP_addr_rd_4,APP_addr_rd_5,APP_addr_rd_6,APP_addr_rd_7,APP_addr_rd_8,APP_addr_rd_9,APP_addr_rd_10,APP_addr_rd_11,APP_addr_rd_12,APP_addr_rd_13,APP_addr_rd_14,APP_addr_rd_15,APP_addr_rd_16,APP_addr_rd_17,APP_addr_rd_18,APP_addr_rd_19,APP_addr_rd_20,APP_addr_rd_21,APP_addr_rd_22,APP_addr_rd_23,APP_addr_rd_24,APP_addr_rd_25;
reg [7:0]  APP_addr_rd_26;
wire [7:0] APPmsg_ini_addr_D0_C26_all ;
reg [`APP_addr_width-2:0] APP_wr_en_cnt;
reg [`APP_addr_width-2:0]  APP_addr_wr_0,APP_addr_wr_1,APP_addr_wr_2,APP_addr_wr_3,APP_addr_wr_4,APP_addr_wr_5,APP_addr_wr_6,APP_addr_wr_7,APP_addr_wr_8,APP_addr_wr_9,APP_addr_wr_10,APP_addr_wr_11,APP_addr_wr_12,APP_addr_wr_13,APP_addr_wr_14,APP_addr_wr_15,APP_addr_wr_16,APP_addr_wr_17,APP_addr_wr_18,APP_addr_wr_19,APP_addr_wr_20,APP_addr_wr_21,APP_addr_wr_22,APP_addr_wr_23,APP_addr_wr_24,APP_addr_wr_25;
reg [7:0] APP_addr_wr_26;

reg APP_wr_en_D0;

// =============================================================================
 // QSN（校验节点）相关寄存器/总线
 // - c_reg_*/c_*：分列保存的校验节点中间结果；
 // - APPmsg_old_*/APPmsg_new_*：变量节点旧/新 APP；
 // - QSN_APPmsg_*：校验节点输出给 DPU 的接口；
 // =============================================================================
reg [`b-1:0] c_reg_0,c_reg_1,c_reg_2,c_reg_3,c_reg_4,c_reg_5,c_reg_6,c_reg_7,c_reg_8,c_reg_9,
      c_reg_10,c_reg_11,c_reg_12,c_reg_13,c_reg_14,c_reg_15,c_reg_16,c_reg_17,c_reg_18,c_reg_19,
      c_reg_20,c_reg_21,c_reg_22,c_reg_23,c_reg_24,c_reg_25;
reg [`b-1:0] c_reg_D0_0,c_reg_D0_1,c_reg_D0_2,c_reg_D0_3,c_reg_D0_4,c_reg_D0_5,c_reg_D0_6,c_reg_D0_7,c_reg_D0_8,c_reg_D0_9,
      c_reg_D0_10,c_reg_D0_11,c_reg_D0_12,c_reg_D0_13,c_reg_D0_14,c_reg_D0_15,c_reg_D0_16,c_reg_D0_17,c_reg_D0_18,c_reg_D0_19,
      c_reg_D0_20,c_reg_D0_21,c_reg_D0_22,c_reg_D0_23,c_reg_D0_24,c_reg_D0_25;
reg [`b-1:0] c_reg_D1_0,c_reg_D1_1,c_reg_D1_2,c_reg_D1_3,c_reg_D1_4,c_reg_D1_5,c_reg_D1_6,c_reg_D1_7,c_reg_D1_8,c_reg_D1_9,
      c_reg_D1_10,c_reg_D1_11,c_reg_D1_12,c_reg_D1_13,c_reg_D1_14,c_reg_D1_15,c_reg_D1_16,c_reg_D1_17,c_reg_D1_18,c_reg_D1_19,
      c_reg_D1_20,c_reg_D1_21,c_reg_D1_22,c_reg_D1_23,c_reg_D1_24,c_reg_D1_25;
wire [`b-1:0] c_0,c_1,c_2,c_3,c_4,c_5,c_6,c_7,c_8,c_9,
      c_10,c_11,c_12,c_13,c_14,c_15,c_16,c_17,c_18,c_19,
      c_20,c_21,c_22,c_23,c_24,c_25;
wire [`APPdata_Len-1:0] APPmsg_old_0,APPmsg_old_1,APPmsg_old_2,APPmsg_old_3,APPmsg_old_4,APPmsg_old_5,APPmsg_old_6,APPmsg_old_7,APPmsg_old_8,APPmsg_old_9,
                  APPmsg_old_10,APPmsg_old_11,APPmsg_old_12,APPmsg_old_13,APPmsg_old_14,APPmsg_old_15,APPmsg_old_16,APPmsg_old_17,APPmsg_old_18,APPmsg_old_19,
                  APPmsg_old_20,APPmsg_old_21,APPmsg_old_22,APPmsg_old_23,APPmsg_old_24,APPmsg_old_25;
wire [`APPdata_Len-1:0] APPmsg_old_26;
 //assign APPmsg_old_26 = 'd0;

reg [`APPdata_Len-1:0] APPmsg_old_26_D0,APPmsg_old_26_D1;				  
wire [`APPdata_Len-1:0] APPmsg_new_0,APPmsg_new_1,APPmsg_new_2,APPmsg_new_3,APPmsg_new_4,APPmsg_new_5,APPmsg_new_6,APPmsg_new_7,APPmsg_new_8,APPmsg_new_9,
                  APPmsg_new_10,APPmsg_new_11,APPmsg_new_12,APPmsg_new_13,APPmsg_new_14,APPmsg_new_15,APPmsg_new_16,APPmsg_new_17,APPmsg_new_18,APPmsg_new_19,
                  APPmsg_new_20,APPmsg_new_21,APPmsg_new_22,APPmsg_new_23,APPmsg_new_24,APPmsg_new_25;
reg [`APPdata_Len-1:0] APPmsg_new_26;
wire [`APPdata_Len-1:0] QSN_APPmsg_0,QSN_APPmsg_1,QSN_APPmsg_2,QSN_APPmsg_3,QSN_APPmsg_4,QSN_APPmsg_5,QSN_APPmsg_6,QSN_APPmsg_7,QSN_APPmsg_8,QSN_APPmsg_9,
                  QSN_APPmsg_10,QSN_APPmsg_11,QSN_APPmsg_12,QSN_APPmsg_13,QSN_APPmsg_14,QSN_APPmsg_15,QSN_APPmsg_16,QSN_APPmsg_17,QSN_APPmsg_18,QSN_APPmsg_19,
                  QSN_APPmsg_20,QSN_APPmsg_21,QSN_APPmsg_22,QSN_APPmsg_23,QSN_APPmsg_24,QSN_APPmsg_25;
// =============================================================================
 // DN / DPU（行/层处理单元）
 // - DN_APPmsg_*：DPU 的输入/中间数据；
 // - DN_APPmsg_reg_*：打拍后的 DPU 数据；
 // =============================================================================
wire [`DPUdata_Len-1:0] DN_APPmsg_0,DN_APPmsg_1,DN_APPmsg_2,DN_APPmsg_3,DN_APPmsg_4,DN_APPmsg_5,DN_APPmsg_6,DN_APPmsg_7,DN_APPmsg_8,DN_APPmsg_9,
                  DN_APPmsg_10,DN_APPmsg_11,DN_APPmsg_12,DN_APPmsg_13,DN_APPmsg_14,DN_APPmsg_15,DN_APPmsg_16,DN_APPmsg_17,DN_APPmsg_18,DN_APPmsg_19,
                  DN_APPmsg_20,DN_APPmsg_21,DN_APPmsg_22,DN_APPmsg_23,DN_APPmsg_24,DN_APPmsg_25,DN_APPmsg_26,DN_APPmsg_27,DN_APPmsg_28,DN_APPmsg_29,DN_APPmsg_30,DN_APPmsg_31;
reg [`DPUdata_Len-1:0] DN_APPmsg_reg_0,DN_APPmsg_reg_1,DN_APPmsg_reg_2,DN_APPmsg_reg_3,DN_APPmsg_reg_4,DN_APPmsg_reg_5,DN_APPmsg_reg_6,DN_APPmsg_reg_7,DN_APPmsg_reg_8,DN_APPmsg_reg_9,
                  DN_APPmsg_reg_10,DN_APPmsg_reg_11,DN_APPmsg_reg_12,DN_APPmsg_reg_13,DN_APPmsg_reg_14,DN_APPmsg_reg_15,DN_APPmsg_reg_16,DN_APPmsg_reg_17,DN_APPmsg_reg_18,DN_APPmsg_reg_19,
                  DN_APPmsg_reg_20,DN_APPmsg_reg_21,DN_APPmsg_reg_22,DN_APPmsg_reg_23,DN_APPmsg_reg_24,DN_APPmsg_reg_25,DN_APPmsg_reg_26,DN_APPmsg_reg_27,DN_APPmsg_reg_28,DN_APPmsg_reg_29,DN_APPmsg_reg_30,DN_APPmsg_reg_31;

// =============================================================================
 // CTV（Check-to-Variable 中间存储）
 // - 读写使能与地址：CTV_rd_en/CTV_wr_en/CTV_addr_*；
 // - CTV_old_* / CTV_new_*：旧值与更新值；
 // - APP_CTV_*：与 APP 聚合后的入 GN 数据；
 // =============================================================================

reg CTV_rd_en;
reg CTV_wr_en;
reg [3:0] CTV_wr_en_cnt;
reg [4:0] CTV_rd_en_cnt;
reg [9:0] CTV_addr_wr,CTV_addr_rd;
wire [`DPUctvdata_Len-1:0]CTV_old_0,CTV_old_1,CTV_old_2,CTV_old_3,CTV_old_4,CTV_old_5,CTV_old_6,CTV_old_7,CTV_old_8,CTV_old_9,
                  CTV_old_10,CTV_old_11,CTV_old_12,CTV_old_13,CTV_old_14,CTV_old_15,CTV_old_16,CTV_old_17,CTV_old_18,CTV_old_19,
                  CTV_old_20,CTV_old_21,CTV_old_22,CTV_old_23,CTV_old_24,CTV_old_25,CTV_old_26,CTV_old_27,CTV_old_28,CTV_old_29,CTV_old_30,CTV_old_31;  
wire [`DPUctvdata_Len-1:0]APP_CTV_0,APP_CTV_1,APP_CTV_2,APP_CTV_3,APP_CTV_4,APP_CTV_5,APP_CTV_6,APP_CTV_7,APP_CTV_8,APP_CTV_9,
                  APP_CTV_10,APP_CTV_11,APP_CTV_12,APP_CTV_13,APP_CTV_14,APP_CTV_15,APP_CTV_16,APP_CTV_17,APP_CTV_18,APP_CTV_19,
                  APP_CTV_20,APP_CTV_21,APP_CTV_22,APP_CTV_23,APP_CTV_24,APP_CTV_25,APP_CTV_26,APP_CTV_27,APP_CTV_28,APP_CTV_29,APP_CTV_30,APP_CTV_31; 				  
wire [`DPUctvdata_Len-1:0]CTV_new_0,CTV_new_1,CTV_new_2,CTV_new_3,CTV_new_4,CTV_new_5,CTV_new_6,CTV_new_7,CTV_new_8,CTV_new_9,
                  CTV_new_10,CTV_new_11,CTV_new_12,CTV_new_13,CTV_new_14,CTV_new_15,CTV_new_16,CTV_new_17,CTV_new_18,CTV_new_19,
                  CTV_new_20,CTV_new_21,CTV_new_22,CTV_new_23,CTV_new_24,CTV_new_25,CTV_new_26,CTV_new_27,CTV_new_28,CTV_new_29,CTV_new_30,CTV_new_31;  

// =============================================================================
 // DPU - 层级/行级计算核心
 // - DPU_APPmsg_* / signAPP_*：对 APP/QSN 的聚合与符号决策；
 // - flag：对 P 个并行通道的使能标志；
 // =============================================================================
reg [`P_num-1:0] flag;
wire [`DPUdata_Len-1:0] DPU_APPmsg_0,DPU_APPmsg_1,DPU_APPmsg_2,DPU_APPmsg_3,DPU_APPmsg_4,DPU_APPmsg_5,DPU_APPmsg_6,DPU_APPmsg_7,DPU_APPmsg_8,DPU_APPmsg_9,
                  DPU_APPmsg_10,DPU_APPmsg_11,DPU_APPmsg_12,DPU_APPmsg_13,DPU_APPmsg_14,DPU_APPmsg_15,DPU_APPmsg_16,DPU_APPmsg_17,DPU_APPmsg_18,DPU_APPmsg_19,
                  DPU_APPmsg_20,DPU_APPmsg_21,DPU_APPmsg_22,DPU_APPmsg_23,DPU_APPmsg_24,DPU_APPmsg_25,DPU_APPmsg_26,DPU_APPmsg_27,DPU_APPmsg_28,DPU_APPmsg_29,DPU_APPmsg_30,DPU_APPmsg_31;
wire  signAPP_0,signAPP_1,signAPP_2,signAPP_3,signAPP_4,signAPP_5,signAPP_6,signAPP_7,signAPP_8,signAPP_9,
                  signAPP_10,signAPP_11,signAPP_12,signAPP_13,signAPP_14,signAPP_15,signAPP_16,signAPP_17,signAPP_18,signAPP_19,
                  signAPP_20,signAPP_21,signAPP_22,signAPP_23,signAPP_24,signAPP_25,signAPP_26,signAPP_27,signAPP_28,signAPP_29,signAPP_30,signAPP_31;   
// =============================================================================
 // GN（Variable Node 更新）
 // - GN_APPmsg_* / GN_APPmsg_reg_*：变量节点 APP 新值与打拍；
 // - 与 APPRam 写回：在 APP_decodin_wr_en 下、结合 shift_* 的有效位决定是否回写。
 // =============================================================================
wire [`APPdata_Len-1:0] GN_APPmsg_0,GN_APPmsg_1,GN_APPmsg_2,GN_APPmsg_3,GN_APPmsg_4,GN_APPmsg_5,GN_APPmsg_6,GN_APPmsg_7,GN_APPmsg_8,GN_APPmsg_9,
                  GN_APPmsg_10,GN_APPmsg_11,GN_APPmsg_12,GN_APPmsg_13,GN_APPmsg_14,GN_APPmsg_15,GN_APPmsg_16,GN_APPmsg_17,GN_APPmsg_18,GN_APPmsg_19,
                  GN_APPmsg_20,GN_APPmsg_21,GN_APPmsg_22,GN_APPmsg_23,GN_APPmsg_24,GN_APPmsg_25,GN_APPmsg_26;
reg [`APPdata_Len-1:0] GN_APPmsg_reg_0,GN_APPmsg_reg_1,GN_APPmsg_reg_2,GN_APPmsg_reg_3,GN_APPmsg_reg_4,GN_APPmsg_reg_5,GN_APPmsg_reg_6,GN_APPmsg_reg_7,GN_APPmsg_reg_8,GN_APPmsg_reg_9,
                  GN_APPmsg_reg_10,GN_APPmsg_reg_11,GN_APPmsg_reg_12,GN_APPmsg_reg_13,GN_APPmsg_reg_14,GN_APPmsg_reg_15,GN_APPmsg_reg_16,GN_APPmsg_reg_17,GN_APPmsg_reg_18,GN_APPmsg_reg_19,
                  GN_APPmsg_reg_20,GN_APPmsg_reg_21,GN_APPmsg_reg_22,GN_APPmsg_reg_23,GN_APPmsg_reg_24,GN_APPmsg_reg_25,GN_APPmsg_reg_26;
reg [`APPdata_Len-1:0] GN_APPmsg_reg_26_D0;
// =============================================================================
 // QSN（校验节点）相关寄存器/总线
 // - c_reg_*/c_*：分列保存的校验节点中间结果；
 // - APPmsg_old_*/APPmsg_new_*：变量节点旧/新 APP；
 // - QSN_APPmsg_*：校验节点输出给 DPU 的接口；
 // =============================================================================
reg [`b-1:0] c_new_0,c_new_1,c_new_2,c_new_3,c_new_4,c_new_5,c_new_6,c_new_7,c_new_8,c_new_9,c_new_10,c_new_11,c_new_12,c_new_13,c_new_14,c_new_15,c_new_16,c_new_17,c_new_18,c_new_19,c_new_20,c_new_21,c_new_22,c_new_23,c_new_24,c_new_25;
reg [`b*26-1:0] c_reg_new_D0,c_reg_new_D1,c_reg_new_D2,c_reg_new_D3,c_reg_new_D4,c_reg_new_D5,c_reg_new_D6,c_reg_new_D7,c_reg_new_D8,c_reg_new_D9,c_reg_new_D10;

wire [`b-1:0] c_D10_0,c_D10_1,c_D10_2,c_D10_3,c_D10_4,c_D10_5,c_D10_6,c_D10_7,c_D10_8,c_D10_9,c_D10_10,c_D10_11,c_D10_12,c_D10_13,c_D10_14,c_D10_15,c_D10_16,c_D10_17,c_D10_18,c_D10_19,c_D10_20,c_D10_21,c_D10_22,c_D10_23,c_D10_24,c_D10_25;
wire [`b-1:0] c_D9_0,c_D9_1,c_D9_2,c_D9_3,c_D9_4,c_D9_5,c_D9_6,c_D9_7,c_D9_8,c_D9_9,c_D9_10,c_D9_11,c_D9_12,c_D9_13,c_D9_14,c_D9_15,c_D9_16,c_D9_17,c_D9_18,c_D9_19,c_D9_20,c_D9_21,c_D9_22,c_D9_23,c_D9_24,c_D9_25;

// =============================================================================
 // 状态机（FSM）总览
 // - 角色：管理两套 APPRam（G0/G1）的装载(BUFFER)与译码(DECODE)交替，协调 FULL/WAIT 场景。
 // - 状态编码位义：[2] => 已缓冲的 APPRam 组数；[1] => 是否有组在译码；[0] => 是否有组在缓冲。
 // - 关键事件：
 //   * buffer_start：开始从输入口写入 APP 分片；
 //   * buffer_end：在 buffer_last 的下一个时钟周期拉高，表示本次装载完成；
 //   * decode_start：进入 DECODE 的启动信号（由当前状态与 buffer_end/decode_end 决定）；
 //   * decode_valid：译码输出有效（单拍）；下一拍产生 decode_end。
 // - 组选择：
 //   * group_to_buffer：在 buffer_end 之后翻转，指示下一次写入的组（0→G0, 1→G1）；
 //   * group_to_decode：在 decode_end 之后翻转，指示下一次译码的组。
 // =============================================================================
// state parameter: [2] denotes the number of APPRam Group that is buffered, [1] denotes whether one of the APPRam Group is being decoded, [0] denotes whether one of the APPRam Group is being buffered
parameter IDLE = 3'b000; // all APPRam Groups are empty, no decoding or buffering is processing
parameter BUFFER = 3'b001; // only 1 APPRam Group is being buffered, the other one is empty
parameter DECODE = 3'b010; // only 1 APPRam Group is being decoded, the other one is empty
parameter FULL = 3'b011; // one of the APPRam Group is being buffered, the other one is being decoded
parameter WAIT = 3'b110; // one of the APPRam Group is being decoded, the other one is buffered and wait to be decoded

reg [2:0] state_next;
reg [2:0] state_cur;

reg buffer_end,decode_end;
reg decode_start;

// index of the APPRam group to be used
reg group_to_buffer;
reg group_to_decode;
reg group_to_decode_C0,group_to_decode_C1,group_to_decode_C2,group_to_decode_C3,group_to_decode_C4,group_to_decode_C5,group_to_decode_C6,group_to_decode_C7,group_to_decode_C8,group_to_decode_C9,group_to_decode_C10,group_to_decode_C11,group_to_decode_C12,group_to_decode_C13,group_to_decode_C14,group_to_decode_C15,group_to_decode_C16,group_to_decode_C17,group_to_decode_C18,group_to_decode_C19,group_to_decode_C20,group_to_decode_C21,group_to_decode_C22,group_to_decode_C23,group_to_decode_C24,group_to_decode_C25,group_to_decode_C26;

// =============================================================================
 // 缓冲（Buffer）入口
 // - 目的：把 6 个子块(APPmsg_ini_subx_0..5，对应 lifting 分片)写入当前选择的 APPRam 组。
 // - 写入门控：
 //   * buffer_valid_D0：同步后的写入使能；
 //   * APPmsg_ini_sub_x_D0：2 比特子块索引(0..3)，每次使能 6 个连续 APPRam 实例；
 //   * group_to_buffer：选择写入 G0 或 G1；
 // - 地址/数据：
 //   * APPmsg_ini_addr/APPmsg_ini_addr_D0：输入侧地址推进；
 //   * APPmsg_G{0/1}_in_*：一次写入 `inNum*VWidth` 宽度。
 // =============================================================================
reg buffer_valid_D0;
reg [1:0] APPmsg_ini_sub_x_D0;

// =============================================================================
 // 译码（Decode）入口
 // - 目的：在所选组(G0/G1)上按层/行进行消息更新，直至一轮或收敛。
 // - 控制关键字：
 //   * iternum：迭代计数；
 //   * iter_start/iter_end：单次迭代的起止；
 //   * update_start/update_end：每层开始/结束；
 //   * APP_addr_rd_end：一次 APP 读遍历结束标志。
 // - 输出相关：
 //   * first_iter_valid / decode_out_start：首轮与输出启动控制；
 //   * decode_valid / decode_valid_cnt：结果有效与计数。
 // =============================================================================
reg [3:0] iternum;

reg iter_start,iter_end;
reg [5:0] Layernum;
reg update_start,update_end;

reg iter_start_D0,iter_start_D1,iter_start_D2,iter_start_D3;
reg first_iter_valid;
reg decode_out_start;
reg decode_out_start_to_decode_valid_time;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        decode_out_start_to_decode_valid_time <= 0; //复位
    else if (decode_out_start)
        decode_out_start_to_decode_valid_time <= 1;
    else if (decode_valid)
        decode_out_start_to_decode_valid_time <= 0;
end

reg APP_addr_rd_end;
reg APP_addr_rd_end_D0,APP_addr_rd_end_D1;

// =============================================================================
 // APPRam 双缓冲（G0 / G1）
 // - 写使能：
 //   * Buffer 阶段：由 APP_G{0/1}_wr_en_* 控制，依赖 buffer_valid_D0 与 APPmsg_ini_sub_x_D0；
 //   * Decode 阶段：由 APP_decodin_wr_en 控制，依赖当前层的移位 `shift_*`（最高位为是否参与写）；
 // - 写地址：APP_G{0/1}_addr_wr_*；读数据：APPmsg_G{0/1}_out_*；
 // - 组选择：group_to_buffer / group_to_decode；
 // - 时序要点：Buffer 与 Decode 互不干扰（FULL 态并行进行，不同组）。
 // =============================================================================
// =============================================================================
 // APPRam G0 - 写使能选择
 // - Buffer 阶段：根据 APPmsg_ini_sub_x_D0 选择 6 连续实例（0..7/8..13/14..19/20..25）；
 // - Decode 阶段：由 APP_decodin_wr_en 与 `~shift_*[HijWidth-1]` 决定是否写回；
 // - 非当前阶段或非当前组：全部 0。
 // =============================================================================,G1
reg APP_G0_wr_en_0,APP_G0_wr_en_1,APP_G0_wr_en_2,APP_G0_wr_en_3,APP_G0_wr_en_4,APP_G0_wr_en_5,APP_G0_wr_en_6,APP_G0_wr_en_7,APP_G0_wr_en_8,APP_G0_wr_en_9,APP_G0_wr_en_10,APP_G0_wr_en_11,APP_G0_wr_en_12,APP_G0_wr_en_13,APP_G0_wr_en_14,APP_G0_wr_en_15,APP_G0_wr_en_16,APP_G0_wr_en_17,APP_G0_wr_en_18,APP_G0_wr_en_19,APP_G0_wr_en_20,APP_G0_wr_en_21,APP_G0_wr_en_22,APP_G0_wr_en_23,APP_G0_wr_en_24,APP_G0_wr_en_25,APP_G0_wr_en_26;
reg APP_G1_wr_en_0,APP_G1_wr_en_1,APP_G1_wr_en_2,APP_G1_wr_en_3,APP_G1_wr_en_4,APP_G1_wr_en_5,APP_G1_wr_en_6,APP_G1_wr_en_7,APP_G1_wr_en_8,APP_G1_wr_en_9,APP_G1_wr_en_10,APP_G1_wr_en_11,APP_G1_wr_en_12,APP_G1_wr_en_13,APP_G1_wr_en_14,APP_G1_wr_en_15,APP_G1_wr_en_16,APP_G1_wr_en_17,APP_G1_wr_en_18,APP_G1_wr_en_19,APP_G1_wr_en_20,APP_G1_wr_en_21,APP_G1_wr_en_22,APP_G1_wr_en_23,APP_G1_wr_en_24,APP_G1_wr_en_25,APP_G1_wr_en_26;

// write address of APPRam G0,G1
reg [`APP_addr_width-2:0] APP_G0_addr_wr_0,APP_G0_addr_wr_1,APP_G0_addr_wr_2,APP_G0_addr_wr_3,APP_G0_addr_wr_4,APP_G0_addr_wr_5,APP_G0_addr_wr_6,APP_G0_addr_wr_7,APP_G0_addr_wr_8,APP_G0_addr_wr_9,APP_G0_addr_wr_10,APP_G0_addr_wr_11,APP_G0_addr_wr_12,APP_G0_addr_wr_13,APP_G0_addr_wr_14,APP_G0_addr_wr_15,APP_G0_addr_wr_16,APP_G0_addr_wr_17,APP_G0_addr_wr_18,APP_G0_addr_wr_19,APP_G0_addr_wr_20,APP_G0_addr_wr_21,APP_G0_addr_wr_22,APP_G0_addr_wr_23,APP_G0_addr_wr_24,APP_G0_addr_wr_25;
reg [7:0] APP_G0_addr_wr_26;
reg [`APP_addr_width-2:0] APP_G1_addr_wr_0,APP_G1_addr_wr_1,APP_G1_addr_wr_2,APP_G1_addr_wr_3,APP_G1_addr_wr_4,APP_G1_addr_wr_5,APP_G1_addr_wr_6,APP_G1_addr_wr_7,APP_G1_addr_wr_8,APP_G1_addr_wr_9,APP_G1_addr_wr_10,APP_G1_addr_wr_11,APP_G1_addr_wr_12,APP_G1_addr_wr_13,APP_G1_addr_wr_14,APP_G1_addr_wr_15,APP_G1_addr_wr_16,APP_G1_addr_wr_17,APP_G1_addr_wr_18,APP_G1_addr_wr_19,APP_G1_addr_wr_20,APP_G1_addr_wr_21,APP_G1_addr_wr_22,APP_G1_addr_wr_23,APP_G1_addr_wr_24,APP_G1_addr_wr_25;
reg [7:0] APP_G1_addr_wr_26;

reg [`APP_addr_width-2:0] APPmsg_ini_addr,APPmsg_ini_addr_D0;
reg [7:0] APPmsg_ini_addr_26;

reg [`APP_addr_width-2:0] APPmsg_ini_addr_C0,APPmsg_ini_addr_C1,APPmsg_ini_addr_C2,APPmsg_ini_addr_C3,APPmsg_ini_addr_C4,APPmsg_ini_addr_C5,APPmsg_ini_addr_C6,APPmsg_ini_addr_C7,APPmsg_ini_addr_C8,APPmsg_ini_addr_C9,APPmsg_ini_addr_C10,APPmsg_ini_addr_C11,APPmsg_ini_addr_C12,APPmsg_ini_addr_C13,APPmsg_ini_addr_C14,APPmsg_ini_addr_C15,APPmsg_ini_addr_C16,APPmsg_ini_addr_C17,APPmsg_ini_addr_C18,APPmsg_ini_addr_C19,APPmsg_ini_addr_C20,APPmsg_ini_addr_C21,APPmsg_ini_addr_C22,APPmsg_ini_addr_C23,APPmsg_ini_addr_C24,APPmsg_ini_addr_C25;
reg [`APP_addr_width-2:0] APPmsg_ini_addr_D0_C0,APPmsg_ini_addr_D0_C1,APPmsg_ini_addr_D0_C2,APPmsg_ini_addr_D0_C3,APPmsg_ini_addr_D0_C4,APPmsg_ini_addr_D0_C5,APPmsg_ini_addr_D0_C6,APPmsg_ini_addr_D0_C7,APPmsg_ini_addr_D0_C8,APPmsg_ini_addr_D0_C9,APPmsg_ini_addr_D0_C10,APPmsg_ini_addr_D0_C11,APPmsg_ini_addr_D0_C12,APPmsg_ini_addr_D0_C13,APPmsg_ini_addr_D0_C14,APPmsg_ini_addr_D0_C15,APPmsg_ini_addr_D0_C16,APPmsg_ini_addr_D0_C17,APPmsg_ini_addr_D0_C18,APPmsg_ini_addr_D0_C19,APPmsg_ini_addr_D0_C20,APPmsg_ini_addr_D0_C21,APPmsg_ini_addr_D0_C22,APPmsg_ini_addr_D0_C23,APPmsg_ini_addr_D0_C24,APPmsg_ini_addr_D0_C25;
reg [7:0] APPmsg_ini_addr_D0_C26;

// write data of APPRam G0,G1
reg [`inNum*`VWidth-1:0] APPmsg_G0_in_0,APPmsg_G0_in_1,APPmsg_G0_in_2,APPmsg_G0_in_3,APPmsg_G0_in_4,APPmsg_G0_in_5,APPmsg_G0_in_6,APPmsg_G0_in_7,APPmsg_G0_in_8,APPmsg_G0_in_9,APPmsg_G0_in_10,APPmsg_G0_in_11,APPmsg_G0_in_12,APPmsg_G0_in_13,APPmsg_G0_in_14,APPmsg_G0_in_15,APPmsg_G0_in_16,APPmsg_G0_in_17,APPmsg_G0_in_18,APPmsg_G0_in_19,APPmsg_G0_in_20,APPmsg_G0_in_21,APPmsg_G0_in_22,APPmsg_G0_in_23,APPmsg_G0_in_24,APPmsg_G0_in_25,APPmsg_G0_in_26;
reg [`inNum*`VWidth-1:0] APPmsg_G1_in_0,APPmsg_G1_in_1,APPmsg_G1_in_2,APPmsg_G1_in_3,APPmsg_G1_in_4,APPmsg_G1_in_5,APPmsg_G1_in_6,APPmsg_G1_in_7,APPmsg_G1_in_8,APPmsg_G1_in_9,APPmsg_G1_in_10,APPmsg_G1_in_11,APPmsg_G1_in_12,APPmsg_G1_in_13,APPmsg_G1_in_14,APPmsg_G1_in_15,APPmsg_G1_in_16,APPmsg_G1_in_17,APPmsg_G1_in_18,APPmsg_G1_in_19,APPmsg_G1_in_20,APPmsg_G1_in_21,APPmsg_G1_in_22,APPmsg_G1_in_23,APPmsg_G1_in_24,APPmsg_G1_in_25,APPmsg_G1_in_26;

wire [`inNum*`VWidth-1:0] APPmsg_ini_data_subx_0,APPmsg_ini_data_subx_1,APPmsg_ini_data_subx_2,APPmsg_ini_data_subx_3,APPmsg_ini_data_subx_4,APPmsg_ini_data_subx_5,APPmsg_ini_data_subx_6,APPmsg_ini_data_subx_7,APPmsg_ini_data_subx_7_or_APPmsg_ini_data_subx_all,APPmsg_ini_data_subx_all;

// read data of APPRam G0,G1
wire [`inNum*`VWidth-1:0] APPmsg_G0_out_0,APPmsg_G0_out_1,APPmsg_G0_out_2,APPmsg_G0_out_3,APPmsg_G0_out_4,APPmsg_G0_out_5,APPmsg_G0_out_6,APPmsg_G0_out_7,APPmsg_G0_out_8,APPmsg_G0_out_9,APPmsg_G0_out_10,APPmsg_G0_out_11,APPmsg_G0_out_12,APPmsg_G0_out_13,APPmsg_G0_out_14,APPmsg_G0_out_15,APPmsg_G0_out_16,APPmsg_G0_out_17,APPmsg_G0_out_18,APPmsg_G0_out_19,APPmsg_G0_out_20,APPmsg_G0_out_21,APPmsg_G0_out_22,APPmsg_G0_out_23,APPmsg_G0_out_24,APPmsg_G0_out_25,APPmsg_G0_out_26;
wire [`inNum*`VWidth-1:0] APPmsg_G1_out_0,APPmsg_G1_out_1,APPmsg_G1_out_2,APPmsg_G1_out_3,APPmsg_G1_out_4,APPmsg_G1_out_5,APPmsg_G1_out_6,APPmsg_G1_out_7,APPmsg_G1_out_8,APPmsg_G1_out_9,APPmsg_G1_out_10,APPmsg_G1_out_11,APPmsg_G1_out_12,APPmsg_G1_out_13,APPmsg_G1_out_14,APPmsg_G1_out_15,APPmsg_G1_out_16,APPmsg_G1_out_17,APPmsg_G1_out_18,APPmsg_G1_out_19,APPmsg_G1_out_20,APPmsg_G1_out_21,APPmsg_G1_out_22,APPmsg_G1_out_23,APPmsg_G1_out_24,APPmsg_G1_out_25,APPmsg_G1_out_26;

wire [`Zc-1:0] APP_dec_out_0,APP_dec_out_1,APP_dec_out_2,APP_dec_out_3,APP_dec_out_4,APP_dec_out_5,APP_dec_out_6,APP_dec_out_7,APP_dec_out_8,APP_dec_out_9,
	 APP_dec_out_10,APP_dec_out_11,APP_dec_out_12,APP_dec_out_13,APP_dec_out_14,APP_dec_out_15,APP_dec_out_16,APP_dec_out_17,APP_dec_out_18,APP_dec_out_19,
	 APP_dec_out_20,APP_dec_out_21;

// write enable of APPRam during decoding
reg APP_decodin_wr_en;

// =============================================================================
 // FSM 实现细节
 // - 第一段：时序寄存 `state_cur`
 // - 第二段：组合产生 `state_next`（状态转移条件包含 buffer_start/buffer_end/decode_end）
 // - 其后分别生成：buffer_end/decode_end 延迟、buffer_ready 输出、decode_start 触发、
 //   以及 group_to_buffer / group_to_decode / group_to_decode_C* 的翻转逻辑。
 // =============================================================================
// state transfer

// parameter IDLE = 3'b000; // all APPRam Groups are empty, no decoding or buffering is processing
// parameter BUFFER = 3'b001; // only 1 APPRam Group is being buffered, the other one is empty
// parameter DECODE = 3'b010; // only 1 APPRam Group is being decoded, the other one is empty
// parameter FULL = 3'b011; // one of the APPRam Group is being buffered, the other one is being decoded
// parameter WAIT = 3'b110; // one of the APPRam Group is being decoded, the other one is buffered and wait to be decoded

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state_cur <= IDLE; //初始状态
	else
		state_cur <= state_next;
end

// state switch
// buffer_start can only be high on IDLE, DECODE
// buffer_end can only be high on BUFFER, FULL
// decode_end can only be high on DECODE, FULL, WAIT
always @(*)
begin
	case(state_cur)
		IDLE:
		begin
			if(buffer_start)
				state_next = BUFFER;
			else
				state_next = IDLE;
		end
		BUFFER:
		begin
			if(buffer_end && ~buffer_start)
				state_next = DECODE;
			else if(buffer_end && buffer_start)
				state_next = FULL;
			else
				state_next = BUFFER;
		end
		DECODE:
		begin
			if(decode_end && !buffer_start)
				state_next = IDLE;
			else if(decode_end && buffer_start)
				state_next = BUFFER;
			else if(!decode_end && buffer_start)
				state_next = FULL;
			else
				state_next = DECODE;
		end
		FULL:
		begin
			if(buffer_end && decode_end)
				state_next = DECODE;
			else if(decode_end)
				state_next = BUFFER;
			else if(buffer_end)
				state_next = WAIT;
			else
				state_next = FULL;
		end
		WAIT:
		begin
			if(decode_end)
				state_next = DECODE;
			else
				state_next = WAIT;
		end
		default:
		begin
			state_next = IDLE;
		end
	endcase
end

// -----------------------------------------------------------------------------
 // buffer_end -- 输入缓冲结束脉冲（与 buffer_last 对应）
 // 规则：在 buffer_last 的下一个时钟周期拉高 1 拍，用于：
 //   1) 驱动 FSM 从 BUFFER 进入 DECODE/FULL；
 //   2) 触发 group_to_buffer 翻转，切换下次写入的 APPRam 组。
 // -----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		buffer_end <= 1'b0;
	else
		buffer_end <= buffer_last; //表示当前写完一组数据
end

// -----------------------------------------------------------------------------
 // decode_end -- 译码结束脉冲（与 decode_valid 对应）
 // 规则：在 decode_valid 的下一个时钟周期拉高 1 拍，用于：
 //   1) 驱动 FSM 退出 DECODE；在 FULL/WAIT 中与 buffer_end 共同决定下一状态；
 //   2) 触发 group_to_decode 翻转，切换下次译码的 APPRam 组。
 // -----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		decode_end <= 1'b0;
	else
		decode_end <= decode_valid;
end

// -----------------------------------------------------------------------------
 // buffer_ready -- 输入侧就绪信号
 // 实际行为：在 IDLE / BUFFER / DECODE 保持为 1；
 //   * FULL：当 buffer_end 到达且 decode 仍在进行时拉低为 0，防止再继续写入；
 //   * WAIT：译码未结束为 0，译码结束后恢复为 1。
 // 用途：与上游 buffer_start/buffer_valid 配合完成一帧 LLR 的装载握手。
 // -----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) //控制buffer_ready信号
begin
	if(!rst_n)
	begin
		buffer_ready <= 0;
	end
	else
	begin
		case(state_cur)
			IDLE,BUFFER,DECODE:
			begin
				buffer_ready <= 1;
			end
			FULL:
			begin
				if((buffer_end || buffer_last) && ~decode_end)
				begin
					buffer_ready <= 0;
				end
				else
				begin
					buffer_ready <= 1;
				end
			end
			WAIT:
			begin
				if(decode_end)
				begin
					buffer_ready <= 1;
				end
				else
				begin
					buffer_ready <= 0;
				end
			end
			default:
			begin
				buffer_ready <= 0;
			end
		endcase
	end
end

// -----------------------------------------------------------------------------
 // decode_start 触发条件（两种情况）
 //   1) 当前处于 BUFFER，且本次缓冲完成（buffer_end=1）；
 //   2) 当前处于 WAIT，且正在进行的译码完成（decode_end=1）。
 // 作用：启动对 `group_to_decode` 指示的 APPRam 组执行译码流程。
 // ---------------------------------------------- -------------------------------
always @(posedge clk or negedge rst_n) //控制 decode_start信号
begin
	if(!rst_n)
	begin
		decode_start <= 1'b0;
	end
	else if(state_cur == BUFFER)
	begin
		if(buffer_end)
			decode_start <= 1'b1;
		else
			decode_start <= 1'b0;
	end
	else if(state_cur == WAIT)
	begin
		if(decode_end)
			decode_start <= 1'b1;
		else
			decode_start <= 1'b0;
	end
	else
	begin
		decode_start <= 1'b0;
	end
end

// group_to_buffer changes when buffer_end is high
always @(posedge clk or negedge rst_n) //控制哪一个buffer接受
begin
	if(!rst_n)
	begin
		group_to_buffer <= 1'b0;
	end
	else
	begin
		if(buffer_end)
			group_to_buffer <= group_to_buffer + 1'b1;
		else
			group_to_buffer <= group_to_buffer;
	end
end

// group_to_decode changes when decode_end is high
always @(posedge clk or negedge rst_n) //控制哪一个buffer信号译码
begin
	if(!rst_n)
	begin
		group_to_decode <= 1'b0;
	end
	else
	begin
		if(decode_end)
			group_to_decode <= group_to_decode + 1'b1;
		else
			group_to_decode <= group_to_decode;
	end
end
always @(posedge clk or negedge rst_n) //从哪一组buffer接受信号
begin
	if(!rst_n)
	begin
		group_to_decode_C0 <= 1'b0;
		group_to_decode_C1 <= 1'b0;
		group_to_decode_C2 <= 1'b0;
		group_to_decode_C3 <= 1'b0;
		group_to_decode_C4 <= 1'b0;
		group_to_decode_C5 <= 1'b0;
		group_to_decode_C6 <= 1'b0;
		group_to_decode_C7 <= 1'b0;
		group_to_decode_C8 <= 1'b0;
		group_to_decode_C9 <= 1'b0;
		group_to_decode_C10 <= 1'b0;
		group_to_decode_C11 <= 1'b0;
		group_to_decode_C12 <= 1'b0;
		group_to_decode_C13 <= 1'b0;
		group_to_decode_C14 <= 1'b0;
		group_to_decode_C15 <= 1'b0;
		group_to_decode_C16 <= 1'b0;
		group_to_decode_C17 <= 1'b0;
		group_to_decode_C18 <= 1'b0;
		group_to_decode_C19 <= 1'b0;
		group_to_decode_C20 <= 1'b0;
		group_to_decode_C21 <= 1'b0;
		group_to_decode_C22 <= 1'b0;
		group_to_decode_C23 <= 1'b0;
		group_to_decode_C24 <= 1'b0;
		group_to_decode_C25 <= 1'b0;
		group_to_decode_C26 <= 1'b0;
	end
	else
	begin
		if(decode_end)
		begin
			group_to_decode_C0 <= group_to_decode_C0 + 1'b1;
			group_to_decode_C1 <= group_to_decode_C1 + 1'b1;
			group_to_decode_C2 <= group_to_decode_C2 + 1'b1;
			group_to_decode_C3 <= group_to_decode_C3 + 1'b1;
			group_to_decode_C4 <= group_to_decode_C4 + 1'b1;
			group_to_decode_C5 <= group_to_decode_C5 + 1'b1;
			group_to_decode_C6 <= group_to_decode_C6 + 1'b1;
			group_to_decode_C7 <= group_to_decode_C7 + 1'b1;
			group_to_decode_C8 <= group_to_decode_C8 + 1'b1;
			group_to_decode_C9 <= group_to_decode_C9 + 1'b1;
			group_to_decode_C10 <= group_to_decode_C10 + 1'b1;
			group_to_decode_C11 <= group_to_decode_C11 + 1'b1;
			group_to_decode_C12 <= group_to_decode_C12 + 1'b1;
			group_to_decode_C13 <= group_to_decode_C13 + 1'b1;
			group_to_decode_C14 <= group_to_decode_C14 + 1'b1;
			group_to_decode_C15 <= group_to_decode_C15 + 1'b1;
			group_to_decode_C16 <= group_to_decode_C16 + 1'b1;
			group_to_decode_C17 <= group_to_decode_C17 + 1'b1;
			group_to_decode_C18 <= group_to_decode_C18 + 1'b1;
			group_to_decode_C19 <= group_to_decode_C19 + 1'b1;
			group_to_decode_C20 <= group_to_decode_C20 + 1'b1;
			group_to_decode_C21 <= group_to_decode_C21 + 1'b1;
			group_to_decode_C22 <= group_to_decode_C22 + 1'b1;
			group_to_decode_C23 <= group_to_decode_C23 + 1'b1;
			group_to_decode_C24 <= group_to_decode_C24 + 1'b1;
			group_to_decode_C25 <= group_to_decode_C25 + 1'b1;
			group_to_decode_C26 <= group_to_decode_C26 + 1'b1;
		end
		else
		begin
			group_to_decode_C0 <= group_to_decode_C0;
			group_to_decode_C1 <= group_to_decode_C1;
			group_to_decode_C2 <= group_to_decode_C2;
			group_to_decode_C3 <= group_to_decode_C3;
			group_to_decode_C4 <= group_to_decode_C4;
			group_to_decode_C5 <= group_to_decode_C5;
			group_to_decode_C6 <= group_to_decode_C6;
			group_to_decode_C7 <= group_to_decode_C7;
			group_to_decode_C8 <= group_to_decode_C8;
			group_to_decode_C9 <= group_to_decode_C9;
			group_to_decode_C10 <= group_to_decode_C10;
			group_to_decode_C11 <= group_to_decode_C11;
			group_to_decode_C12 <= group_to_decode_C12;
			group_to_decode_C13 <= group_to_decode_C13;
			group_to_decode_C14 <= group_to_decode_C14;
			group_to_decode_C15 <= group_to_decode_C15;
			group_to_decode_C16 <= group_to_decode_C16;
			group_to_decode_C17 <= group_to_decode_C17;
			group_to_decode_C18 <= group_to_decode_C18;
			group_to_decode_C19 <= group_to_decode_C19;
			group_to_decode_C20 <= group_to_decode_C20;
			group_to_decode_C21 <= group_to_decode_C21;
			group_to_decode_C22 <= group_to_decode_C22;
			group_to_decode_C23 <= group_to_decode_C23;
			group_to_decode_C24 <= group_to_decode_C24;
			group_to_decode_C25 <= group_to_decode_C25;
			group_to_decode_C26 <= group_to_decode_C26;			
		end
	end
end


// =============================================================================
 // Buffer 阶段 - 组合逻辑（写使能选择）
 // - 依据 group_to_buffer 选择 G0 或 G1；
 // - 依据 APPmsg_ini_sub_x_D0 将 26 个 APPRam 按 (0..7)(8..13)(14..19)(20..25) 分 4 组，
 //   每次只打开 6 个连续实例的 wr_en；
 // - 初始化首组时会处理"首组 8 个"的对齐细节（由原始代码逻辑控制）。
 // =============================================================================

// =============================================================================
 // APPRam G0 - 写使能选择
 // - Buffer 阶段：根据 APPmsg_ini_sub_x_D0 选择 6 连续实例（0..7/8..13/14..19/20..25）；
 // - Decode 阶段：由 APP_decodin_wr_en 与 `~shift_*[HijWidth-1]` 决定是否写回；
 // - 非当前阶段或非当前组：全部 0。
 // =============================================================================
// during initializing, only 6 APPRams' wr_en is high at a time (except the 1st time)
always @(*)   //控制信号往哪一个RAM写入，第一个buffer
begin
	if(buffer_valid_D0 && group_to_buffer == 0) //写入APP时
	begin
		case(APPmsg_ini_sub_x_D0)
		0:
		begin
			APP_G0_wr_en_0  = buffer_valid_D0;
			APP_G0_wr_en_1  = buffer_valid_D0; //0
			APP_G0_wr_en_2  = buffer_valid_D0;
			APP_G0_wr_en_3  = buffer_valid_D0;
			APP_G0_wr_en_4  = buffer_valid_D0;
			APP_G0_wr_en_5  = buffer_valid_D0;
			APP_G0_wr_en_6  = buffer_valid_D0;
			APP_G0_wr_en_7  = buffer_valid_D0;
			APP_G0_wr_en_8  = buffer_valid_D0;
			APP_G0_wr_en_9  = buffer_valid_D0;
			APP_G0_wr_en_10 = 0;
			APP_G0_wr_en_11 = 0;
			APP_G0_wr_en_12 = 0;
			APP_G0_wr_en_13 = 0;
			APP_G0_wr_en_14 = 0;
			APP_G0_wr_en_15 = 0;
			APP_G0_wr_en_16 = 0;
			APP_G0_wr_en_17 = 0;
			APP_G0_wr_en_18 = 0;
			APP_G0_wr_en_19 = 0;
			APP_G0_wr_en_20 = 0;
			APP_G0_wr_en_21 = 0;
			APP_G0_wr_en_22 = 0;
			APP_G0_wr_en_23 = 0;
			APP_G0_wr_en_24 = 0;
			APP_G0_wr_en_25 = 0;
			APP_G0_wr_en_26 = 0;			
		end
		1:
		begin
			APP_G0_wr_en_0  = 0;
			APP_G0_wr_en_1  = 0;
			APP_G0_wr_en_2  = 0;
			APP_G0_wr_en_3  = 0;
			APP_G0_wr_en_4  = 0;
			APP_G0_wr_en_5  = 0;
			APP_G0_wr_en_6  = 0;
			APP_G0_wr_en_7  = 0;
			APP_G0_wr_en_8  = 0;
			APP_G0_wr_en_9  = 0;
			APP_G0_wr_en_10 = buffer_valid_D0;
			APP_G0_wr_en_11 = buffer_valid_D0;
			APP_G0_wr_en_12 = buffer_valid_D0;
			APP_G0_wr_en_13 = buffer_valid_D0;
			APP_G0_wr_en_14 = buffer_valid_D0;
			APP_G0_wr_en_15 = buffer_valid_D0;
			APP_G0_wr_en_16 = buffer_valid_D0;
			APP_G0_wr_en_17 = buffer_valid_D0;
			APP_G0_wr_en_18 = 0;
			APP_G0_wr_en_19 = 0;
			APP_G0_wr_en_20 = 0;
			APP_G0_wr_en_21 = 0;
			APP_G0_wr_en_22 = 0;
			APP_G0_wr_en_23 = 0;
			APP_G0_wr_en_24 = 0;
			APP_G0_wr_en_25 = 0;	
			APP_G0_wr_en_26 = 0;		
		end
		2:
		begin
			APP_G0_wr_en_0  = 0;
			APP_G0_wr_en_1  = 0;
			APP_G0_wr_en_2  = 0;
			APP_G0_wr_en_3  = 0;
			APP_G0_wr_en_4  = 0;
			APP_G0_wr_en_5  = 0;
			APP_G0_wr_en_6  = 0;
			APP_G0_wr_en_7  = 0;
			APP_G0_wr_en_8  = 0;
			APP_G0_wr_en_9  = 0;
			APP_G0_wr_en_10 = 0;
			APP_G0_wr_en_11 = 0;
			APP_G0_wr_en_12 = 0;
			APP_G0_wr_en_13 = 0;
			APP_G0_wr_en_14 = 0;
			APP_G0_wr_en_15 = 0;
			APP_G0_wr_en_16 = 0;
			APP_G0_wr_en_17 = 0;
			APP_G0_wr_en_18 = buffer_valid_D0;
			APP_G0_wr_en_19 = buffer_valid_D0;
			APP_G0_wr_en_20 = buffer_valid_D0;
			APP_G0_wr_en_21 = buffer_valid_D0; // 
			APP_G0_wr_en_22 = buffer_valid_D0; 
			APP_G0_wr_en_23 = buffer_valid_D0;
			APP_G0_wr_en_24 = buffer_valid_D0;
			APP_G0_wr_en_25 = buffer_valid_D0;
			APP_G0_wr_en_26 = buffer_valid_D0;				
		end
		3:
		begin
			APP_G0_wr_en_0  = 0;
			APP_G0_wr_en_1  = 0;
			APP_G0_wr_en_2  = 0;
			APP_G0_wr_en_3  = 0;
			APP_G0_wr_en_4  = 0;
			APP_G0_wr_en_5  = 0;
			APP_G0_wr_en_6  = 0;
			APP_G0_wr_en_7  = 0;
			APP_G0_wr_en_8  = 0;
			APP_G0_wr_en_9  = 0;
			APP_G0_wr_en_10 = 0;
			APP_G0_wr_en_11 = 0;
			APP_G0_wr_en_12 = 0;
			APP_G0_wr_en_13 = 0;
			APP_G0_wr_en_14 = 0;
			APP_G0_wr_en_15 = 0;
			APP_G0_wr_en_16 = 0;
			APP_G0_wr_en_17 = 0;
			APP_G0_wr_en_18 = 0;
			APP_G0_wr_en_19 = 0;
			APP_G0_wr_en_20 = 0;
			APP_G0_wr_en_21 = 0;
			APP_G0_wr_en_22 = 0;
			APP_G0_wr_en_23 = 0;
			APP_G0_wr_en_24 = 0;
			APP_G0_wr_en_25 = 0;
			APP_G0_wr_en_26 = buffer_valid_D0; 				
		end
		endcase
	end
	else if(group_to_decode == 0) //更新，译码时
	begin
		APP_G0_wr_en_0  = APP_decodin_wr_en & ~shift_0 [`HijWidth-1];
		APP_G0_wr_en_1  = APP_decodin_wr_en & ~shift_1 [`HijWidth-1];
		APP_G0_wr_en_2  = APP_decodin_wr_en & ~shift_2 [`HijWidth-1];
		APP_G0_wr_en_3  = APP_decodin_wr_en & ~shift_3 [`HijWidth-1];
		APP_G0_wr_en_4  = APP_decodin_wr_en & ~shift_4 [`HijWidth-1];
		APP_G0_wr_en_5  = APP_decodin_wr_en & ~shift_5 [`HijWidth-1];
		APP_G0_wr_en_6  = APP_decodin_wr_en & ~shift_6 [`HijWidth-1];
		APP_G0_wr_en_7  = APP_decodin_wr_en & ~shift_7 [`HijWidth-1];
		APP_G0_wr_en_8  = APP_decodin_wr_en & ~shift_8 [`HijWidth-1];
		APP_G0_wr_en_9  = APP_decodin_wr_en & ~shift_9 [`HijWidth-1];
		APP_G0_wr_en_10 = APP_decodin_wr_en & ~shift_10[`HijWidth-1];
		APP_G0_wr_en_11 = APP_decodin_wr_en & ~shift_11[`HijWidth-1];
		APP_G0_wr_en_12 = APP_decodin_wr_en & ~shift_12[`HijWidth-1];
		APP_G0_wr_en_13 = APP_decodin_wr_en & ~shift_13[`HijWidth-1];
		APP_G0_wr_en_14 = APP_decodin_wr_en & ~shift_14[`HijWidth-1];
		APP_G0_wr_en_15 = APP_decodin_wr_en & ~shift_15[`HijWidth-1];
		APP_G0_wr_en_16 = APP_decodin_wr_en & ~shift_16[`HijWidth-1];
		APP_G0_wr_en_17 = APP_decodin_wr_en & ~shift_17[`HijWidth-1];
		APP_G0_wr_en_18 = APP_decodin_wr_en & ~shift_18[`HijWidth-1];
		APP_G0_wr_en_19 = APP_decodin_wr_en & ~shift_19[`HijWidth-1];
		APP_G0_wr_en_20 = APP_decodin_wr_en & ~shift_20[`HijWidth-1];
		APP_G0_wr_en_21 = APP_decodin_wr_en & ~shift_21[`HijWidth-1];
		APP_G0_wr_en_22 = APP_decodin_wr_en & ~shift_22[`HijWidth-1];
		APP_G0_wr_en_23 = APP_decodin_wr_en & ~shift_23[`HijWidth-1];
		APP_G0_wr_en_24 = APP_decodin_wr_en & ~shift_24[`HijWidth-1];
		APP_G0_wr_en_25 = APP_decodin_wr_en & ~shift_25[`HijWidth-1];
		APP_G0_wr_en_26 = APP_decodin_wr_en & share_flag;
	end
	else
	begin
		APP_G0_wr_en_0 = 0;
		APP_G0_wr_en_1 = 0;
		APP_G0_wr_en_2 = 0;
		APP_G0_wr_en_3 = 0;
		APP_G0_wr_en_4 = 0;
		APP_G0_wr_en_5 = 0;
		APP_G0_wr_en_6 = 0;
		APP_G0_wr_en_7 = 0;
		APP_G0_wr_en_8 = 0;
		APP_G0_wr_en_9 = 0;
		APP_G0_wr_en_10 = 0;
		APP_G0_wr_en_11 = 0;
		APP_G0_wr_en_12 = 0;
		APP_G0_wr_en_13 = 0;
		APP_G0_wr_en_14 = 0;
		APP_G0_wr_en_15 = 0;
		APP_G0_wr_en_16 = 0;
		APP_G0_wr_en_17 = 0;
		APP_G0_wr_en_18 = 0;
		APP_G0_wr_en_19 = 0;
		APP_G0_wr_en_20 = 0;
		APP_G0_wr_en_21 = 0;
		APP_G0_wr_en_22 = 0;
		APP_G0_wr_en_23 = 0;
		APP_G0_wr_en_24 = 0;
		APP_G0_wr_en_25 = 0;
		APP_G0_wr_en_26 = 0;
	end
end
// =============================================================================
 // APPRam G1 - 写使能选择
 // 逻辑同 G0，但使用 group_to_buffer==1 或 group_to_decode==1 的条件。
 // =============================================================================
always @(*) //控制信号往哪一个RAM写入，针对第二个buffer
begin
	if(buffer_valid_D0 && group_to_buffer == 1)
	begin
		case(APPmsg_ini_sub_x_D0)
		0:
		begin
			APP_G1_wr_en_0  = buffer_valid_D0;
			APP_G1_wr_en_1  = buffer_valid_D0;
			APP_G1_wr_en_2  = buffer_valid_D0;
			APP_G1_wr_en_3  = buffer_valid_D0;
			APP_G1_wr_en_4  = buffer_valid_D0;
			APP_G1_wr_en_5  = buffer_valid_D0;
			APP_G1_wr_en_6  = buffer_valid_D0;
			APP_G1_wr_en_7  = buffer_valid_D0;
			APP_G1_wr_en_8  = buffer_valid_D0;
			APP_G1_wr_en_9  = buffer_valid_D0;
			APP_G1_wr_en_10 = 0;
			APP_G1_wr_en_11 = 0;
			APP_G1_wr_en_12 = 0;
			APP_G1_wr_en_13 = 0;
			APP_G1_wr_en_14 = 0;
			APP_G1_wr_en_15 = 0;
			APP_G1_wr_en_16 = 0;
			APP_G1_wr_en_17 = 0;
			APP_G1_wr_en_18 = 0;
			APP_G1_wr_en_19 = 0;
			APP_G1_wr_en_20 = 0;
			APP_G1_wr_en_21 = 0;
			APP_G1_wr_en_22 = 0;
			APP_G1_wr_en_23 = 0;
			APP_G1_wr_en_24 = 0;
			APP_G1_wr_en_25 = 0;
			APP_G1_wr_en_26 = 0;			
		end
		1:
		begin
			APP_G1_wr_en_0  = 0;
			APP_G1_wr_en_1  = 0;
			APP_G1_wr_en_2  = 0;
			APP_G1_wr_en_3  = 0;
			APP_G1_wr_en_4  = 0;
			APP_G1_wr_en_5  = 0;
			APP_G1_wr_en_6  = 0;
			APP_G1_wr_en_7  = 0;
			APP_G1_wr_en_8  = 0;
			APP_G1_wr_en_9  = 0;
			APP_G1_wr_en_10 = buffer_valid_D0;
			APP_G1_wr_en_11 = buffer_valid_D0;
			APP_G1_wr_en_12 = buffer_valid_D0;
			APP_G1_wr_en_13 = buffer_valid_D0;
			APP_G1_wr_en_14 = buffer_valid_D0;
			APP_G1_wr_en_15 = buffer_valid_D0;
			APP_G1_wr_en_16 = buffer_valid_D0;
			APP_G1_wr_en_17 = buffer_valid_D0;
			APP_G1_wr_en_18 = 0;
			APP_G1_wr_en_19 = 0;
			APP_G1_wr_en_20 = 0;
			APP_G1_wr_en_21 = 0;
			APP_G1_wr_en_22 = 0;
			APP_G1_wr_en_23 = 0;
			APP_G1_wr_en_24 = 0;
			APP_G1_wr_en_25 = 0;
			APP_G1_wr_en_26 = 0;	
		end
		2:
		begin
			APP_G1_wr_en_0  = 0;
			APP_G1_wr_en_1  = 0;
			APP_G1_wr_en_2  = 0;
			APP_G1_wr_en_3  = 0;
			APP_G1_wr_en_4  = 0;
			APP_G1_wr_en_5  = 0;
			APP_G1_wr_en_6  = 0;
			APP_G1_wr_en_7  = 0;
			APP_G1_wr_en_8  = 0;
			APP_G1_wr_en_9  = 0;
			APP_G1_wr_en_10 = 0;
			APP_G1_wr_en_11 = 0;
			APP_G1_wr_en_12 = 0;
			APP_G1_wr_en_13 = 0;
			APP_G1_wr_en_14 = 0;
			APP_G1_wr_en_15 = 0;
			APP_G1_wr_en_16 = 0;
			APP_G1_wr_en_17 = 0;
			APP_G1_wr_en_18 = buffer_valid_D0;
			APP_G1_wr_en_19 = buffer_valid_D0;
			APP_G1_wr_en_20 = buffer_valid_D0;
			APP_G1_wr_en_21 = buffer_valid_D0;
			APP_G1_wr_en_22 = buffer_valid_D0;
			APP_G1_wr_en_23 = buffer_valid_D0;
			APP_G1_wr_en_24 = buffer_valid_D0;
			APP_G1_wr_en_25 = buffer_valid_D0;
			APP_G1_wr_en_26 = buffer_valid_D0;				
		end
		3:
		begin
			APP_G1_wr_en_0  = 0;
			APP_G1_wr_en_1  = 0;
			APP_G1_wr_en_2  = 0;
			APP_G1_wr_en_3  = 0;
			APP_G1_wr_en_4  = 0;
			APP_G1_wr_en_5  = 0;
			APP_G1_wr_en_6  = 0;
			APP_G1_wr_en_7  = 0;
			APP_G1_wr_en_8  = 0;
			APP_G1_wr_en_9  = 0;
			APP_G1_wr_en_10 = 0;
			APP_G1_wr_en_11 = 0;
			APP_G1_wr_en_12 = 0;
			APP_G1_wr_en_13 = 0;
			APP_G1_wr_en_14 = 0;
			APP_G1_wr_en_15 = 0;
			APP_G1_wr_en_16 = 0;
			APP_G1_wr_en_17 = 0;
			APP_G1_wr_en_18 = 0;
			APP_G1_wr_en_19 = 0;
			APP_G1_wr_en_20 = 0;
			APP_G1_wr_en_21 = 0;
			APP_G1_wr_en_22 = 0;
			APP_G1_wr_en_23 = 0;
			APP_G1_wr_en_24 = 0;
			APP_G1_wr_en_25 = 0;
			APP_G1_wr_en_26 = buffer_valid_D0;				
		end
		endcase
	end
	else if(group_to_decode == 1)
	begin
		APP_G1_wr_en_0  = APP_decodin_wr_en & ~shift_0 [`HijWidth-1];
		APP_G1_wr_en_1  = APP_decodin_wr_en & ~shift_1 [`HijWidth-1];
		APP_G1_wr_en_2  = APP_decodin_wr_en & ~shift_2 [`HijWidth-1];
		APP_G1_wr_en_3  = APP_decodin_wr_en & ~shift_3 [`HijWidth-1];
		APP_G1_wr_en_4  = APP_decodin_wr_en & ~shift_4 [`HijWidth-1];
		APP_G1_wr_en_5  = APP_decodin_wr_en & ~shift_5 [`HijWidth-1];
		APP_G1_wr_en_6  = APP_decodin_wr_en & ~shift_6 [`HijWidth-1];
		APP_G1_wr_en_7  = APP_decodin_wr_en & ~shift_7 [`HijWidth-1];
		APP_G1_wr_en_8  = APP_decodin_wr_en & ~shift_8 [`HijWidth-1];
		APP_G1_wr_en_9  = APP_decodin_wr_en & ~shift_9 [`HijWidth-1];
		APP_G1_wr_en_10 = APP_decodin_wr_en & ~shift_10[`HijWidth-1];
		APP_G1_wr_en_11 = APP_decodin_wr_en & ~shift_11[`HijWidth-1];
		APP_G1_wr_en_12 = APP_decodin_wr_en & ~shift_12[`HijWidth-1];
		APP_G1_wr_en_13 = APP_decodin_wr_en & ~shift_13[`HijWidth-1];
		APP_G1_wr_en_14 = APP_decodin_wr_en & ~shift_14[`HijWidth-1];
		APP_G1_wr_en_15 = APP_decodin_wr_en & ~shift_15[`HijWidth-1];
		APP_G1_wr_en_16 = APP_decodin_wr_en & ~shift_16[`HijWidth-1];
		APP_G1_wr_en_17 = APP_decodin_wr_en & ~shift_17[`HijWidth-1];
		APP_G1_wr_en_18 = APP_decodin_wr_en & ~shift_18[`HijWidth-1];
		APP_G1_wr_en_19 = APP_decodin_wr_en & ~shift_19[`HijWidth-1];
		APP_G1_wr_en_20 = APP_decodin_wr_en & ~shift_20[`HijWidth-1];
		APP_G1_wr_en_21 = APP_decodin_wr_en & ~shift_21[`HijWidth-1];
		APP_G1_wr_en_22 = APP_decodin_wr_en & ~shift_22[`HijWidth-1];
		APP_G1_wr_en_23 = APP_decodin_wr_en & ~shift_23[`HijWidth-1];
		APP_G1_wr_en_24 = APP_decodin_wr_en & ~shift_24[`HijWidth-1];
		APP_G1_wr_en_25 = APP_decodin_wr_en & ~shift_25[`HijWidth-1];
		APP_G1_wr_en_26 = APP_decodin_wr_en & share_flag;
	end
	else
	begin
		APP_G1_wr_en_0 = 0;
		APP_G1_wr_en_1 = 0;
		APP_G1_wr_en_2 = 0;
		APP_G1_wr_en_3 = 0;
		APP_G1_wr_en_4 = 0;
		APP_G1_wr_en_5 = 0;
		APP_G1_wr_en_6 = 0;
		APP_G1_wr_en_7 = 0;
		APP_G1_wr_en_8 = 0;
		APP_G1_wr_en_9 = 0;
		APP_G1_wr_en_10 = 0;
		APP_G1_wr_en_11 = 0;
		APP_G1_wr_en_12 = 0;
		APP_G1_wr_en_13 = 0;
		APP_G1_wr_en_14 = 0;
		APP_G1_wr_en_15 = 0;
		APP_G1_wr_en_16 = 0;
		APP_G1_wr_en_17 = 0;
		APP_G1_wr_en_18 = 0;
		APP_G1_wr_en_19 = 0;
		APP_G1_wr_en_20 = 0;
		APP_G1_wr_en_21 = 0;
		APP_G1_wr_en_22 = 0;
		APP_G1_wr_en_23 = 0;
		APP_G1_wr_en_24 = 0;
		APP_G1_wr_en_25 = 0;
		APP_G1_wr_en_26 = 0;
	end
end

// write address of APPRam G0
// during initializing, all APPRams' write address is APPmsg_ini_addr
always @(*)
begin
	if(buffer_valid_D0 && group_to_buffer == 0)  //刚开始写入，从0到 APPmsg_addr_max
	begin
		APP_G0_addr_wr_0 = APPmsg_ini_addr_D0_C0;
		APP_G0_addr_wr_1 = APPmsg_ini_addr_D0_C1;
		APP_G0_addr_wr_2 = APPmsg_ini_addr_D0_C2;
		APP_G0_addr_wr_3 = APPmsg_ini_addr_D0_C3;
		APP_G0_addr_wr_4 = APPmsg_ini_addr_D0_C4;
		APP_G0_addr_wr_5 = APPmsg_ini_addr_D0_C5;
		APP_G0_addr_wr_6 = APPmsg_ini_addr_D0_C6;
		APP_G0_addr_wr_7 = APPmsg_ini_addr_D0_C7;
		APP_G0_addr_wr_8 = APPmsg_ini_addr_D0_C8;
		APP_G0_addr_wr_9 = APPmsg_ini_addr_D0_C9;
		APP_G0_addr_wr_10 = APPmsg_ini_addr_D0_C10;
		APP_G0_addr_wr_11 = APPmsg_ini_addr_D0_C11;
		APP_G0_addr_wr_12 = APPmsg_ini_addr_D0_C12;
		APP_G0_addr_wr_13 = APPmsg_ini_addr_D0_C13;
		APP_G0_addr_wr_14 = APPmsg_ini_addr_D0_C14;
		APP_G0_addr_wr_15 = APPmsg_ini_addr_D0_C15;
		APP_G0_addr_wr_16 = APPmsg_ini_addr_D0_C16;
		APP_G0_addr_wr_17 = APPmsg_ini_addr_D0_C17;
		APP_G0_addr_wr_18 = APPmsg_ini_addr_D0_C18;
		APP_G0_addr_wr_19 = APPmsg_ini_addr_D0_C19;
		APP_G0_addr_wr_20 = APPmsg_ini_addr_D0_C20;
		APP_G0_addr_wr_21 = APPmsg_ini_addr_D0_C21;
		APP_G0_addr_wr_22 = APPmsg_ini_addr_D0_C22;
		APP_G0_addr_wr_23 = APPmsg_ini_addr_D0_C23;
		APP_G0_addr_wr_24 = APPmsg_ini_addr_D0_C24;
		APP_G0_addr_wr_25 = APPmsg_ini_addr_D0_C25;
		APP_G0_addr_wr_26 = APPmsg_ini_addr_D0_C26_all;
	end
	else
	begin                                      //更新时，从第一行为1的列开始写
		APP_G0_addr_wr_0 = APP_addr_wr_0;
		APP_G0_addr_wr_1 = APP_addr_wr_1;
		APP_G0_addr_wr_2 = APP_addr_wr_2;
		APP_G0_addr_wr_3 = APP_addr_wr_3;
		APP_G0_addr_wr_4 = APP_addr_wr_4;
		APP_G0_addr_wr_5 = APP_addr_wr_5;
		APP_G0_addr_wr_6 = APP_addr_wr_6;
		APP_G0_addr_wr_7 = APP_addr_wr_7;
		APP_G0_addr_wr_8 = APP_addr_wr_8;
		APP_G0_addr_wr_9 = APP_addr_wr_9;
		APP_G0_addr_wr_10 = APP_addr_wr_10;
		APP_G0_addr_wr_11 = APP_addr_wr_11;
		APP_G0_addr_wr_12 = APP_addr_wr_12;
		APP_G0_addr_wr_13 = APP_addr_wr_13;
		APP_G0_addr_wr_14 = APP_addr_wr_14;
		APP_G0_addr_wr_15 = APP_addr_wr_15;
		APP_G0_addr_wr_16 = APP_addr_wr_16;
		APP_G0_addr_wr_17 = APP_addr_wr_17;
		APP_G0_addr_wr_18 = APP_addr_wr_18;
		APP_G0_addr_wr_19 = APP_addr_wr_19;
		APP_G0_addr_wr_20 = APP_addr_wr_20;
		APP_G0_addr_wr_21 = APP_addr_wr_21;
		APP_G0_addr_wr_22 = APP_addr_wr_22;
		APP_G0_addr_wr_23 = APP_addr_wr_23;
		APP_G0_addr_wr_24 = APP_addr_wr_24;
		APP_G0_addr_wr_25 = APP_addr_wr_25;
		APP_G0_addr_wr_26 = APP_addr_wr_26;
	end
end
// write address of APPRam G1
always @(*)
begin
	if(buffer_valid_D0 && group_to_buffer == 1)
	begin
		APP_G1_addr_wr_0 = APPmsg_ini_addr_D0_C0;
		APP_G1_addr_wr_1 = APPmsg_ini_addr_D0_C1;
		APP_G1_addr_wr_2 = APPmsg_ini_addr_D0_C2;
		APP_G1_addr_wr_3 = APPmsg_ini_addr_D0_C3;
		APP_G1_addr_wr_4 = APPmsg_ini_addr_D0_C4;
		APP_G1_addr_wr_5 = APPmsg_ini_addr_D0_C5;
		APP_G1_addr_wr_6 = APPmsg_ini_addr_D0_C6;
		APP_G1_addr_wr_7 = APPmsg_ini_addr_D0_C7;
		APP_G1_addr_wr_8 = APPmsg_ini_addr_D0_C8;
		APP_G1_addr_wr_9 = APPmsg_ini_addr_D0_C9;
		APP_G1_addr_wr_10 = APPmsg_ini_addr_D0_C10;
		APP_G1_addr_wr_11 = APPmsg_ini_addr_D0_C11;
		APP_G1_addr_wr_12 = APPmsg_ini_addr_D0_C12;
		APP_G1_addr_wr_13 = APPmsg_ini_addr_D0_C13;
		APP_G1_addr_wr_14 = APPmsg_ini_addr_D0_C14;
		APP_G1_addr_wr_15 = APPmsg_ini_addr_D0_C15;
		APP_G1_addr_wr_16 = APPmsg_ini_addr_D0_C16;
		APP_G1_addr_wr_17 = APPmsg_ini_addr_D0_C17;
		APP_G1_addr_wr_18 = APPmsg_ini_addr_D0_C18;
		APP_G1_addr_wr_19 = APPmsg_ini_addr_D0_C19;
		APP_G1_addr_wr_20 = APPmsg_ini_addr_D0_C20;
		APP_G1_addr_wr_21 = APPmsg_ini_addr_D0_C21;
		APP_G1_addr_wr_22 = APPmsg_ini_addr_D0_C22;
		APP_G1_addr_wr_23 = APPmsg_ini_addr_D0_C23;
		APP_G1_addr_wr_24 = APPmsg_ini_addr_D0_C24;
		APP_G1_addr_wr_25 = APPmsg_ini_addr_D0_C25;
		APP_G1_addr_wr_26 = APPmsg_ini_addr_D0_C26_all;
	end
	else
	begin
		APP_G1_addr_wr_0 = APP_addr_wr_0;
		APP_G1_addr_wr_1 = APP_addr_wr_1;
		APP_G1_addr_wr_2 = APP_addr_wr_2;
		APP_G1_addr_wr_3 = APP_addr_wr_3;
		APP_G1_addr_wr_4 = APP_addr_wr_4;
		APP_G1_addr_wr_5 = APP_addr_wr_5;
		APP_G1_addr_wr_6 = APP_addr_wr_6;
		APP_G1_addr_wr_7 = APP_addr_wr_7;
		APP_G1_addr_wr_8 = APP_addr_wr_8;
		APP_G1_addr_wr_9 = APP_addr_wr_9;
		APP_G1_addr_wr_10 = APP_addr_wr_10;
		APP_G1_addr_wr_11 = APP_addr_wr_11;
		APP_G1_addr_wr_12 = APP_addr_wr_12;
		APP_G1_addr_wr_13 = APP_addr_wr_13;
		APP_G1_addr_wr_14 = APP_addr_wr_14;
		APP_G1_addr_wr_15 = APP_addr_wr_15;
		APP_G1_addr_wr_16 = APP_addr_wr_16;
		APP_G1_addr_wr_17 = APP_addr_wr_17;
		APP_G1_addr_wr_18 = APP_addr_wr_18;
		APP_G1_addr_wr_19 = APP_addr_wr_19;
		APP_G1_addr_wr_20 = APP_addr_wr_20;
		APP_G1_addr_wr_21 = APP_addr_wr_21;
		APP_G1_addr_wr_22 = APP_addr_wr_22;
		APP_G1_addr_wr_23 = APP_addr_wr_23;
		APP_G1_addr_wr_24 = APP_addr_wr_24;
		APP_G1_addr_wr_25 = APP_addr_wr_25;
		APP_G1_addr_wr_26 = APP_addr_wr_26;
	end
end

// write data of APPRam G0
// during initializing, all APPRams' write data is generated by get_msgini (except the 1st 2 Rams)
assign APPmsg_ini_data_subx_7_or_APPmsg_ini_data_subx_all = (APPmsg_ini_sub_x_D0 == 2'd3) ? APPmsg_ini_data_subx_all:APPmsg_ini_data_subx_7;
wire [2:0] mod8;

assign mod8 = (group_to_buffer == 0) ? 
              ((APPmsg_ini_sub_x_D0 == 2'd3) ? ((APPmsg_ini_addr_D0_C26 - 16) % 8) : 0) :
              ((APPmsg_ini_sub_x_D0 == 2'd3) ? ((APPmsg_ini_addr_D0_C26 - 16) % 8) : 0);

assign APPmsg_ini_data_subx_all =   (mod8 == 3'd0) ? APPmsg_ini_data_subx_0 : //对8取余，就是第三位
									(mod8 == 3'd1) ? APPmsg_ini_data_subx_1 :
									(mod8 == 3'd2) ? APPmsg_ini_data_subx_2 :
									(mod8 == 3'd3) ? APPmsg_ini_data_subx_3 :
									(mod8 == 3'd4) ? APPmsg_ini_data_subx_4 :
									(mod8 == 3'd5) ? APPmsg_ini_data_subx_5 :
									(mod8 == 3'd6) ? APPmsg_ini_data_subx_6 : APPmsg_ini_data_subx_7;


assign APPmsg_ini_addr_D0_C26_all = (APPmsg_ini_sub_x_D0 == 2'd3) ? 16 + (APPmsg_ini_addr_D0_C26 - 8'd16)/8 + ((APPmsg_ini_addr_D0_C26 - 8'd16) % 8) * 16 : APPmsg_ini_addr_D0_C26; //在输入第四段时+8加，在输入第三段时+1加

always @(*) //写入接口 APP
begin
	if(buffer_valid_D0 && group_to_buffer == 0) //写入buffer时
	begin
		APPmsg_G0_in_0 = 0;
		APPmsg_G0_in_1 = 0;
		APPmsg_G0_in_2 = APPmsg_ini_data_subx_0;
		APPmsg_G0_in_3 = APPmsg_ini_data_subx_1;
		APPmsg_G0_in_4 = APPmsg_ini_data_subx_2;
		APPmsg_G0_in_5 = APPmsg_ini_data_subx_3;
		APPmsg_G0_in_6 = APPmsg_ini_data_subx_4;
		APPmsg_G0_in_7 = APPmsg_ini_data_subx_5;
		APPmsg_G0_in_8 = APPmsg_ini_data_subx_6;
		APPmsg_G0_in_9 = APPmsg_ini_data_subx_7;

		APPmsg_G0_in_10 = APPmsg_ini_data_subx_0;
		APPmsg_G0_in_11 = APPmsg_ini_data_subx_1;
		APPmsg_G0_in_12 = APPmsg_ini_data_subx_2;
		APPmsg_G0_in_13 = APPmsg_ini_data_subx_3;
		APPmsg_G0_in_14 = APPmsg_ini_data_subx_4;
		APPmsg_G0_in_15 = APPmsg_ini_data_subx_5;
		APPmsg_G0_in_16 = APPmsg_ini_data_subx_6;
		APPmsg_G0_in_17 = APPmsg_ini_data_subx_7;

		APPmsg_G0_in_18 = APPmsg_ini_data_subx_0;
		APPmsg_G0_in_19 = APPmsg_ini_data_subx_1;
		APPmsg_G0_in_20 = APPmsg_ini_data_subx_2;
		APPmsg_G0_in_21 = {`inNum{6'd31}};  //置为大LLR
		APPmsg_G0_in_22 = APPmsg_ini_data_subx_3;
		APPmsg_G0_in_23 = APPmsg_ini_data_subx_4;
		APPmsg_G0_in_24 = APPmsg_ini_data_subx_5;
		APPmsg_G0_in_25 = APPmsg_ini_data_subx_6;
		APPmsg_G0_in_26 = APPmsg_ini_data_subx_7_or_APPmsg_ini_data_subx_all; 
	end
	else             //更新buffer时
	begin 
		APPmsg_G0_in_0 = APPmsg_new_0;
		APPmsg_G0_in_1 = APPmsg_new_1;
		APPmsg_G0_in_2 = APPmsg_new_2;
		APPmsg_G0_in_3 = APPmsg_new_3;
		APPmsg_G0_in_4 = APPmsg_new_4;
		APPmsg_G0_in_5 = APPmsg_new_5;
		APPmsg_G0_in_6 = APPmsg_new_6;
		APPmsg_G0_in_7 = APPmsg_new_7;
		APPmsg_G0_in_8 = APPmsg_new_8;
		APPmsg_G0_in_9 = APPmsg_new_9;
		APPmsg_G0_in_10 = APPmsg_new_10;
		APPmsg_G0_in_11 = APPmsg_new_11;
		APPmsg_G0_in_12 = APPmsg_new_12;
		APPmsg_G0_in_13 = APPmsg_new_13;
		APPmsg_G0_in_14 = APPmsg_new_14;
		APPmsg_G0_in_15 = APPmsg_new_15;
		APPmsg_G0_in_16 = APPmsg_new_16;	
		APPmsg_G0_in_17 = APPmsg_new_17;
		APPmsg_G0_in_18 = APPmsg_new_18;
		APPmsg_G0_in_19 = APPmsg_new_19;
		APPmsg_G0_in_20 = APPmsg_new_20;
		APPmsg_G0_in_21 = APPmsg_new_21; //更新
		APPmsg_G0_in_22 = APPmsg_new_22;
		APPmsg_G0_in_23 = APPmsg_new_23;
		APPmsg_G0_in_24 = APPmsg_new_24;
		APPmsg_G0_in_25 = APPmsg_new_25;
		APPmsg_G0_in_26 = APPmsg_new_26;
	end
end
// write data of APPRam G1
always @(*)  //写入接口 APP
begin
	if(buffer_valid_D0 && group_to_buffer == 1)
	begin
		APPmsg_G1_in_0 = 0;
		APPmsg_G1_in_1 = 0;
		APPmsg_G1_in_2 = APPmsg_ini_data_subx_0;
		APPmsg_G1_in_3 = APPmsg_ini_data_subx_1;
		APPmsg_G1_in_4 = APPmsg_ini_data_subx_2;
		APPmsg_G1_in_5 = APPmsg_ini_data_subx_3;
		APPmsg_G1_in_6 = APPmsg_ini_data_subx_4;
		APPmsg_G1_in_7 = APPmsg_ini_data_subx_5;
		APPmsg_G1_in_8 = APPmsg_ini_data_subx_6;
		APPmsg_G1_in_9 = APPmsg_ini_data_subx_7;

		APPmsg_G1_in_10 = APPmsg_ini_data_subx_0;
		APPmsg_G1_in_11 = APPmsg_ini_data_subx_1;
		APPmsg_G1_in_12 = APPmsg_ini_data_subx_2;
		APPmsg_G1_in_13 = APPmsg_ini_data_subx_3;
		APPmsg_G1_in_14 = APPmsg_ini_data_subx_4;
		APPmsg_G1_in_15 = APPmsg_ini_data_subx_5;
		APPmsg_G1_in_16 = APPmsg_ini_data_subx_6;
		APPmsg_G1_in_17 = APPmsg_ini_data_subx_7;

		APPmsg_G1_in_18 = APPmsg_ini_data_subx_0;
		APPmsg_G1_in_19 = APPmsg_ini_data_subx_1;
		APPmsg_G1_in_20 = APPmsg_ini_data_subx_2;
		APPmsg_G1_in_21 =  {`inNum{6'd31}}; 
		APPmsg_G1_in_22 = APPmsg_ini_data_subx_3;
		APPmsg_G1_in_23 = APPmsg_ini_data_subx_4;
		APPmsg_G1_in_24 = APPmsg_ini_data_subx_5;
		APPmsg_G1_in_25 = APPmsg_ini_data_subx_6;
		APPmsg_G1_in_26 = APPmsg_ini_data_subx_7_or_APPmsg_ini_data_subx_all;
	end
	else
	begin
		APPmsg_G1_in_0 = APPmsg_new_0;
		APPmsg_G1_in_1 = APPmsg_new_1;
		APPmsg_G1_in_2 = APPmsg_new_2;
		APPmsg_G1_in_3 = APPmsg_new_3;
		APPmsg_G1_in_4 = APPmsg_new_4;
		APPmsg_G1_in_5 = APPmsg_new_5;
		APPmsg_G1_in_6 = APPmsg_new_6;
		APPmsg_G1_in_7 = APPmsg_new_7;
		APPmsg_G1_in_8 = APPmsg_new_8;
		APPmsg_G1_in_9 = APPmsg_new_9;
		APPmsg_G1_in_10 = APPmsg_new_10;
		APPmsg_G1_in_11 = APPmsg_new_11;
		APPmsg_G1_in_12 = APPmsg_new_12;
		APPmsg_G1_in_13 = APPmsg_new_13;
		APPmsg_G1_in_14 = APPmsg_new_14;
		APPmsg_G1_in_15 = APPmsg_new_15;
		APPmsg_G1_in_16 = APPmsg_new_16;	
		APPmsg_G1_in_17 = APPmsg_new_17;
		APPmsg_G1_in_18 = APPmsg_new_18;
		APPmsg_G1_in_19 = APPmsg_new_19;
		APPmsg_G1_in_20 = APPmsg_new_20;
		APPmsg_G1_in_21 = APPmsg_new_21;
		APPmsg_G1_in_22 = APPmsg_new_22;
		APPmsg_G1_in_23 = APPmsg_new_23;
		APPmsg_G1_in_24 = APPmsg_new_24;
		APPmsg_G1_in_25 = APPmsg_new_25;
		APPmsg_G1_in_26 = APPmsg_new_26;
	end
end

// =============================================================================
 // Buffer 阶段 - 时序逻辑（地址/有效同步）
 // - 输入握手：buffer_valid / buffer_start / buffer_last 同步到 D0；
 // - 地址自增：APPmsg_ini_addr / APP_wr_en_cnt；
 // - 结束标志：buffer_end 在 buffer_last 后 1 拍拉高，用于翻转 group_to_buffer 并触发 DECODE。
 // =============================================================================
// APPmsg_ini_addr increases when buffer_valid is high 写入地址从0累加
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C0 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C0 == APP_addr_rd_max)
			APPmsg_ini_addr_C0 <= 0;
		else
			APPmsg_ini_addr_C0 <= APPmsg_ini_addr_C0 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C0 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C1 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C1 == APP_addr_rd_max)
			APPmsg_ini_addr_C1 <= 0;
		else
			APPmsg_ini_addr_C1 <= APPmsg_ini_addr_C1 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C1 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C2 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C2 == APP_addr_rd_max)
			APPmsg_ini_addr_C2 <= 0;
		else
			APPmsg_ini_addr_C2 <= APPmsg_ini_addr_C2 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C2 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C3 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C3 == APP_addr_rd_max)
			APPmsg_ini_addr_C3 <= 0;
		else
			APPmsg_ini_addr_C3 <= APPmsg_ini_addr_C3 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C3 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C4 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C4 == APP_addr_rd_max)
			APPmsg_ini_addr_C4 <= 0;
		else
			APPmsg_ini_addr_C4 <= APPmsg_ini_addr_C4 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C4 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C5 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C5 == APP_addr_rd_max)
			APPmsg_ini_addr_C5 <= 0;
		else
			APPmsg_ini_addr_C5 <= APPmsg_ini_addr_C5 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C5 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C6 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C6 == APP_addr_rd_max)
			APPmsg_ini_addr_C6 <= 0;
		else
			APPmsg_ini_addr_C6 <= APPmsg_ini_addr_C6 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C6 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C7 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C7 == APP_addr_rd_max)
			APPmsg_ini_addr_C7 <= 0;
		else
			APPmsg_ini_addr_C7 <= APPmsg_ini_addr_C7 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C7 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C8 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C8 == APP_addr_rd_max)
			APPmsg_ini_addr_C8 <= 0;
		else
			APPmsg_ini_addr_C8 <= APPmsg_ini_addr_C8 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C8 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C9 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C9 == APP_addr_rd_max)
			APPmsg_ini_addr_C9 <= 0;
		else
			APPmsg_ini_addr_C9 <= APPmsg_ini_addr_C9 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C9 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C10 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C10 == APP_addr_rd_max)
			APPmsg_ini_addr_C10 <= 0;
		else
			APPmsg_ini_addr_C10 <= APPmsg_ini_addr_C10 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C10 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C11 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C11 == APP_addr_rd_max)
			APPmsg_ini_addr_C11 <= 0;
		else
			APPmsg_ini_addr_C11 <= APPmsg_ini_addr_C11 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C11 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C12 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C12 == APP_addr_rd_max)
			APPmsg_ini_addr_C12 <= 0;
		else
			APPmsg_ini_addr_C12 <= APPmsg_ini_addr_C12 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C12 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C13 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C13 == APP_addr_rd_max)
			APPmsg_ini_addr_C13 <= 0;
		else
			APPmsg_ini_addr_C13 <= APPmsg_ini_addr_C13 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C13 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C14 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C14 == APP_addr_rd_max)
			APPmsg_ini_addr_C14 <= 0;
		else
			APPmsg_ini_addr_C14 <= APPmsg_ini_addr_C14 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C14 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C15 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C15 == APP_addr_rd_max)
			APPmsg_ini_addr_C15 <= 0;
		else
			APPmsg_ini_addr_C15 <= APPmsg_ini_addr_C15 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C15 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C16 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C16 == APP_addr_rd_max)
			APPmsg_ini_addr_C16 <= 0;
		else
			APPmsg_ini_addr_C16 <= APPmsg_ini_addr_C16 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C16 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C17 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C17 == APP_addr_rd_max)
			APPmsg_ini_addr_C17 <= 0;
		else
			APPmsg_ini_addr_C17 <= APPmsg_ini_addr_C17 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C17 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C18 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C18 == APP_addr_rd_max)
			APPmsg_ini_addr_C18 <= 0;
		else
			APPmsg_ini_addr_C18 <= APPmsg_ini_addr_C18 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C18 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C19 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C19 == APP_addr_rd_max)
			APPmsg_ini_addr_C19 <= 0;
		else
			APPmsg_ini_addr_C19 <= APPmsg_ini_addr_C19 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C19 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C20 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C20 == APP_addr_rd_max)
			APPmsg_ini_addr_C20 <= 0;
		else
			APPmsg_ini_addr_C20 <= APPmsg_ini_addr_C20 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C20 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C21 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C21 == APP_addr_rd_max)
			APPmsg_ini_addr_C21 <= 0;
		else
			APPmsg_ini_addr_C21 <= APPmsg_ini_addr_C21 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C21 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C22 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C22 == APP_addr_rd_max)
			APPmsg_ini_addr_C22 <= 0;
		else
			APPmsg_ini_addr_C22 <= APPmsg_ini_addr_C22 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C22 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C23 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C23 == APP_addr_rd_max)
			APPmsg_ini_addr_C23 <= 0;
		else
			APPmsg_ini_addr_C23 <= APPmsg_ini_addr_C23 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C23 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C24 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C24 == APP_addr_rd_max)
			APPmsg_ini_addr_C24 <= 0;
		else
			APPmsg_ini_addr_C24 <= APPmsg_ini_addr_C24 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C24 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_C25 <= 0;
	end
	else if(buffer_valid)
	begin
		if(APPmsg_ini_addr_C25 == APP_addr_rd_max)
			APPmsg_ini_addr_C25 <= 0;
		else
			APPmsg_ini_addr_C25 <= APPmsg_ini_addr_C25 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_C25 <= 0;
	end
end

// APPmsg_ini_addr_D0_Cx are 26 copies of 1 clk delayed version of APPmsg_ini_addr
always @(posedge clk or negedge rst_n) // 		初始送入APP 位置信号 APPmsg_ini_addr_D0_C0 <= APPmsg_ini_addr; APPmsg_ini_addr_D0_C1 <= APPmsg_ini_addr;的接线 从零开始累加
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_D0_C0 <= 0;
		APPmsg_ini_addr_D0_C1 <= 0;
		APPmsg_ini_addr_D0_C2 <= 0;
		APPmsg_ini_addr_D0_C3 <= 0;
		APPmsg_ini_addr_D0_C4 <= 0;
		APPmsg_ini_addr_D0_C5 <= 0;
		APPmsg_ini_addr_D0_C6 <= 0;
		APPmsg_ini_addr_D0_C7 <= 0;
		APPmsg_ini_addr_D0_C8 <= 0;
		APPmsg_ini_addr_D0_C9 <= 0;
		APPmsg_ini_addr_D0_C10 <= 0;
		APPmsg_ini_addr_D0_C11 <= 0;
		APPmsg_ini_addr_D0_C12 <= 0;
		APPmsg_ini_addr_D0_C13 <= 0;
		APPmsg_ini_addr_D0_C14 <= 0;
		APPmsg_ini_addr_D0_C15 <= 0;
		APPmsg_ini_addr_D0_C16 <= 0;
		APPmsg_ini_addr_D0_C17 <= 0;
		APPmsg_ini_addr_D0_C18 <= 0;
		APPmsg_ini_addr_D0_C19 <= 0;
		APPmsg_ini_addr_D0_C20 <= 0;
		APPmsg_ini_addr_D0_C21 <= 0;
		APPmsg_ini_addr_D0_C22 <= 0;
		APPmsg_ini_addr_D0_C23 <= 0;
		APPmsg_ini_addr_D0_C24 <= 0;
		APPmsg_ini_addr_D0_C25 <= 0;
		APPmsg_ini_addr_D0_C26 <= 0;
	end
	else
	begin
		APPmsg_ini_addr_D0_C0 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C1 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C2 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C3 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C4 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C5 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C6 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C7 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C8 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C9 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C10 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C11 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C12 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C13 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C14 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C15 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C16 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C17 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C18 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C19 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C20 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C21 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C22 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C23 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C24 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C25 <= APPmsg_ini_addr;
		APPmsg_ini_addr_D0_C26 <= APPmsg_ini_addr_26;
	end
end

// always @(posedge clk or negedge rst_n) //初始送入APP 信号 地址计数
// begin
// 	if(!rst_n)
// 	begin
// 		APPmsg_ini_addr <= 0;
// 	end
// 	else if(buffer_valid)
// 	begin
// 		if(APPmsg_ini_addr == APP_addr_rd_max)
// 			APPmsg_ini_addr <= 0;
// 		else
// 			APPmsg_ini_addr <= APPmsg_ini_addr + 1'b1;
// 	end
// 	else
// 	begin
// 		APPmsg_ini_addr <= 0;
// 	end
// end

reg [2:0] eight_clk_cnt; // 用于八拍计数
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) begin
        APPmsg_ini_addr <= 0;
        eight_clk_cnt <= 0;
    end
    else if (buffer_valid) begin
        if (APPmsg_ini_sub_x == 3) begin
            // 八拍计数逻辑
            if (eight_clk_cnt == 7) begin
                eight_clk_cnt <= 0;
                if (APPmsg_ini_addr == APP_addr_rd_max)
                    APPmsg_ini_addr <= 0;
                else
                    APPmsg_ini_addr <= APPmsg_ini_addr + 1'b1;
            end
            else begin
                eight_clk_cnt <= eight_clk_cnt + 1'b1;
            end
        end
        else begin
            // 正常每拍加一
            eight_clk_cnt <= 0; // 重置八拍计数器
            if (APPmsg_ini_addr == APP_addr_rd_max)
                APPmsg_ini_addr <= 0;
            else
                APPmsg_ini_addr <= APPmsg_ini_addr + 1'b1;
        end
    end
    else begin
        APPmsg_ini_addr <= 0;
        eight_clk_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) //初始送入APP 信号 地址计数
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_26 <= 0;
	end
	else if(buffer_valid && (APPmsg_ini_sub_x == 2'd3 || APPmsg_ini_sub_x == 2'd2))
	begin
		if(APPmsg_ini_addr_26 == 8'd143) //+16*9 -1
			APPmsg_ini_addr_26 <= 0;
		else
			APPmsg_ini_addr_26 <= APPmsg_ini_addr_26 + 1'b1;
	end
	else
	begin
		APPmsg_ini_addr_26 <= 0;
	end
end


always @(posedge clk or negedge rst_n) //目前没用到
begin
	if(!rst_n)
	begin
		APPmsg_ini_addr_D0 <= 0;
	end
	else
	begin
		APPmsg_ini_addr_D0 <= APPmsg_ini_addr;
	end
end



always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_valid_D0 <= 0;
	end
	else
	begin
		buffer_valid_D0 <= buffer_valid;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_sub_x_D0 <= 0;
	end
	else
	begin
		APPmsg_ini_sub_x_D0 <= APPmsg_ini_sub_x;
	end
end

// =============================================================================
 // Buffer 相关子模块/接口
 // - APPRam(G0/G1) 的端口定义与实例化；
 // - 初始 APP 数据打片与拼接（APPmsg_ini_data_subx_*）；
 // - 与后端译码路径的隔离：Buffer 只写当前选择组，不读。
 // =============================================================================
// get_msgini: replace the input data to be written into APPRams
get_msgini u0_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_0),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_0)
);
get_msgini u1_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_1),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_1)
);
get_msgini u2_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_2),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_2)
);
get_msgini u3_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_3),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_3)
);
get_msgini u4_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_4),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_4)
);
get_msgini u5_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_5),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_5)
);

get_msgini u6_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_6),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_6)
);

get_msgini u7_get_msgini(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_ini_subx_7),
	.addr_in(APPmsg_ini_addr),
	.en_in(buffer_valid),
	.data_out(APPmsg_ini_data_subx_7)
);


// =============================================================================
 // Decode 阶段 - 组合逻辑（数据路径）
 // - HROM：给出每层每行的移位/拓扑 `shift_*`（最高位为屏蔽标志，低位为循环移位量）；
 // - QSN：计算校验节点消息（c_reg_* / c_*）；
 // - DPU：按层聚合与阈值/和/最小值等运算（DN_APPmsg_* / DPU_APPmsg_* / signAPP_*）；
 // - GN ：更新变量节点 APP（GN_APPmsg_*），并决定是否写回；
 // - CTV：缓存/复用中间软信息（CTV_old_* / CTV_new_* / APP_CTV_*）。
 // =============================================================================
// APPmsg_old_x is switched between APPmsg_G0_out_x and APPmsg_G1_out_x by group_to_decode
assign APPmsg_old_0 = group_to_decode_C0?APPmsg_G1_out_0:APPmsg_G0_out_0;
assign APPmsg_old_1 = group_to_decode_C1?APPmsg_G1_out_1:APPmsg_G0_out_1;
assign APPmsg_old_2 = group_to_decode_C2?APPmsg_G1_out_2:APPmsg_G0_out_2;
assign APPmsg_old_3 = group_to_decode_C3?APPmsg_G1_out_3:APPmsg_G0_out_3;
assign APPmsg_old_4 = group_to_decode_C4?APPmsg_G1_out_4:APPmsg_G0_out_4;
assign APPmsg_old_5 = group_to_decode_C5?APPmsg_G1_out_5:APPmsg_G0_out_5;
assign APPmsg_old_6 = group_to_decode_C6?APPmsg_G1_out_6:APPmsg_G0_out_6;
assign APPmsg_old_7 = group_to_decode_C7?APPmsg_G1_out_7:APPmsg_G0_out_7;
assign APPmsg_old_8 = group_to_decode_C8?APPmsg_G1_out_8:APPmsg_G0_out_8;
assign APPmsg_old_9 = group_to_decode_C9?APPmsg_G1_out_9:APPmsg_G0_out_9;
assign APPmsg_old_10 = group_to_decode_C10?APPmsg_G1_out_10:APPmsg_G0_out_10;
assign APPmsg_old_11 = group_to_decode_C11?APPmsg_G1_out_11:APPmsg_G0_out_11;
assign APPmsg_old_12 = group_to_decode_C12?APPmsg_G1_out_12:APPmsg_G0_out_12;
assign APPmsg_old_13 = group_to_decode_C13?APPmsg_G1_out_13:APPmsg_G0_out_13;
assign APPmsg_old_14 = group_to_decode_C14?APPmsg_G1_out_14:APPmsg_G0_out_14;
assign APPmsg_old_15 = group_to_decode_C15?APPmsg_G1_out_15:APPmsg_G0_out_15;
assign APPmsg_old_16 = group_to_decode_C16?APPmsg_G1_out_16:APPmsg_G0_out_16;
assign APPmsg_old_17 = group_to_decode_C17?APPmsg_G1_out_17:APPmsg_G0_out_17;
assign APPmsg_old_18 = group_to_decode_C18?APPmsg_G1_out_18:APPmsg_G0_out_18;
assign APPmsg_old_19 = group_to_decode_C19?APPmsg_G1_out_19:APPmsg_G0_out_19;
assign APPmsg_old_20 = group_to_decode_C20?APPmsg_G1_out_20:APPmsg_G0_out_20;
assign APPmsg_old_21 = group_to_decode_C21?APPmsg_G1_out_21:APPmsg_G0_out_21;
assign APPmsg_old_22 = group_to_decode_C22?APPmsg_G1_out_22:APPmsg_G0_out_22;
assign APPmsg_old_23 = group_to_decode_C23?APPmsg_G1_out_23:APPmsg_G0_out_23;
assign APPmsg_old_24 = group_to_decode_C24?APPmsg_G1_out_24:APPmsg_G0_out_24;
assign APPmsg_old_25 = group_to_decode_C25?APPmsg_G1_out_25:APPmsg_G0_out_25;
assign APPmsg_old_26 = group_to_decode_C26?APPmsg_G1_out_26:APPmsg_G0_out_26;

// APPmsg_decode_out is the concat of APP_dec_out_0~APP_dec_out_21
assign APPmsg_decode_out = {APP_dec_out_21,APP_dec_out_20,APP_dec_out_19,APP_dec_out_18,APP_dec_out_17,APP_dec_out_16,APP_dec_out_15,APP_dec_out_14,APP_dec_out_13,APP_dec_out_12,APP_dec_out_11,APP_dec_out_10,APP_dec_out_9,APP_dec_out_8,APP_dec_out_7,APP_dec_out_6,APP_dec_out_5,APP_dec_out_4,APP_dec_out_3,APP_dec_out_2,APP_dec_out_1,APP_dec_out_0};
// assign APPmsg_decode_out = {~APP_dec_out_21,~APP_dec_out_20,~APP_dec_out_19,~APP_dec_out_18,~APP_dec_out_17,~APP_dec_out_16,~APP_dec_out_15,~APP_dec_out_14,~APP_dec_out_13,~APP_dec_out_12,~APP_dec_out_11,~APP_dec_out_10,~APP_dec_out_9,~APP_dec_out_8,~APP_dec_out_7,~APP_dec_out_6,~APP_dec_out_5,~APP_dec_out_4,~APP_dec_out_3,~APP_dec_out_2,~APP_dec_out_1,~APP_dec_out_0};

// =============================================================================
 // Decode 阶段 - 时序逻辑（推进与结束）
 // - iter_start/iter_end：迭代粒度控制（基于 Layernum/totalLayernum）；
 // - update_start/update_end：层粒度控制（基于 HROM 输出的每层行数/移位）；
 // - APP_addr_rd_end：一次 APP 遍历完成；
 // - decode_out_start / decode_valid / decode_valid_cnt：输出触发与统计；
 // - decode_end：对 decode_valid 延后一拍，驱动组翻转与状态跳转。
 // =============================================================================
// iternum is the iteration number
always @(posedge clk or negedge rst_n) //layernum和iternum 分别控制 迭代次数计数
begin
	if(!rst_n)begin
		iternum <= 0;
	end
	else if(decode_end)
	begin
		iternum <= 0;
	end
	else if(iter_end && (~iter_start))begin
		iternum <= iternum + 1;
	end
	else
	begin
		iternum <= iternum;
	end
end

// iter_start is high on the 1st clk of each iteration
always @(posedge clk or negedge rst_n) // iter_start 每次迭代第一拍才为1
begin
	if(!rst_n)
		iter_start <= 1'b0;
	else if(decode_start)
		iter_start <= 1'b1;
	else if(iter_end && iternum < `maxIterNum-1)
		iter_start <= 1'b1;
	else
		iter_start <= 0;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		iter_start_D0 <= 0;
		iter_start_D1 <= 0;
		iter_start_D2 <= 0;
		iter_start_D3 <= 0;
	end
	else begin
		iter_start_D0 <= iter_start;
		iter_start_D1 <= iter_start_D0;
		iter_start_D2 <= iter_start_D1;
		iter_start_D3 <= iter_start_D2;
	end
end

// first_iter_valid is high during the 1st iteration
always @(posedge clk or negedge rst_n) // first_iter_valid 第一次迭代为1
begin
	if(!rst_n)
		first_iter_valid <= 1'b0;
	else if(decode_start)
		first_iter_valid <= 1'b1;
	else if(iter_end)
		first_iter_valid <= 1'b0;
	else
		first_iter_valid <= first_iter_valid;
end

// decode_out_start is high 1 clk behind the end of the last iteration
always @(posedge clk or negedge rst_n) //decode_out_start 迭代完成 可以输出
begin
	if(!rst_n)
		decode_out_start <= 1'b0;
	else if(iter_end && iternum == `maxIterNum-1)
		decode_out_start <= 1'b1;
	else
		decode_out_start <= 1'b0;
end

// decode_valid is high when APPmsg_decode_out is valid (2 clk delay due to RAM read latency and 1 clk delay due to get_msgfin)
always @(posedge clk or negedge rst_n) //APP_addr_rd_end 读到头了
begin
	if(!rst_n)
		APP_addr_rd_end <= 1'b0;
	else if(APP_addr_rd_0 == APP_addr_rd_max && iternum == `maxIterNum)
		APP_addr_rd_end <= 1'b1;
	else
		APP_addr_rd_end <= 1'b0;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APP_addr_rd_end_D0 <= 1'b0;
		APP_addr_rd_end_D1 <= 1'b0;
		decode_valid <= 1'b0;
	end
	else
	begin
		APP_addr_rd_end_D0 <= APP_addr_rd_end;
		APP_addr_rd_end_D1 <= APP_addr_rd_end_D0;
		decode_valid <= APP_addr_rd_end_D1; //D 表示delay两拍
	end
end

always @(posedge clk or negedge rst_n) //
begin
	if(!rst_n)
	begin
		decode_valid_cnt <= 0;
	end
	else if(APP_addr_rd_end_D1)
	begin
		if(decode_valid_cnt == `BlkNumperDecoder) //第几个输入的数据解码完成？
			decode_valid_cnt <= 0;
		else
			decode_valid_cnt <= decode_valid_cnt + 1;
	end
	else
	begin
		decode_valid_cnt <= decode_valid_cnt;
	end
end

// update_start is high on 1st clk of each layer iteration
always@(posedge clk or negedge rst_n) //每一层第一拍update_start为1
begin
	if(!rst_n)
	begin
		update_start <= 0;
	end
	else if(iter_start_D2)
	begin
		update_start <= 1;
	end
	else if(update_end && iternum <`maxIterNum)
	begin
		if(Layernum == totalLayernum - 1)
			update_start <= 0;
		else
			update_start <= 1;
	end
	else
	begin
		update_start <= 0;
	end
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		update_end <= 0;
	end
	else if(APP_rd_endD13)  //APP_rd_end通过读取地址个数控制 控制 update_end 对 Layernum 计数 在读完后延迟14拍也更新写完
	begin
		update_end <= 1;
	end
	else
		update_end <= 0;
end

//
always@(posedge clk or negedge rst_n) //每次迭代对 Layernum 计数，iter_end控制
begin
	if(!rst_n)
	begin
		Layernum <= 0;
		iter_end <= 0;
	end
	else if(iter_start)
	begin
		Layernum <= 0;
		iter_end <= 0;
	end
	else if(update_end)
	begin
		if(Layernum == totalLayernum - 1)
		begin
			Layernum <= 0;
			iter_end <= 1;
		end
		else
		begin
			Layernum <= Layernum + 1;
			iter_end <= 0;
		end
	end
	else
	begin
		Layernum <= Layernum;
		iter_end <= 0;
	end
end

always@(posedge clk or negedge rst_n) //这里才开始送出有效数据DPU  APP_decodin_wr_en开始为1
begin
	if(!rst_n)
	begin
		APP_decodin_wr_en <= 0;
	end
	else if(APP_wr_en_cnt == APP_addr_rd_max)
	begin
		APP_decodin_wr_en <= 0;
	end
	else if(APP_rd_en_cnt == `APP_ProcessTime && iternum <`maxIterNum)
	begin
		APP_decodin_wr_en <= 1;
	end
	else
	begin
		APP_decodin_wr_en <= APP_decodin_wr_en;
	end
end

// TODO: 4 decode part: sub-modules
// get_msgfin: decide, and replace the decode bits to be output
get_msgfin u0_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_0), //APPmemory_0  u0_G0_APPmemory 读出
	.addr_in(APP_addr_rd_0), //APPmemory_0  u0_G0_APPmemory 读出地址
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_0)
);
get_msgfin u1_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_1),
	.addr_in(APP_addr_rd_1),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_1)
);
get_msgfin u2_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_2),
	.addr_in(APP_addr_rd_2),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_2)
);
get_msgfin u3_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_3),
	.addr_in(APP_addr_rd_3),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_3)
);
get_msgfin u4_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_4),
	.addr_in(APP_addr_rd_4),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_4)
);
get_msgfin u5_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_5),
	.addr_in(APP_addr_rd_5),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_5)
);
get_msgfin u6_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_6),
	.addr_in(APP_addr_rd_6),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_6)
);
get_msgfin u7_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_7),
	.addr_in(APP_addr_rd_7),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_7)
);
get_msgfin u8_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_8),
	.addr_in(APP_addr_rd_8),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_8)
);
get_msgfin u9_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_9),
	.addr_in(APP_addr_rd_9),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_9)
);
get_msgfin u10_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_10),
	.addr_in(APP_addr_rd_10),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_10)
);
get_msgfin u11_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_11),
	.addr_in(APP_addr_rd_11),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_11)
);
get_msgfin u12_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_12),
	.addr_in(APP_addr_rd_12),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_12)
);
get_msgfin u13_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_13),
	.addr_in(APP_addr_rd_13),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_13)
);
get_msgfin u14_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_14),
	.addr_in(APP_addr_rd_14),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_14)
);
get_msgfin u15_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_15),
	.addr_in(APP_addr_rd_15),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_15)
);
get_msgfin u16_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_16),
	.addr_in(APP_addr_rd_16),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_16)
);
get_msgfin u17_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_17),
	.addr_in(APP_addr_rd_17),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_17)
);
get_msgfin u18_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_18),
	.addr_in(APP_addr_rd_18),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_18)
);
get_msgfin u19_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_19),
	.addr_in(APP_addr_rd_19),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_19)
);
get_msgfin u20_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_20),
	.addr_in(APP_addr_rd_20),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_20)
);
get_msgfin u21_get_msgfin(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(APPmsg_old_21), //QSN移位前
	.addr_in(APP_addr_rd_21),
	.en_in(APP_rd_en && (iternum==`maxIterNum)),
	.data_out(APP_dec_out_21) //并串变换 
);


// =============================================================================
 // 状态/流程控制相关信号
 // - totalLayernum：一个码字在所选 BG/ lifting 下的总层数；
 // - update_start_*/update_end_*：层起止打拍；
 // - share_flag：资源复用/跨层共享标志（若有）；
 // ============================================================================= 





/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		iter_end <= 0;
	end
	else if(Layernum == totalLayernum )
		iter_end <= 1;
	else 
		iter_end <= 0;	
end
*/


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		update_start_D0 <= 0;
		update_start_D1 <= 0;
		update_start_D2 <= 0;
	end
	else begin
		update_start_D0 <= update_start;
		update_start_D1 <= update_start_D0;
		update_start_D2 <= update_start_D1;
	end
end

//reg update_end_D0;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		update_end_D0 <= 0;
	end
	else 
		update_end_D0 <= update_end;
end
//get the shift value
/*
reg [6:0] shift_addr_rd1;
wire [259:0] bg1_shift;
wire [9:0] shift_0,shift_1,shift_2,shift_3,shift_4,shift_5,shift_6,shift_7,shift_8,shift_9,
    shift_10,shift_11,shift_12,shift_13,shift_14,shift_15,shift_16,shift_17,shift_18,shift_19,
    shift_20,shift_21,shift_22,shift_23,shift_24,shift_25;
reg HROM_rd_en;
*/

always@(posedge clk or negedge rst_n)begin // HROM_rd_en 开始读取矩阵
	if(!rst_n)begin 
		HROM_rd_en <= 0;
 	end
	else if(update_start)begin
		HROM_rd_en <= 1;
	end
	else
		HROM_rd_en <= 1;
end
always@(posedge clk or negedge rst_n)begin //HROM 选取读取开始位置
	if(!rst_n)begin
		shift_addr_rd1 <= 0;
	end
	else if(iter_start)begin
		shift_addr_rd1 <= shift_addr_rd1_ini;	
	end
	else if(APP_rd_endD10)begin
		if( shift_addr_rd1 < `TotalLayernum -1)
		begin
		shift_addr_rd1 <= shift_addr_rd1 + 1;
		end
	end
end

HROM1_0 u10_HRom(.addra(shift_addr_rd1[3:0]),.clka(clk),.douta(bg1_shift_0),.ena(HROM_rd_en)); //现在矩阵只有4行 后续需要修改	

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		bg1_shift <= 0;
	end
	else
	begin
		if(iLs == 3'd1)
		begin
			bg1_shift <= bg1_shift_0;
		end
		else
		begin
			bg1_shift <= 0;		
		end
	end
end		


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		shift_addr_rd1_ini <= 0;
	end
	else
	begin
		if(jLs == 3'd1)
		begin
			shift_addr_rd1_ini <= 0;
		end
		else
		begin
			shift_addr_rd1_ini <= 1;
		end
	end
end		
assign shift_25 =	bg1_shift[`HijWidth*1-1 :`HijWidth*0 ];
assign shift_24 =	bg1_shift[`HijWidth*2-1 :`HijWidth*1 ];
assign shift_23 =	bg1_shift[`HijWidth*3-1 :`HijWidth*2 ];
assign shift_22 =	bg1_shift[`HijWidth*4-1 :`HijWidth*3 ];
assign shift_21 =	bg1_shift[`HijWidth*5-1 :`HijWidth*4 ];
assign shift_20 =	bg1_shift[`HijWidth*6-1 :`HijWidth*5 ];
assign shift_19 =	bg1_shift[`HijWidth*7-1 :`HijWidth*6 ];
assign shift_18 =	bg1_shift[`HijWidth*8-1 :`HijWidth*7 ];
assign shift_17 =	bg1_shift[`HijWidth*9-1 :`HijWidth*8 ];
assign shift_16 =	bg1_shift[`HijWidth*10-1 :`HijWidth*9 ];
assign shift_15 =	bg1_shift[`HijWidth*11-1:`HijWidth*10 ];
assign shift_14 =	bg1_shift[`HijWidth*12-1:`HijWidth*11 ];
assign shift_13 =	bg1_shift[`HijWidth*13-1:`HijWidth*12 ];
assign shift_12 =	bg1_shift[`HijWidth*14-1:`HijWidth*13 ];
assign shift_11 =	bg1_shift[`HijWidth*15-1:`HijWidth*14 ];
assign shift_10 =	bg1_shift[`HijWidth*16-1:`HijWidth*15 ];
assign shift_9 =	bg1_shift[`HijWidth*17-1:`HijWidth*16 ];
assign shift_8 =	bg1_shift[`HijWidth*18-1:`HijWidth*17 ];
assign shift_7 =	bg1_shift[`HijWidth*19-1:`HijWidth*18 ];
assign shift_6 =	bg1_shift[`HijWidth*20-1:`HijWidth*19 ];
assign shift_5 =	bg1_shift[`HijWidth*21-1:`HijWidth*20 ];
assign shift_4 =	bg1_shift[`HijWidth*22-1:`HijWidth*21 ];
assign shift_3 =	bg1_shift[`HijWidth*23-1:`HijWidth*22 ];
assign shift_2 =	bg1_shift[`HijWidth*24-1:`HijWidth*23 ];
assign shift_1 =	bg1_shift[`HijWidth*25-1:`HijWidth*24 ];
assign shift_0 =	bg1_shift[`HijWidth*26-1:`HijWidth*25 ];

assign shift_nsign_25 =	shift_25[`HijWidth-2:0]; //取消符号
assign shift_nsign_24 =	shift_24[`HijWidth-2:0];
assign shift_nsign_23 =	shift_23[`HijWidth-2:0];
assign shift_nsign_22 =	shift_22[`HijWidth-2:0];
assign shift_nsign_21 =	shift_21[`HijWidth-2:0];
assign shift_nsign_20 =	shift_20[`HijWidth-2:0];
assign shift_nsign_19 =	shift_19[`HijWidth-2:0];
assign shift_nsign_18 =	shift_18[`HijWidth-2:0];
assign shift_nsign_17 =	shift_17[`HijWidth-2:0];
assign shift_nsign_16 =	shift_16[`HijWidth-2:0];
assign shift_nsign_15 =	shift_15[`HijWidth-2:0];
assign shift_nsign_14 =	shift_14[`HijWidth-2:0];
assign shift_nsign_13 =	shift_13[`HijWidth-2:0];
assign shift_nsign_12 =	shift_12[`HijWidth-2:0];
assign shift_nsign_11 =	shift_11[`HijWidth-2:0];
assign shift_nsign_10 =	shift_10[`HijWidth-2:0];
assign shift_nsign_9 =	shift_9[`HijWidth-2:0];
assign shift_nsign_8 =	shift_8[`HijWidth-2:0];
assign shift_nsign_7 =	shift_7[`HijWidth-2:0];
assign shift_nsign_6 =	shift_6[`HijWidth-2:0];
assign shift_nsign_5 =	shift_5[`HijWidth-2:0];
assign shift_nsign_4 =	shift_4[`HijWidth-2:0];
assign shift_nsign_3 =	shift_3[`HijWidth-2:0];
assign shift_nsign_2 =	shift_2[`HijWidth-2:0];
assign shift_nsign_1 =	shift_1[`HijWidth-2:0];
assign shift_nsign_0 =	shift_0[`HijWidth-2:0]; //得到循环移位值

// =============================================================================
 // APPRam 地址/读写控制
 // - APP_rd_en / APP_rd_end / APP_rd_en_cnt：译码读遍历控制；
 // - APP_addr_rd_* / APP_addr_wr_*：分片/层对齐的读写地址生成；
 // - *_max：当前码长/ lifting 环境下允许的最大地址；
 // ============================================================================= RAM

/*
wire [3:0]  APP_addr_rd_ini_0,APP_addr_rd_ini_1,APP_addr_rd_ini_2,APP_addr_rd_ini_3,APP_addr_rd_ini_4,APP_addr_rd_ini_5,APP_addr_rd_ini_6,APP_addr_rd_ini_7,APP_addr_rd_ini_8,APP_addr_rd_ini_9,
           APP_addr_rd_ini_10,APP_addr_rd_ini_11,APP_addr_rd_ini_12,APP_addr_rd_ini_13,APP_addr_rd_ini_14,APP_addr_rd_ini_15,APP_addr_rd_ini_16,APP_addr_rd_ini_17,APP_addr_rd_ini_18,APP_addr_rd_ini_19,
           APP_addr_rd_ini_20,APP_addr_rd_ini_21,APP_addr_rd_ini_22,APP_addr_rd_ini_23,APP_addr_rd_ini_24,APP_addr_rd_ini_25,APP_addr_rd_ini_26;	
reg [3:0]  APP_addr_rd_0,APP_addr_rd_1,APP_addr_rd_2,APP_addr_rd_3,APP_addr_rd_4,APP_addr_rd_5,APP_addr_rd_6,APP_addr_rd_7,APP_addr_rd_8,APP_addr_rd_9,
           APP_addr_rd_10,APP_addr_rd_11,APP_addr_rd_12,APP_addr_rd_13,APP_addr_rd_14,APP_addr_rd_15,APP_addr_rd_16,APP_addr_rd_17,APP_addr_rd_18,APP_addr_rd_19,
           APP_addr_rd_20,APP_addr_rd_21,APP_addr_rd_22,APP_addr_rd_23,APP_addr_rd_24,APP_addr_rd_25;


reg [5:0] c_reg_0,c_reg_1,c_reg_2,c_reg_3,c_reg_4,c_reg_5,c_reg_6,c_reg_7,c_reg_8,c_reg_9,
      c_reg_10,c_reg_11,c_reg_12,c_reg_13,c_reg_14,c_reg_15,c_reg_16,c_reg_17,c_reg_18,c_reg_19,
      c_reg_20,c_reg_21,c_reg_22,c_reg_23,c_reg_24,c_reg_25;
wire [5:0] c_0,c_1,c_2,c_3,c_4,c_5,c_6,c_7,c_8,c_9,
      c_10,c_11,c_12,c_13,c_14,c_15,c_16,c_17,c_18,c_19,
      c_20,c_21,c_22,c_23,c_24,c_25;	  
*/
get_addrini u0_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_0 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_0 ),.c(c_0)); //0~4095 循环移位值  /APP深度 ？ mod /
get_addrini u1_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_1 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_1 ),.c(c_1 ));
get_addrini u2_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_2 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_2 ),.c(c_2 ));
get_addrini u3_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_3 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_3 ),.c(c_3 ));
get_addrini u4_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_4 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_4 ),.c(c_4 ));
get_addrini u5_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_5 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_5 ),.c(c_5 ));
get_addrini u6_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_6 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_6 ),.c(c_6 ));
get_addrini u7_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_7 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_7 ),.c(c_7 ));
get_addrini u8_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_8 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_8 ),.c(c_8 ));
get_addrini u9_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_9 ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_9 ),.c(c_9 ));
get_addrini u10_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_10),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_10),.c(c_10));
get_addrini u11_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_11),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_11),.c(c_11));
get_addrini u12_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_12),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_12),.c(c_12));
get_addrini u13_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_13),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_13),.c(c_13));
get_addrini u14_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_14),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_14),.c(c_14));
get_addrini u15_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_15),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_15),.c(c_15));
get_addrini u16_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_16),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_16),.c(c_16));
get_addrini u17_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_17),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_17),.c(c_17));
get_addrini u18_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_18),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_18),.c(c_18));
get_addrini u19_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_19),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_19),.c(c_19));
get_addrini u20_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_20),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_20),.c(c_20));
get_addrini u21_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_21),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_21),.c(c_21));
get_addrini u22_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_22),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_22),.c(c_22));
get_addrini u23_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_23),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_23),.c(c_23));
get_addrini u24_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_24),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_24),.c(c_24));
get_addrini u25_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_25),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_25),.c(c_25));

assign APP_addr_wr_max = APP_addr_rd_max;

always@(posedge clk or negedge rst_n)begin // APP_rd_en 控制APP_addr_rd_max拍为1 读取数据流水线读取
	if(!rst_n)begin
		APP_rd_en <= 0;
		
	end
	else if(update_start_D0)begin //每一层 update_start
		APP_rd_en <= 1;
	end
	else if(decode_out_start) //这里开始向输出写
	begin
		APP_rd_en <= 1;
	end
	else if(APP_rd_en_cnt == APP_addr_rd_max)begin 
		APP_rd_en <= 0;
	end
end


always@(posedge clk or negedge rst_n)begin //APP_rd_en_cnt 对读取开始后的节拍计数 读入深度拍
	if(!rst_n)begin
		APP_rd_en_cnt <= 0;
	end
	else if(APP_rd_en)begin
		if(APP_rd_en_cnt == APP_addr_rd_max)
			APP_rd_en_cnt <= 0;
		else
			APP_rd_en_cnt <= APP_rd_en_cnt + 1;
	end
end

always@(posedge clk or negedge rst_n)begin //APP_rd_end 读取APP RAM完成
	if(!rst_n)begin
		APP_rd_end <= 0;
	end
	else if(APP_rd_en_cnt == APP_addr_rd_max && iternum < `maxIterNum)
		APP_rd_end <= 1;
	else 
		APP_rd_end <= 0;	
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_rd_endD0  <= 0;
		APP_rd_endD1  <= 0;		
		APP_rd_endD2  <= 0;
		APP_rd_endD3  <= 0;
		APP_rd_endD4  <= 0;
		APP_rd_endD5  <= 0;
		APP_rd_endD6  <= 0;
		APP_rd_endD7  <= 0;		
		APP_rd_endD8  <= 0;
		APP_rd_endD9  <= 0;
		APP_rd_endD10 <= 0;
		APP_rd_endD11 <= 0;
		APP_rd_endD12 <= 0;
		APP_rd_endD13 <= 0;		
		APP_rd_endD14 <= 0;
		APP_rd_endD15 <= 0;
		APP_rd_endD16 <= 0;
	end
	else begin
		APP_rd_endD0  <= APP_rd_end ;
		APP_rd_endD1  <= APP_rd_endD0 ;		
		APP_rd_endD2  <= APP_rd_endD1 ;
		APP_rd_endD3  <= APP_rd_endD2 ;
		APP_rd_endD4  <= APP_rd_endD3 ;
		APP_rd_endD5  <= APP_rd_endD4 ;
		APP_rd_endD6  <= APP_rd_endD5 ;
		APP_rd_endD7  <= APP_rd_endD6 ;	//对应 CTV（check-to-variable）处理开始时刻	
		APP_rd_endD8  <= APP_rd_endD7 ;
		APP_rd_endD9  <= APP_rd_endD8 ;
		APP_rd_endD10 <= APP_rd_endD9 ; //开始更换读取矩阵行
		APP_rd_endD11 <= APP_rd_endD10;
		APP_rd_endD12 <= APP_rd_endD11;
		APP_rd_endD13 <= APP_rd_endD12;		
		APP_rd_endD14 <= APP_rd_endD13; //对应 APP 累加输出
		APP_rd_endD15 <= APP_rd_endD14;
		APP_rd_endD16 <= APP_rd_endD15;	//对应 一次完整的流水对齐结束
		
	end
end

always@(posedge clk or negedge rst_n)begin //APP_addr_rd_0 地址更新 读取地址更新，             写的地址更新依靠信号选择实现
	if(!rst_n)begin
		APP_addr_rd_0  <= 0;
		c_reg_0 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_0  <= APP_addr_rd_ini_0 ; //get_addrini u0_getaddrini 来着
		c_reg_0 <= c_0; //APP_addr_rd_0 ← 初始地址 (APP_addr_rd_ini_0)   c_reg_0 ← 初始循环变量 (c_0)
	end
	else if(decode_out_start) //这里让读出数据时从第一个开始？
	begin
		APP_addr_rd_0  <= 0; //地址清零，可能进入一个新的解码数据搬运阶段。
	end
	// 	当读使能 APP_rd_en=1 时，地址开始自增：
	// 若地址未到最大值：
	// APP_addr_rd_0++
	// 若到达最大地址 (APP_addr_rd_max)：
	// 地址清零 → APP_addr_rd_0=0
	// 同时循环计数 c_reg_0 自增（或回到 0，如果到达 P_1）
	else if(APP_rd_en)begin
	if(APP_addr_rd_0 == APP_addr_rd_max)begin
		if(c_reg_0==P_1)
			c_reg_0 <= 0;
		else
			c_reg_0 <= c_reg_0 + 1; //说明书里面的加 1
		APP_addr_rd_0 <= 0;
	end
	else
		APP_addr_rd_0 <= APP_addr_rd_0+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_1  <= 0;
		c_reg_1 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_1  <= APP_addr_rd_ini_1 ;
		c_reg_1 <= c_1;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_1  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_1 == APP_addr_rd_max)begin
		APP_addr_rd_1 <= 0;
		if(c_reg_1==P_1)
			c_reg_1 <= 0;
		else
			c_reg_1 <= c_reg_1 + 1;
	end
	else
		APP_addr_rd_1 <= APP_addr_rd_1+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_2  <= 0;
		c_reg_2 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_2  <= APP_addr_rd_ini_2 ;
		c_reg_2 <= c_2;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_2  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_2 == APP_addr_rd_max)begin
		if(c_reg_2==P_1)
			c_reg_2 <= 0;
		else
			c_reg_2 <= c_reg_2 + 1;
			APP_addr_rd_2 <= 0;
	end
	else
		APP_addr_rd_2 <= APP_addr_rd_2+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_3  <= 0;
		c_reg_3 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_3  <= APP_addr_rd_ini_3 ;
		c_reg_3 <= c_3;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_3  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_3 == APP_addr_rd_max)begin
		if(c_reg_3==P_1)
			c_reg_3 <= 0;
		else
			c_reg_3 <= c_reg_3 + 1;
		APP_addr_rd_3 <= 0;
	end
	else
		APP_addr_rd_3 <= APP_addr_rd_3+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_4  <= 0;
		c_reg_4 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_4  <= APP_addr_rd_ini_4 ;
		c_reg_4 <= c_4;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_4  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_4 == APP_addr_rd_max)begin
		if(c_reg_4==P_1)
			c_reg_4 <= 0;
		else
			c_reg_4 <= c_reg_4 + 1;
		APP_addr_rd_4 <= 0;
	end
	else
		APP_addr_rd_4 <= APP_addr_rd_4+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_5  <= 0;
		c_reg_5 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_5  <= APP_addr_rd_ini_5 ;
		c_reg_5 <= c_5;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_5  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_5 == APP_addr_rd_max)begin
		if(c_reg_5==P_1)
			c_reg_5 <= 0;
		else
			c_reg_5 <= c_reg_5 + 1;
		APP_addr_rd_5 <= 0;
	end
	else
		APP_addr_rd_5 <= APP_addr_rd_5+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_6  <= 0;
		c_reg_6 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_6  <= APP_addr_rd_ini_6 ;
		c_reg_6 <= c_6;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_6  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_6 == APP_addr_rd_max)begin
		if(c_reg_6==P_1)
			c_reg_6 <= 0;
		else
			c_reg_6 <= c_reg_6 + 1;
		APP_addr_rd_6 <= 0;
	end
	else
		APP_addr_rd_6 <= APP_addr_rd_6+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_7  <= 0;
		c_reg_7 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_7  <= APP_addr_rd_ini_7 ;
		c_reg_7 <= c_7;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_7  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_7 == APP_addr_rd_max)begin
		if(c_reg_7==P_1)
			c_reg_7 <= 0;
		else
			c_reg_7 <= c_reg_7 + 1;
		APP_addr_rd_7 <= 0;
	end
	else
		APP_addr_rd_7 <= APP_addr_rd_7+1;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_8  <= 0;
		c_reg_8 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_8  <= APP_addr_rd_ini_8 ;
		c_reg_8 <= c_8;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_8  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_8 == APP_addr_rd_max)begin
		if(c_reg_8==P_1)
			c_reg_8 <= 0;
		else
			c_reg_8 <= c_reg_8 + 1;
		APP_addr_rd_8 <= 0;
	end
	else
		APP_addr_rd_8 <= APP_addr_rd_8+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_9  <= 0;
		c_reg_9 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_9  <= APP_addr_rd_ini_9 ;
		c_reg_9 <= c_9;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_9  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_9 == APP_addr_rd_max)begin
		if(c_reg_9==P_1)
			c_reg_9 <= 0;
		else
			c_reg_9 <= c_reg_9 + 1;
		APP_addr_rd_9 <= 0;
	end
	else
		APP_addr_rd_9 <= APP_addr_rd_9+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_10  <= 0;
		c_reg_10 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_10  <= APP_addr_rd_ini_10 ;
		c_reg_10 <= c_10;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_10  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_10 == APP_addr_rd_max)begin
		if(c_reg_10==P_1)
			c_reg_10 <= 0;
		else
			c_reg_10 <= c_reg_10 + 1;
		APP_addr_rd_10 <= 0;
	end
	else
		APP_addr_rd_10 <= APP_addr_rd_10+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_11  <= 0;
		c_reg_11 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_11  <= APP_addr_rd_ini_11 ;
		c_reg_11 <= c_11;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_11  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_11 == APP_addr_rd_max)begin
		if(c_reg_11==P_1)
			c_reg_11 <= 0;
		else
			c_reg_11 <= c_reg_11 + 1;
		APP_addr_rd_11 <= 0;
	end
	else
		APP_addr_rd_11 <= APP_addr_rd_11+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_12  <= 0;
		c_reg_12 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_12  <= APP_addr_rd_ini_12 ;
		c_reg_12 <= c_12;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_12  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_12 == APP_addr_rd_max)begin
		if(c_reg_12==P_1)
			c_reg_12 <= 0;
		else
			c_reg_12 <= c_reg_12 + 1;
		APP_addr_rd_12 <= 0;
	end
	else
		APP_addr_rd_12 <= APP_addr_rd_12+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_13  <= 0;
		c_reg_13 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_13  <= APP_addr_rd_ini_13 ;
		c_reg_13 <= c_13;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_13  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_13 == APP_addr_rd_max)begin
		if(c_reg_13==P_1)
			c_reg_13 <= 0;
		else
			c_reg_13 <= c_reg_13 + 1;
		APP_addr_rd_13 <= 0;
	end
	else
		APP_addr_rd_13 <= APP_addr_rd_13+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_14  <= 0;
		c_reg_14 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_14  <= APP_addr_rd_ini_14 ;
		c_reg_14 <= c_14;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_14  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_14 == APP_addr_rd_max)begin
		if(c_reg_14==P_1)
			c_reg_14 <= 0;
		else
			c_reg_14 <= c_reg_14 + 1;
		APP_addr_rd_14 <= 0;
	end
	else
		APP_addr_rd_14 <= APP_addr_rd_14+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_15  <= 0;
		c_reg_15 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_15  <= APP_addr_rd_ini_15 ;
		c_reg_15 <= c_15;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_15  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_15 == APP_addr_rd_max)begin
		if(c_reg_15==P_1)
			c_reg_15 <= 0;
		else
			c_reg_15 <= c_reg_15 + 1;
		APP_addr_rd_15 <= 0;
	end
	else
		APP_addr_rd_15 <= APP_addr_rd_15+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_16  <= 0;
		c_reg_16 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_16  <= APP_addr_rd_ini_16 ;
		c_reg_16 <= c_16;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_16  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_16 == APP_addr_rd_max)begin
		if(c_reg_16==P_1)
			c_reg_16 <= 0;
		else
			c_reg_16 <= c_reg_16 + 1;
		APP_addr_rd_16 <= 0;
	end
	else
		APP_addr_rd_16 <= APP_addr_rd_16+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_17  <= 0;
		c_reg_17 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_17  <= APP_addr_rd_ini_17 ;
		c_reg_17 <= c_17;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_17  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_17 == APP_addr_rd_max)begin
		if(c_reg_17==P_1)
			c_reg_17 <= 0;
		else
			c_reg_17 <= c_reg_17 + 1;
		APP_addr_rd_17 <= 0;
	end
	else
		APP_addr_rd_17 <= APP_addr_rd_17+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_18  <= 0;
		c_reg_18 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_18  <= APP_addr_rd_ini_18 ;
		c_reg_18 <= c_18;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_18  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_18 == APP_addr_rd_max)begin
		if(c_reg_18==P_1)
			c_reg_18 <= 0;
		else
			c_reg_18 <= c_reg_18 + 1;
		APP_addr_rd_18 <= 0;
	end
	else
		APP_addr_rd_18 <= APP_addr_rd_18+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_19  <= 0;
		c_reg_19 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_19  <= APP_addr_rd_ini_19 ;
		c_reg_19 <= c_19;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_19  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_19 == APP_addr_rd_max)begin
		if(c_reg_19==P_1)
			c_reg_19 <= 0;
		else
			c_reg_19 <= c_reg_19 + 1;
		APP_addr_rd_19 <= 0;
	end
	else
		APP_addr_rd_19 <= APP_addr_rd_19+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_20  <= 0;
		c_reg_20 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_20  <= APP_addr_rd_ini_20 ;
		c_reg_20 <= c_20;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_20  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_20 == APP_addr_rd_max)begin
		if(c_reg_20==P_1)
			c_reg_20 <= 0;
		else
			c_reg_20 <= c_reg_20 + 1;
		APP_addr_rd_20 <= 0;
	end
	else
		APP_addr_rd_20 <= APP_addr_rd_20+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_21  <= 0;
		c_reg_21 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_21  <= APP_addr_rd_ini_21 ;
		c_reg_21 <= c_21;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_21  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_21 == APP_addr_rd_max)begin
		if(c_reg_21==P_1)
			c_reg_21 <= 0;
		else
			c_reg_21 <= c_reg_21 + 1;
		APP_addr_rd_21 <= 0;
	end
	else
		APP_addr_rd_21 <= APP_addr_rd_21+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_22  <= 0;
		c_reg_22 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_22  <= APP_addr_rd_ini_22 ;
		c_reg_22 <= c_22;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_22  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_22 == APP_addr_rd_max)begin
		if(c_reg_22==P_1)
			c_reg_22 <= 0;
		else
			c_reg_22 <= c_reg_22 + 1;
		APP_addr_rd_22 <= 0;
	end
	else
		APP_addr_rd_22 <= APP_addr_rd_22+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_23  <= 0;
		c_reg_23 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_23  <= APP_addr_rd_ini_23 ;
		c_reg_23 <= c_23;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_23  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_23 == APP_addr_rd_max)begin
		if(c_reg_23==P_1)
			c_reg_23 <= 0;
		else
			c_reg_23 <= c_reg_23 + 1;
		APP_addr_rd_23 <= 0;
	end
	else
		APP_addr_rd_23 <= APP_addr_rd_23+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_24  <= 0;
		c_reg_24 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_24  <= APP_addr_rd_ini_24 ;
		c_reg_24 <= c_24;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_24  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_24 == APP_addr_rd_max)begin
		if(c_reg_24==P_1)
			c_reg_24 <= 0;
		else
			c_reg_24 <= c_reg_24 + 1;
		APP_addr_rd_24 <= 0;
	end
	else
		APP_addr_rd_24 <= APP_addr_rd_24+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_25  <= 0;
		c_reg_25 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_25  <= APP_addr_rd_ini_25 ;
		c_reg_25 <= c_25;
	end
	else if(decode_out_start)
	begin
		APP_addr_rd_25  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_25 == APP_addr_rd_max)begin //过最大地址后，需要c_reg加1
		if(c_reg_25==P_1)
			c_reg_25 <= 0;
		else
			c_reg_25 <= c_reg_25 + 1;
		APP_addr_rd_25 <= 0;
	end
	else
		APP_addr_rd_25 <= APP_addr_rd_25+1;
	end
end


always@(posedge clk or negedge rst_n)begin //share_flag 共享RAM 是否开启
	if(!rst_n)begin
		share_flag  <= 0;
	end
	else if(iter_start)
		share_flag  <= 0;
	else if(Layernum >= 5'd4)begin
		share_flag  <= 1;
	end
	else
		share_flag <= share_flag;

end

reg [4:0] share_cnt;
reg share_rd_flag; //目前没有用到
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
			share_rd_flag <= 0;
	end
	else if(iter_start)begin
		share_rd_flag <= 0;
	end
	else if(update_start_D0)begin
		share_rd_flag <= 1;
	end	
	else if(share_cnt == APP_addr_max)
		share_rd_flag <= 0;
	else
		share_rd_flag <= share_rd_flag;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_26  <= 0;
	end
	else if(iter_start)begin
		APP_addr_wr_26  <= 0;
	end
	else if(APP_decodin_wr_en && share_flag)begin
		APP_addr_wr_26  <= APP_addr_wr_26+1;
	end
end

//c_reg 
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		c_reg_D0_0  <= 0;
		c_reg_D0_1  <= 0;
		c_reg_D0_2  <= 0;
		c_reg_D0_3  <= 0;
		c_reg_D0_4  <= 0;
		c_reg_D0_5  <= 0;
		c_reg_D0_6  <= 0;
		c_reg_D0_7  <= 0;
		c_reg_D0_8  <= 0;
		c_reg_D0_9  <= 0;
		c_reg_D0_10 <= 0;
		c_reg_D0_11 <= 0;
		c_reg_D0_12 <= 0;
		c_reg_D0_13 <= 0;
		c_reg_D0_14 <= 0;
		c_reg_D0_15 <= 0;
		c_reg_D0_16 <= 0;
		c_reg_D0_17 <= 0;
		c_reg_D0_18 <= 0;
		c_reg_D0_19 <= 0;
		c_reg_D0_20 <= 0;
		c_reg_D0_21 <= 0;
		c_reg_D0_22 <= 0;
		c_reg_D0_23 <= 0;
		c_reg_D0_24 <= 0;
		c_reg_D0_25 <= 0;
	end
	else begin
		c_reg_D0_0  <= c_reg_0 ;
		c_reg_D0_1  <= c_reg_1 ;
		c_reg_D0_2  <= c_reg_2 ;
		c_reg_D0_3  <= c_reg_3 ;
		c_reg_D0_4  <= c_reg_4 ;
		c_reg_D0_5  <= c_reg_5 ;
		c_reg_D0_6  <= c_reg_6 ;
		c_reg_D0_7  <= c_reg_7 ;
		c_reg_D0_8  <= c_reg_8 ;
		c_reg_D0_9  <= c_reg_9 ;
		c_reg_D0_10 <= c_reg_10;
		c_reg_D0_11 <= c_reg_11;
		c_reg_D0_12 <= c_reg_12;
		c_reg_D0_13 <= c_reg_13;
		c_reg_D0_14 <= c_reg_14;
		c_reg_D0_15 <= c_reg_15;
		c_reg_D0_16 <= c_reg_16;
		c_reg_D0_17 <= c_reg_17;
		c_reg_D0_18 <= c_reg_18;
		c_reg_D0_19 <= c_reg_19;
		c_reg_D0_20 <= c_reg_20;
		c_reg_D0_21 <= c_reg_21;
		c_reg_D0_22 <= c_reg_22;
		c_reg_D0_23 <= c_reg_23;
		c_reg_D0_24 <= c_reg_24;
		c_reg_D0_25 <= c_reg_25;		
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		c_reg_D1_0  <= 0;
		c_reg_D1_1  <= 0;
		c_reg_D1_2  <= 0;
		c_reg_D1_3  <= 0;
		c_reg_D1_4  <= 0;
		c_reg_D1_5  <= 0;
		c_reg_D1_6  <= 0;
		c_reg_D1_7  <= 0;
		c_reg_D1_8  <= 0;
		c_reg_D1_9  <= 0;
		c_reg_D1_10 <= 0;
		c_reg_D1_11 <= 0;
		c_reg_D1_12 <= 0;
		c_reg_D1_13 <= 0;
		c_reg_D1_14 <= 0;
		c_reg_D1_15 <= 0;
		c_reg_D1_16 <= 0;
		c_reg_D1_17 <= 0;
		c_reg_D1_18 <= 0;
		c_reg_D1_19 <= 0;
		c_reg_D1_20 <= 0;
		c_reg_D1_21 <= 0;
		c_reg_D1_22 <= 0;
		c_reg_D1_23 <= 0;
		c_reg_D1_24 <= 0;
		c_reg_D1_25 <= 0;
	end
	else begin
		c_reg_D1_0  <= c_reg_D0_0 ;
		c_reg_D1_1  <= c_reg_D0_1 ;
		c_reg_D1_2  <= c_reg_D0_2 ;
		c_reg_D1_3  <= c_reg_D0_3 ;
		c_reg_D1_4  <= c_reg_D0_4 ;
		c_reg_D1_5  <= c_reg_D0_5 ;
		c_reg_D1_6  <= c_reg_D0_6 ;
		c_reg_D1_7  <= c_reg_D0_7 ;
		c_reg_D1_8  <= c_reg_D0_8 ;
		c_reg_D1_9  <= c_reg_D0_9 ;
		c_reg_D1_10 <= c_reg_D0_10;
		c_reg_D1_11 <= c_reg_D0_11;
		c_reg_D1_12 <= c_reg_D0_12;
		c_reg_D1_13 <= c_reg_D0_13;
		c_reg_D1_14 <= c_reg_D0_14;
		c_reg_D1_15 <= c_reg_D0_15;
		c_reg_D1_16 <= c_reg_D0_16;
		c_reg_D1_17 <= c_reg_D0_17;
		c_reg_D1_18 <= c_reg_D0_18;
		c_reg_D1_19 <= c_reg_D0_19;
		c_reg_D1_20 <= c_reg_D0_20;
		c_reg_D1_21 <= c_reg_D0_21;
		c_reg_D1_22 <= c_reg_D0_22;
		c_reg_D1_23 <= c_reg_D0_23;
		c_reg_D1_24 <= c_reg_D0_24;
		c_reg_D1_25 <= c_reg_D0_25;		
	end
end
//wr///////////////////////////////////////////////////////////////////////////
//wr///////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) //没有用到
begin
	if(!rst_n)
	begin
		APP_wr_en_D0 <= 0;
	end
	else
	begin
		APP_wr_en_D0 <= APP_decodin_wr_en; //达到APP_ProcessTime后开始
	end
end

always@(posedge clk or negedge rst_n)begin // APP_wr_en_cnt 写入计数同样写APP深度拍 写的地址更新依靠信号选择实现
	if(!rst_n)begin
		APP_wr_en_cnt <= 0;
	end
	else if(APP_wr_en_cnt == APP_addr_rd_max)begin
		APP_wr_en_cnt <= 0;
	end
	else if(APP_decodin_wr_en)begin
		APP_wr_en_cnt <= APP_wr_en_cnt+1;
	end
	else
		APP_wr_en_cnt <= APP_wr_en_cnt;
end

always@(posedge clk or negedge rst_n)begin //写入地址初始化和累加 写的地址更新依靠信号选择实现
	if(!rst_n)begin
		APP_addr_wr_0  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_0  <= APP_addr_rd_ini_0 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_0 == APP_addr_wr_max)begin
		APP_addr_wr_0 <= 0;
	end
	else
		APP_addr_wr_0 <= APP_addr_wr_0+1;
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_1  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_1  <= APP_addr_rd_ini_1 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_1 == APP_addr_wr_max)begin
		APP_addr_wr_1 <= 0;
	end
	else
		APP_addr_wr_1 <= APP_addr_wr_1+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_2  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_2  <= APP_addr_rd_ini_2 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_2 == APP_addr_wr_max)begin
		APP_addr_wr_2 <= 0;
	end
	else
		APP_addr_wr_2 <= APP_addr_wr_2+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_3  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_3  <= APP_addr_rd_ini_3 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_3 == APP_addr_wr_max)begin
		APP_addr_wr_3 <= 0;
	end
	else
		APP_addr_wr_3 <= APP_addr_wr_3+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_4  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_4  <= APP_addr_rd_ini_4 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_4 == APP_addr_wr_max)begin
		APP_addr_wr_4 <= 0;
	end
	else
		APP_addr_wr_4 <= APP_addr_wr_4+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_5  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_5  <= APP_addr_rd_ini_5 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_5 == APP_addr_wr_max)begin
		APP_addr_wr_5 <= 0;
	end
	else
		APP_addr_wr_5 <= APP_addr_wr_5+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_6  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_6  <= APP_addr_rd_ini_6 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_6 == APP_addr_wr_max)begin
		APP_addr_wr_6 <= 0;
	end
	else
		APP_addr_wr_6 <= APP_addr_wr_6+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_7  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_7  <= APP_addr_rd_ini_7 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_7 == APP_addr_wr_max)begin
		APP_addr_wr_7 <= 0;
	end
	else
		APP_addr_wr_7 <= APP_addr_wr_7+1;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_8  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_8  <= APP_addr_rd_ini_8 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_8 == APP_addr_wr_max)begin
		APP_addr_wr_8 <= 0;
	end
	else
		APP_addr_wr_8 <= APP_addr_wr_8+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_9  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_9  <= APP_addr_rd_ini_9 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_9 == APP_addr_wr_max)begin
		APP_addr_wr_9 <= 0;
	end
	else
		APP_addr_wr_9 <= APP_addr_wr_9+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_10  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_10  <= APP_addr_rd_ini_10 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_10 == APP_addr_wr_max)begin
		APP_addr_wr_10 <= 0;
	end
	else
		APP_addr_wr_10 <= APP_addr_wr_10+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_11  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_11  <= APP_addr_rd_ini_11 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_11 == APP_addr_wr_max)begin
		APP_addr_wr_11 <= 0;
	end
	else
		APP_addr_wr_11 <= APP_addr_wr_11+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_12  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_12  <= APP_addr_rd_ini_12 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_12 == APP_addr_wr_max)begin
		APP_addr_wr_12 <= 0;
	end
	else
		APP_addr_wr_12 <= APP_addr_wr_12+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_13  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_13  <= APP_addr_rd_ini_13 ;

	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_13 == APP_addr_wr_max)begin
		APP_addr_wr_13 <= 0;
	end
	else
		APP_addr_wr_13 <= APP_addr_wr_13+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_14  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_14  <= APP_addr_rd_ini_14 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_14 == APP_addr_wr_max)begin
		APP_addr_wr_14 <= 0;
	end
	else
		APP_addr_wr_14 <= APP_addr_wr_14+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_15  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_15  <= APP_addr_rd_ini_15 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_15 == APP_addr_wr_max)begin
		APP_addr_wr_15 <= 0;
	end
	else
		APP_addr_wr_15 <= APP_addr_wr_15+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_16  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_16  <= APP_addr_rd_ini_16 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_16 == APP_addr_wr_max)begin
		APP_addr_wr_16 <= 0;
	end
	else
		APP_addr_wr_16 <= APP_addr_wr_16+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_17  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_17  <= APP_addr_rd_ini_17 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_17 == APP_addr_wr_max)begin
		APP_addr_wr_17 <= 0;
	end
	else
		APP_addr_wr_17 <= APP_addr_wr_17+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_18  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_18  <= APP_addr_rd_ini_18 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_18 == APP_addr_wr_max)begin
		APP_addr_wr_18 <= 0;
	end
	else
		APP_addr_wr_18 <= APP_addr_wr_18+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_19  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_19  <= APP_addr_rd_ini_19 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_19 == APP_addr_wr_max)begin
		APP_addr_wr_19 <= 0;
	end
	else
		APP_addr_wr_19 <= APP_addr_wr_19+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_20  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_20  <= APP_addr_rd_ini_20 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_20 == APP_addr_wr_max)begin
		APP_addr_wr_20 <= 0;
	end
	else
		APP_addr_wr_20 <= APP_addr_wr_20+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_21  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_21  <= APP_addr_rd_ini_21 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_21 == APP_addr_wr_max)begin
		APP_addr_wr_21 <= 0;
	end
	else
		APP_addr_wr_21 <= APP_addr_wr_21+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_22  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_22  <= APP_addr_rd_ini_22 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_22 == APP_addr_wr_max)begin
		APP_addr_wr_22 <= 0;
	end
	else
		APP_addr_wr_22 <= APP_addr_wr_22+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_23  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_23  <= APP_addr_rd_ini_23 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_23 == APP_addr_wr_max)begin
		APP_addr_wr_23 <= 0;
	end
	else
		APP_addr_wr_23 <= APP_addr_wr_23+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_24  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_24  <= APP_addr_rd_ini_24 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_24 == APP_addr_wr_max)begin
		APP_addr_wr_24 <= 0;
	end
	else
		APP_addr_wr_24 <= APP_addr_wr_24+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_25  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_25  <= APP_addr_rd_ini_25 ;
	end
	else if(APP_decodin_wr_en)begin
	if(APP_addr_wr_25 == APP_addr_wr_max)begin
		APP_addr_wr_25 <= 0;
	end
	else
		APP_addr_wr_25 <= APP_addr_wr_25+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_26  <= 0;
	end
	else if(decode_start)begin
		APP_addr_rd_26  <= 0;
	end
	else if(APP_addr_rd_26 == 10'd143)begin
		APP_addr_rd_26  <= 0;
	end
	else if(APP_rd_en && share_flag)begin
		APP_addr_rd_26  <= APP_addr_rd_26+1;
	end
end

/*

reg flag_0,flag_1,flag_2,flag_3,flag_4,flag_5,flag_6,flag_7,flag_8,flag_9,
    flag_10,flag_11,flag_12,flag_13,flag_14,flag_15,flag_16,flag_17,flag_18,flag_19,
    flag_20,flag_21,flag_22,flag_23,flag_24,flag_25,flag_26,flag_27,flag_28,flag_29,flag_30,flag_31;

wire [`APPdata_Len-1:0] APPmsg_old_0,APPmsg_old_1,APPmsg_old_2,APPmsg_old_3,APPmsg_old_4,APPmsg_old_5,APPmsg_old_6,APPmsg_old_7,APPmsg_old_8,APPmsg_old_9,
                  APPmsg_old_10,APPmsg_old_11,APPmsg_old_12,APPmsg_old_13,APPmsg_old_14,APPmsg_old_15,APPmsg_old_16,APPmsg_old_17,APPmsg_old_18,APPmsg_old_19,
                  APPmsg_old_20,APPmsg_old_21,APPmsg_old_22,APPmsg_old_23,APPmsg_old_24,APPmsg_old_25,APPmsg_old_26;	  
reg [`APPdata_Len-1:0] APPmsg_new_0,APPmsg_new_1,APPmsg_new_2,APPmsg_new_3,APPmsg_new_4,APPmsg_new_5,APPmsg_new_6,APPmsg_new_7,APPmsg_new_8,APPmsg_new_9,
                  APPmsg_new_10,APPmsg_new_11,APPmsg_new_12,APPmsg_new_13,APPmsg_new_14,APPmsg_new_15,APPmsg_new_16,APPmsg_new_17,APPmsg_new_18,APPmsg_new_19,
                  APPmsg_new_20,APPmsg_new_21,APPmsg_new_22,APPmsg_new_23,APPmsg_new_24,APPmsg_new_25;
reg APP_decodin_wr_en;
reg [3:0] APP_wr_en_cnt;
*/

// TODO: 5 APPRam part: sub-modules
// APPRam Group 0
APPmemory_0  u0_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_0 ), .wea(1'b1), .addra(APP_G0_addr_wr_0 ), .dina(APPmsg_G0_in_0 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_0 ), .doutb(APPmsg_G0_out_0 )); //写入，然后根据地址一段段读出来 应该是的 更新
APPmemory_0  u1_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_1 ), .wea(1'b1), .addra(APP_G0_addr_wr_1 ), .dina(APPmsg_G0_in_1 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_1 ), .doutb(APPmsg_G0_out_1 ));
APPmemory_0  u2_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_2 ), .wea(1'b1), .addra(APP_G0_addr_wr_2 ), .dina(APPmsg_G0_in_2 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_2 ), .doutb(APPmsg_G0_out_2 ));
APPmemory_0  u3_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_3 ), .wea(1'b1), .addra(APP_G0_addr_wr_3 ), .dina(APPmsg_G0_in_3 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_3 ), .doutb(APPmsg_G0_out_3 ));
APPmemory_0  u4_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_4 ), .wea(1'b1), .addra(APP_G0_addr_wr_4 ), .dina(APPmsg_G0_in_4 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_4 ), .doutb(APPmsg_G0_out_4 ));
APPmemory_0  u5_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_5 ), .wea(1'b1), .addra(APP_G0_addr_wr_5 ), .dina(APPmsg_G0_in_5 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_5 ), .doutb(APPmsg_G0_out_5 ));
APPmemory_0  u6_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_6 ), .wea(1'b1), .addra(APP_G0_addr_wr_6 ), .dina(APPmsg_G0_in_6 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_6 ), .doutb(APPmsg_G0_out_6 ));
APPmemory_0  u7_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_7 ), .wea(1'b1), .addra(APP_G0_addr_wr_7 ), .dina(APPmsg_G0_in_7 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_7 ), .doutb(APPmsg_G0_out_7 ));
APPmemory_0  u8_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_8 ), .wea(1'b1), .addra(APP_G0_addr_wr_8 ), .dina(APPmsg_G0_in_8 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_8 ), .doutb(APPmsg_G0_out_8 ));
APPmemory_0  u9_G0_APPmemory(.clka(clk),   .ena(APP_G0_wr_en_9 ), .wea(1'b1), .addra(APP_G0_addr_wr_9 ), .dina(APPmsg_G0_in_9 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_9 ), .doutb(APPmsg_G0_out_9 ));
APPmemory_0 u10_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_10), .wea(1'b1), .addra(APP_G0_addr_wr_10), .dina(APPmsg_G0_in_10), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_10), .doutb(APPmsg_G0_out_10));
APPmemory_0 u11_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_11), .wea(1'b1), .addra(APP_G0_addr_wr_11), .dina(APPmsg_G0_in_11), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_11), .doutb(APPmsg_G0_out_11));
APPmemory_0 u12_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_12), .wea(1'b1), .addra(APP_G0_addr_wr_12), .dina(APPmsg_G0_in_12), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_12), .doutb(APPmsg_G0_out_12));
APPmemory_0 u13_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_13), .wea(1'b1), .addra(APP_G0_addr_wr_13), .dina(APPmsg_G0_in_13), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_13), .doutb(APPmsg_G0_out_13));
APPmemory_0 u14_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_14), .wea(1'b1), .addra(APP_G0_addr_wr_14), .dina(APPmsg_G0_in_14), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_14), .doutb(APPmsg_G0_out_14));
APPmemory_0 u15_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_15), .wea(1'b1), .addra(APP_G0_addr_wr_15), .dina(APPmsg_G0_in_15), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_15), .doutb(APPmsg_G0_out_15));
APPmemory_0 u16_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_16), .wea(1'b1), .addra(APP_G0_addr_wr_16), .dina(APPmsg_G0_in_16), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_16), .doutb(APPmsg_G0_out_16));
APPmemory_0 u17_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_17), .wea(1'b1), .addra(APP_G0_addr_wr_17), .dina(APPmsg_G0_in_17), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_17), .doutb(APPmsg_G0_out_17));
APPmemory_0 u18_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_18), .wea(1'b1), .addra(APP_G0_addr_wr_18), .dina(APPmsg_G0_in_18), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_18), .doutb(APPmsg_G0_out_18));
APPmemory_0 u19_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_19), .wea(1'b1), .addra(APP_G0_addr_wr_19), .dina(APPmsg_G0_in_19), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_19), .doutb(APPmsg_G0_out_19));
APPmemory_0 u20_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_20), .wea(1'b1), .addra(APP_G0_addr_wr_20), .dina(APPmsg_G0_in_20), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_20), .doutb(APPmsg_G0_out_20));
APPmemory_0 u21_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_21), .wea(1'b1), .addra(APP_G0_addr_wr_21), .dina(APPmsg_G0_in_21), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_21), .doutb(APPmsg_G0_out_21));
APPmemory_0 u22_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_22), .wea(1'b1), .addra(APP_G0_addr_wr_22), .dina(APPmsg_G0_in_22), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_22), .doutb(APPmsg_G0_out_22));
APPmemory_0 u23_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_23), .wea(1'b1), .addra(APP_G0_addr_wr_23), .dina(APPmsg_G0_in_23), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_23), .doutb(APPmsg_G0_out_23));
APPmemory_0 u24_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_24), .wea(1'b1), .addra(APP_G0_addr_wr_24), .dina(APPmsg_G0_in_24), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_24), .doutb(APPmsg_G0_out_24));
APPmemory_0 u25_G0_APPmemory(.clka(clk),  .ena(APP_G0_wr_en_25), .wea(1'b1), .addra(APP_G0_addr_wr_25), .dina(APPmsg_G0_in_25), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_25), .doutb(APPmsg_G0_out_25));
shareAPPmemory shared_G0_APPmemory(.clka(clk),.ena(APP_G0_wr_en_26), .wea(1'b1), .addra(APP_G0_addr_wr_26), .dina(APPmsg_G0_in_26), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_26), .doutb(APPmsg_G0_out_26));

// APPRam Group 1
APPmemory_0  u0_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_0 ), .wea(1'b1), .addra(APP_G1_addr_wr_0 ), .dina(APPmsg_G1_in_0 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_0 ), .doutb(APPmsg_G1_out_0 ));
APPmemory_0  u1_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_1 ), .wea(1'b1), .addra(APP_G1_addr_wr_1 ), .dina(APPmsg_G1_in_1 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_1 ), .doutb(APPmsg_G1_out_1 ));
APPmemory_0  u2_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_2 ), .wea(1'b1), .addra(APP_G1_addr_wr_2 ), .dina(APPmsg_G1_in_2 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_2 ), .doutb(APPmsg_G1_out_2 ));
APPmemory_0  u3_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_3 ), .wea(1'b1), .addra(APP_G1_addr_wr_3 ), .dina(APPmsg_G1_in_3 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_3 ), .doutb(APPmsg_G1_out_3 ));
APPmemory_0  u4_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_4 ), .wea(1'b1), .addra(APP_G1_addr_wr_4 ), .dina(APPmsg_G1_in_4 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_4 ), .doutb(APPmsg_G1_out_4 ));
APPmemory_0  u5_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_5 ), .wea(1'b1), .addra(APP_G1_addr_wr_5 ), .dina(APPmsg_G1_in_5 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_5 ), .doutb(APPmsg_G1_out_5 ));
APPmemory_0  u6_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_6 ), .wea(1'b1), .addra(APP_G1_addr_wr_6 ), .dina(APPmsg_G1_in_6 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_6 ), .doutb(APPmsg_G1_out_6 ));
APPmemory_0  u7_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_7 ), .wea(1'b1), .addra(APP_G1_addr_wr_7 ), .dina(APPmsg_G1_in_7 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_7 ), .doutb(APPmsg_G1_out_7 ));
APPmemory_0  u8_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_8 ), .wea(1'b1), .addra(APP_G1_addr_wr_8 ), .dina(APPmsg_G1_in_8 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_8 ), .doutb(APPmsg_G1_out_8 ));
APPmemory_0  u9_G1_APPmemory(.clka(clk),   .ena(APP_G1_wr_en_9 ), .wea(1'b1), .addra(APP_G1_addr_wr_9 ), .dina(APPmsg_G1_in_9 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_9 ), .doutb(APPmsg_G1_out_9 ));
APPmemory_0 u10_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_10), .wea(1'b1), .addra(APP_G1_addr_wr_10), .dina(APPmsg_G1_in_10), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_10), .doutb(APPmsg_G1_out_10));
APPmemory_0 u11_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_11), .wea(1'b1), .addra(APP_G1_addr_wr_11), .dina(APPmsg_G1_in_11), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_11), .doutb(APPmsg_G1_out_11));
APPmemory_0 u12_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_12), .wea(1'b1), .addra(APP_G1_addr_wr_12), .dina(APPmsg_G1_in_12), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_12), .doutb(APPmsg_G1_out_12));
APPmemory_0 u13_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_13), .wea(1'b1), .addra(APP_G1_addr_wr_13), .dina(APPmsg_G1_in_13), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_13), .doutb(APPmsg_G1_out_13));
APPmemory_0 u14_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_14), .wea(1'b1), .addra(APP_G1_addr_wr_14), .dina(APPmsg_G1_in_14), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_14), .doutb(APPmsg_G1_out_14));
APPmemory_0 u15_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_15), .wea(1'b1), .addra(APP_G1_addr_wr_15), .dina(APPmsg_G1_in_15), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_15), .doutb(APPmsg_G1_out_15));
APPmemory_0 u16_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_16), .wea(1'b1), .addra(APP_G1_addr_wr_16), .dina(APPmsg_G1_in_16), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_16), .doutb(APPmsg_G1_out_16));
APPmemory_0 u17_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_17), .wea(1'b1), .addra(APP_G1_addr_wr_17), .dina(APPmsg_G1_in_17), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_17), .doutb(APPmsg_G1_out_17));
APPmemory_0 u18_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_18), .wea(1'b1), .addra(APP_G1_addr_wr_18), .dina(APPmsg_G1_in_18), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_18), .doutb(APPmsg_G1_out_18));
APPmemory_0 u19_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_19), .wea(1'b1), .addra(APP_G1_addr_wr_19), .dina(APPmsg_G1_in_19), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_19), .doutb(APPmsg_G1_out_19));
APPmemory_0 u20_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_20), .wea(1'b1), .addra(APP_G1_addr_wr_20), .dina(APPmsg_G1_in_20), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_20), .doutb(APPmsg_G1_out_20));
APPmemory_0 u21_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_21), .wea(1'b1), .addra(APP_G1_addr_wr_21), .dina(APPmsg_G1_in_21), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_21), .doutb(APPmsg_G1_out_21));
APPmemory_0 u22_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_22), .wea(1'b1), .addra(APP_G1_addr_wr_22), .dina(APPmsg_G1_in_22), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_22), .doutb(APPmsg_G1_out_22));
APPmemory_0 u23_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_23), .wea(1'b1), .addra(APP_G1_addr_wr_23), .dina(APPmsg_G1_in_23), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_23), .doutb(APPmsg_G1_out_23));
APPmemory_0 u24_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_24), .wea(1'b1), .addra(APP_G1_addr_wr_24), .dina(APPmsg_G1_in_24), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_24), .doutb(APPmsg_G1_out_24));
APPmemory_0 u25_G1_APPmemory(.clka(clk),  .ena(APP_G1_wr_en_25), .wea(1'b1), .addra(APP_G1_addr_wr_25), .dina(APPmsg_G1_in_25), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_25), .doutb(APPmsg_G1_out_25));
shareAPPmemory shared_G1_APPmemory(.clka(clk),.ena(APP_G1_wr_en_26), .wea(1'b1), .addra(APP_G1_addr_wr_26), .dina(APPmsg_G1_in_26), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_26), .doutb(APPmsg_G1_out_26));

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		 APPmsg_old_26_D0 <= 0;
		 APPmsg_old_26_D1 <= 0;
	end
	else begin
		 APPmsg_old_26_D0 <= APPmsg_old_26;
		 APPmsg_old_26_D1 <= APPmsg_old_26_D0;
	end
end
	

// =============================================================================
 // QSN（校验节点）相关寄存器/总线
 // - c_reg_*/c_*：分列保存的校验节点中间结果；
 // - APPmsg_old_*/APPmsg_new_*：变量节点旧/新 APP；
 // - QSN_APPmsg_*：校验节点输出给 DPU 的接口；
 // =============================================================================
/*
wire [`APPdata_Len-1:0] QSN_APPmsg_0,QSN_APPmsg_1,QSN_APPmsg_2,QSN_APPmsg_3,QSN_APPmsg_4,QSN_APPmsg_5,QSN_APPmsg_6,QSN_APPmsg_7,QSN_APPmsg_8,QSN_APPmsg_9,
                  QSN_APPmsg_10,QSN_APPmsg_11,QSN_APPmsg_12,QSN_APPmsg_13,QSN_APPmsg_14,QSN_APPmsg_15,QSN_APPmsg_16,QSN_APPmsg_17,QSN_APPmsg_18,QSN_APPmsg_19,
                  QSN_APPmsg_20,QSN_APPmsg_21,QSN_APPmsg_22,QSN_APPmsg_23,QSN_APPmsg_24,QSN_APPmsg_25;
*/
QSN u0_QSN(.clk(clk),.in(APPmsg_old_0 ), .p(P),.c(c_reg_D1_0 ),.out(QSN_APPmsg_0 )); //送入DPU APPmsg_old_0 由于第一次信息，初始化都为0，所有不用累加
QSN u1_QSN(.clk(clk),.in(APPmsg_old_1 ), .p(P),.c(c_reg_D1_1 ),.out(QSN_APPmsg_1 ));
QSN u2_QSN(.clk(clk),.in(APPmsg_old_2 ), .p(P),.c(c_reg_D1_2 ),.out(QSN_APPmsg_2 ));
QSN u3_QSN(.clk(clk),.in(APPmsg_old_3 ), .p(P),.c(c_reg_D1_3 ),.out(QSN_APPmsg_3 ));
QSN u4_QSN(.clk(clk),.in(APPmsg_old_4 ), .p(P),.c(c_reg_D1_4 ),.out(QSN_APPmsg_4 ));
QSN u5_QSN(.clk(clk),.in(APPmsg_old_5 ), .p(P),.c(c_reg_D1_5 ),.out(QSN_APPmsg_5 ));
QSN u6_QSN(.clk(clk),.in(APPmsg_old_6 ), .p(P),.c(c_reg_D1_6 ),.out(QSN_APPmsg_6 ));
QSN u7_QSN(.clk(clk),.in(APPmsg_old_7 ), .p(P),.c(c_reg_D1_7 ),.out(QSN_APPmsg_7 ));
QSN u8_QSN(.clk(clk),.in(APPmsg_old_8 ), .p(P),.c(c_reg_D1_8 ),.out(QSN_APPmsg_8 ));
QSN u9_QSN(.clk(clk),.in(APPmsg_old_9 ), .p(P),.c(c_reg_D1_9 ),.out(QSN_APPmsg_9 ));
QSN u10_QSN(.clk(clk),.in(APPmsg_old_10),.p(P),.c(c_reg_D1_10),.out(QSN_APPmsg_10));
QSN u11_QSN(.clk(clk),.in(APPmsg_old_11),.p(P),.c(c_reg_D1_11),.out(QSN_APPmsg_11));
QSN u12_QSN(.clk(clk),.in(APPmsg_old_12),.p(P),.c(c_reg_D1_12),.out(QSN_APPmsg_12));
QSN u13_QSN(.clk(clk),.in(APPmsg_old_13),.p(P),.c(c_reg_D1_13),.out(QSN_APPmsg_13));
QSN u14_QSN(.clk(clk),.in(APPmsg_old_14),.p(P),.c(c_reg_D1_14),.out(QSN_APPmsg_14));
QSN u15_QSN(.clk(clk),.in(APPmsg_old_15),.p(P),.c(c_reg_D1_15),.out(QSN_APPmsg_15));
QSN u16_QSN(.clk(clk),.in(APPmsg_old_16),.p(P),.c(c_reg_D1_16),.out(QSN_APPmsg_16));
QSN u17_QSN(.clk(clk),.in(APPmsg_old_17),.p(P),.c(c_reg_D1_17),.out(QSN_APPmsg_17));
QSN u18_QSN(.clk(clk),.in(APPmsg_old_18),.p(P),.c(c_reg_D1_18),.out(QSN_APPmsg_18));
QSN u19_QSN(.clk(clk),.in(APPmsg_old_19),.p(P),.c(c_reg_D1_19),.out(QSN_APPmsg_19));
QSN u20_QSN(.clk(clk),.in(APPmsg_old_20),.p(P),.c(c_reg_D1_20),.out(QSN_APPmsg_20));
QSN u21_QSN(.clk(clk),.in(APPmsg_old_21),.p(P),.c(c_reg_D1_21),.out(QSN_APPmsg_21));
QSN u22_QSN(.clk(clk),.in(APPmsg_old_22),.p(P),.c(c_reg_D1_22),.out(QSN_APPmsg_22));
QSN u23_QSN(.clk(clk),.in(APPmsg_old_23),.p(P),.c(c_reg_D1_23),.out(QSN_APPmsg_23));
QSN u24_QSN(.clk(clk),.in(APPmsg_old_24),.p(P),.c(c_reg_D1_24),.out(QSN_APPmsg_24));
QSN u25_QSN(.clk(clk),.in(APPmsg_old_25),.p(P),.c(c_reg_D1_25),.out(QSN_APPmsg_25));




//Distribution Network
/*
wire [`DPUdata_Len-1:0] DN_APPmsg_0,DN_APPmsg_1,DN_APPmsg_2,DN_APPmsg_3,DN_APPmsg_4,DN_APPmsg_5,DN_APPmsg_6,DN_APPmsg_7,DN_APPmsg_8,DN_APPmsg_9,
                  DN_APPmsg_10,DN_APPmsg_11,DN_APPmsg_12,DN_APPmsg_13,DN_APPmsg_14,DN_APPmsg_15,DN_APPmsg_16,DN_APPmsg_17,DN_APPmsg_18,DN_APPmsg_19,
                  DN_APPmsg_20,DN_APPmsg_21,DN_APPmsg_22,DN_APPmsg_23,DN_APPmsg_24,DN_APPmsg_25,DN_APPmsg_26,DN_APPmsg_27,DN_APPmsg_28,DN_APPmsg_29,DN_APPmsg_30,DN_APPmsg_31;
*/
assign DN_APPmsg_31 = {QSN_APPmsg_0 [`VWidth*32-1:`VWidth*31], //数据分发
					  QSN_APPmsg_1 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_2 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_3 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_4 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_5 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_6 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_7 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_8 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_9 [`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_10[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_11[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_12[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_13[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_14[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_15[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_16[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_17[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_18[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_19[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_20[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_21[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_22[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_23[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_24[`VWidth*32-1:`VWidth*31],
					  QSN_APPmsg_25[`VWidth*32-1:`VWidth*31],
					  APPmsg_old_26_D1[`VWidth*32-1:`VWidth*31]};
					  
assign DN_APPmsg_30 = {QSN_APPmsg_0 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_1 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_2 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_3 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_4 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_5 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_6 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_7 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_8 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_9 [`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_10[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_11[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_12[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_13[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_14[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_15[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_16[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_17[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_18[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_19[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_20[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_21[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_22[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_23[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_24[`VWidth*31-1:`VWidth*30],
					  QSN_APPmsg_25[`VWidth*31-1:`VWidth*30],
					  APPmsg_old_26_D1[`VWidth*31-1:`VWidth*30]};	
					  
assign DN_APPmsg_29 ={QSN_APPmsg_0 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_1 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_2 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_3 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_4 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_5 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_6 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_7 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_8 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_9 [`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_10[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_11[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_12[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_13[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_14[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_15[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_16[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_17[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_18[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_19[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_20[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_21[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_22[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_23[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_24[`VWidth*30-1:`VWidth*29],
					  QSN_APPmsg_25[`VWidth*30-1:`VWidth*29],
					  APPmsg_old_26_D1[`VWidth*30-1:`VWidth*29]};	

assign DN_APPmsg_28 ={QSN_APPmsg_0 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_1 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_2 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_3 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_4 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_5 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_6 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_7 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_8 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_9 [`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_10[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_11[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_12[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_13[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_14[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_15[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_16[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_17[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_18[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_19[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_20[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_21[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_22[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_23[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_24[`VWidth*29-1:`VWidth*28],
					  QSN_APPmsg_25[`VWidth*29-1:`VWidth*28],
					  APPmsg_old_26_D1[`VWidth*29-1:`VWidth*28]};						  

assign DN_APPmsg_27 ={QSN_APPmsg_0 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_1 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_2 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_3 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_4 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_5 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_6 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_7 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_8 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_9 [`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_10[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_11[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_12[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_13[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_14[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_15[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_16[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_17[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_18[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_19[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_20[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_21[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_22[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_23[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_24[`VWidth*28-1:`VWidth*27],
					  QSN_APPmsg_25[`VWidth*28-1:`VWidth*27],
					  APPmsg_old_26_D1[`VWidth*28-1:`VWidth*27]};

assign DN_APPmsg_26 ={QSN_APPmsg_0 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_1 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_2 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_3 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_4 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_5 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_6 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_7 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_8 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_9 [`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_10[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_11[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_12[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_13[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_14[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_15[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_16[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_17[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_18[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_19[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_20[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_21[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_22[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_23[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_24[`VWidth*27-1:`VWidth*26],
					  QSN_APPmsg_25[`VWidth*27-1:`VWidth*26],
					  APPmsg_old_26_D1[`VWidth*27-1:`VWidth*26]};					  

assign DN_APPmsg_25 ={QSN_APPmsg_0 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_1 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_2 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_3 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_4 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_5 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_6 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_7 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_8 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_9 [`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_10[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_11[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_12[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_13[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_14[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_15[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_16[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_17[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_18[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_19[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_20[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_21[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_22[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_23[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_24[`VWidth*26-1:`VWidth*25],
					  QSN_APPmsg_25[`VWidth*26-1:`VWidth*25],
					  APPmsg_old_26_D1[`VWidth*26-1:`VWidth*25]};

assign DN_APPmsg_24 ={QSN_APPmsg_0 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_1 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_2 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_3 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_4 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_5 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_6 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_7 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_8 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_9 [`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_10[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_11[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_12[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_13[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_14[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_15[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_16[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_17[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_18[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_19[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_20[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_21[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_22[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_23[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_24[`VWidth*25-1:`VWidth*24],
					  QSN_APPmsg_25[`VWidth*25-1:`VWidth*24],
					  APPmsg_old_26_D1[`VWidth*25-1:`VWidth*24]};

assign DN_APPmsg_23 ={QSN_APPmsg_0 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_1 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_2 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_3 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_4 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_5 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_6 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_7 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_8 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_9 [`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_10[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_11[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_12[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_13[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_14[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_15[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_16[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_17[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_18[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_19[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_20[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_21[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_22[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_23[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_24[`VWidth*24-1:`VWidth*23],
					  QSN_APPmsg_25[`VWidth*24-1:`VWidth*23],
					  APPmsg_old_26_D1[`VWidth*24-1:`VWidth*23]};	
					  
assign DN_APPmsg_22 ={QSN_APPmsg_0 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_1 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_2 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_3 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_4 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_5 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_6 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_7 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_8 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_9 [`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_10[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_11[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_12[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_13[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_14[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_15[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_16[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_17[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_18[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_19[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_20[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_21[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_22[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_23[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_24[`VWidth*23-1:`VWidth*22],
					  QSN_APPmsg_25[`VWidth*23-1:`VWidth*22],
					  APPmsg_old_26_D1[`VWidth*23-1:`VWidth*22]};

assign DN_APPmsg_21 ={QSN_APPmsg_0 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_1 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_2 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_3 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_4 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_5 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_6 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_7 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_8 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_9 [`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_10[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_11[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_12[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_13[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_14[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_15[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_16[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_17[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_18[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_19[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_20[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_21[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_22[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_23[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_24[`VWidth*22-1:`VWidth*21],
					  QSN_APPmsg_25[`VWidth*22-1:`VWidth*21],
					  APPmsg_old_26_D1[`VWidth*22-1:`VWidth*21]};

assign DN_APPmsg_20 ={QSN_APPmsg_0 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_1 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_2 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_3 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_4 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_5 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_6 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_7 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_8 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_9 [`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_10[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_11[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_12[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_13[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_14[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_15[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_16[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_17[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_18[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_19[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_20[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_21[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_22[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_23[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_24[`VWidth*21-1:`VWidth*20],
					  QSN_APPmsg_25[`VWidth*21-1:`VWidth*20],
					  APPmsg_old_26_D1[`VWidth*21-1:`VWidth*20]};		

assign DN_APPmsg_19 ={QSN_APPmsg_0 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_1 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_2 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_3 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_4 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_5 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_6 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_7 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_8 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_9 [`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_10[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_11[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_12[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_13[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_14[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_15[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_16[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_17[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_18[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_19[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_20[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_21[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_22[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_23[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_24[`VWidth*20-1:`VWidth*19],
					  QSN_APPmsg_25[`VWidth*20-1:`VWidth*19],
					  APPmsg_old_26_D1[`VWidth*20-1:`VWidth*19]};
assign DN_APPmsg_18 ={QSN_APPmsg_0 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_1 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_2 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_3 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_4 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_5 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_6 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_7 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_8 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_9 [`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_10[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_11[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_12[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_13[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_14[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_15[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_16[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_17[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_18[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_19[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_20[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_21[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_22[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_23[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_24[`VWidth*19-1:`VWidth*18],
					  QSN_APPmsg_25[`VWidth*19-1:`VWidth*18],
					  APPmsg_old_26_D1[`VWidth*19-1:`VWidth*18]};
assign DN_APPmsg_17 ={QSN_APPmsg_0 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_1 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_2 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_3 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_4 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_5 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_6 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_7 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_8 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_9 [`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_10[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_11[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_12[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_13[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_14[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_15[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_16[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_17[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_18[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_19[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_20[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_21[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_22[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_23[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_24[`VWidth*18-1:`VWidth*17],
					  QSN_APPmsg_25[`VWidth*18-1:`VWidth*17],
					  APPmsg_old_26_D1[`VWidth*18-1:`VWidth*17]};
assign DN_APPmsg_16 ={QSN_APPmsg_0 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_1 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_2 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_3 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_4 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_5 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_6 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_7 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_8 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_9 [`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_10[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_11[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_12[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_13[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_14[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_15[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_16[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_17[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_18[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_19[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_20[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_21[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_22[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_23[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_24[`VWidth*17-1:`VWidth*16],
					  QSN_APPmsg_25[`VWidth*17-1:`VWidth*16],
					  APPmsg_old_26_D1[`VWidth*17-1:`VWidth*16]};
assign DN_APPmsg_15 ={QSN_APPmsg_0 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_1 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_2 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_3 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_4 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_5 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_6 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_7 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_8 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_9 [`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_10[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_11[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_12[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_13[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_14[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_15[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_16[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_17[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_18[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_19[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_20[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_21[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_22[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_23[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_24[`VWidth*16-1:`VWidth*15],
					  QSN_APPmsg_25[`VWidth*16-1:`VWidth*15],
					  APPmsg_old_26_D1[`VWidth*16-1:`VWidth*15]};
assign DN_APPmsg_14 ={QSN_APPmsg_0 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_1 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_2 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_3 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_4 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_5 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_6 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_7 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_8 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_9 [`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_10[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_11[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_12[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_13[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_14[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_15[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_16[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_17[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_18[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_19[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_20[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_21[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_22[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_23[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_24[`VWidth*15-1:`VWidth*14],
					  QSN_APPmsg_25[`VWidth*15-1:`VWidth*14],
					  APPmsg_old_26_D1[`VWidth*15-1:`VWidth*14]};
					  
assign DN_APPmsg_13 ={QSN_APPmsg_0 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_1 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_2 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_3 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_4 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_5 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_6 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_7 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_8 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_9 [`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_10[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_11[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_12[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_13[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_14[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_15[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_16[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_17[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_18[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_19[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_20[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_21[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_22[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_23[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_24[`VWidth*14-1:`VWidth*13],
					  QSN_APPmsg_25[`VWidth*14-1:`VWidth*13],
					  APPmsg_old_26_D1[`VWidth*14-1:`VWidth*13]};
					  
assign DN_APPmsg_12 ={QSN_APPmsg_0 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_1 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_2 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_3 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_4 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_5 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_6 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_7 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_8 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_9 [`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_10[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_11[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_12[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_13[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_14[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_15[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_16[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_17[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_18[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_19[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_20[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_21[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_22[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_23[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_24[`VWidth*13-1:`VWidth*12],
					  QSN_APPmsg_25[`VWidth*13-1:`VWidth*12],
					  APPmsg_old_26_D1[`VWidth*13-1:`VWidth*12]};					  

assign DN_APPmsg_11 ={QSN_APPmsg_0 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_1 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_2 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_3 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_4 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_5 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_6 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_7 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_8 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_9 [`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_10[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_11[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_12[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_13[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_14[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_15[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_16[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_17[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_18[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_19[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_20[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_21[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_22[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_23[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_24[`VWidth*12-1:`VWidth*11],
					  QSN_APPmsg_25[`VWidth*12-1:`VWidth*11],
					  APPmsg_old_26_D1[`VWidth*12-1:`VWidth*11]};
					  
assign DN_APPmsg_10 ={QSN_APPmsg_0 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_1 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_2 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_3 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_4 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_5 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_6 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_7 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_8 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_9 [`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_10[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_11[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_12[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_13[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_14[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_15[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_16[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_17[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_18[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_19[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_20[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_21[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_22[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_23[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_24[`VWidth*11-1:`VWidth*10],
					  QSN_APPmsg_25[`VWidth*11-1:`VWidth*10],
					  APPmsg_old_26_D1[`VWidth*11-1:`VWidth*10]};			

assign DN_APPmsg_9 = {QSN_APPmsg_0 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_1 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_2 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_3 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_4 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_5 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_6 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_7 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_8 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_9 [`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_10[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_11[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_12[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_13[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_14[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_15[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_16[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_17[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_18[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_19[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_20[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_21[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_22[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_23[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_24[`VWidth*10-1:`VWidth*9],
					  QSN_APPmsg_25[`VWidth*10-1:`VWidth*9],
					  APPmsg_old_26_D1[`VWidth*10-1:`VWidth*9]};
assign DN_APPmsg_8 = {QSN_APPmsg_0 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_1 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_2 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_3 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_4 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_5 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_6 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_7 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_8 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_9 [`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_10[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_11[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_12[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_13[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_14[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_15[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_16[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_17[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_18[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_19[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_20[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_21[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_22[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_23[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_24[`VWidth*9-1:`VWidth*8],
					  QSN_APPmsg_25[`VWidth*9-1:`VWidth*8],
					  APPmsg_old_26_D1[`VWidth*9-1:`VWidth*8]};
assign DN_APPmsg_7 = {QSN_APPmsg_0 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_1 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_2 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_3 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_4 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_5 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_6 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_7 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_8 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_9 [`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_10[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_11[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_12[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_13[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_14[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_15[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_16[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_17[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_18[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_19[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_20[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_21[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_22[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_23[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_24[`VWidth*8-1:`VWidth*7],
					  QSN_APPmsg_25[`VWidth*8-1:`VWidth*7],
					  APPmsg_old_26_D1[`VWidth*8-1:`VWidth*7]};
assign DN_APPmsg_6 = {QSN_APPmsg_0 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_1 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_2 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_3 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_4 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_5 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_6 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_7 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_8 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_9 [`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_10[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_11[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_12[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_13[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_14[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_15[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_16[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_17[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_18[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_19[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_20[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_21[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_22[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_23[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_24[`VWidth*7-1:`VWidth*6],
					  QSN_APPmsg_25[`VWidth*7-1:`VWidth*6],
					  APPmsg_old_26_D1[`VWidth*7-1:`VWidth*6]};
assign DN_APPmsg_5 = {QSN_APPmsg_0 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_1 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_2 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_3 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_4 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_5 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_6 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_7 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_8 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_9 [`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_10[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_11[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_12[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_13[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_14[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_15[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_16[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_17[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_18[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_19[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_20[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_21[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_22[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_23[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_24[`VWidth*6-1:`VWidth*5],
					  QSN_APPmsg_25[`VWidth*6-1:`VWidth*5],
					  APPmsg_old_26_D1[`VWidth*6-1:`VWidth*5]};
assign DN_APPmsg_4 = {QSN_APPmsg_0 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_1 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_2 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_3 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_4 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_5 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_6 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_7 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_8 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_9 [`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_10[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_11[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_12[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_13[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_14[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_15[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_16[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_17[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_18[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_19[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_20[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_21[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_22[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_23[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_24[`VWidth*5-1:`VWidth*4],
					  QSN_APPmsg_25[`VWidth*5-1:`VWidth*4],
					  APPmsg_old_26_D1[`VWidth*5-1:`VWidth*4]};
					  
assign DN_APPmsg_3 = {QSN_APPmsg_0 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_1 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_2 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_3 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_4 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_5 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_6 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_7 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_8 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_9 [`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_10[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_11[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_12[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_13[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_14[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_15[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_16[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_17[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_18[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_19[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_20[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_21[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_22[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_23[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_24[`VWidth*4-1:`VWidth*3],
					  QSN_APPmsg_25[`VWidth*4-1:`VWidth*3],
					  APPmsg_old_26_D1[`VWidth*4-1:`VWidth*3]};
					  
assign DN_APPmsg_2 = {QSN_APPmsg_0 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_1 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_2 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_3 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_4 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_5 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_6 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_7 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_8 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_9 [`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_10[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_11[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_12[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_13[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_14[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_15[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_16[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_17[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_18[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_19[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_20[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_21[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_22[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_23[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_24[`VWidth*3-1:`VWidth*2],
					  QSN_APPmsg_25[`VWidth*3-1:`VWidth*2],
					  APPmsg_old_26_D1[`VWidth*3-1:`VWidth*2]};					  

assign DN_APPmsg_1 = {QSN_APPmsg_0 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_1 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_2 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_3 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_4 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_5 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_6 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_7 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_8 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_9 [`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_10[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_11[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_12[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_13[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_14[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_15[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_16[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_17[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_18[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_19[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_20[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_21[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_22[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_23[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_24[`VWidth*2-1:`VWidth*1],
					  QSN_APPmsg_25[`VWidth*2-1:`VWidth*1],
					  APPmsg_old_26_D1[`VWidth*2-1:`VWidth*1]};
					  
assign DN_APPmsg_0 = {QSN_APPmsg_0 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_1 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_2 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_3 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_4 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_5 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_6 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_7 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_8 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_9 [`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_10[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_11[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_12[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_13[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_14[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_15[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_16[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_17[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_18[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_19[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_20[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_21[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_22[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_23[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_24[`VWidth*1-1:`VWidth*0],
					  QSN_APPmsg_25[`VWidth*1-1:`VWidth*0],
					  APPmsg_old_26_D1[`VWidth*1-1:`VWidth*0]};	
					  
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		DN_APPmsg_reg_0  <= 0 ;
		DN_APPmsg_reg_1  <= 0 ;
		DN_APPmsg_reg_2  <= 0 ;
		DN_APPmsg_reg_3  <= 0 ;
		DN_APPmsg_reg_4  <= 0 ;
		DN_APPmsg_reg_5  <= 0 ;
		DN_APPmsg_reg_6  <= 0 ;
		DN_APPmsg_reg_7  <= 0 ;
		DN_APPmsg_reg_8  <= 0 ;
		DN_APPmsg_reg_9  <= 0 ;
		DN_APPmsg_reg_10 <= 0 ;
		DN_APPmsg_reg_11 <= 0 ;
		DN_APPmsg_reg_12 <= 0 ;
		DN_APPmsg_reg_13 <= 0 ;
		DN_APPmsg_reg_14 <= 0 ;
		DN_APPmsg_reg_15 <= 0 ;
		DN_APPmsg_reg_16 <= 0 ;
		DN_APPmsg_reg_17 <= 0 ;
		DN_APPmsg_reg_18 <= 0 ;
		DN_APPmsg_reg_19 <= 0 ;
		DN_APPmsg_reg_20 <= 0 ;
		DN_APPmsg_reg_21 <= 0 ;
		DN_APPmsg_reg_22 <= 0 ;
		DN_APPmsg_reg_23 <= 0 ;
		DN_APPmsg_reg_24 <= 0 ;
		DN_APPmsg_reg_25 <= 0 ;
		DN_APPmsg_reg_26 <= 0 ;
		DN_APPmsg_reg_27 <= 0 ;
		DN_APPmsg_reg_28 <= 0 ;
		DN_APPmsg_reg_29 <= 0 ;
		DN_APPmsg_reg_30 <= 0 ;
		DN_APPmsg_reg_31 <= 0 ;
	end
	else begin
		DN_APPmsg_reg_0  <= DN_APPmsg_0  ;
		DN_APPmsg_reg_1  <= DN_APPmsg_1  ;
		DN_APPmsg_reg_2  <= DN_APPmsg_2  ;
		DN_APPmsg_reg_3  <= DN_APPmsg_3  ;
		DN_APPmsg_reg_4  <= DN_APPmsg_4  ;
		DN_APPmsg_reg_5  <= DN_APPmsg_5  ;
		DN_APPmsg_reg_6  <= DN_APPmsg_6  ;
		DN_APPmsg_reg_7  <= DN_APPmsg_7  ;
		DN_APPmsg_reg_8  <= DN_APPmsg_8  ;
		DN_APPmsg_reg_9  <= DN_APPmsg_9  ;
		DN_APPmsg_reg_10 <= DN_APPmsg_10 ;
		DN_APPmsg_reg_11 <= DN_APPmsg_11 ;
		DN_APPmsg_reg_12 <= DN_APPmsg_12 ;
		DN_APPmsg_reg_13 <= DN_APPmsg_13 ;
		DN_APPmsg_reg_14 <= DN_APPmsg_14 ;
		DN_APPmsg_reg_15 <= DN_APPmsg_15 ;
		DN_APPmsg_reg_16 <= DN_APPmsg_16 ;
		DN_APPmsg_reg_17 <= DN_APPmsg_17 ;
		DN_APPmsg_reg_18 <= DN_APPmsg_18 ;
		DN_APPmsg_reg_19 <= DN_APPmsg_19 ;
		DN_APPmsg_reg_20 <= DN_APPmsg_20 ;
		DN_APPmsg_reg_21 <= DN_APPmsg_21 ;
		DN_APPmsg_reg_22 <= DN_APPmsg_22 ;
		DN_APPmsg_reg_23 <= DN_APPmsg_23 ;
		DN_APPmsg_reg_24 <= DN_APPmsg_24 ;
		DN_APPmsg_reg_25 <= DN_APPmsg_25 ;
		DN_APPmsg_reg_26 <= DN_APPmsg_26 ;
		DN_APPmsg_reg_27 <= DN_APPmsg_27 ;
		DN_APPmsg_reg_28 <= DN_APPmsg_28 ;
		DN_APPmsg_reg_29 <= DN_APPmsg_29 ;
		DN_APPmsg_reg_30 <= DN_APPmsg_30 ;
		DN_APPmsg_reg_31 <= DN_APPmsg_31 ;
	end
end				  
					  
// =============================================================================
 // CTV（Check-to-Variable 中间存储）
 // - 读写使能与地址：CTV_rd_en/CTV_wr_en/CTV_addr_*；
 // - CTV_old_* / CTV_new_*：旧值与更新值；
 // - APP_CTV_*：与 APP 聚合后的入 GN 数据；
 // ============================================================================= memory
/*
reg CTV_wr_en,CTV_rd_en;
reg [8:0] CTV_addr_wr,CTV_addr_rd;
wire [`DPUdata_Len-1:0]CTV_old_0,CTV_old_1,CTV_old_2,CTV_old_3,CTV_old_4,CTV_old_5,CTV_old_6,CTV_old_7,CTV_old_8,CTV_old_9,
                  CTV_old_10,CTV_old_11,CTV_old_12,CTV_old_13,CTV_old_14,CTV_old_15,CTV_old_16,CTV_old_17,CTV_old_18,CTV_old_19,
                  CTV_old_20,CTV_old_21,CTV_old_22,CTV_old_23,CTV_old_24,CTV_old_25,CTV_old_26,CTV_old_27,CTV_old_28,CTV_old_29,CTV_old_30,CTV_old_31;  
wire [`DPUdata_Len-1:0]CTV_new_0,CTV_new_1,CTV_new_2,CTV_new_3,CTV_new_4,CTV_new_5,CTV_new_6,CTV_new_7,CTV_new_8,CTV_new_9,
                  CTV_new_10,CTV_new_11,CTV_new_12,CTV_new_13,CTV_new_14,CTV_new_15,CTV_new_16,CTV_new_17,CTV_new_18,CTV_new_19,
                  CTV_new_20,CTV_new_21,CTV_new_22,CTV_new_23,CTV_new_24,CTV_new_25,CTV_new_26,CTV_new_27,CTV_new_28,CTV_new_29,CTV_new_30,CTV_new_31;  
wire [`DPUdata_Len-1:0]APP_CTV_0...;
*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_rd_D0 <= 0;
		APP_rd_D1 <= 0;
		APP_rd_D2 <= 0;
	end
	else begin
		APP_rd_D0 <= APP_rd_en;
		APP_rd_D1 <= APP_rd_D0;
		APP_rd_D2 <= APP_rd_D1;
	end
end

reg [3:0] CTV_rd_en_cnt_1;
reg CTV_rd_en_flag;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_rd_en_cnt_1 <= 0;
		CTV_rd_en_flag  <= 1;
	end
	else if(CTV_rd_en) begin
		if(CTV_rd_en_cnt_1 == 4'd15) begin
			CTV_rd_en_cnt_1 <= 0;
			CTV_rd_en_flag  <= 0;
			end
		else if(CTV_rd_en_flag) begin
			CTV_rd_en_cnt_1 <= CTV_rd_en_cnt_1 + 1;
		end
	end
	else begin
		CTV_rd_en_cnt_1 <= 0;
		CTV_rd_en_flag <= 1;
		end
end

always@(posedge clk or negedge rst_n)begin // APP读取一拍后再读取 CTV_rd  CTV_rd_en = 1
	if(!rst_n)begin
		CTV_rd_en <= 0;
	end
	else begin
		if(!decode_out_start_to_decode_valid_time)
		CTV_rd_en <= APP_rd_D1;
		else 
		CTV_rd_en <= 0;
	end
end


always@(posedge clk or negedge rst_n)begin //同样读取相同深度
	if(!rst_n)begin
		CTV_rd_en_cnt <= 0;
	end
	else if(CTV_rd_en)begin
		if(CTV_rd_en_cnt == APP_addr_rd_max)
			CTV_rd_en_cnt <= 0;
		else
			CTV_rd_en_cnt <= CTV_rd_en_cnt + 1;
	end
end

reg [4:0] CTV_rd_begin_cnt;
reg CTV_rd_begin_cnt_flag;
reg CTV_rd_D0;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_rd_D0 <= 0;
	end
	else
		CTV_rd_D0 <= CTV_rd_en;

end

always@(posedge clk or negedge rst_n)begin //计算 CTV_rd_begin_cnt 开始了多少拍
	if(!rst_n)begin
		CTV_rd_begin_cnt <= 0;
		CTV_rd_begin_cnt_flag <= 0;
	end
	else if(CTV_rd_en && ~CTV_rd_D0)begin
		CTV_rd_begin_cnt <= 0;
		CTV_rd_begin_cnt_flag <= 1;
	end
	else if(CTV_rd_begin_cnt_flag) begin 
		CTV_rd_begin_cnt <= CTV_rd_begin_cnt + 1 ;
	end
end

//
always@(posedge clk or negedge rst_n)begin //CTV_rd_begin_cnt 经过 CTV_ProcessTime后开始写入
	if(!rst_n)begin
		CTV_wr_en <= 0;
	end
	else if(CTV_wr_en_cnt == APP_addr_rd_max)begin
		CTV_wr_en <= 0;
	end
	else if(CTV_rd_begin_cnt == `CTV_ProcessTime && !decode_out_start_to_decode_valid_time)begin
		CTV_wr_en <= 1;
	end
	else
		CTV_wr_en <= CTV_wr_en;
end


always@(posedge clk or negedge rst_n)begin // 写入 CTV_wr_en_cnt 计数
	if(!rst_n)begin
		CTV_wr_en_cnt <= 0;
	end
	else if(CTV_wr_en_cnt == APP_addr_rd_max)begin
		CTV_wr_en_cnt <= 0;
	end
	else if(CTV_wr_en)begin
		CTV_wr_en_cnt <= CTV_wr_en_cnt+1;
	end
	else
		CTV_wr_en_cnt <= CTV_wr_en_cnt;
end
//
always@(posedge clk or negedge rst_n)begin //CTV_addr_rd 读取深度计数
	if(!rst_n)begin
		CTV_addr_rd <= 0;
	end
	else if(iter_start)begin
		CTV_addr_rd <= 0;	
	end
	else if(CTV_addr_rd == `Total_DPU_small_process_num)begin
		CTV_addr_rd <= 0;
	end
	else if(CTV_rd_en)begin
		CTV_addr_rd <= CTV_addr_rd + 1;
	end
end

always@(posedge clk or negedge rst_n)begin //写入深度计数
	if(!rst_n)begin
		CTV_addr_wr <= 0;
	end
	else if(iter_start)begin
		CTV_addr_wr <= 0;	
	end
	else if(CTV_wr_en)begin
		CTV_addr_wr <= CTV_addr_wr + 1;
	end
end

CTVmemory u0_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_0  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_0  ));
CTVmemory u1_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_1  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_1  ));
CTVmemory u2_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_2  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_2  ));					  
CTVmemory u3_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_3  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_3  ));
CTVmemory u4_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_4  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_4  ));
CTVmemory u5_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_5  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_5  ));
CTVmemory u6_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_6  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_6  ));
CTVmemory u7_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_7  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_7  ));
CTVmemory u8_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_8  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_8  ));					  
CTVmemory u9_CTVmeory(.clka(clk),  .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_9  ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_9  ));
CTVmemory u10_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_10 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_10 ));
CTVmemory u11_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_11 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_11 ));
CTVmemory u12_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_12 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_12 ));
CTVmemory u13_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_13 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_13 ));
CTVmemory u14_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_14 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_14 ));					  
CTVmemory u15_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_15 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_15 ));
CTVmemory u16_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_16 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_16 ));
CTVmemory u17_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_17 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_17 ));
CTVmemory u18_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_18 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_18 ));
CTVmemory u19_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_19 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_19 ));
CTVmemory u20_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_20 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_20 ));					  
CTVmemory u21_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_21 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_21 ));
CTVmemory u22_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_22 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_22 ));
CTVmemory u23_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_23 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_23 ));
CTVmemory u24_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_24 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_24 ));
CTVmemory u25_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_25 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_25 ));
CTVmemory u26_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_26 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_26 ));					  
CTVmemory u27_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_27 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_27 ));
CTVmemory u28_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_28 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_28 ));
CTVmemory u29_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_29 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_29 ));
CTVmemory u30_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_30 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_30 ));
CTVmemory u31_CTVmeory(.clka(clk), .ena(CTV_wr_en), .wea(1'b1), .addra(CTV_addr_wr), .dina(CTV_new_31 ), .clkb(clk), .addrb(CTV_addr_rd), .doutb(CTV_old_31 ));


// =============================================================================
 // DPU - 层级/行级计算核心
 // - DPU_APPmsg_* / signAPP_*：对 APP/QSN 的聚合与符号决策；
 // - flag：对 P 个并行通道的使能标志；
 // =============================================================================
/*
wire [`DPUdata_Len-1:0] DPU_APPmsg_0,DPU_APPmsg_1,DPU_APPmsg_2,DPU_APPmsg_3,DPU_APPmsg_4,DPU_APPmsg_5,DPU_APPmsg_6,DPU_APPmsg_7,DPU_APPmsg_8,DPU_APPmsg_9,
                  DPU_APPmsg_10,DPU_APPmsg_11,DPU_APPmsg_12,DPU_APPmsg_13,DPU_APPmsg_14,DPU_APPmsg_15,DPU_APPmsg_16,DPU_APPmsg_17,DPU_APPmsg_18,DPU_APPmsg_19,
                  DPU_APPmsg_20,DPU_APPmsg_21,DPU_APPmsg_22,DPU_APPmsg_23,DPU_APPmsg_24,DPU_APPmsg_25,DPU_APPmsg_26,DPU_APPmsg_27,DPU_APPmsg_28,DPU_APPmsg_29,DPU_APPmsg_30,DPU_APPmsg_31;
wire  signAPP_0,signAPP_1,signAPP_2,signAPP_3,signAPP_4,signAPP_5,signAPP_6,signAPP_7,signAPP_8,signAPP_9,
                  signAPP_10,signAPP_11,signAPP_12,signAPP_13,signAPP_14,signAPP_15,signAPP_16,signAPP_17,signAPP_18,signAPP_19,
                  signAPP_20,signAPP_21,signAPP_22,signAPP_23,signAPP_24,signAPP_25,signAPP_26,signAPP_27,signAPP_28,signAPP_29,signAPP_30,signAPP_31;   
 */     

assign APP_CTV_0  = first_iter_valid ? 0 : CTV_old_0;
assign APP_CTV_1  = first_iter_valid ? 0 : CTV_old_1; 
assign APP_CTV_2  = first_iter_valid ? 0 : CTV_old_2; 
assign APP_CTV_3  = first_iter_valid ? 0 : CTV_old_3; 
assign APP_CTV_4  = first_iter_valid ? 0 : CTV_old_4; 
assign APP_CTV_5  = first_iter_valid ? 0 : CTV_old_5; 
assign APP_CTV_6  = first_iter_valid ? 0 : CTV_old_6; 
assign APP_CTV_7  = first_iter_valid ? 0 : CTV_old_7; 
assign APP_CTV_8  = first_iter_valid ? 0 : CTV_old_8; 
assign APP_CTV_9  = first_iter_valid ? 0 : CTV_old_9; 
assign APP_CTV_10 = first_iter_valid ? 0 : CTV_old_10;
assign APP_CTV_11 = first_iter_valid ? 0 : CTV_old_11;
assign APP_CTV_12 = first_iter_valid ? 0 : CTV_old_12;
assign APP_CTV_13 = first_iter_valid ? 0 : CTV_old_13;
assign APP_CTV_14 = first_iter_valid ? 0 : CTV_old_14;
assign APP_CTV_15 = first_iter_valid ? 0 : CTV_old_15;
assign APP_CTV_16 = first_iter_valid ? 0 : CTV_old_16;
assign APP_CTV_17 = first_iter_valid ? 0 : CTV_old_17;
assign APP_CTV_18 = first_iter_valid ? 0 : CTV_old_18;
assign APP_CTV_19 = first_iter_valid ? 0 : CTV_old_19;
assign APP_CTV_20 = first_iter_valid ? 0 : CTV_old_20;
assign APP_CTV_21 = first_iter_valid ? 0 : CTV_old_21;
assign APP_CTV_22 = first_iter_valid ? 0 : CTV_old_22;
assign APP_CTV_23 = first_iter_valid ? 0 : CTV_old_23;
assign APP_CTV_24 = first_iter_valid ? 0 : CTV_old_24;
assign APP_CTV_25 = first_iter_valid ? 0 : CTV_old_25;
assign APP_CTV_26 = first_iter_valid ? 0 : CTV_old_26;
assign APP_CTV_27 = first_iter_valid ? 0 : CTV_old_27;
assign APP_CTV_28 = first_iter_valid ? 0 : CTV_old_28;
assign APP_CTV_29 = first_iter_valid ? 0 : CTV_old_29;
assign APP_CTV_30 = first_iter_valid ? 0 : CTV_old_30;
assign APP_CTV_31 = first_iter_valid ? 0 : CTV_old_31;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		flag <= 0;
	end
	else if(iter_start_D3 | APP_rd_endD16) begin
		flag <= {~share_flag,
				 shift_25[`HijWidth-1],
				 shift_24[`HijWidth-1],
				 shift_23[`HijWidth-1],
				 shift_22[`HijWidth-1],
				 shift_21[`HijWidth-1],
				 shift_20[`HijWidth-1],
				 shift_19[`HijWidth-1],
				 shift_18[`HijWidth-1],
				 shift_17[`HijWidth-1],
				 shift_16[`HijWidth-1],
				 shift_15[`HijWidth-1],
				 shift_14[`HijWidth-1],
				 shift_13[`HijWidth-1],
				 shift_12[`HijWidth-1],
				 shift_11[`HijWidth-1],
				 shift_10[`HijWidth-1],
				 shift_9[`HijWidth-1],
				 shift_8[`HijWidth-1],
				 shift_7[`HijWidth-1],
				 shift_6[`HijWidth-1],
				 shift_5[`HijWidth-1],
				 shift_4[`HijWidth-1],
				 shift_3[`HijWidth-1],
				 shift_2[`HijWidth-1],
				 shift_1[`HijWidth-1],
				 shift_0[`HijWidth-1]
				 };
	end
	else 
		flag <= flag;
end


 
DPU u0_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_0 ),.CTVdin(APP_CTV_0 ),.flag(flag),.APPdout(DPU_APPmsg_0 ),.CTVdout(CTV_new_0 ),.signAPP(signAPP_0 ) ); //输入重整后的同一行数据  flag控制是否链接
DPU u1_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_1 ),.CTVdin(APP_CTV_1 ),.flag(flag),.APPdout(DPU_APPmsg_1 ),.CTVdout(CTV_new_1 ),.signAPP(signAPP_1 ));
DPU u2_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_2 ),.CTVdin(APP_CTV_2 ),.flag(flag),.APPdout(DPU_APPmsg_2 ),.CTVdout(CTV_new_2 ),.signAPP(signAPP_2 ));
DPU u3_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_3 ),.CTVdin(APP_CTV_3 ),.flag(flag),.APPdout(DPU_APPmsg_3 ),.CTVdout(CTV_new_3 ),.signAPP(signAPP_3 ));
DPU u4_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_4 ),.CTVdin(APP_CTV_4 ),.flag(flag),.APPdout(DPU_APPmsg_4 ),.CTVdout(CTV_new_4 ),.signAPP(signAPP_4 ));
DPU u5_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_5 ),.CTVdin(APP_CTV_5 ),.flag(flag),.APPdout(DPU_APPmsg_5 ),.CTVdout(CTV_new_5 ),.signAPP(signAPP_5 ));
DPU u6_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_6 ),.CTVdin(APP_CTV_6 ),.flag(flag),.APPdout(DPU_APPmsg_6 ),.CTVdout(CTV_new_6 ),.signAPP(signAPP_6 ));
DPU u7_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_7 ),.CTVdin(APP_CTV_7 ),.flag(flag),.APPdout(DPU_APPmsg_7 ),.CTVdout(CTV_new_7 ),.signAPP(signAPP_7 ));
DPU u8_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_8 ),.CTVdin(APP_CTV_8 ),.flag(flag),.APPdout(DPU_APPmsg_8 ),.CTVdout(CTV_new_8 ),.signAPP(signAPP_8 ));
DPU u9_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_9 ),.CTVdin(APP_CTV_9 ),.flag(flag),.APPdout(DPU_APPmsg_9 ),.CTVdout(CTV_new_9 ),.signAPP(signAPP_9 ));
DPU u10_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_10),.CTVdin(APP_CTV_10),.flag(flag),.APPdout(DPU_APPmsg_10),.CTVdout(CTV_new_10),.signAPP(signAPP_10));
DPU u11_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_11),.CTVdin(APP_CTV_11),.flag(flag),.APPdout(DPU_APPmsg_11),.CTVdout(CTV_new_11),.signAPP(signAPP_11));
DPU u12_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_12),.CTVdin(APP_CTV_12),.flag(flag),.APPdout(DPU_APPmsg_12),.CTVdout(CTV_new_12),.signAPP(signAPP_12));
DPU u13_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_13),.CTVdin(APP_CTV_13),.flag(flag),.APPdout(DPU_APPmsg_13),.CTVdout(CTV_new_13),.signAPP(signAPP_13));
DPU u14_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_14),.CTVdin(APP_CTV_14),.flag(flag),.APPdout(DPU_APPmsg_14),.CTVdout(CTV_new_14),.signAPP(signAPP_14));
DPU u15_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_15),.CTVdin(APP_CTV_15),.flag(flag),.APPdout(DPU_APPmsg_15),.CTVdout(CTV_new_15),.signAPP(signAPP_15));
DPU u16_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_16),.CTVdin(APP_CTV_16),.flag(flag),.APPdout(DPU_APPmsg_16),.CTVdout(CTV_new_16),.signAPP(signAPP_16));
DPU u17_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_17),.CTVdin(APP_CTV_17),.flag(flag),.APPdout(DPU_APPmsg_17),.CTVdout(CTV_new_17),.signAPP(signAPP_17));
DPU u18_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_18),.CTVdin(APP_CTV_18),.flag(flag),.APPdout(DPU_APPmsg_18),.CTVdout(CTV_new_18),.signAPP(signAPP_18));
DPU u19_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_19),.CTVdin(APP_CTV_19),.flag(flag),.APPdout(DPU_APPmsg_19),.CTVdout(CTV_new_19),.signAPP(signAPP_19));
DPU u20_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_20),.CTVdin(APP_CTV_20),.flag(flag),.APPdout(DPU_APPmsg_20),.CTVdout(CTV_new_20),.signAPP(signAPP_20));
DPU u21_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_21),.CTVdin(APP_CTV_21),.flag(flag),.APPdout(DPU_APPmsg_21),.CTVdout(CTV_new_21),.signAPP(signAPP_21));
DPU u22_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_22),.CTVdin(APP_CTV_22),.flag(flag),.APPdout(DPU_APPmsg_22),.CTVdout(CTV_new_22),.signAPP(signAPP_22));
DPU u23_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_23),.CTVdin(APP_CTV_23),.flag(flag),.APPdout(DPU_APPmsg_23),.CTVdout(CTV_new_23),.signAPP(signAPP_23));
DPU u24_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_24),.CTVdin(APP_CTV_24),.flag(flag),.APPdout(DPU_APPmsg_24),.CTVdout(CTV_new_24),.signAPP(signAPP_24));
DPU u25_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_25),.CTVdin(APP_CTV_25),.flag(flag),.APPdout(DPU_APPmsg_25),.CTVdout(CTV_new_25),.signAPP(signAPP_25));
DPU u26_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_26),.CTVdin(APP_CTV_26),.flag(flag),.APPdout(DPU_APPmsg_26),.CTVdout(CTV_new_26),.signAPP(signAPP_26));
DPU u27_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_27),.CTVdin(APP_CTV_27),.flag(flag),.APPdout(DPU_APPmsg_27),.CTVdout(CTV_new_27),.signAPP(signAPP_27));
DPU u28_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_28),.CTVdin(APP_CTV_28),.flag(flag),.APPdout(DPU_APPmsg_28),.CTVdout(CTV_new_28),.signAPP(signAPP_28));
DPU u29_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_29),.CTVdin(APP_CTV_29),.flag(flag),.APPdout(DPU_APPmsg_29),.CTVdout(CTV_new_29),.signAPP(signAPP_29));
DPU u30_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_30),.CTVdin(APP_CTV_30),.flag(flag),.APPdout(DPU_APPmsg_30),.CTVdout(CTV_new_30),.signAPP(signAPP_30));
DPU u31_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_31),.CTVdin(APP_CTV_31),.flag(flag),.APPdout(DPU_APPmsg_31),.CTVdout(CTV_new_31),.signAPP(signAPP_31)); //DN_APPmsg_reg_31经过DPU后送出  DPU_APPmsg_31


//Gathering Network
/*
wire [`APPdata_Len-1:0] GN_APPmsg_0,GN_APPmsg_1,GN_APPmsg_2,GN_APPmsg_3,GN_APPmsg_4,GN_APPmsg_5,GN_APPmsg_6,GN_APPmsg_7,GN_APPmsg_8,GN_APPmsg_9,
                  GN_APPmsg_10,GN_APPmsg_11,GN_APPmsg_12,GN_APPmsg_13,GN_APPmsg_14,GN_APPmsg_15,GN_APPmsg_16,GN_APPmsg_17,GN_APPmsg_18,GN_APPmsg_19,
                  GN_APPmsg_20,GN_APPmsg_21,GN_APPmsg_22,GN_APPmsg_23,GN_APPmsg_24,GN_APPmsg_25,GN_APPmsg_26;
*/

assign GN_APPmsg_0 ={ DPU_APPmsg_31[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_30[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_29[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_28[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_27[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_26[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_25[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_24[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_23[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_22[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_21[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_20[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_19[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_18[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_17[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_16[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_15[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_14[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_13[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_12[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_11[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_10[`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_9 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_8 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_7 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_6 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_5 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_4 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_3 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_2 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_1 [`VWidth*27-1:`VWidth*26],
					  DPU_APPmsg_0 [`VWidth*27-1:`VWidth*26]};
					  
assign GN_APPmsg_1 ={ DPU_APPmsg_31[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_30[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_29[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_28[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_27[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_26[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_25[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_24[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_23[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_22[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_21[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_20[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_19[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_18[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_17[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_16[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_15[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_14[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_13[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_12[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_11[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_10[`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_9 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_8 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_7 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_6 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_5 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_4 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_3 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_2 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_1 [`VWidth*26-1:`VWidth*25],
					  DPU_APPmsg_0 [`VWidth*26-1:`VWidth*25]};

assign GN_APPmsg_2 ={ DPU_APPmsg_31[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_30[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_29[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_28[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_27[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_26[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_25[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_24[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_23[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_22[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_21[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_20[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_19[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_18[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_17[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_16[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_15[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_14[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_13[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_12[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_11[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_10[`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_9 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_8 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_7 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_6 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_5 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_4 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_3 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_2 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_1 [`VWidth*25-1:`VWidth*24],
					  DPU_APPmsg_0 [`VWidth*25-1:`VWidth*24]};
					  
					  
assign GN_APPmsg_3 ={ DPU_APPmsg_31[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_30[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_29[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_28[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_27[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_26[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_25[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_24[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_23[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_22[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_21[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_20[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_19[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_18[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_17[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_16[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_15[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_14[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_13[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_12[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_11[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_10[`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_9 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_8 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_7 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_6 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_5 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_4 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_3 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_2 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_1 [`VWidth*24-1:`VWidth*23],
					  DPU_APPmsg_0 [`VWidth*24-1:`VWidth*23]};
					  
assign GN_APPmsg_4 ={ DPU_APPmsg_31[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_30[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_29[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_28[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_27[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_26[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_25[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_24[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_23[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_22[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_21[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_20[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_19[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_18[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_17[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_16[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_15[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_14[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_13[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_12[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_11[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_10[`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_9 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_8 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_7 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_6 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_5 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_4 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_3 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_2 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_1 [`VWidth*23-1:`VWidth*22],
					  DPU_APPmsg_0 [`VWidth*23-1:`VWidth*22]};

assign GN_APPmsg_5 ={ DPU_APPmsg_31[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_30[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_29[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_28[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_27[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_26[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_25[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_24[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_23[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_22[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_21[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_20[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_19[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_18[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_17[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_16[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_15[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_14[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_13[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_12[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_11[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_10[`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_9 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_8 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_7 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_6 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_5 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_4 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_3 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_2 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_1 [`VWidth*22-1:`VWidth*21],
					  DPU_APPmsg_0 [`VWidth*22-1:`VWidth*21]};		
					  
assign GN_APPmsg_6 ={ DPU_APPmsg_31[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_30[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_29[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_28[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_27[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_26[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_25[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_24[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_23[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_22[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_21[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_20[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_19[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_18[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_17[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_16[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_15[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_14[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_13[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_12[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_11[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_10[`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_9 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_8 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_7 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_6 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_5 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_4 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_3 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_2 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_1 [`VWidth*21-1:`VWidth*20],
					  DPU_APPmsg_0 [`VWidth*21-1:`VWidth*20]};	

assign GN_APPmsg_7 ={ DPU_APPmsg_31[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_30[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_29[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_28[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_27[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_26[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_25[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_24[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_23[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_22[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_21[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_20[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_19[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_18[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_17[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_16[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_15[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_14[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_13[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_12[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_11[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_10[`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_9 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_8 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_7 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_6 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_5 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_4 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_3 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_2 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_1 [`VWidth*20-1:`VWidth*19],
					  DPU_APPmsg_0 [`VWidth*20-1:`VWidth*19]};							  
					  

assign GN_APPmsg_8 ={ DPU_APPmsg_31[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_30[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_29[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_28[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_27[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_26[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_25[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_24[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_23[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_22[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_21[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_20[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_19[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_18[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_17[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_16[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_15[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_14[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_13[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_12[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_11[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_10[`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_9 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_8 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_7 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_6 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_5 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_4 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_3 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_2 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_1 [`VWidth*19-1:`VWidth*18],
					  DPU_APPmsg_0 [`VWidth*19-1:`VWidth*18]};	

assign GN_APPmsg_9 ={ DPU_APPmsg_31[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_30[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_29[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_28[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_27[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_26[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_25[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_24[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_23[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_22[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_21[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_20[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_19[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_18[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_17[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_16[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_15[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_14[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_13[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_12[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_11[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_10[`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_9 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_8 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_7 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_6 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_5 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_4 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_3 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_2 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_1 [`VWidth*18-1:`VWidth*17],
					  DPU_APPmsg_0 [`VWidth*18-1:`VWidth*17]};						  
					  
assign GN_APPmsg_10 ={DPU_APPmsg_31[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_30[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_29[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_28[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_27[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_26[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_25[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_24[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_23[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_22[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_21[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_20[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_19[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_18[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_17[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_16[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_15[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_14[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_13[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_12[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_11[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_10[`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_9 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_8 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_7 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_6 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_5 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_4 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_3 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_2 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_1 [`VWidth*17-1:`VWidth*16],
					  DPU_APPmsg_0 [`VWidth*17-1:`VWidth*16]};	

assign GN_APPmsg_11 ={DPU_APPmsg_31[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_30[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_29[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_28[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_27[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_26[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_25[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_24[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_23[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_22[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_21[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_20[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_19[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_18[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_17[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_16[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_15[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_14[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_13[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_12[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_11[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_10[`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_9 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_8 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_7 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_6 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_5 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_4 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_3 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_2 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_1 [`VWidth*16-1:`VWidth*15],
					  DPU_APPmsg_0 [`VWidth*16-1:`VWidth*15]};		

assign GN_APPmsg_12 ={DPU_APPmsg_31[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_30[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_29[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_28[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_27[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_26[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_25[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_24[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_23[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_22[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_21[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_20[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_19[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_18[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_17[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_16[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_15[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_14[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_13[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_12[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_11[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_10[`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_9 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_8 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_7 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_6 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_5 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_4 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_3 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_2 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_1 [`VWidth*15-1:`VWidth*14],
					  DPU_APPmsg_0 [`VWidth*15-1:`VWidth*14]};	

assign GN_APPmsg_13 ={DPU_APPmsg_31[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_30[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_29[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_28[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_27[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_26[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_25[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_24[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_23[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_22[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_21[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_20[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_19[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_18[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_17[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_16[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_15[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_14[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_13[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_12[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_11[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_10[`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_9 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_8 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_7 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_6 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_5 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_4 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_3 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_2 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_1 [`VWidth*14-1:`VWidth*13],
					  DPU_APPmsg_0 [`VWidth*14-1:`VWidth*13]};

assign GN_APPmsg_14 ={DPU_APPmsg_31[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_30[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_29[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_28[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_27[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_26[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_25[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_24[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_23[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_22[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_21[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_20[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_19[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_18[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_17[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_16[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_15[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_14[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_13[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_12[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_11[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_10[`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_9 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_8 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_7 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_6 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_5 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_4 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_3 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_2 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_1 [`VWidth*13-1:`VWidth*12],
					  DPU_APPmsg_0 [`VWidth*13-1:`VWidth*12]};	

assign GN_APPmsg_15 ={DPU_APPmsg_31[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_30[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_29[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_28[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_27[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_26[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_25[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_24[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_23[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_22[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_21[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_20[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_19[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_18[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_17[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_16[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_15[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_14[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_13[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_12[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_11[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_10[`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_9 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_8 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_7 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_6 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_5 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_4 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_3 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_2 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_1 [`VWidth*12-1:`VWidth*11],
					  DPU_APPmsg_0 [`VWidth*12-1:`VWidth*11]};	

assign GN_APPmsg_16 ={DPU_APPmsg_31[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_30[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_29[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_28[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_27[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_26[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_25[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_24[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_23[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_22[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_21[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_20[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_19[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_18[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_17[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_16[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_15[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_14[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_13[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_12[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_11[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_10[`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_9 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_8 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_7 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_6 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_5 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_4 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_3 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_2 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_1 [`VWidth*11-1:`VWidth*10],
					  DPU_APPmsg_0 [`VWidth*11-1:`VWidth*10]};	

assign GN_APPmsg_17 ={DPU_APPmsg_31[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_30[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_29[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_28[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_27[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_26[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_25[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_24[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_23[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_22[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_21[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_20[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_19[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_18[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_17[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_16[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_15[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_14[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_13[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_12[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_11[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_10[`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_9 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_8 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_7 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_6 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_5 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_4 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_3 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_2 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_1 [`VWidth*10-1:`VWidth*9],
					  DPU_APPmsg_0 [`VWidth*10-1:`VWidth*9]};	

assign GN_APPmsg_18 ={DPU_APPmsg_31[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_30[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_29[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_28[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_27[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_26[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_25[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_24[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_23[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_22[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_21[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_20[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_19[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_18[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_17[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_16[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_15[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_14[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_13[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_12[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_11[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_10[`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_9 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_8 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_7 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_6 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_5 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_4 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_3 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_2 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_1 [`VWidth*9-1:`VWidth*8],
					  DPU_APPmsg_0 [`VWidth*9-1:`VWidth*8]};	

assign GN_APPmsg_19 ={DPU_APPmsg_31[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_30[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_29[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_28[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_27[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_26[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_25[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_24[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_23[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_22[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_21[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_20[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_19[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_18[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_17[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_16[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_15[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_14[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_13[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_12[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_11[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_10[`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_9 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_8 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_7 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_6 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_5 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_4 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_3 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_2 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_1 [`VWidth*8-1:`VWidth*7],
					  DPU_APPmsg_0 [`VWidth*8-1:`VWidth*7]};						  
					  
assign GN_APPmsg_20 ={DPU_APPmsg_31[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_30[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_29[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_28[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_27[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_26[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_25[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_24[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_23[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_22[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_21[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_20[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_19[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_18[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_17[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_16[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_15[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_14[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_13[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_12[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_11[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_10[`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_9 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_8 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_7 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_6 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_5 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_4 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_3 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_2 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_1 [`VWidth*7-1:`VWidth*6],
					  DPU_APPmsg_0 [`VWidth*7-1:`VWidth*6]};

assign GN_APPmsg_21 ={DPU_APPmsg_31[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_30[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_29[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_28[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_27[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_26[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_25[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_24[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_23[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_22[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_21[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_20[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_19[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_18[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_17[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_16[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_15[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_14[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_13[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_12[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_11[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_10[`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_9 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_8 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_7 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_6 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_5 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_4 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_3 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_2 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_1 [`VWidth*6-1:`VWidth*5],
					  DPU_APPmsg_0 [`VWidth*6-1:`VWidth*5]};						  


assign GN_APPmsg_22 ={DPU_APPmsg_31[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_30[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_29[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_28[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_27[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_26[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_25[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_24[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_23[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_22[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_21[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_20[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_19[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_18[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_17[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_16[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_15[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_14[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_13[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_12[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_11[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_10[`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_9 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_8 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_7 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_6 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_5 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_4 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_3 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_2 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_1 [`VWidth*5-1:`VWidth*4],
					  DPU_APPmsg_0 [`VWidth*5-1:`VWidth*4]};	

assign GN_APPmsg_23 ={DPU_APPmsg_31[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_30[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_29[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_28[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_27[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_26[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_25[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_24[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_23[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_22[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_21[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_20[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_19[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_18[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_17[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_16[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_15[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_14[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_13[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_12[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_11[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_10[`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_9 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_8 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_7 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_6 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_5 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_4 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_3 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_2 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_1 [`VWidth*4-1:`VWidth*3],
					  DPU_APPmsg_0 [`VWidth*4-1:`VWidth*3]};	

assign GN_APPmsg_24 ={DPU_APPmsg_31[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_30[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_29[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_28[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_27[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_26[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_25[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_24[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_23[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_22[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_21[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_20[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_19[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_18[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_17[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_16[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_15[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_14[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_13[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_12[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_11[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_10[`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_9 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_8 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_7 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_6 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_5 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_4 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_3 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_2 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_1 [`VWidth*3-1:`VWidth*2],
					  DPU_APPmsg_0 [`VWidth*3-1:`VWidth*2]};					  
					  
assign GN_APPmsg_25 ={DPU_APPmsg_31[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_30[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_29[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_28[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_27[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_26[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_25[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_24[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_23[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_22[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_21[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_20[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_19[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_18[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_17[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_16[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_15[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_14[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_13[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_12[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_11[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_10[`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_9 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_8 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_7 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_6 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_5 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_4 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_3 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_2 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_1 [`VWidth*2-1:`VWidth*1],
					  DPU_APPmsg_0 [`VWidth*2-1:`VWidth*1]};					  
					  
assign GN_APPmsg_26 ={DPU_APPmsg_31[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_30[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_29[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_28[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_27[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_26[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_25[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_24[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_23[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_22[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_21[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_20[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_19[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_18[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_17[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_16[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_15[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_14[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_13[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_12[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_11[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_10[`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_9 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_8 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_7 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_6 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_5 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_4 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_3 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_2 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_1 [`VWidth*1-1:`VWidth*0],
					  DPU_APPmsg_0 [`VWidth*1-1:`VWidth*0]};					  



//reg [`APPdata_Len-1:0] GN_APPmsg_26_reg;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		GN_APPmsg_reg_0  <= 0 ;
		GN_APPmsg_reg_1  <= 0 ;
		GN_APPmsg_reg_2  <= 0 ;
		GN_APPmsg_reg_3  <= 0 ;
		GN_APPmsg_reg_4  <= 0 ;
		GN_APPmsg_reg_5  <= 0 ;
		GN_APPmsg_reg_6  <= 0 ;
		GN_APPmsg_reg_7  <= 0 ;
		GN_APPmsg_reg_8  <= 0 ;
		GN_APPmsg_reg_9  <= 0 ;
		GN_APPmsg_reg_10 <= 0 ;
		GN_APPmsg_reg_11 <= 0 ;
		GN_APPmsg_reg_12 <= 0 ;
		GN_APPmsg_reg_13 <= 0 ;
		GN_APPmsg_reg_14 <= 0 ;
		GN_APPmsg_reg_15 <= 0 ;
		GN_APPmsg_reg_16 <= 0 ;
		GN_APPmsg_reg_17 <= 0 ;
		GN_APPmsg_reg_18 <= 0 ;
		GN_APPmsg_reg_19 <= 0 ;
		GN_APPmsg_reg_20 <= 0 ;
		GN_APPmsg_reg_21 <= 0 ;
		GN_APPmsg_reg_22 <= 0 ;
		GN_APPmsg_reg_23 <= 0 ;
		GN_APPmsg_reg_24 <= 0 ;
		GN_APPmsg_reg_25 <= 0 ;
		GN_APPmsg_reg_25 <= 0 ;
        GN_APPmsg_reg_26 <= 0;
	end
	else begin
		GN_APPmsg_reg_0  <= GN_APPmsg_0  ;
		GN_APPmsg_reg_1  <= GN_APPmsg_1  ;
		GN_APPmsg_reg_2  <= GN_APPmsg_2  ;
		GN_APPmsg_reg_3  <= GN_APPmsg_3  ;
		GN_APPmsg_reg_4  <= GN_APPmsg_4  ;
		GN_APPmsg_reg_5  <= GN_APPmsg_5  ;
		GN_APPmsg_reg_6  <= GN_APPmsg_6  ;
		GN_APPmsg_reg_7  <= GN_APPmsg_7  ;
		GN_APPmsg_reg_8  <= GN_APPmsg_8  ;
		GN_APPmsg_reg_9  <= GN_APPmsg_9  ;
		GN_APPmsg_reg_10 <= GN_APPmsg_10 ;
		GN_APPmsg_reg_11 <= GN_APPmsg_11 ;
		GN_APPmsg_reg_12 <= GN_APPmsg_12 ;
		GN_APPmsg_reg_13 <= GN_APPmsg_13 ;
		GN_APPmsg_reg_14 <= GN_APPmsg_14 ;
		GN_APPmsg_reg_15 <= GN_APPmsg_15 ;
		GN_APPmsg_reg_16 <= GN_APPmsg_16 ;
		GN_APPmsg_reg_17 <= GN_APPmsg_17 ;
		GN_APPmsg_reg_18 <= GN_APPmsg_18 ;
		GN_APPmsg_reg_19 <= GN_APPmsg_19 ;
		GN_APPmsg_reg_20 <= GN_APPmsg_20 ;
		GN_APPmsg_reg_21 <= GN_APPmsg_21 ;
		GN_APPmsg_reg_22 <= GN_APPmsg_22 ;
		GN_APPmsg_reg_23 <= GN_APPmsg_23 ;
		GN_APPmsg_reg_24 <= GN_APPmsg_24 ;
		GN_APPmsg_reg_25 <= GN_APPmsg_25 ;
		GN_APPmsg_reg_26 <= GN_APPmsg_26 ;
	end
end		


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		c_reg_new_D0  <= 0;
        c_reg_new_D1  <= 0;
        c_reg_new_D2  <= 0;
        c_reg_new_D3  <= 0;
        c_reg_new_D4  <= 0;
        c_reg_new_D5  <= 0;
        c_reg_new_D6  <= 0;
        c_reg_new_D7  <= 0;
        c_reg_new_D8  <= 0;
        c_reg_new_D9  <= 0;
        c_reg_new_D10 <= 0;
	end
	else
	begin
		c_reg_new_D0  <=  {c_reg_D1_0,c_reg_D1_1,c_reg_D1_2,c_reg_D1_3,c_reg_D1_4,c_reg_D1_5,c_reg_D1_6,c_reg_D1_7,c_reg_D1_8,c_reg_D1_9,
						c_reg_D1_10,c_reg_D1_11,c_reg_D1_12,c_reg_D1_13,c_reg_D1_14,c_reg_D1_15,c_reg_D1_16,c_reg_D1_17,c_reg_D1_18,c_reg_D1_19,
						c_reg_D1_20,c_reg_D1_21,c_reg_D1_22,c_reg_D1_23,c_reg_D1_24,c_reg_D1_25};
        c_reg_new_D1  <= c_reg_new_D0;
        c_reg_new_D2  <= c_reg_new_D1;
        c_reg_new_D3  <= c_reg_new_D2;
        c_reg_new_D4  <= c_reg_new_D3;
        c_reg_new_D5  <= c_reg_new_D4;
        c_reg_new_D6  <= c_reg_new_D5;
        c_reg_new_D7  <= c_reg_new_D6;
        c_reg_new_D8  <= c_reg_new_D7;
        c_reg_new_D9  <= c_reg_new_D8;
        c_reg_new_D10 <= c_reg_new_D9;
	end
end

assign c_D9_0 = P-c_reg_new_D9[`b*26-1:`b*25]; //反过来移位
assign c_D9_1 = P-c_reg_new_D9[`b*25-1:`b*24];
assign c_D9_2 = P-c_reg_new_D9[`b*24-1:`b*23];
assign c_D9_3 = P-c_reg_new_D9[`b*23-1:`b*22];
assign c_D9_4 = P-c_reg_new_D9[`b*22-1:`b*21];
assign c_D9_5 = P-c_reg_new_D9[`b*21-1:`b*20];
assign c_D9_6 = P-c_reg_new_D9[`b*20-1:`b*19];
assign c_D9_7 = P-c_reg_new_D9[`b*19-1:`b*18];
assign c_D9_8 = P-c_reg_new_D9[`b*18-1:`b*17];
assign c_D9_9 = P-c_reg_new_D9[`b*17-1:`b*16];
assign c_D9_10= P-c_reg_new_D9[`b*16-1:`b*15];
assign c_D9_11= P-c_reg_new_D9[`b*15-1:`b*14];
assign c_D9_12= P-c_reg_new_D9[`b*14-1:`b*13];
assign c_D9_13= P-c_reg_new_D9[`b*13-1:`b*12];
assign c_D9_14= P-c_reg_new_D9[`b*12-1:`b*11];
assign c_D9_15= P-c_reg_new_D9[`b*11-1:`b*10];
assign c_D9_16= P-c_reg_new_D9[`b*10-1:`b*9];
assign c_D9_17= P-c_reg_new_D9[`b*9-1: `b*8];
assign c_D9_18= P-c_reg_new_D9[`b*8-1: `b*7];
assign c_D9_19= P-c_reg_new_D9[`b*7-1: `b*6];
assign c_D9_20= P-c_reg_new_D9[`b*6-1: `b*5];
assign c_D9_21= P-c_reg_new_D9[`b*5-1: `b*4];
assign c_D9_22= P-c_reg_new_D9[`b*4-1: `b*3];
assign c_D9_23= P-c_reg_new_D9[`b*3-1: `b*2];
assign c_D9_24= P-c_reg_new_D9[`b*2-1: `b*1];
assign c_D9_25= P-c_reg_new_D9[`b*1-1: `b*0];

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
        c_new_0  <= 0;
        c_new_1  <= 0;
        c_new_2  <= 0;
        c_new_3  <= 0;
        c_new_4  <= 0;
        c_new_5  <= 0;
        c_new_6  <= 0;
        c_new_7  <= 0;
        c_new_8  <= 0;
        c_new_9  <= 0;
        c_new_10 <= 0;
        c_new_11 <= 0;
        c_new_12 <= 0;
        c_new_13 <= 0;
        c_new_14 <= 0;
        c_new_15 <= 0;
        c_new_16 <= 0;
        c_new_17 <= 0;
        c_new_18 <= 0;
        c_new_19 <= 0;
        c_new_20 <= 0;
        c_new_21 <= 0;
        c_new_22 <= 0;
        c_new_23 <= 0;
        c_new_24 <= 0;
        c_new_25 <= 0;
	end
	else begin
		c_new_0  <= c_D9_0  ;
        c_new_1  <= c_D9_1  ;
        c_new_2  <= c_D9_2  ;
        c_new_3  <= c_D9_3  ;
        c_new_4  <= c_D9_4  ;
        c_new_5  <= c_D9_5  ;
        c_new_6  <= c_D9_6  ;
        c_new_7  <= c_D9_7  ;
        c_new_8  <= c_D9_8  ;
        c_new_9  <= c_D9_9  ;
        c_new_10 <= c_D9_10 ;
        c_new_11 <= c_D9_11 ;
        c_new_12 <= c_D9_12 ;
        c_new_13 <= c_D9_13 ;
        c_new_14 <= c_D9_14 ;
        c_new_15 <= c_D9_15 ;
        c_new_16 <= c_D9_16 ;
        c_new_17 <= c_D9_17 ;
        c_new_18 <= c_D9_18 ;
        c_new_19 <= c_D9_19 ;
        c_new_20 <= c_D9_20 ;
        c_new_21 <= c_D9_21 ;
        c_new_22 <= c_D9_22 ;
        c_new_23 <= c_D9_23 ;
        c_new_24 <= c_D9_24 ;
        c_new_25 <= c_D9_25 ;
	end
end

QSN u26_QSN(.clk(clk),.in(GN_APPmsg_reg_0 ),.p(P),.c(c_new_0 ),.out(APPmsg_new_0 )); //先重新分发回来 再次经过一个QSN移位，送出 
QSN u27_QSN(.clk(clk),.in(GN_APPmsg_reg_1 ),.p(P),.c(c_new_1 ),.out(APPmsg_new_1 ));
QSN u28_QSN(.clk(clk),.in(GN_APPmsg_reg_2 ),.p(P),.c(c_new_2 ),.out(APPmsg_new_2 ));
QSN u29_QSN(.clk(clk),.in(GN_APPmsg_reg_3 ),.p(P),.c(c_new_3 ),.out(APPmsg_new_3 ));
QSN u30_QSN(.clk(clk),.in(GN_APPmsg_reg_4 ),.p(P),.c(c_new_4 ),.out(APPmsg_new_4 ));
QSN u31_QSN(.clk(clk),.in(GN_APPmsg_reg_5 ),.p(P),.c(c_new_5 ),.out(APPmsg_new_5 ));
QSN u32_QSN(.clk(clk),.in(GN_APPmsg_reg_6 ),.p(P),.c(c_new_6 ),.out(APPmsg_new_6 ));
QSN u33_QSN(.clk(clk),.in(GN_APPmsg_reg_7 ),.p(P),.c(c_new_7 ),.out(APPmsg_new_7 ));
QSN u34_QSN(.clk(clk),.in(GN_APPmsg_reg_8 ),.p(P),.c(c_new_8 ),.out(APPmsg_new_8 ));
QSN u35_QSN(.clk(clk),.in(GN_APPmsg_reg_9 ),.p(P),.c(c_new_9 ),.out(APPmsg_new_9 ));
QSN u36_QSN(.clk(clk),.in(GN_APPmsg_reg_10),.p(P),.c(c_new_10),.out(APPmsg_new_10));
QSN u37_QSN(.clk(clk),.in(GN_APPmsg_reg_11),.p(P),.c(c_new_11),.out(APPmsg_new_11));
QSN u38_QSN(.clk(clk),.in(GN_APPmsg_reg_12),.p(P),.c(c_new_12),.out(APPmsg_new_12));
QSN u39_QSN(.clk(clk),.in(GN_APPmsg_reg_13),.p(P),.c(c_new_13),.out(APPmsg_new_13));
QSN u40_QSN(.clk(clk),.in(GN_APPmsg_reg_14),.p(P),.c(c_new_14),.out(APPmsg_new_14));
QSN u41_QSN(.clk(clk),.in(GN_APPmsg_reg_15),.p(P),.c(c_new_15),.out(APPmsg_new_15));
QSN u42_QSN(.clk(clk),.in(GN_APPmsg_reg_16),.p(P),.c(c_new_16),.out(APPmsg_new_16));
QSN u43_QSN(.clk(clk),.in(GN_APPmsg_reg_17),.p(P),.c(c_new_17),.out(APPmsg_new_17));
QSN u44_QSN(.clk(clk),.in(GN_APPmsg_reg_18),.p(P),.c(c_new_18),.out(APPmsg_new_18));
QSN u45_QSN(.clk(clk),.in(GN_APPmsg_reg_19),.p(P),.c(c_new_19),.out(APPmsg_new_19));
QSN u46_QSN(.clk(clk),.in(GN_APPmsg_reg_20),.p(P),.c(c_new_20),.out(APPmsg_new_20));
QSN u47_QSN(.clk(clk),.in(GN_APPmsg_reg_21),.p(P),.c(c_new_21),.out(APPmsg_new_21));
QSN u48_QSN(.clk(clk),.in(GN_APPmsg_reg_22),.p(P),.c(c_new_22),.out(APPmsg_new_22));
QSN u49_QSN(.clk(clk),.in(GN_APPmsg_reg_23),.p(P),.c(c_new_23),.out(APPmsg_new_23));
QSN u50_QSN(.clk(clk),.in(GN_APPmsg_reg_24),.p(P),.c(c_new_24),.out(APPmsg_new_24));
QSN u51_QSN(.clk(clk),.in(GN_APPmsg_reg_25),.p(P),.c(c_new_25),.out(APPmsg_new_25));

// always@(posedge clk or negedge rst_n)begin
// 	if(!rst_n) begin
// 		GN_APPmsg_reg_26_D0 <= 0;

// 	end
// 	else begin
// 		GN_APPmsg_reg_26_D0 <= GN_APPmsg_reg_26;
// 	end
// end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		GN_APPmsg_reg_26_D0 <= 0;
		APPmsg_new_26 <= 0;

	end
	else begin
		GN_APPmsg_reg_26_D0 <= GN_APPmsg_reg_26;
		APPmsg_new_26 <= GN_APPmsg_reg_26_D0;
	end
end



//post process


//save data
// integer app_file_0 ;
// integer app_file_1 ;
// integer app_file_2 ;
// integer app_file_3 ;
// integer app_file_4 ;
// integer app_file_5 ;
// integer app_file_6 ;
// integer app_file_7 ;
// integer app_file_8 ;
// integer app_file_9 ;
// integer app_file_10;
// integer app_file_11;
// integer app_file_12;
// integer app_file_13;
// integer app_file_14;
// integer app_file_15;
// integer app_file_16;
// integer app_file_17;
// integer app_file_18;
// integer app_file_19;
// integer app_file_20;
// integer app_file_21;
// integer app_file_22;
// integer app_file_23;
// integer app_file_24;
// integer app_file_25;
// integer app_file_26;

// integer ctv_file_0 ;
// integer ctv_file_1 ;
// integer ctv_file_2 ;
// integer ctv_file_3 ;
// integer ctv_file_4 ;
// integer ctv_file_5 ;
// integer ctv_file_6 ;
// integer ctv_file_7 ;
// integer ctv_file_8 ;
// integer ctv_file_9 ;
// integer ctv_file_10;
// integer ctv_file_11;
// integer ctv_file_12;
// integer ctv_file_13;
// integer ctv_file_14;
// integer ctv_file_15;
// integer ctv_file_16;
// integer ctv_file_17;
// integer ctv_file_18;
// integer ctv_file_19;
// integer ctv_file_20;
// integer ctv_file_21;
// integer ctv_file_22;
// integer ctv_file_23;
// integer ctv_file_24;
// integer ctv_file_25;
// integer ctv_file_26;
// integer ctv_file_27;
// integer ctv_file_28;
// integer ctv_file_29;
// integer ctv_file_30;
// integer ctv_file_31;

// initial
// begin
// 	if(decoder_id == 0)
// 		app_file_0 =$fopen("appdata_0.txt");
// 		app_file_1 =$fopen("appdata_1.txt");
// 		app_file_2 =$fopen("appdata_2.txt");
// 		app_file_3 =$fopen("appdata_3.txt");
// 		app_file_4 =$fopen("appdata_4.txt");
// 		app_file_5 =$fopen("appdata_5.txt");
// 		app_file_6 =$fopen("appdata_6.txt");
// 		app_file_7 =$fopen("appdata_7.txt");
// 		app_file_8 =$fopen("appdata_8.txt");
// 		app_file_9 =$fopen("appdata_9.txt");
// 		app_file_10=$fopen("appdata_10.txt");
// 		app_file_11=$fopen("appdata_11.txt");
// 		app_file_12=$fopen("appdata_12.txt");
// 		app_file_13=$fopen("appdata_13.txt");
// 		app_file_14=$fopen("appdata_14.txt");
// 		app_file_15=$fopen("appdata_15.txt");
// 		app_file_16=$fopen("appdata_16.txt");
// 		app_file_17=$fopen("appdata_17.txt");
// 		app_file_18=$fopen("appdata_18.txt");
// 		app_file_19=$fopen("appdata_19.txt");
// 		app_file_20=$fopen("appdata_20.txt");
// 		app_file_21=$fopen("appdata_21.txt");
// 		app_file_22=$fopen("appdata_22.txt");
// 		app_file_23=$fopen("appdata_23.txt");
// 		app_file_24=$fopen("appdata_24.txt");
// 		app_file_25=$fopen("appdata_25.txt");
// 		app_file_26=$fopen("appdata_26.txt");
// end
// always @(posedge clk)
// begin
// 	if(decoder_id==0)
// 	begin
// 		if(APP_decodin_wr_en && (iternum == 4'd0))
// 		begin     
// 			$fwrite(app_file_0  ,"%h\n",$unsigned(APPmsg_new_0 ));
// 			$fwrite(app_file_1  ,"%h\n",$unsigned(APPmsg_new_1 ));
// 			$fwrite(app_file_2  ,"%h\n",$unsigned(APPmsg_new_2 ));
// 			$fwrite(app_file_3  ,"%h\n",$unsigned(APPmsg_new_3 ));
// 			$fwrite(app_file_4  ,"%h\n",$unsigned(APPmsg_new_4 ));
// 			$fwrite(app_file_5  ,"%h\n",$unsigned(APPmsg_new_5 ));
// 			$fwrite(app_file_6  ,"%h\n",$unsigned(APPmsg_new_6 ));
// 			$fwrite(app_file_7  ,"%h\n",$unsigned(APPmsg_new_7 ));
// 			$fwrite(app_file_8  ,"%h\n",$unsigned(APPmsg_new_8 ));
// 			$fwrite(app_file_9  ,"%h\n",$unsigned(APPmsg_new_9 ));
// 			$fwrite(app_file_10 ,"%h\n",$unsigned(APPmsg_new_10));
// 			$fwrite(app_file_11 ,"%h\n",$unsigned(APPmsg_new_11));
// 			$fwrite(app_file_12 ,"%h\n",$unsigned(APPmsg_new_12));
// 			$fwrite(app_file_13 ,"%h\n",$unsigned(APPmsg_new_13));
// 			$fwrite(app_file_14 ,"%h\n",$unsigned(APPmsg_new_14));
// 			$fwrite(app_file_15 ,"%h\n",$unsigned(APPmsg_new_15));
// 			$fwrite(app_file_16 ,"%h\n",$unsigned(APPmsg_new_16));
// 			$fwrite(app_file_17 ,"%h\n",$unsigned(APPmsg_new_17));
// 			$fwrite(app_file_18 ,"%h\n",$unsigned(APPmsg_new_18));
// 			$fwrite(app_file_19 ,"%h\n",$unsigned(APPmsg_new_19));
// 			$fwrite(app_file_20 ,"%h\n",$unsigned(APPmsg_new_20));
// 			$fwrite(app_file_21 ,"%h\n",$unsigned(APPmsg_new_21));
// 			$fwrite(app_file_22 ,"%h\n",$unsigned(APPmsg_new_22));
// 			$fwrite(app_file_23 ,"%h\n",$unsigned(APPmsg_new_23));
// 			$fwrite(app_file_24 ,"%h\n",$unsigned(APPmsg_new_24));
// 			$fwrite(app_file_25 ,"%h\n",$unsigned(APPmsg_new_25));
// 		end
// 		else if( (iternum == 4'd0) && iter_end)
// 		begin
// 			$fclose(app_file_0 );
// 			$fclose(app_file_1 );
// 			$fclose(app_file_2 );
// 			$fclose(app_file_3 );
// 			$fclose(app_file_4 );
// 			$fclose(app_file_5 );
// 			$fclose(app_file_6 );
// 			$fclose(app_file_7 );
// 			$fclose(app_file_8 );
// 			$fclose(app_file_9 );
// 			$fclose(app_file_10);
// 			$fclose(app_file_11);
// 			$fclose(app_file_12);
// 			$fclose(app_file_13);
// 			$fclose(app_file_14);
// 			$fclose(app_file_15);
// 			$fclose(app_file_16);
// 			$fclose(app_file_17);
// 			$fclose(app_file_18);
// 			$fclose(app_file_19);
// 			$fclose(app_file_20);
// 			$fclose(app_file_21);
// 			$fclose(app_file_22);
// 			$fclose(app_file_23);
// 			$fclose(app_file_24);
// 			$fclose(app_file_25);
// 			$fclose(app_file_26);
// 		end
// 	end
// end
// always @(posedge clk)
// begin
// 	if(APP_rd_D1 && (iternum == `maxIterNum))
// 	begin     
// 		$fwrite(app_file_0  ,"%h\n",$unsigned(APPmsg_old_0 ));
// 		$fwrite(app_file_1  ,"%h\n",$unsigned(APPmsg_old_1 ));
// 		$fwrite(app_file_2  ,"%h\n",$unsigned(APPmsg_old_2 ));
// 		$fwrite(app_file_3  ,"%h\n",$unsigned(APPmsg_old_3 ));
// 		$fwrite(app_file_4  ,"%h\n",$unsigned(APPmsg_old_4 ));
// 		$fwrite(app_file_5  ,"%h\n",$unsigned(APPmsg_old_5 ));
// 		$fwrite(app_file_6  ,"%h\n",$unsigned(APPmsg_old_6 ));
// 		$fwrite(app_file_7  ,"%h\n",$unsigned(APPmsg_old_7 ));
// 		$fwrite(app_file_8  ,"%h\n",$unsigned(APPmsg_old_8 ));
// 		$fwrite(app_file_9  ,"%h\n",$unsigned(APPmsg_old_9 ));
// 		$fwrite(app_file_10 ,"%h\n",$unsigned(APPmsg_old_10));
// 		$fwrite(app_file_11 ,"%h\n",$unsigned(APPmsg_old_11));
// 		$fwrite(app_file_12 ,"%h\n",$unsigned(APPmsg_old_12));
// 		$fwrite(app_file_13 ,"%h\n",$unsigned(APPmsg_old_13));
// 		$fwrite(app_file_14 ,"%h\n",$unsigned(APPmsg_old_14));
// 		$fwrite(app_file_15 ,"%h\n",$unsigned(APPmsg_old_15));
// 		$fwrite(app_file_16 ,"%h\n",$unsigned(APPmsg_old_16));
// 		$fwrite(app_file_17 ,"%h\n",$unsigned(APPmsg_old_17));
// 		$fwrite(app_file_18 ,"%h\n",$unsigned(APPmsg_old_18));
// 		$fwrite(app_file_19 ,"%h\n",$unsigned(APPmsg_old_19));
// 		$fwrite(app_file_20 ,"%h\n",$unsigned(APPmsg_old_20));
// 		$fwrite(app_file_21 ,"%h\n",$unsigned(APPmsg_old_21));
// 		$fwrite(app_file_22 ,"%h\n",$unsigned(APPmsg_old_22));
// 		$fwrite(app_file_23 ,"%h\n",$unsigned(APPmsg_old_23));
// 		$fwrite(app_file_24 ,"%h\n",$unsigned(APPmsg_old_24));
// 		$fwrite(app_file_25 ,"%h\n",$unsigned(APPmsg_old_25));
// 		$fwrite(app_file_26 ,"%h\n",$unsigned(APPmsg_old_26));
// 	end
// 	else if( (iternum == `maxIterNum) && decode_end)
// 	begin	
// 		$fclose(app_file_0 );
// 		$fclose(app_file_1 );
// 		$fclose(app_file_2 );
// 		$fclose(app_file_3 );
// 		$fclose(app_file_4 );
// 		$fclose(app_file_5 );
// 		$fclose(app_file_6 );
// 		$fclose(app_file_7 );
// 		$fclose(app_file_8 );
// 		$fclose(app_file_9 );
// 		$fclose(app_file_10);
// 		$fclose(app_file_11);
// 		$fclose(app_file_12);
// 		$fclose(app_file_13);
// 		$fclose(app_file_14);
// 		$fclose(app_file_15);
// 		$fclose(app_file_16);
// 		$fclose(app_file_17);
// 		$fclose(app_file_18);
// 		$fclose(app_file_19);
// 		$fclose(app_file_20);
// 		$fclose(app_file_21);
// 		$fclose(app_file_22);
// 		$fclose(app_file_23);
// 		$fclose(app_file_24);
// 		$fclose(app_file_25);
// 		$fclose(app_file_26);			
// 	end
// end
endmodule