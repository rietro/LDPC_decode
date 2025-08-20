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
module LDPC_Dec(
    input clk,
	input rst_n,
	
	input  data_in_I1,
	input  data_in_I2,
	input  data_in_Q1,
	input  data_in_Q2,
	
	input	en_datain,
	
	input [8:0] Zc,
	input [2:0] iLs,
	input [2:0] jLs,
	input bg,
	input [5:0] P,
	input [4:0] APP_addr_max,
	input [3:0] APP_addr_rd_max,
	

	//input [9:0] shift_addr_rd_ini,
	
	input first_iter_flag,
	input decode_start,//diyici kaishi xinhao
	input decode_output_flag,

	output reg 	     decode_end,
	output reg [3:0] iternum
);

wire [8:0] APP_share_addr_rd_max;


`include "Decoder_Parameters.v"

wire [5:0] P_1;
assign P_1 = P-1'b1;
// reg [3:0] iternum;

//state control 

wire [5:0] totalLayernum;
reg [5:0] Layernum;
reg decode_start_D0,decode_start_D1,decode_start_D2,decode_start_D3;
reg update_start;//meici diedai gengxing xinhao
reg update_start_D0,update_start_D1,update_start_D2;
reg update_end;
reg update_end_D0;
reg share_flag;//

//shift value
reg [8:0] shift_addr_rd1_ini;
reg [8:0] shift_addr_rd2_ini;
reg [8:0] shift_addr_rd1;
reg [8:0] shift_addr_rd2;
reg [259:0] bg1_shift;
reg [139:0] bg2_shift;

wire [259:0] bg1_shift_0;
wire [259:0] bg1_shift_1;
wire [259:0] bg1_shift_2;
wire [259:0] bg1_shift_3;
wire [259:0] bg1_shift_4;
wire [259:0] bg1_shift_5;
wire [259:0] bg1_shift_6;
wire [259:0] bg1_shift_7;

wire [139:0] bg2_shift_0;
wire [139:0] bg2_shift_1;
wire [139:0] bg2_shift_2;
wire [139:0] bg2_shift_3;
wire [139:0] bg2_shift_4;
wire [139:0] bg2_shift_5;
wire [139:0] bg2_shift_6;
wire [139:0] bg2_shift_7;
wire [9:0] shift_0,shift_1,shift_2,shift_3,shift_4,shift_5,shift_6,shift_7,shift_8,shift_9,
    shift_10,shift_11,shift_12,shift_13,shift_14,shift_15,shift_16,shift_17,shift_18,shift_19,
    shift_20,shift_21,shift_22,shift_23,shift_24,shift_25;
	
wire [8:0]  shift_nsign_0,shift_nsign_1,shift_nsign_2,shift_nsign_3,shift_nsign_4,shift_nsign_5,shift_nsign_6,shift_nsign_7,shift_nsign_8,shift_nsign_9,
    shift_nsign_10,shift_nsign_11,shift_nsign_12,shift_nsign_13,shift_nsign_14,shift_nsign_15,shift_nsign_16,shift_nsign_17,shift_nsign_18,shift_nsign_19,
    shift_nsign_20,shift_nsign_21,shift_nsign_22,shift_nsign_23,shift_nsign_24,shift_nsign_25;
reg HROM_rd_en;

//APP 
wire [3:0] APP_addr_wr_max;
reg APP_rd_en;
reg APP_rd_D0,APP_rd_D1,APP_rd_D2;
reg [4:0] APP_rd_en_cnt;
reg APP_rd_end;
reg [4:0] APP_rd_end_cnt;
reg APP_rd_endD0,APP_rd_endD1,APP_rd_endD2,APP_rd_endD3,APP_rd_endD4,APP_rd_endD5,APP_rd_endD6,APP_rd_endD7,APP_rd_endD8,APP_rd_endD9,
    APP_rd_endD10,APP_rd_endD11,APP_rd_endD12,APP_rd_endD13,APP_rd_endD14,APP_rd_endD15,APP_rd_endD16;
wire [3:0]  APP_addr_rd_ini_0,APP_addr_rd_ini_1,APP_addr_rd_ini_2,APP_addr_rd_ini_3,APP_addr_rd_ini_4,APP_addr_rd_ini_5,APP_addr_rd_ini_6,APP_addr_rd_ini_7,APP_addr_rd_ini_8,APP_addr_rd_ini_9,
           APP_addr_rd_ini_10,APP_addr_rd_ini_11,APP_addr_rd_ini_12,APP_addr_rd_ini_13,APP_addr_rd_ini_14,APP_addr_rd_ini_15,APP_addr_rd_ini_16,APP_addr_rd_ini_17,APP_addr_rd_ini_18,APP_addr_rd_ini_19,
           APP_addr_rd_ini_20,APP_addr_rd_ini_21,APP_addr_rd_ini_22,APP_addr_rd_ini_23,APP_addr_rd_ini_24,APP_addr_rd_ini_25,APP_addr_rd_ini_26;	
reg [3:0]  APP_addr_rd_0,APP_addr_rd_1,APP_addr_rd_2,APP_addr_rd_3,APP_addr_rd_4,APP_addr_rd_5,APP_addr_rd_6,APP_addr_rd_7,APP_addr_rd_8,APP_addr_rd_9,
           APP_addr_rd_10,APP_addr_rd_11,APP_addr_rd_12,APP_addr_rd_13,APP_addr_rd_14,APP_addr_rd_15,APP_addr_rd_16,APP_addr_rd_17,APP_addr_rd_18,APP_addr_rd_19,
           APP_addr_rd_20,APP_addr_rd_21,APP_addr_rd_22,APP_addr_rd_23,APP_addr_rd_24,APP_addr_rd_25;
reg [9:0]  APP_addr_rd_26;

reg APP_wr_en;
reg [3:0] APP_wr_en_cnt;
reg [3:0]  APP_addr_wr_0,APP_addr_wr_1,APP_addr_wr_2,APP_addr_wr_3,APP_addr_wr_4,APP_addr_wr_5,APP_addr_wr_6,APP_addr_wr_7,APP_addr_wr_8,APP_addr_wr_9,
           APP_addr_wr_10,APP_addr_wr_11,APP_addr_wr_12,APP_addr_wr_13,APP_addr_wr_14,APP_addr_wr_15,APP_addr_wr_16,APP_addr_wr_17,APP_addr_wr_18,APP_addr_wr_19,
           APP_addr_wr_20,APP_addr_wr_21,APP_addr_wr_22,APP_addr_wr_23,APP_addr_wr_24,APP_addr_wr_25;
reg [9:0]  APP_addr_wr_26;

wire APP_wr_en_0,APP_wr_en_1,APP_wr_en_2,APP_wr_en_3,APP_wr_en_4,APP_wr_en_5,APP_wr_en_6,APP_wr_en_7,APP_wr_en_8,APP_wr_en_9,
                  APP_wr_en_10,APP_wr_en_11,APP_wr_en_12,APP_wr_en_13,APP_wr_en_14,APP_wr_en_15,APP_wr_en_16,APP_wr_en_17,APP_wr_en_18,APP_wr_en_19,
                  APP_wr_en_20,APP_wr_en_21,APP_wr_en_22,APP_wr_en_23,APP_wr_en_24,APP_wr_en_25,APP_wr_en_26;

reg APP_wr_en_D0;

//QSN
reg [4:0] c_reg_0,c_reg_1,c_reg_2,c_reg_3,c_reg_4,c_reg_5,c_reg_6,c_reg_7,c_reg_8,c_reg_9,
      c_reg_10,c_reg_11,c_reg_12,c_reg_13,c_reg_14,c_reg_15,c_reg_16,c_reg_17,c_reg_18,c_reg_19,
      c_reg_20,c_reg_21,c_reg_22,c_reg_23,c_reg_24,c_reg_25;
reg [4:0] c_reg_D0_0,c_reg_D0_1,c_reg_D0_2,c_reg_D0_3,c_reg_D0_4,c_reg_D0_5,c_reg_D0_6,c_reg_D0_7,c_reg_D0_8,c_reg_D0_9,
      c_reg_D0_10,c_reg_D0_11,c_reg_D0_12,c_reg_D0_13,c_reg_D0_14,c_reg_D0_15,c_reg_D0_16,c_reg_D0_17,c_reg_D0_18,c_reg_D0_19,
      c_reg_D0_20,c_reg_D0_21,c_reg_D0_22,c_reg_D0_23,c_reg_D0_24,c_reg_D0_25;
reg [4:0] c_reg_D1_0,c_reg_D1_1,c_reg_D1_2,c_reg_D1_3,c_reg_D1_4,c_reg_D1_5,c_reg_D1_6,c_reg_D1_7,c_reg_D1_8,c_reg_D1_9,
      c_reg_D1_10,c_reg_D1_11,c_reg_D1_12,c_reg_D1_13,c_reg_D1_14,c_reg_D1_15,c_reg_D1_16,c_reg_D1_17,c_reg_D1_18,c_reg_D1_19,
      c_reg_D1_20,c_reg_D1_21,c_reg_D1_22,c_reg_D1_23,c_reg_D1_24,c_reg_D1_25;
wire [4:0] c_0,c_1,c_2,c_3,c_4,c_5,c_6,c_7,c_8,c_9,
      c_10,c_11,c_12,c_13,c_14,c_15,c_16,c_17,c_18,c_19,
      c_20,c_21,c_22,c_23,c_24,c_25;
wire [`APPdata_Len-1:0] APPmsg_old_0,APPmsg_old_1,APPmsg_old_2,APPmsg_old_3,APPmsg_old_4,APPmsg_old_5,APPmsg_old_6,APPmsg_old_7,APPmsg_old_8,APPmsg_old_9,
                  APPmsg_old_10,APPmsg_old_11,APPmsg_old_12,APPmsg_old_13,APPmsg_old_14,APPmsg_old_15,APPmsg_old_16,APPmsg_old_17,APPmsg_old_18,APPmsg_old_19,
                  APPmsg_old_20,APPmsg_old_21,APPmsg_old_22,APPmsg_old_23,APPmsg_old_24,APPmsg_old_25,APPmsg_old_26;
reg [`APPdata_Len-1:0] APPmsg_old_26_D0,APPmsg_old_26_D1;				  
wire [`APPdata_Len-1:0] APPmsg_new_0,APPmsg_new_1,APPmsg_new_2,APPmsg_new_3,APPmsg_new_4,APPmsg_new_5,APPmsg_new_6,APPmsg_new_7,APPmsg_new_8,APPmsg_new_9,
                  APPmsg_new_10,APPmsg_new_11,APPmsg_new_12,APPmsg_new_13,APPmsg_new_14,APPmsg_new_15,APPmsg_new_16,APPmsg_new_17,APPmsg_new_18,APPmsg_new_19,
                  APPmsg_new_20,APPmsg_new_21,APPmsg_new_22,APPmsg_new_23,APPmsg_new_24,APPmsg_new_25;
reg [`APPdata_Len-1:0]  APPmsg_new_26;
wire [`APPdata_Len-1:0] QSN_APPmsg_0,QSN_APPmsg_1,QSN_APPmsg_2,QSN_APPmsg_3,QSN_APPmsg_4,QSN_APPmsg_5,QSN_APPmsg_6,QSN_APPmsg_7,QSN_APPmsg_8,QSN_APPmsg_9,
                  QSN_APPmsg_10,QSN_APPmsg_11,QSN_APPmsg_12,QSN_APPmsg_13,QSN_APPmsg_14,QSN_APPmsg_15,QSN_APPmsg_16,QSN_APPmsg_17,QSN_APPmsg_18,QSN_APPmsg_19,
                  QSN_APPmsg_20,QSN_APPmsg_21,QSN_APPmsg_22,QSN_APPmsg_23,QSN_APPmsg_24,QSN_APPmsg_25;
//DN
wire [`DPUdata_Len-1:0] DN_APPmsg_0,DN_APPmsg_1,DN_APPmsg_2,DN_APPmsg_3,DN_APPmsg_4,DN_APPmsg_5,DN_APPmsg_6,DN_APPmsg_7,DN_APPmsg_8,DN_APPmsg_9,
                  DN_APPmsg_10,DN_APPmsg_11,DN_APPmsg_12,DN_APPmsg_13,DN_APPmsg_14,DN_APPmsg_15,DN_APPmsg_16,DN_APPmsg_17,DN_APPmsg_18,DN_APPmsg_19,
                  DN_APPmsg_20,DN_APPmsg_21,DN_APPmsg_22,DN_APPmsg_23,DN_APPmsg_24,DN_APPmsg_25,DN_APPmsg_26,DN_APPmsg_27,DN_APPmsg_28,DN_APPmsg_29,DN_APPmsg_30,DN_APPmsg_31;
reg [`DPUdata_Len-1:0] DN_APPmsg_reg_0,DN_APPmsg_reg_1,DN_APPmsg_reg_2,DN_APPmsg_reg_3,DN_APPmsg_reg_4,DN_APPmsg_reg_5,DN_APPmsg_reg_6,DN_APPmsg_reg_7,DN_APPmsg_reg_8,DN_APPmsg_reg_9,
                  DN_APPmsg_reg_10,DN_APPmsg_reg_11,DN_APPmsg_reg_12,DN_APPmsg_reg_13,DN_APPmsg_reg_14,DN_APPmsg_reg_15,DN_APPmsg_reg_16,DN_APPmsg_reg_17,DN_APPmsg_reg_18,DN_APPmsg_reg_19,
                  DN_APPmsg_reg_20,DN_APPmsg_reg_21,DN_APPmsg_reg_22,DN_APPmsg_reg_23,DN_APPmsg_reg_24,DN_APPmsg_reg_25,DN_APPmsg_reg_26,DN_APPmsg_reg_27,DN_APPmsg_reg_28,DN_APPmsg_reg_29,DN_APPmsg_reg_30,DN_APPmsg_reg_31;

//CTV

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

//DPU
reg [`P_num-1:0] flag;
wire [`DPUdata_Len-1:0] DPU_APPmsg_0,DPU_APPmsg_1,DPU_APPmsg_2,DPU_APPmsg_3,DPU_APPmsg_4,DPU_APPmsg_5,DPU_APPmsg_6,DPU_APPmsg_7,DPU_APPmsg_8,DPU_APPmsg_9,
                  DPU_APPmsg_10,DPU_APPmsg_11,DPU_APPmsg_12,DPU_APPmsg_13,DPU_APPmsg_14,DPU_APPmsg_15,DPU_APPmsg_16,DPU_APPmsg_17,DPU_APPmsg_18,DPU_APPmsg_19,
                  DPU_APPmsg_20,DPU_APPmsg_21,DPU_APPmsg_22,DPU_APPmsg_23,DPU_APPmsg_24,DPU_APPmsg_25,DPU_APPmsg_26,DPU_APPmsg_27,DPU_APPmsg_28,DPU_APPmsg_29,DPU_APPmsg_30,DPU_APPmsg_31;
wire  signAPP_0,signAPP_1,signAPP_2,signAPP_3,signAPP_4,signAPP_5,signAPP_6,signAPP_7,signAPP_8,signAPP_9,
                  signAPP_10,signAPP_11,signAPP_12,signAPP_13,signAPP_14,signAPP_15,signAPP_16,signAPP_17,signAPP_18,signAPP_19,
                  signAPP_20,signAPP_21,signAPP_22,signAPP_23,signAPP_24,signAPP_25,signAPP_26,signAPP_27,signAPP_28,signAPP_29,signAPP_30,signAPP_31;   
//GN
wire [`APPdata_Len-1:0] GN_APPmsg_0,GN_APPmsg_1,GN_APPmsg_2,GN_APPmsg_3,GN_APPmsg_4,GN_APPmsg_5,GN_APPmsg_6,GN_APPmsg_7,GN_APPmsg_8,GN_APPmsg_9,
                  GN_APPmsg_10,GN_APPmsg_11,GN_APPmsg_12,GN_APPmsg_13,GN_APPmsg_14,GN_APPmsg_15,GN_APPmsg_16,GN_APPmsg_17,GN_APPmsg_18,GN_APPmsg_19,
                  GN_APPmsg_20,GN_APPmsg_21,GN_APPmsg_22,GN_APPmsg_23,GN_APPmsg_24,GN_APPmsg_25,GN_APPmsg_26;
reg [`APPdata_Len-1:0] GN_APPmsg_reg_0,GN_APPmsg_reg_1,GN_APPmsg_reg_2,GN_APPmsg_reg_3,GN_APPmsg_reg_4,GN_APPmsg_reg_5,GN_APPmsg_reg_6,GN_APPmsg_reg_7,GN_APPmsg_reg_8,GN_APPmsg_reg_9,
                  GN_APPmsg_reg_10,GN_APPmsg_reg_11,GN_APPmsg_reg_12,GN_APPmsg_reg_13,GN_APPmsg_reg_14,GN_APPmsg_reg_15,GN_APPmsg_reg_16,GN_APPmsg_reg_17,GN_APPmsg_reg_18,GN_APPmsg_reg_19,
                  GN_APPmsg_reg_20,GN_APPmsg_reg_21,GN_APPmsg_reg_22,GN_APPmsg_reg_23,GN_APPmsg_reg_24,GN_APPmsg_reg_25,GN_APPmsg_reg_26;
reg [`APPdata_Len-1:0] GN_APPmsg_reg_26_D0;
//QSN
reg [`b-1:0] c_new_0,c_new_1,c_new_2,c_new_3,c_new_4,c_new_5,c_new_6,c_new_7,c_new_8,c_new_9,
      c_new_10,c_new_11,c_new_12,c_new_13,c_new_14,c_new_15,c_new_16,c_new_17,c_new_18,c_new_19,
      c_new_20,c_new_21,c_new_22,c_new_23,c_new_24,c_new_25;
reg [`b*26-1:0] c_reg_new_D0,c_reg_new_D1,c_reg_new_D2,c_reg_new_D3,c_reg_new_D4,c_reg_new_D5,c_reg_new_D6,c_reg_new_D7,c_reg_new_D8,c_reg_new_D9,c_reg_new_D10;

wire [`b-1:0] c_D10_0,c_D10_1,c_D10_2,c_D10_3,c_D10_4,c_D10_5,c_D10_6,c_D10_7,c_D10_8,c_D10_9,
      c_D10_10,c_D10_11,c_D10_12,c_D10_13,c_D10_14,c_D10_15,c_D10_16,c_D10_17,c_D10_18,c_D10_19,
      c_D10_20,c_D10_21,c_D10_22,c_D10_23,c_D10_24,c_D10_25;
wire [`b-1:0] c_D9_0,c_D9_1,c_D9_2,c_D9_3,c_D9_4,c_D9_5,c_D9_6,c_D9_7,c_D9_8,c_D9_9,
      c_D9_10,c_D9_11,c_D9_12,c_D9_13,c_D9_14,c_D9_15,c_D9_16,c_D9_17,c_D9_18,c_D9_19,
      c_D9_20,c_D9_21,c_D9_22,c_D9_23,c_D9_24,c_D9_25;	


always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		iternum <= 0;
	end
	else if(decode_end && (~decode_start))begin
		iternum <= iternum + 1;
	end
end	  
//state control 
assign totalLayernum = bg?6'd42:6'd4;

assign APP_share_addr_rd_max = {totalLayernum,APP_addr_rd_max};
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		decode_start_D0 <= 0;
		decode_start_D1 <= 0;
		decode_start_D2 <= 0;
		decode_start_D3 <= 0;
	end
	else begin
		decode_start_D0 <= decode_start;
		decode_start_D1 <= decode_start_D0;
		decode_start_D2 <= decode_start_D1;
		decode_start_D3 <= decode_start_D2;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		Layernum <= 0;
		decode_end <= 0;
	end
	else if(decode_start)begin
		Layernum <= 0;
		decode_end <= 0;
	end
	else if(update_end)begin
		if(Layernum == totalLayernum - 1)begin
			Layernum <= 0;
			decode_end <= 1;
		end
		else begin
			Layernum <= Layernum + 1;
			decode_end <= 0;
		end
	end
	else begin
		Layernum <= Layernum;
		decode_end <= 0;
	end
end
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		decode_end <= 0;
	end
	else if(Layernum == totalLayernum )
		decode_end <= 1;
	else 
		decode_end <= 0;	
end
*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		update_start <= 0;
	end
	else if(decode_start_D2)begin
		update_start <= 1;
	end
	else if(update_end && iternum <4'd3)begin
		if(Layernum == totalLayernum - 1)
			update_start <= 0;
		else
			update_start <= 1;
	end
	else
		update_start <= 0;
end

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
		update_end <= 0;
	end
	else if(APP_rd_endD13)begin
		update_end <= 1;
	end
	else
		update_end <= 0;
end

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
reg [6:0] shift_addr_rd2;
wire [259:0] bg1_shift;
wire [139:0] bg2_shift;
wire [9:0] shift_0,shift_1,shift_2,shift_3,shift_4,shift_5,shift_6,shift_7,shift_8,shift_9,
    shift_10,shift_11,shift_12,shift_13,shift_14,shift_15,shift_16,shift_17,shift_18,shift_19,
    shift_20,shift_21,shift_22,shift_23,shift_24,shift_25;
reg HROM_rd_en;
*/

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		HROM_rd_en <= 0;
 	end
	else if(update_start)begin
		HROM_rd_en <= 1;
	end
	else
		HROM_rd_en <= 1;
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		shift_addr_rd1 <= 0;
		shift_addr_rd2 <= 0;
	end
	else if(decode_start)begin
		shift_addr_rd1 <= shift_addr_rd1_ini;
		shift_addr_rd2 <= shift_addr_rd2_ini;	
	end
	else if(APP_rd_endD10)begin
		shift_addr_rd1 <= shift_addr_rd1 + 1;
		shift_addr_rd2 <= shift_addr_rd2 + 1;
	end
end

HROM1_0 u10_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_0),.ena(HROM_rd_en));
HROM1_1 u11_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_1),.ena(0));	
HROM1_2 u12_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_2),.ena(0));
HROM1_3 u13_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_3),.ena(0));	
HROM1_4 u14_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_4),.ena(0));
HROM1_5 u15_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_5),.ena(0));
HROM1_6 u16_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_6),.ena(0));
HROM1_7 u17_HRom(.addra(shift_addr_rd1),.clka(clk),.douta(bg1_shift_7),.ena(0));
																		
HROM2_0 u20_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_0),.ena(HROM_rd_en));
HROM2_1 u21_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_1),.ena(HROM_rd_en));	
HROM2_2 u22_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_2),.ena(HROM_rd_en));
HROM2_3 u23_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_3),.ena(HROM_rd_en));	
HROM2_4 u24_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_4),.ena(HROM_rd_en));
HROM2_5 u25_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_5),.ena(HROM_rd_en));
HROM2_6 u26_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_6),.ena(HROM_rd_en));
HROM2_7 u27_HRom(.addra(shift_addr_rd2),.clka(clk),.douta(bg2_shift_7),.ena(HROM_rd_en));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		bg1_shift <= 0;
		bg2_shift <= 0;

	end
	else
	begin
		if(iLs == 3'd1)
		begin
			bg1_shift <= bg1_shift_0;
			bg2_shift <= bg2_shift_0;
		end
		else
		begin
			bg1_shift <= 0;
			bg2_shift <= 0;			
		end
	end
end		


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		shift_addr_rd1_ini <= 0;
		shift_addr_rd2_ini <= 0; 
	end
	else
	begin
		if(jLs == 3'd1)
		begin
			shift_addr_rd1_ini <= 0;
			shift_addr_rd2_ini <= 0;
		end
		else
		begin
			shift_addr_rd1_ini <= 1;
			shift_addr_rd2_ini <= 1;
		end
	end
end		
assign shift_25 =	bg ?     10'b1000000000: bg1_shift[9  :0  ];
assign shift_24 =	bg ?     10'b1000000000: bg1_shift[19 :10 ];
assign shift_23 =	bg ?     10'b1000000000: bg1_shift[29 :20 ];
assign shift_22 =	bg ?     10'b1000000000: bg1_shift[39 :30 ];
assign shift_21 =	bg ?     10'b1000000000: bg1_shift[49 :40 ];
assign shift_20 =	bg ?     10'b1000000000: bg1_shift[59 :50 ];
assign shift_19 =	bg ?     10'b1000000000: bg1_shift[69 :60 ];
assign shift_18 =	bg ?     10'b1000000000: bg1_shift[79 :70 ];
assign shift_17 =	bg ?     10'b1000000000: bg1_shift[89 :80 ];
assign shift_16 =	bg ?     10'b1000000000: bg1_shift[99 :90 ];
assign shift_15 =	bg ?     10'b1000000000: bg1_shift[109:100];
assign shift_14 =	bg ?     10'b1000000000: bg1_shift[119:110];
assign shift_13 =	bg ? bg2_shift[9  :0  ]: bg1_shift[129:120];
assign shift_12 =	bg ? bg2_shift[19 :10 ]: bg1_shift[139:130];
assign shift_11 =	bg ? bg2_shift[29 :20 ]: bg1_shift[149:140];
assign shift_10 =	bg ? bg2_shift[39 :30 ]: bg1_shift[159:150];
assign shift_9 =	bg ? bg2_shift[49 :40 ]: bg1_shift[169:160];
assign shift_8 =	bg ? bg2_shift[59 :50 ]: bg1_shift[179:170];
assign shift_7 =	bg ? bg2_shift[69 :60 ]: bg1_shift[189:180];
assign shift_6 =	bg ? bg2_shift[79 :70 ]: bg1_shift[199:190];
assign shift_5 =	bg ? bg2_shift[89 :80 ]: bg1_shift[209:200];
assign shift_4 =	bg ? bg2_shift[99 :90 ]: bg1_shift[219:210];
assign shift_3 =	bg ? bg2_shift[109:100]: bg1_shift[229:220];
assign shift_2 =	bg ? bg2_shift[119:110]: bg1_shift[239:230];
assign shift_1 =	bg ? bg2_shift[129:120]: bg1_shift[249:240];
assign shift_0 =	bg ? bg2_shift[139:130]: bg1_shift[259:250];

assign shift_nsign_25 =	shift_25[8:0]  ;
assign shift_nsign_24 =	shift_24[8:0]  ;
assign shift_nsign_23 =	shift_23[8:0]  ;
assign shift_nsign_22 =	shift_22[8:0]  ;
assign shift_nsign_21 =	shift_21[8:0]  ;
assign shift_nsign_20 =	shift_20[8:0]  ;
assign shift_nsign_19 =	shift_19[8:0]  ;
assign shift_nsign_18 =	shift_18[8:0]  ;
assign shift_nsign_17 =	shift_17[8:0]  ;
assign shift_nsign_16 =	shift_16[8:0]  ;
assign shift_nsign_15 =	shift_15[8:0]  ;
assign shift_nsign_14 =	shift_14[8:0]  ;
assign shift_nsign_13 =	shift_13[8:0]  ;
assign shift_nsign_12 =	shift_12[8:0]  ;
assign shift_nsign_11 =	shift_11[8:0]  ;
assign shift_nsign_10 =	shift_10[8:0]  ;
assign shift_nsign_9 =	shift_9[8:0]  ;
assign shift_nsign_8 =	shift_8[8:0]  ;
assign shift_nsign_7 =	shift_7[8:0]  ;
assign shift_nsign_6 =	shift_6[8:0]  ;
assign shift_nsign_5 =	shift_5[8:0]  ;
assign shift_nsign_4 =	shift_4[8:0]  ;
assign shift_nsign_3 =	shift_3[8:0]  ;
assign shift_nsign_2 =	shift_2[8:0]  ;
assign shift_nsign_1 =	shift_1[8:0]  ;
assign shift_nsign_0 =	shift_0[8:0]  ;

//APP RAM

/*
wire [3:0]  APP_addr_rd_ini_0,APP_addr_rd_ini_1,APP_addr_rd_ini_2,APP_addr_rd_ini_3,APP_addr_rd_ini_4,APP_addr_rd_ini_5,APP_addr_rd_ini_6,APP_addr_rd_ini_7,APP_addr_rd_ini_8,APP_addr_rd_ini_9,
           APP_addr_rd_ini_10,APP_addr_rd_ini_11,APP_addr_rd_ini_12,APP_addr_rd_ini_13,APP_addr_rd_ini_14,APP_addr_rd_ini_15,APP_addr_rd_ini_16,APP_addr_rd_ini_17,APP_addr_rd_ini_18,APP_addr_rd_ini_19,
           APP_addr_rd_ini_20,APP_addr_rd_ini_21,APP_addr_rd_ini_22,APP_addr_rd_ini_23,APP_addr_rd_ini_24,APP_addr_rd_ini_25,APP_addr_rd_ini_26;	
reg [3:0]  APP_addr_rd_0,APP_addr_rd_1,APP_addr_rd_2,APP_addr_rd_3,APP_addr_rd_4,APP_addr_rd_5,APP_addr_rd_6,APP_addr_rd_7,APP_addr_rd_8,APP_addr_rd_9,
           APP_addr_rd_10,APP_addr_rd_11,APP_addr_rd_12,APP_addr_rd_13,APP_addr_rd_14,APP_addr_rd_15,APP_addr_rd_16,APP_addr_rd_17,APP_addr_rd_18,APP_addr_rd_19,
           APP_addr_rd_20,APP_addr_rd_21,APP_addr_rd_22,APP_addr_rd_23,APP_addr_rd_24,APP_addr_rd_25;
reg [9:0]  APP_addr_rd_26;


reg [5:0] c_reg_0,c_reg_1,c_reg_2,c_reg_3,c_reg_4,c_reg_5,c_reg_6,c_reg_7,c_reg_8,c_reg_9,
      c_reg_10,c_reg_11,c_reg_12,c_reg_13,c_reg_14,c_reg_15,c_reg_16,c_reg_17,c_reg_18,c_reg_19,
      c_reg_20,c_reg_21,c_reg_22,c_reg_23,c_reg_24,c_reg_25;
wire [5:0] c_0,c_1,c_2,c_3,c_4,c_5,c_6,c_7,c_8,c_9,
      c_10,c_11,c_12,c_13,c_14,c_15,c_16,c_17,c_18,c_19,
      c_20,c_21,c_22,c_23,c_24,c_25;	  
*/
get_addrini u0_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_0[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_0 ),.c(c_0));
get_addrini u1_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_1[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_1 ),.c(c_1 ));
get_addrini u2_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_2[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_2 ),.c(c_2 ));
get_addrini u3_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_3[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_3 ),.c(c_3 ));
get_addrini u4_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_4[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_4 ),.c(c_4 ));
get_addrini u5_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_5[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_5 ),.c(c_5 ));
get_addrini u6_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_6[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_6 ),.c(c_6 ));
get_addrini u7_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_7[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_7 ),.c(c_7 ));
get_addrini u8_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_8[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_8 ),.c(c_8 ));
get_addrini u9_getaddrini(.clk(clk),.rst_n(rst_n),.shift( shift_nsign_9[8:0] ),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_9 ),.c(c_9 ));
get_addrini u10_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_10[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_10),.c(c_10));
get_addrini u11_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_11[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_11),.c(c_11));
get_addrini u12_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_12[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_12),.c(c_12));
get_addrini u13_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_13[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_13),.c(c_13));
get_addrini u14_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_14[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_14),.c(c_14));
get_addrini u15_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_15[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_15),.c(c_15));
get_addrini u16_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_16[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_16),.c(c_16));
get_addrini u17_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_17[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_17),.c(c_17));
get_addrini u18_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_18[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_18),.c(c_18));
get_addrini u19_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_19[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_19),.c(c_19));
get_addrini u20_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_20[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_20),.c(c_20));
get_addrini u21_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_21[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_21),.c(c_21));
get_addrini u22_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_22[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_22),.c(c_22));
get_addrini u23_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_23[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_23),.c(c_23));
get_addrini u24_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_24[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_24),.c(c_24));
get_addrini u25_getaddrini(.clk(clk),.rst_n(rst_n),.shift(shift_nsign_25[8:0]),.max_addr(APP_addr_max),.addrini(APP_addr_rd_ini_25),.c(c_25));


//reg APP_rd_en;
//reg [3:0] APP_rd_en_cnt;

wire [4:0] APP_rd_en_cnt_max;
assign APP_rd_en_cnt_max = APP_addr_rd_max + 2;

assign APP_addr_wr_max = APP_addr_rd_max;

reg [4:0] APP_rd_begin_cnt;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_rd_begin_cnt <= 0;
		
	end
	else if(APP_rd_en && ~APP_rd_D0)begin
		APP_rd_begin_cnt <= 0;
	end
	else begin //APP_addr_rd_max
		APP_rd_begin_cnt <= APP_rd_begin_cnt + 1 ;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_rd_en <= 0;
		
	end
	else if(update_start_D0)begin
		APP_rd_en <= 1;
	end
	else if(decode_output_flag)
	begin
		APP_rd_en <= 1;
	end
	else if(APP_rd_en_cnt == APP_addr_rd_max)begin //APP_addr_rd_max
		APP_rd_en <= 0;
	end
end


always@(posedge clk or negedge rst_n)begin
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

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_rd_end <= 0;
	end
	else if(APP_rd_en_cnt == APP_addr_rd_max)
		APP_rd_end <= 1;
	else 
		APP_rd_end <= 0;	
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_rd_end_cnt <= 0;
	end
	else if(APP_rd_end)
		APP_rd_end_cnt <= APP_rd_end_cnt + 1;
	else 
		APP_rd_end_cnt <= 0;	
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
		APP_rd_endD7  <= APP_rd_endD6 ;		
		APP_rd_endD8  <= APP_rd_endD7 ;
		APP_rd_endD9  <= APP_rd_endD8 ;
		APP_rd_endD10 <= APP_rd_endD9 ;
		APP_rd_endD11 <= APP_rd_endD10;
		APP_rd_endD12 <= APP_rd_endD11;
		APP_rd_endD13 <= APP_rd_endD12;		
		APP_rd_endD14 <= APP_rd_endD13;
		APP_rd_endD15 <= APP_rd_endD14;
		APP_rd_endD16 <= APP_rd_endD15;	
		
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_0  <= 0;
		c_reg_0 <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_rd_0  <= APP_addr_rd_ini_0 ;
		c_reg_0 <= c_0;
	end
	else if(decode_output_flag)
	begin
		APP_addr_rd_0  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_0 == APP_addr_rd_max)begin
		if(c_reg_0==P_1)
			c_reg_0 <= 0;
		else
			c_reg_0 <= c_reg_0 + 1;
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
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
	else if(decode_output_flag)
	begin
		APP_addr_rd_25  <= 0;
	end
	else if(APP_rd_en)begin
	if(APP_addr_rd_25 == APP_addr_rd_max)begin
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


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		share_flag  <= 0;
	end
	else if(decode_start)
		share_flag  <= 0;
	else if(Layernum == 5'd4)begin
		share_flag  <= 1;
	end
	else
		share_flag <= share_flag;

end

reg [4:0] share_cnt;
reg share_rd_flag;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
			share_rd_flag <= 0;
	end
	else if(decode_start)begin
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
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_26  <= 0;
		share_cnt <= 0;

	end
	else if(decode_start| APP_addr_rd_26 == APP_share_addr_rd_max)begin
		APP_addr_rd_26  <= 0;
		share_cnt <= 0;
	end
	else if(share_cnt == APP_addr_max)begin
		APP_addr_rd_26  <= APP_addr_rd_26;
		share_cnt <= 0;
	end
	else if( APP_rd_en && share_flag && share_rd_flag)begin
		APP_addr_rd_26  <= APP_addr_rd_26+1;
		share_cnt <= share_cnt + 1;
	end
end
*/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_rd_26  <= 0;
	end
	else if(decode_start)begin
		APP_addr_rd_26  <= 0;
	end
	else if(APP_addr_rd_26 == 10'd671)begin
		APP_addr_rd_26  <= 0;
	end
	else if(APP_rd_en && share_flag)begin
		APP_addr_rd_26  <= APP_addr_rd_26+1;
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_26  <= 0;
	end
	else if(decode_start)begin
		APP_addr_wr_26  <= 0;
	end
	else if(APP_wr_en && share_flag)begin
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

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_wr_en <= 0;
	end
	else if(APP_wr_en_cnt == APP_addr_rd_max)begin
		APP_wr_en <= 0;
	end
	else if(APP_rd_begin_cnt == `APP_ProcessTime && iternum <3'd3)begin
		APP_wr_en <= 1;
	end
	else
		APP_wr_en <= APP_wr_en;
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APP_wr_en_D0 <= 0;
	end
	else
	begin
		APP_wr_en_D0 <= APP_wr_en;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_wr_en_cnt <= 0;
	end
	else if(APP_wr_en_cnt == APP_addr_rd_max)begin
		APP_wr_en_cnt <= 0;
	end
	else if(APP_wr_en)begin
		APP_wr_en_cnt <= APP_wr_en_cnt+1;
	end
	else
		APP_wr_en_cnt <= APP_wr_en_cnt;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		APP_addr_wr_0  <= 0;
	end
	else if(update_start_D0)begin
		APP_addr_wr_0  <= APP_addr_rd_ini_0 ;
	end
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
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
	else if(APP_wr_en)begin
	if(APP_addr_wr_25 == APP_addr_wr_max)begin
		APP_addr_wr_25 <= 0;
	end
	else
		APP_addr_wr_25 <= APP_addr_wr_25+1;
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
                  APPmsg_new_20,APPmsg_new_21,APPmsg_new_22,APPmsg_new_23,APPmsg_new_24,APPmsg_new_25,APPmsg_new_26;
reg APP_wr_en;
reg [3:0] APP_wr_en_cnt;
wire APP_wr_en_0,APP_wr_en_1,APP_wr_en_2,APP_wr_en_3,APP_wr_en_4,APP_wr_en_5,APP_wr_en_6,APP_wr_en_7,APP_wr_en_8,APP_wr_en_9,
                  APP_wr_en_10,APP_wr_en_11,APP_wr_en_12,APP_wr_en_13,APP_wr_en_14,APP_wr_en_15,APP_wr_en_16,APP_wr_en_17,APP_wr_en_18,APP_wr_en_19,
                  APP_wr_en_20,APP_wr_en_21,APP_wr_en_22,APP_wr_en_23,APP_wr_en_24,APP_wr_en_25,APP_wr_en_26;
*/


assign  APP_wr_en_0  = APP_wr_en & ~shift_0 [9];
assign  APP_wr_en_1  = APP_wr_en & ~shift_1 [9];
assign  APP_wr_en_2  = APP_wr_en & ~shift_2 [9];
assign  APP_wr_en_3  = APP_wr_en & ~shift_3 [9];
assign  APP_wr_en_4  = APP_wr_en & ~shift_4 [9];
assign  APP_wr_en_5  = APP_wr_en & ~shift_5 [9];
assign  APP_wr_en_6  = APP_wr_en & ~shift_6 [9];
assign  APP_wr_en_7  = APP_wr_en & ~shift_7 [9];
assign  APP_wr_en_8  = APP_wr_en & ~shift_8 [9];
assign  APP_wr_en_9  = APP_wr_en & ~shift_9 [9];
assign  APP_wr_en_10 = APP_wr_en & ~shift_10[9];
assign  APP_wr_en_11 = APP_wr_en & ~shift_11[9];
assign  APP_wr_en_12 = APP_wr_en & ~shift_12[9];
assign  APP_wr_en_13 = APP_wr_en & ~shift_13[9];
assign  APP_wr_en_14 = APP_wr_en & ~shift_14[9];
assign  APP_wr_en_15 = APP_wr_en & ~shift_15[9];
assign  APP_wr_en_16 = APP_wr_en & ~shift_16[9];
assign  APP_wr_en_17 = APP_wr_en & ~shift_17[9];
assign  APP_wr_en_18 = APP_wr_en & ~shift_18[9];
assign  APP_wr_en_19 = APP_wr_en & ~shift_19[9];
assign  APP_wr_en_20 = APP_wr_en & ~shift_20[9];
assign  APP_wr_en_21 = APP_wr_en & ~shift_21[9];
assign  APP_wr_en_22 = APP_wr_en & ~shift_22[9];
assign  APP_wr_en_23 = APP_wr_en & ~shift_23[9];
assign  APP_wr_en_24 = APP_wr_en & ~shift_24[9];
assign  APP_wr_en_25 = APP_wr_en & ~shift_25[9];
assign  APP_wr_en_26 = APP_wr_en & share_flag;

APPmemory_0  u0_APPmemory(.clka(clk),   .ena(APP_wr_en_0 ), .wea(1'b1), .addra(APP_addr_wr_0 ), .dina(APPmsg_new_0 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_0 ), .doutb(APPmsg_old_0 ));
APPmemory_1  u1_APPmemory(.clka(clk),   .ena(APP_wr_en_1 ), .wea(1'b1), .addra(APP_addr_wr_1 ), .dina(APPmsg_new_1 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_1 ), .doutb(APPmsg_old_1 ));
APPmemory_2  u2_APPmemory(.clka(clk),   .ena(APP_wr_en_2 ), .wea(1'b1), .addra(APP_addr_wr_2 ), .dina(APPmsg_new_2 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_2 ), .doutb(APPmsg_old_2 ));
APPmemory_3  u3_APPmemory(.clka(clk),   .ena(APP_wr_en_3 ), .wea(1'b1), .addra(APP_addr_wr_3 ), .dina(APPmsg_new_3 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_3 ), .doutb(APPmsg_old_3 ));
APPmemory_4  u4_APPmemory(.clka(clk),   .ena(APP_wr_en_4 ), .wea(1'b1), .addra(APP_addr_wr_4 ), .dina(APPmsg_new_4 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_4 ), .doutb(APPmsg_old_4 ));
APPmemory_5  u5_APPmemory(.clka(clk),   .ena(APP_wr_en_5 ), .wea(1'b1), .addra(APP_addr_wr_5 ), .dina(APPmsg_new_5 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_5 ), .doutb(APPmsg_old_5 ));
APPmemory_6  u6_APPmemory(.clka(clk),   .ena(APP_wr_en_6 ), .wea(1'b1), .addra(APP_addr_wr_6 ), .dina(APPmsg_new_6 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_6 ), .doutb(APPmsg_old_6 ));
APPmemory_7  u7_APPmemory(.clka(clk),   .ena(APP_wr_en_7 ), .wea(1'b1), .addra(APP_addr_wr_7 ), .dina(APPmsg_new_7 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_7 ), .doutb(APPmsg_old_7 ));
APPmemory_8  u8_APPmemory(.clka(clk),   .ena(APP_wr_en_8 ), .wea(1'b1), .addra(APP_addr_wr_8 ), .dina(APPmsg_new_8 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_8 ), .doutb(APPmsg_old_8 ));
APPmemory_9  u9_APPmemory(.clka(clk),   .ena(APP_wr_en_9 ), .wea(1'b1), .addra(APP_addr_wr_9 ), .dina(APPmsg_new_9 ), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_9 ), .doutb(APPmsg_old_9 ));
APPmemory_10 u10_APPmemory(.clka(clk),  .ena(APP_wr_en_10), .wea(1'b1), .addra(APP_addr_wr_10), .dina(APPmsg_new_10), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_10), .doutb(APPmsg_old_10));
APPmemory_11 u11_APPmemory(.clka(clk),  .ena(APP_wr_en_11), .wea(1'b1), .addra(APP_addr_wr_11), .dina(APPmsg_new_11), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_11), .doutb(APPmsg_old_11));
APPmemory_12 u12_APPmemory(.clka(clk),  .ena(APP_wr_en_12), .wea(1'b1), .addra(APP_addr_wr_12), .dina(APPmsg_new_12), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_12), .doutb(APPmsg_old_12));
APPmemory_13 u13_APPmemory(.clka(clk),  .ena(APP_wr_en_13), .wea(1'b1), .addra(APP_addr_wr_13), .dina(APPmsg_new_13), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_13), .doutb(APPmsg_old_13));
APPmemory_14 u14_APPmemory(.clka(clk),  .ena(APP_wr_en_14), .wea(1'b1), .addra(APP_addr_wr_14), .dina(APPmsg_new_14), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_14), .doutb(APPmsg_old_14));
APPmemory_15 u15_APPmemory(.clka(clk),  .ena(APP_wr_en_15), .wea(1'b1), .addra(APP_addr_wr_15), .dina(APPmsg_new_15), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_15), .doutb(APPmsg_old_15));
APPmemory_16 u16_APPmemory(.clka(clk),  .ena(APP_wr_en_16), .wea(1'b1), .addra(APP_addr_wr_16), .dina(APPmsg_new_16), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_16), .doutb(APPmsg_old_16));
APPmemory_17 u17_APPmemory(.clka(clk),  .ena(APP_wr_en_17), .wea(1'b1), .addra(APP_addr_wr_17), .dina(APPmsg_new_17), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_17), .doutb(APPmsg_old_17));
APPmemory_18 u18_APPmemory(.clka(clk),  .ena(APP_wr_en_18), .wea(1'b1), .addra(APP_addr_wr_18), .dina(APPmsg_new_18), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_18), .doutb(APPmsg_old_18));
APPmemory_19 u19_APPmemory(.clka(clk),  .ena(APP_wr_en_19), .wea(1'b1), .addra(APP_addr_wr_19), .dina(APPmsg_new_19), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_19), .doutb(APPmsg_old_19));
APPmemory_20 u20_APPmemory(.clka(clk),  .ena(APP_wr_en_20), .wea(1'b1), .addra(APP_addr_wr_20), .dina(APPmsg_new_20), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_20), .doutb(APPmsg_old_20));
APPmemory_21 u21_APPmemory(.clka(clk),  .ena(APP_wr_en_21), .wea(1'b1), .addra(APP_addr_wr_21), .dina(APPmsg_new_21), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_21), .doutb(APPmsg_old_21));
APPmemory_22 u22_APPmemory(.clka(clk),  .ena(APP_wr_en_22), .wea(1'b1), .addra(APP_addr_wr_22), .dina(APPmsg_new_22), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_22), .doutb(APPmsg_old_22));
APPmemory_23 u23_APPmemory(.clka(clk),  .ena(APP_wr_en_23), .wea(1'b1), .addra(APP_addr_wr_23), .dina(APPmsg_new_23), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_23), .doutb(APPmsg_old_23));
APPmemory_24 u24_APPmemory(.clka(clk),  .ena(APP_wr_en_24), .wea(1'b1), .addra(APP_addr_wr_24), .dina(APPmsg_new_24), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_24), .doutb(APPmsg_old_24));
APPmemory_25 u25_APPmemory(.clka(clk),  .ena(APP_wr_en_25), .wea(1'b1), .addra(APP_addr_wr_25), .dina(APPmsg_new_25), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_25), .doutb(APPmsg_old_25));
shareAPPmemory u26_APPmemory(.clka(clk),.ena(APP_wr_en_26), .wea(1'b1), .addra(APP_addr_wr_26), .dina(APPmsg_new_26), .clkb(clk),	.enb(1'd1),  .addrb(APP_addr_rd_26), .doutb(APPmsg_old_26));
/*
data_mcu u0_data_mcu(
		);
	*/	

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
	

//QSN
/*
wire [`APPdata_Len-1:0] QSN_APPmsg_0,QSN_APPmsg_1,QSN_APPmsg_2,QSN_APPmsg_3,QSN_APPmsg_4,QSN_APPmsg_5,QSN_APPmsg_6,QSN_APPmsg_7,QSN_APPmsg_8,QSN_APPmsg_9,
                  QSN_APPmsg_10,QSN_APPmsg_11,QSN_APPmsg_12,QSN_APPmsg_13,QSN_APPmsg_14,QSN_APPmsg_15,QSN_APPmsg_16,QSN_APPmsg_17,QSN_APPmsg_18,QSN_APPmsg_19,
                  QSN_APPmsg_20,QSN_APPmsg_21,QSN_APPmsg_22,QSN_APPmsg_23,QSN_APPmsg_24,QSN_APPmsg_25;
*/
QSN u0_QSN(.clk(clk),.in(APPmsg_old_0 ), .p(P),.c(c_reg_D1_0 ),.out(QSN_APPmsg_0 ));
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
assign DN_APPmsg_31 = {QSN_APPmsg_0 [`VWidth*32-1:`VWidth*31],
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
					  
//CTV memory
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

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_rd_en <= 0;
	end
	else begin
		CTV_rd_en <= APP_rd_D1;
	end
end


always@(posedge clk or negedge rst_n)begin
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

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_rd_begin_cnt <= 0;
		CTV_rd_begin_cnt_flag <= 0;
	end
	else if(CTV_rd_en && ~CTV_rd_D0)begin
		CTV_rd_begin_cnt <= 0;
		CTV_rd_begin_cnt_flag <= 1;
	end
	else if(CTV_rd_begin_cnt_flag) begin //APP_addr_rd_max
		CTV_rd_begin_cnt <= CTV_rd_begin_cnt + 1 ;
	end
end

//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_wr_en <= 0;
	end
	else if(CTV_wr_en_cnt == APP_addr_rd_max)begin
		CTV_wr_en <= 0;
	end
	else if(CTV_rd_begin_cnt == `CTV_ProcessTime)begin
		CTV_wr_en <= 1;
	end
	else
		CTV_wr_en <= CTV_wr_en;
end


always@(posedge clk or negedge rst_n)begin
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
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_addr_rd <= 0;
	end
	else if(decode_start)begin
		CTV_addr_rd <= 0;	
	end
	else if(CTV_addr_rd == 10'd735)begin
		CTV_addr_rd <= 0;
	end
	else if(CTV_rd_en)begin
		CTV_addr_rd <= CTV_addr_rd + 1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CTV_addr_wr <= 0;
	end
	else if(decode_start)begin
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


//DPU
/*
wire [`DPUdata_Len-1:0] DPU_APPmsg_0,DPU_APPmsg_1,DPU_APPmsg_2,DPU_APPmsg_3,DPU_APPmsg_4,DPU_APPmsg_5,DPU_APPmsg_6,DPU_APPmsg_7,DPU_APPmsg_8,DPU_APPmsg_9,
                  DPU_APPmsg_10,DPU_APPmsg_11,DPU_APPmsg_12,DPU_APPmsg_13,DPU_APPmsg_14,DPU_APPmsg_15,DPU_APPmsg_16,DPU_APPmsg_17,DPU_APPmsg_18,DPU_APPmsg_19,
                  DPU_APPmsg_20,DPU_APPmsg_21,DPU_APPmsg_22,DPU_APPmsg_23,DPU_APPmsg_24,DPU_APPmsg_25,DPU_APPmsg_26,DPU_APPmsg_27,DPU_APPmsg_28,DPU_APPmsg_29,DPU_APPmsg_30,DPU_APPmsg_31;
wire  signAPP_0,signAPP_1,signAPP_2,signAPP_3,signAPP_4,signAPP_5,signAPP_6,signAPP_7,signAPP_8,signAPP_9,
                  signAPP_10,signAPP_11,signAPP_12,signAPP_13,signAPP_14,signAPP_15,signAPP_16,signAPP_17,signAPP_18,signAPP_19,
                  signAPP_20,signAPP_21,signAPP_22,signAPP_23,signAPP_24,signAPP_25,signAPP_26,signAPP_27,signAPP_28,signAPP_29,signAPP_30,signAPP_31;   
 */     

assign APP_CTV_0  = first_iter_flag ? 0 : CTV_old_0;
assign APP_CTV_1  = first_iter_flag ? 0 : CTV_old_1; 
assign APP_CTV_2  = first_iter_flag ? 0 : CTV_old_2; 
assign APP_CTV_3  = first_iter_flag ? 0 : CTV_old_3; 
assign APP_CTV_4  = first_iter_flag ? 0 : CTV_old_4; 
assign APP_CTV_5  = first_iter_flag ? 0 : CTV_old_5; 
assign APP_CTV_6  = first_iter_flag ? 0 : CTV_old_6; 
assign APP_CTV_7  = first_iter_flag ? 0 : CTV_old_7; 
assign APP_CTV_8  = first_iter_flag ? 0 : CTV_old_8; 
assign APP_CTV_9  = first_iter_flag ? 0 : CTV_old_9; 
assign APP_CTV_10 = first_iter_flag ? 0 : CTV_old_10;
assign APP_CTV_11 = first_iter_flag ? 0 : CTV_old_11;
assign APP_CTV_12 = first_iter_flag ? 0 : CTV_old_12;
assign APP_CTV_13 = first_iter_flag ? 0 : CTV_old_13;
assign APP_CTV_14 = first_iter_flag ? 0 : CTV_old_14;
assign APP_CTV_15 = first_iter_flag ? 0 : CTV_old_15;
assign APP_CTV_16 = first_iter_flag ? 0 : CTV_old_16;
assign APP_CTV_17 = first_iter_flag ? 0 : CTV_old_17;
assign APP_CTV_18 = first_iter_flag ? 0 : CTV_old_18;
assign APP_CTV_19 = first_iter_flag ? 0 : CTV_old_19;
assign APP_CTV_20 = first_iter_flag ? 0 : CTV_old_20;
assign APP_CTV_21 = first_iter_flag ? 0 : CTV_old_21;
assign APP_CTV_22 = first_iter_flag ? 0 : CTV_old_22;
assign APP_CTV_23 = first_iter_flag ? 0 : CTV_old_23;
assign APP_CTV_24 = first_iter_flag ? 0 : CTV_old_24;
assign APP_CTV_25 = first_iter_flag ? 0 : CTV_old_25;
assign APP_CTV_26 = first_iter_flag ? 0 : CTV_old_26;
assign APP_CTV_27 = first_iter_flag ? 0 : CTV_old_27;
assign APP_CTV_28 = first_iter_flag ? 0 : CTV_old_28;
assign APP_CTV_29 = first_iter_flag ? 0 : CTV_old_29;
assign APP_CTV_30 = first_iter_flag ? 0 : CTV_old_30;
assign APP_CTV_31 = first_iter_flag ? 0 : CTV_old_31;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		flag <= 0;
	end
	else if(decode_start_D3 | APP_rd_endD16) begin
		flag <= {~share_flag,
				 shift_25[9],
				 shift_24[9],
				 shift_23[9],
				 shift_22[9],
				 shift_21[9],
				 shift_20[9],
				 shift_19[9],
				 shift_18[9],
				 shift_17[9],
				 shift_16[9],
				 shift_15[9],
				 shift_14[9],
				 shift_13[9],
				 shift_12[9],
				 shift_11[9],
				 shift_10[9],
				 shift_9[9],
				 shift_8[9],
				 shift_7[9],
				 shift_6[9],
				 shift_5[9],
				 shift_4[9],
				 shift_3[9],
				 shift_2[9],
				 shift_1[9],
				 shift_0[9]
				 };
	end
	else 
		flag <= flag;
end



DPU u0_DPU(.clk(clk),.rst_n(rst_n), .APPdin(DN_APPmsg_reg_0 ),.CTVdin(APP_CTV_0 ),.flag(flag),.APPdout(DPU_APPmsg_0 ),.CTVdout(CTV_new_0 ),.signAPP(signAPP_0 ) );
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
DPU u31_DPU(.clk(clk),.rst_n(rst_n),.APPdin(DN_APPmsg_reg_31),.CTVdin(APP_CTV_31),.flag(flag),.APPdout(DPU_APPmsg_31),.CTVdout(CTV_new_31),.signAPP(signAPP_31));


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

//QSN
/*
wire [5:0] c_new_0,c_new_1,c_new_2,c_new_3,c_new_4,c_new_5,c_new_6,c_new_7,c_new_8,c_new_9,
      c_new_10,c_new_11,c_new_12,c_new_13,c_new_14,c_new_15,c_new_16,c_new_17,c_new_18,c_new_19,
      c_new_20,c_new_21,c_new_22,c_new_23,c_new_24,c_new_25;
reg [155:0] c_reg_new_D0,c_reg_new_D1,c_reg_new_D2,c_reg_new_D3,c_reg_new_D4,c_reg_new_D5,c_reg_new_D6,c_reg_new_D7,c_reg_new_D8,c_reg_new_D9,c_reg_new_10;

wire [5:0] c_D9_0,c_D9_1,c_D9_2,c_D9_3,c_D9_4,c_D9_5,c_D9_6,c_D9_7,c_D9_8,c_D9_9,
      c_D9_10,c_D9_11,c_D9_12,c_D9_13,c_D9_14,c_D9_15,c_D9_16,c_D9_17,c_D9_18,c_D9_19,
      c_D9_20,c_D9_21,c_D9_22,c_D9_23,c_D9_24,c_D9_25;
*/	  
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

assign c_D9_0 = P-c_reg_new_D9[`b*26-1:`b*25];
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

QSN u26_QSN(.clk(clk),.in(GN_APPmsg_reg_0 ),.p(P),.c(c_new_0 ),.out(APPmsg_new_0 ));
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
integer app_file_0 ;
integer app_file_1 ;
integer app_file_2 ;
integer app_file_3 ;
integer app_file_4 ;
integer app_file_5 ;
integer app_file_6 ;
integer app_file_7 ;
integer app_file_8 ;
integer app_file_9 ;
integer app_file_10;
integer app_file_11;
integer app_file_12;
integer app_file_13;
integer app_file_14;
integer app_file_15;
integer app_file_16;
integer app_file_17;
integer app_file_18;
integer app_file_19;
integer app_file_20;
integer app_file_21;
integer app_file_22;
integer app_file_23;
integer app_file_24;
integer app_file_25;
integer app_file_26;

integer ctv_file_0 ;
integer ctv_file_1 ;
integer ctv_file_2 ;
integer ctv_file_3 ;
integer ctv_file_4 ;
integer ctv_file_5 ;
integer ctv_file_6 ;
integer ctv_file_7 ;
integer ctv_file_8 ;
integer ctv_file_9 ;
integer ctv_file_10;
integer ctv_file_11;
integer ctv_file_12;
integer ctv_file_13;
integer ctv_file_14;
integer ctv_file_15;
integer ctv_file_16;
integer ctv_file_17;
integer ctv_file_18;
integer ctv_file_19;
integer ctv_file_20;
integer ctv_file_21;
integer ctv_file_22;
integer ctv_file_23;
integer ctv_file_24;
integer ctv_file_25;
integer ctv_file_26;
integer ctv_file_27;
integer ctv_file_28;
integer ctv_file_29;
integer ctv_file_30;
integer ctv_file_31;

initial begin
	app_file_0 =$fopen("appdata_0.txt");
	app_file_1 =$fopen("appdata_1.txt");
	app_file_2 =$fopen("appdata_2.txt");
	app_file_3 =$fopen("appdata_3.txt");
	app_file_4 =$fopen("appdata_4.txt");
	app_file_5 =$fopen("appdata_5.txt");
	app_file_6 =$fopen("appdata_6.txt");
	app_file_7 =$fopen("appdata_7.txt");
	app_file_8 =$fopen("appdata_8.txt");
	app_file_9 =$fopen("appdata_9.txt");
	app_file_10=$fopen("appdata_10.txt");
	app_file_11=$fopen("appdata_11.txt");
	app_file_12=$fopen("appdata_12.txt");
	app_file_13=$fopen("appdata_13.txt");
	app_file_14=$fopen("appdata_14.txt");
	app_file_15=$fopen("appdata_15.txt");
	app_file_16=$fopen("appdata_16.txt");
	app_file_17=$fopen("appdata_17.txt");
	app_file_18=$fopen("appdata_18.txt");
	app_file_19=$fopen("appdata_19.txt");
	app_file_20=$fopen("appdata_20.txt");
	app_file_21=$fopen("appdata_21.txt");
	app_file_22=$fopen("appdata_22.txt");
	app_file_23=$fopen("appdata_23.txt");
	app_file_24=$fopen("appdata_24.txt");
	app_file_25=$fopen("appdata_25.txt");
	app_file_26=$fopen("appdata_26.txt");

     if(app_file_26 == 0)begin 
                $display ("can not open the file!");    //锟斤拷锟斤拷锟侥硷拷失锟杰ｏ拷锟斤拷示can not open the file!
                $stop;
       end
       
	/*ctv_file_0 =$fopen("ctvdata_0.txt");
	ctv_file_1 =$fopen("ctvdata_1.txt");
	ctv_file_2 =$fopen("ctvdata_2.txt");
	ctv_file_3 =$fopen("ctvdata_3.txt");
	ctv_file_4 =$fopen("ctvdata_4.txt");
	ctv_file_5 =$fopen("ctvdata_5.txt");
	ctv_file_6 =$fopen("ctvdata_6.txt");
	ctv_file_7 =$fopen("ctvdata_7.txt");
	ctv_file_8 =$fopen("ctvdata_8.txt");
	ctv_file_9 =$fopen("ctvdata_9.txt");
	ctv_file_10=$fopen("ctvdata_10.txt");
	ctv_file_11=$fopen("ctvdata_11.txt");
	ctv_file_12=$fopen("ctvdata_12.txt");
	ctv_file_13=$fopen("ctvdata_13.txt");
	ctv_file_14=$fopen("ctvdata_14.txt");
	ctv_file_15=$fopen("ctvdata_15.txt");
	ctv_file_16=$fopen("ctvdata_16.txt");
	ctv_file_17=$fopen("ctvdata_17.txt");
	ctv_file_18=$fopen("ctvdata_18.txt");
	ctv_file_19=$fopen("ctvdata_19.txt");
	ctv_file_20=$fopen("ctvdata_20.txt");
	ctv_file_21=$fopen("ctvdata_21.txt");
	ctv_file_22=$fopen("ctvdata_22.txt");
	ctv_file_23=$fopen("ctvdata_23.txt");
	ctv_file_24=$fopen("ctvdata_24.txt");
	ctv_file_25=$fopen("ctvdata_25.txt");
	ctv_file_26=$fopen("ctvdata_26.txt");
	ctv_file_27=$fopen("ctvdata_27.txt");
	ctv_file_28=$fopen("ctvdata_28.txt");
	ctv_file_29=$fopen("ctvdata_29.txt");
	ctv_file_30=$fopen("ctvdata_30.txt");
	ctv_file_31=$fopen("ctvdata_31.txt");
       if(ctv_file_20 == 0)begin 
                $display ("can not open the file!");    //锟斤拷锟斤拷锟侥硷拷失锟杰ｏ拷锟斤拷示can not open the file!
                $stop;
       end  `
     */ 
end

// always @(posedge clk)
//      if(APP_wr_en && (iternum == 4'd0))   begin     
//       $fwrite(app_file_0  ,"%h\n",$unsigned(APPmsg_new_0 ));
// 	  $fwrite(app_file_1  ,"%h\n",$unsigned(APPmsg_new_1 ));
// 	  $fwrite(app_file_2  ,"%h\n",$unsigned(APPmsg_new_2 ));
// 	  $fwrite(app_file_3  ,"%h\n",$unsigned(APPmsg_new_3 ));
// 	  $fwrite(app_file_4  ,"%h\n",$unsigned(APPmsg_new_4 ));
// 	  $fwrite(app_file_5  ,"%h\n",$unsigned(APPmsg_new_5 ));
// 	  $fwrite(app_file_6  ,"%h\n",$unsigned(APPmsg_new_6 ));
// 	  $fwrite(app_file_7  ,"%h\n",$unsigned(APPmsg_new_7 ));
// 	  $fwrite(app_file_8  ,"%h\n",$unsigned(APPmsg_new_8 ));
// 	  $fwrite(app_file_9  ,"%h\n",$unsigned(APPmsg_new_9 ));
// 	  $fwrite(app_file_10 ,"%h\n",$unsigned(APPmsg_new_10));
// 	  $fwrite(app_file_11 ,"%h\n",$unsigned(APPmsg_new_11));
// 	  $fwrite(app_file_12 ,"%h\n",$unsigned(APPmsg_new_12));
// 	  $fwrite(app_file_13 ,"%h\n",$unsigned(APPmsg_new_13));
// 	  $fwrite(app_file_14 ,"%h\n",$unsigned(APPmsg_new_14));
// 	  $fwrite(app_file_15 ,"%h\n",$unsigned(APPmsg_new_15));
// 	  $fwrite(app_file_16 ,"%h\n",$unsigned(APPmsg_new_16));
// 	  $fwrite(app_file_17 ,"%h\n",$unsigned(APPmsg_new_17));
// 	  $fwrite(app_file_18 ,"%h\n",$unsigned(APPmsg_new_18));
// 	  $fwrite(app_file_19 ,"%h\n",$unsigned(APPmsg_new_19));
// 	  $fwrite(app_file_20 ,"%h\n",$unsigned(APPmsg_new_20));
// 	  $fwrite(app_file_21 ,"%h\n",$unsigned(APPmsg_new_21));
// 	  $fwrite(app_file_22 ,"%h\n",$unsigned(APPmsg_new_22));
// 	  $fwrite(app_file_23 ,"%h\n",$unsigned(APPmsg_new_23));
// 	  $fwrite(app_file_24 ,"%h\n",$unsigned(APPmsg_new_24));
// 	  $fwrite(app_file_25 ,"%h\n",$unsigned(APPmsg_new_25));
// 	  $fwrite(app_file_26 ,"%h\n",$unsigned(APPmsg_new_26));
// 	end
// 	else if( (iternum == 4'd0) && decode_end)
// 	begin
		
//       $fclose(app_file_0 );
// 	  $fclose(app_file_1 );
// 	  $fclose(app_file_2 );
// 	  $fclose(app_file_3 );
// 	  $fclose(app_file_4 );
// 	  $fclose(app_file_5 );
// 	  $fclose(app_file_6 );
// 	  $fclose(app_file_7 );
// 	  $fclose(app_file_8 );
// 	  $fclose(app_file_9 );
// 	  $fclose(app_file_10);
// 	  $fclose(app_file_11);
// 	  $fclose(app_file_12);
// 	  $fclose(app_file_13);
// 	  $fclose(app_file_14);
// 	  $fclose(app_file_15);
// 	  $fclose(app_file_16);
// 	  $fclose(app_file_17);
// 	  $fclose(app_file_18);
// 	  $fclose(app_file_19);
// 	  $fclose(app_file_20);
// 	  $fclose(app_file_21);
// 	  $fclose(app_file_22);
// 	  $fclose(app_file_23);
// 	  $fclose(app_file_24);
// 	  $fclose(app_file_25);
// 	  $fclose(app_file_26);			
// 	end
/*always @(posedge clk)
     if(CTV_wr_en)  begin      
       //$fwrite(ctv_file_0 ,"%h\n",$unsigned(CTV_new_0 ));
	   $fwrite(ctv_file_1 ,"%h\n",$unsigned(CTV_new_1 ));
	   $fwrite(ctv_file_2 ,"%h\n",$unsigned(CTV_new_2 ));
	   $fwrite(ctv_file_3 ,"%h\n",$unsigned(CTV_new_3 ));
	   $fwrite(ctv_file_4 ,"%h\n",$unsigned(CTV_new_4 ));
	   $fwrite(ctv_file_5 ,"%h\n",$unsigned(CTV_new_5 ));
	   $fwrite(ctv_file_6 ,"%h\n",$unsigned(CTV_new_6 ));
	   $fwrite(ctv_file_7 ,"%h\n",$unsigned(CTV_new_7 ));
	   $fwrite(ctv_file_8 ,"%h\n",$unsigned(CTV_new_8 ));
	   $fwrite(ctv_file_9 ,"%h\n",$unsigned(CTV_new_9 ));
	   $fwrite(ctv_file_10,"%h\n",$unsigned(CTV_new_10));
	   $fwrite(ctv_file_11,"%h\n",$unsigned(CTV_new_11));
	   $fwrite(ctv_file_12,"%h\n",$unsigned(CTV_new_12));
	   $fwrite(ctv_file_13,"%h\n",$unsigned(CTV_new_13));
	   $fwrite(ctv_file_14,"%h\n",$unsigned(CTV_new_14));
	   $fwrite(ctv_file_15,"%h\n",$unsigned(CTV_new_15));
	   $fwrite(ctv_file_16,"%h\n",$unsigned(CTV_new_16));
	   $fwrite(ctv_file_17,"%h\n",$unsigned(CTV_new_17));
	   $fwrite(ctv_file_18,"%h\n",$unsigned(CTV_new_18));
	   $fwrite(ctv_file_19,"%h\n",$unsigned(CTV_new_19));
	   $fwrite(ctv_file_20,"%h\n",$unsigned(CTV_new_20));
	   $fwrite(ctv_file_21,"%h\n",$unsigned(CTV_new_21));
	   $fwrite(ctv_file_22,"%h\n",$unsigned(CTV_new_22));
	   $fwrite(ctv_file_23,"%h\n",$unsigned(CTV_new_23));
	   $fwrite(ctv_file_24,"%h\n",$unsigned(CTV_new_24));
	   $fwrite(ctv_file_25,"%h\n",$unsigned(CTV_new_25));
	   $fwrite(ctv_file_26,"%h\n",$unsigned(CTV_new_26));
	   $fwrite(ctv_file_27,"%h\n",$unsigned(CTV_new_27));
	   $fwrite(ctv_file_28,"%h\n",$unsigned(CTV_new_28));
	   $fwrite(ctv_file_29,"%h\n",$unsigned(CTV_new_29));
	   $fwrite(ctv_file_30,"%h\n",$unsigned(CTV_new_30));
	   $fwrite(ctv_file_31,"%h\n",$unsigned(CTV_new_31));
	end 
		else if(update_end)begin
	//$fclose(ctv_file_0 );
	$fclose(ctv_file_1 );
	$fclose(ctv_file_2 );
	$fclose(ctv_file_3 );
	$fclose(ctv_file_4 );
	$fclose(ctv_file_5 );
	$fclose(ctv_file_6 );
	$fclose(ctv_file_7 );
	$fclose(ctv_file_8 );
	$fclose(ctv_file_9 );
	$fclose(ctv_file_10);
	$fclose(ctv_file_11);
	$fclose(ctv_file_12);
	$fclose(ctv_file_13);
	$fclose(ctv_file_14);
	$fclose(ctv_file_15);
	$fclose(ctv_file_16);
	$fclose(ctv_file_17);
	$fclose(ctv_file_18);
	$fclose(ctv_file_19);
	$fclose(ctv_file_20);
	$fclose(ctv_file_21);
	$fclose(ctv_file_22);
	$fclose(ctv_file_23);
	$fclose(ctv_file_24);
	$fclose(ctv_file_25);
	$fclose(ctv_file_26);
	$fclose(ctv_file_27);
	$fclose(ctv_file_28);
	$fclose(ctv_file_29);
	$fclose(ctv_file_30);
	$fclose(ctv_file_31);
		
		end
	   
	  */ 

always @(posedge clk)
begin
	if(APP_rd_D1 && (iternum == 4'd3))
	begin     
		$fwrite(app_file_0  ,"%h\n",$unsigned(APPmsg_old_0 ));
		$fwrite(app_file_1  ,"%h\n",$unsigned(APPmsg_old_1 ));
		$fwrite(app_file_2  ,"%h\n",$unsigned(APPmsg_old_2 ));
		$fwrite(app_file_3  ,"%h\n",$unsigned(APPmsg_old_3 ));
		$fwrite(app_file_4  ,"%h\n",$unsigned(APPmsg_old_4 ));
		$fwrite(app_file_5  ,"%h\n",$unsigned(APPmsg_old_5 ));
		$fwrite(app_file_6  ,"%h\n",$unsigned(APPmsg_old_6 ));
		$fwrite(app_file_7  ,"%h\n",$unsigned(APPmsg_old_7 ));
		$fwrite(app_file_8  ,"%h\n",$unsigned(APPmsg_old_8 ));
		$fwrite(app_file_9  ,"%h\n",$unsigned(APPmsg_old_9 ));
		$fwrite(app_file_10 ,"%h\n",$unsigned(APPmsg_old_10));
		$fwrite(app_file_11 ,"%h\n",$unsigned(APPmsg_old_11));
		$fwrite(app_file_12 ,"%h\n",$unsigned(APPmsg_old_12));
		$fwrite(app_file_13 ,"%h\n",$unsigned(APPmsg_old_13));
		$fwrite(app_file_14 ,"%h\n",$unsigned(APPmsg_old_14));
		$fwrite(app_file_15 ,"%h\n",$unsigned(APPmsg_old_15));
		$fwrite(app_file_16 ,"%h\n",$unsigned(APPmsg_old_16));
		$fwrite(app_file_17 ,"%h\n",$unsigned(APPmsg_old_17));
		$fwrite(app_file_18 ,"%h\n",$unsigned(APPmsg_old_18));
		$fwrite(app_file_19 ,"%h\n",$unsigned(APPmsg_old_19));
		$fwrite(app_file_20 ,"%h\n",$unsigned(APPmsg_old_20));
		$fwrite(app_file_21 ,"%h\n",$unsigned(APPmsg_old_21));
		$fwrite(app_file_22 ,"%h\n",$unsigned(APPmsg_old_22));
		$fwrite(app_file_23 ,"%h\n",$unsigned(APPmsg_old_23));
		$fwrite(app_file_24 ,"%h\n",$unsigned(APPmsg_old_24));
		$fwrite(app_file_25 ,"%h\n",$unsigned(APPmsg_old_25));
		$fwrite(app_file_26 ,"%h\n",$unsigned(APPmsg_old_26));
	end
	else if( (iternum == 4'd3) && APP_rd_endD1)
	begin	
		$fclose(app_file_0 );
		$fclose(app_file_1 );
		$fclose(app_file_2 );
		$fclose(app_file_3 );
		$fclose(app_file_4 );
		$fclose(app_file_5 );
		$fclose(app_file_6 );
		$fclose(app_file_7 );
		$fclose(app_file_8 );
		$fclose(app_file_9 );
		$fclose(app_file_10);
		$fclose(app_file_11);
		$fclose(app_file_12);
		$fclose(app_file_13);
		$fclose(app_file_14);
		$fclose(app_file_15);
		$fclose(app_file_16);
		$fclose(app_file_17);
		$fclose(app_file_18);
		$fclose(app_file_19);
		$fclose(app_file_20);
		$fclose(app_file_21);
		$fclose(app_file_22);
		$fclose(app_file_23);
		$fclose(app_file_24);
		$fclose(app_file_25);
		$fclose(app_file_26);			
	end
end
endmodule