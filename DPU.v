`include "Decoder_Parameters.v"

module DPU(
    input clk,
    input rst_n,
    input [`DPUdata_Len-1:0] APPdin,
    input [`DPUctvdata_Len-1:0] CTVdin,
    input [`P_num-1:0] flag,

    output [`DPUdata_Len-1:0] APPdout,
    output [`DPUctvdata_Len-1:0] CTVdout,
    output signAPP
);
assign signAPP = 1'b0;
wire [`VAWidth-2:0] Max1;
assign Max1 = ~0;
wire signed [`VAWidth-1:0] Max;
assign Max = {1'b0,Max1};
//input APP message
wire signed [`VWidth-1:0] APP0,APP1,APP2,APP3,APP4,APP5,APP6,APP7,APP8,APP9,
                  APP10,APP11,APP12,APP13,APP14,APP15,APP16,APP17,APP18,APP19,
                  APP20,APP21,APP22,APP23,APP24,APP25,APP26;
//updated APP
reg signed [`VRWidth-1:0] APPnew0,APPnew1,APPnew2,APPnew3,APPnew4,APPnew5,APPnew6,APPnew7,APPnew8,APPnew9,
                  APPnew10,APPnew11,APPnew12,APPnew13,APPnew14,APPnew15,APPnew16,APPnew17,APPnew18,APPnew19,
                  APPnew20,APPnew21,APPnew22,APPnew23,APPnew24,APPnew25,APPnew26;

wire signed [`CWidth-1:0] CTV0,CTV1,CTV2,CTV3,CTV4,CTV5,CTV6,CTV7,CTV8,CTV9,
                  CTV10,CTV11,CTV12,CTV13,CTV14,CTV15,CTV16,CTV17,CTV18,CTV19,
                  CTV20,CTV21,CTV22,CTV23,CTV24,CTV25,CTV26;

reg  signed [`CRWidth-1:0] CTVnew0,CTVnew1,CTVnew2,CTVnew3,CTVnew4,CTVnew5,CTVnew6,CTVnew7,CTVnew8,CTVnew9,
                   CTVnew10,CTVnew11,CTVnew12,CTVnew13,CTVnew14,CTVnew15,CTVnew16,CTVnew17,CTVnew18,CTVnew19,
                   CTVnew20,CTVnew21,CTVnew22,CTVnew23,CTVnew24,CTVnew25,CTVnew26;

reg signed [`VAWidth-1:0] VTC0,VTC1,VTC2,VTC3,VTC4,VTC5,VTC6,VTC7,VTC8,VTC9,
                  VTC10,VTC11,VTC12,VTC13,VTC14,VTC15,VTC16,VTC17,VTC18,VTC19,
                  VTC20,VTC21,VTC22,VTC23,VTC24,VTC25,VTC26;

reg	signed [`VAWidth-1:0] VTC0_d1,  VTC1_d1,  VTC2_d1,  VTC3_d1,VTC4_d1,  VTC5_d1,  VTC6_d1,  VTC7_d1,VTC8_d1,  VTC9_d1,
						 VTC10_d1, VTC11_d1,VTC12_d1, VTC13_d1, VTC14_d1, VTC15_d1,VTC16_d1, VTC17_d1, VTC18_d1, VTC19_d1,
						 VTC20_d1, VTC21_d1, VTC22_d1, VTC23_d1,VTC24_d1, VTC25_d1, VTC26_d1;
reg	signed [`VAWidth-1:0] VTC0_d2,  VTC1_d2,  VTC2_d2,  VTC3_d2,VTC4_d2,  VTC5_d2,  VTC6_d2,  VTC7_d2,VTC8_d2,  VTC9_d2,
						 VTC10_d2, VTC11_d2,VTC12_d2, VTC13_d2, VTC14_d2, VTC15_d2,VTC16_d2, VTC17_d2, VTC18_d2, VTC19_d2,
						 VTC20_d2, VTC21_d2, VTC22_d2, VTC23_d2,VTC24_d2, VTC25_d2, VTC26_d2;
reg	signed [`VAWidth-1:0] VTC0_d3,  VTC1_d3,  VTC2_d3,  VTC3_d3,VTC4_d3,  VTC5_d3,  VTC6_d3,  VTC7_d3,VTC8_d3,  VTC9_d3,
						 VTC10_d3, VTC11_d3,VTC12_d3, VTC13_d3, VTC14_d3, VTC15_d3,VTC16_d3, VTC17_d3, VTC18_d3, VTC19_d3,
						 VTC20_d3, VTC21_d3, VTC22_d3, VTC23_d3,VTC24_d3, VTC25_d3, VTC26_d3;
reg	signed [`VAWidth-1:0] VTC0_d4,  VTC1_d4,  VTC2_d4,  VTC3_d4,VTC4_d4,  VTC5_d4,  VTC6_d4,  VTC7_d4,VTC8_d4,  VTC9_d4,
						 VTC10_d4, VTC11_d4,VTC12_d4, VTC13_d4, VTC14_d4, VTC15_d4,VTC16_d4, VTC17_d4, VTC18_d4, VTC19_d4,
						 VTC20_d4, VTC21_d4, VTC22_d4, VTC23_d4,VTC24_d4, VTC25_d4, VTC26_d4;
reg	signed [`VAWidth-1:0] VTC0_d5,  VTC1_d5,  VTC2_d5,  VTC3_d5,VTC4_d5,  VTC5_d5,  VTC6_d5,  VTC7_d5,VTC8_d5,  VTC9_d5,
						 VTC10_d5, VTC11_d5,VTC12_d5, VTC13_d5, VTC14_d5, VTC15_d5,VTC16_d5, VTC17_d5, VTC18_d5, VTC19_d5,
						 VTC20_d5, VTC21_d5, VTC22_d5, VTC23_d5,VTC24_d5, VTC25_d5, VTC26_d5;

						 
wire  [`VAWidth-2:0] VTCabs0,VTCabs1,VTCabs2,VTCabs3,VTCabs4,VTCabs5,VTCabs6,VTCabs7,VTCabs8,VTCabs9,
                  VTCabs10,VTCabs11,VTCabs12,VTCabs13,VTCabs14,VTCabs15,VTCabs16,VTCabs17,VTCabs18,VTCabs19,
                  VTCabs20,VTCabs21,VTCabs22,VTCabs23,VTCabs24,VTCabs25,VTCabs26;

reg     sign0,sign1,sign2,sign3,sign4,sign5,sign6,sign7,sign8,sign9,
        sign10,sign11,sign12,sign13,sign14,sign15,sign16,sign17,sign18,sign19,
        sign20,sign21,sign22,sign23,sign24,sign25,sign26;

reg		sign0_1, sign1_1, sign2_1, sign3_1, sign4_1, sign5_1, sign6_1, sign7_1;
reg		sign8_1, sign9_1, sign10_1, sign11_1, sign12_1, sign13_1;
reg		sign0_2, sign1_2, sign2_2, sign3_2, sign4_2, sign5_2, sign6_2;
reg		sign0_3, sign1_3, sign2_3, sign3_3;
reg		sign_sum;


// reg signed [`VWidth-1:0] Sub0,Sub1,Sub2,Sub3,Sub4,Sub5,Sub6,Sub7,Sub8,Sub9,
//                   Sub10,Sub11,Sub12,Sub13,Sub14,Sub15,Sub16,Sub17,Sub18,Sub19,
//                   Sub20,Sub21,Sub22,Sub23,Sub24,Sub25,Sub26,Sub26;


assign APP26 = APPdin[`VWidth-1:0];
assign APP25 = APPdin[`VWidth*2-1:`VWidth];
assign APP24 = APPdin[`VWidth*3-1:`VWidth*2];
assign APP23 = APPdin[`VWidth*4-1:`VWidth*3];
assign APP22 = APPdin[`VWidth*5-1:`VWidth*4];
assign APP21 = APPdin[`VWidth*6-1:`VWidth*5];
assign APP20 = APPdin[`VWidth*7-1:`VWidth*6];
assign APP19 = APPdin[`VWidth*8-1:`VWidth*7];
assign APP18 = APPdin[`VWidth*9-1:`VWidth*8];
assign APP17 = APPdin[`VWidth*10-1:`VWidth*9];
assign APP16 = APPdin[`VWidth*11-1:`VWidth*10];
assign APP15 = APPdin[`VWidth*12-1:`VWidth*11];
assign APP14 = APPdin[`VWidth*13-1:`VWidth*12];
assign APP13 = APPdin[`VWidth*14-1:`VWidth*13];
assign APP12 = APPdin[`VWidth*15-1:`VWidth*14];
assign APP11 = APPdin[`VWidth*16-1:`VWidth*15];
assign APP10 = APPdin[`VWidth*17-1:`VWidth*16];
assign APP9 = APPdin[`VWidth*18-1:`VWidth*17];
assign APP8 = APPdin[`VWidth*19-1:`VWidth*18];
assign APP7 = APPdin[`VWidth*20-1:`VWidth*19];
assign APP6 = APPdin[`VWidth*21-1:`VWidth*20];
assign APP5 = APPdin[`VWidth*22-1:`VWidth*21];
assign APP4 = APPdin[`VWidth*23-1:`VWidth*22];
assign APP3 = APPdin[`VWidth*24-1:`VWidth*23];
assign APP2 = APPdin[`VWidth*25-1:`VWidth*24];
assign APP1 = APPdin[`VWidth*26-1:`VWidth*25];
assign APP0 = APPdin[`VWidth*27-1:`VWidth*26];


assign CTV26 = CTVdin[`CWidth-1:0];
assign CTV25 = CTVdin[`CWidth*2-1: `CWidth];
assign CTV24 = CTVdin[`CWidth*3-1: `CWidth*2];
assign CTV23 = CTVdin[`CWidth*4-1: `CWidth*3];
assign CTV22 = CTVdin[`CWidth*5-1: `CWidth*4];
assign CTV21 = CTVdin[`CWidth*6-1: `CWidth*5];
assign CTV20 = CTVdin[`CWidth*7-1: `CWidth*6];
assign CTV19 = CTVdin[`CWidth*8-1: `CWidth*7];
assign CTV18 = CTVdin[`CWidth*9-1: `CWidth*8];
assign CTV17 = CTVdin[`CWidth*10-1:`CWidth*9];
assign CTV16 = CTVdin[`CWidth*11-1:`CWidth*10];
assign CTV15 = CTVdin[`CWidth*12-1:`CWidth*11];
assign CTV14 = CTVdin[`CWidth*13-1:`CWidth*12];
assign CTV13 = CTVdin[`CWidth*14-1:`CWidth*13];
assign CTV12 = CTVdin[`CWidth*15-1:`CWidth*14];
assign CTV11 = CTVdin[`CWidth*16-1:`CWidth*15];
assign CTV10 = CTVdin[`CWidth*17-1:`CWidth*16];
assign CTV9  = CTVdin[`CWidth*18-1:`CWidth*17];
assign CTV8  = CTVdin[`CWidth*19-1:`CWidth*18];
assign CTV7  = CTVdin[`CWidth*20-1:`CWidth*19];
assign CTV6  = CTVdin[`CWidth*21-1:`CWidth*20];
assign CTV5  = CTVdin[`CWidth*22-1:`CWidth*21];
assign CTV4  = CTVdin[`CWidth*23-1:`CWidth*22];
assign CTV3  = CTVdin[`CWidth*24-1:`CWidth*23];
assign CTV2  = CTVdin[`CWidth*25-1:`CWidth*24];
assign CTV1  = CTVdin[`CWidth*26-1:`CWidth*25];
assign CTV0  = CTVdin[`CWidth*27-1:`CWidth*26];



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        VTC0 <= 0;
        VTC1 <= 0;
        VTC2 <= 0;
        VTC3 <= 0;
        VTC4 <= 0;
        VTC5 <= 0;
        VTC6 <= 0;
        VTC7 <= 0;
        VTC8 <= 0;
        VTC9 <= 0;
        VTC10 <= 0;
        VTC11 <= 0;
        VTC12 <= 0;
        VTC13 <= 0;
        VTC14 <= 0;
        VTC15 <= 0;
        VTC16 <= 0;
        VTC17 <= 0;
        VTC18 <= 0;
        VTC19 <= 0;
        VTC20 <= 0;
        VTC21 <= 0;
        VTC22 <= 0;
        VTC23 <= 0;
        VTC24 <= 0;
        VTC25 <= 0;
        VTC26 <= 0;
    end
    else begin
        VTC0 <= flag[0]?  Max: (APP0-CTV0);
        VTC1 <= flag[1]?  Max: (APP1-CTV1);
        VTC2 <= flag[2]?  Max: (APP2-CTV2);
        VTC3 <= flag[3]?  Max: (APP3-CTV3);
        VTC4 <= flag[4]?  Max: (APP4-CTV4);
        VTC5 <= flag[5]?  Max: (APP5-CTV5);
        VTC6 <= flag[6]?  Max: (APP6-CTV6);
        VTC7 <= flag[7]?  Max: (APP7-CTV7);
        VTC8 <= flag[8]?  Max: (APP8-CTV8);
        VTC9 <= flag[9]?  Max: (APP9-CTV9);
        VTC10 <= flag[10]?Max: (APP10-CTV10);
        VTC11 <= flag[11]?Max: (APP11-CTV11);
        VTC12 <= flag[12]?Max: (APP12-CTV12);
        VTC13 <= flag[13]?Max: (APP13-CTV13);
        VTC14 <= flag[14]?Max: (APP14-CTV14);
        VTC15 <= flag[15]?Max: (APP15-CTV15);
        VTC16 <= flag[16]?Max: (APP16-CTV16);
        VTC17 <= flag[17]?Max: (APP17-CTV17);
        VTC18 <= flag[18]?Max: (APP18-CTV18);
        VTC19 <= flag[19]?Max: (APP19-CTV19);
        VTC20 <= flag[20]?Max: (APP20-CTV20);
        VTC21 <= flag[21]?Max: (APP21-CTV21);
        VTC22 <= flag[22]?Max: (APP22-CTV22);
        VTC23 <= flag[23]?Max: (APP23-CTV23);
        VTC24 <= flag[24]?Max: (APP24-CTV24);
        VTC25 <= flag[25]?Max: (APP25-CTV25);
        VTC26 <= flag[26]?Max: (APP26-CTV26);

    end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		VTC0_d1  <= 0;  VTC1_d1  <= 0;  VTC2_d1  <= 0;  VTC3_d1  <= 0;  VTC4_d1  <= 0;  VTC5_d1  <= 0;  VTC6_d1  <= 0;  VTC7_d1  <= 0; 
		VTC8_d1  <= 0;  VTC9_d1  <= 0;  VTC10_d1 <= 0;  VTC11_d1 <= 0;  VTC12_d1 <= 0;  VTC13_d1 <= 0;  VTC14_d1 <= 0;  VTC15_d1 <= 0;
		VTC16_d1 <= 0;  VTC17_d1 <= 0;  VTC18_d1 <= 0;  VTC19_d1 <= 0;  VTC20_d1 <= 0;  VTC21_d1 <= 0;  VTC22_d1 <= 0;  VTC23_d1 <= 0;
		VTC24_d1 <= 0;  VTC25_d1 <= 0;  VTC26_d1 <= 0;  
	end
	else
	begin
		VTC0_d1  <= VTC0 ;  VTC1_d1  <= VTC1 ;  VTC2_d1  <= VTC2 ;  VTC3_d1  <= VTC3 ;  VTC4_d1  <= VTC4 ;  VTC5_d1  <= VTC5 ;  VTC6_d1  <= VTC6 ;  VTC7_d1  <= VTC7 ; 
		VTC8_d1  <= VTC8 ;  VTC9_d1  <= VTC9 ;  VTC10_d1 <= VTC10 ; VTC11_d1 <= VTC11 ; VTC12_d1 <= VTC12 ; VTC13_d1 <= VTC13 ; VTC14_d1 <= VTC14 ; VTC15_d1 <= VTC15 ;
		VTC16_d1 <= VTC16 ; VTC17_d1 <= VTC17 ; VTC18_d1 <= VTC18 ; VTC19_d1 <= VTC19 ; VTC20_d1 <= VTC20 ; VTC21_d1 <= VTC21 ; VTC22_d1 <= VTC22 ; VTC23_d1 <= VTC23 ;
		VTC24_d1 <= VTC24 ; VTC25_d1 <= VTC25 ; VTC26_d1 <= VTC26 ;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		VTC0_d2  <= 0;  VTC1_d2  <= 0;  VTC2_d2  <= 0;  VTC3_d2  <= 0;  VTC4_d2  <= 0;  VTC5_d2  <= 0;  VTC6_d2  <= 0;  VTC7_d2  <= 0; 
		VTC8_d2  <= 0;  VTC9_d2  <= 0;  VTC10_d2 <= 0;  VTC11_d2 <= 0;  VTC12_d2 <= 0;  VTC13_d2 <= 0;  VTC14_d2 <= 0;  VTC15_d2 <= 0;
		VTC16_d2 <= 0;  VTC17_d2 <= 0;  VTC18_d2 <= 0;  VTC19_d2 <= 0;  VTC20_d2 <= 0;  VTC21_d2 <= 0;  VTC22_d2 <= 0;  VTC23_d2 <= 0;
		VTC24_d2 <= 0;  VTC25_d2 <= 0;  VTC26_d2 <= 0;  
	end
	else
	begin
		VTC0_d2  <= VTC0_d1;  VTC1_d2  <= VTC1_d1;  VTC2_d2  <= VTC2_d1;  VTC3_d2  <= VTC3_d1;  VTC4_d2  <= VTC4_d1;  VTC5_d2  <= VTC5_d1;  VTC6_d2  <= VTC6_d1;  VTC7_d2  <= VTC7_d1; 
		VTC8_d2  <= VTC8_d1;  VTC9_d2  <= VTC9_d1;  VTC10_d2 <= VTC10_d1; VTC11_d2 <= VTC11_d1; VTC12_d2 <= VTC12_d1; VTC13_d2 <= VTC13_d1; VTC14_d2 <= VTC14_d1; VTC15_d2 <= VTC15_d1;
		VTC16_d2 <= VTC16_d1; VTC17_d2 <= VTC17_d1; VTC18_d2 <= VTC18_d1; VTC19_d2 <= VTC19_d1; VTC20_d2 <= VTC20_d1; VTC21_d2 <= VTC21_d1; VTC22_d2 <= VTC22_d1; VTC23_d2 <= VTC23_d1;
		VTC24_d2 <= VTC24_d1; VTC25_d2 <= VTC25_d1; VTC26_d2 <= VTC26_d1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		VTC0_d3  <= 0;  VTC1_d3  <= 0;  VTC2_d3  <= 0;  VTC3_d3  <= 0;  VTC4_d3  <= 0;  VTC5_d3  <= 0;  VTC6_d3  <= 0;  VTC7_d3  <= 0; 
		VTC8_d3  <= 0;  VTC9_d3  <= 0;  VTC10_d3 <= 0;  VTC11_d3 <= 0;  VTC12_d3 <= 0;  VTC13_d3 <= 0;  VTC14_d3 <= 0;  VTC15_d3 <= 0;
		VTC16_d3 <= 0;  VTC17_d3 <= 0;  VTC18_d3 <= 0;  VTC19_d3 <= 0;  VTC20_d3 <= 0;  VTC21_d3 <= 0;  VTC22_d3 <= 0;  VTC23_d3 <= 0;
		VTC24_d3 <= 0;  VTC25_d3 <= 0;  VTC26_d3 <= 0;  
	end
	else
	begin
		VTC0_d3  <= VTC0_d2;  VTC1_d3  <= VTC1_d2;  VTC2_d3  <= VTC2_d2;  VTC3_d3  <= VTC3_d2;  VTC4_d3  <= VTC4_d2;  VTC5_d3  <= VTC5_d2;  VTC6_d3  <= VTC6_d2;  VTC7_d3  <= VTC7_d2; 
		VTC8_d3  <= VTC8_d2;  VTC9_d3  <= VTC9_d2;  VTC10_d3 <= VTC10_d2; VTC11_d3 <= VTC11_d2; VTC12_d3 <= VTC12_d2; VTC13_d3 <= VTC13_d2; VTC14_d3 <= VTC14_d2; VTC15_d3 <= VTC15_d2;
		VTC16_d3 <= VTC16_d2; VTC17_d3 <= VTC17_d2; VTC18_d3 <= VTC18_d2; VTC19_d3 <= VTC19_d2; VTC20_d3 <= VTC20_d2; VTC21_d3 <= VTC21_d2; VTC22_d3 <= VTC22_d2; VTC23_d3 <= VTC23_d2;
		VTC24_d3 <= VTC24_d2; VTC25_d3 <= VTC25_d2; VTC26_d3 <= VTC26_d2;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		VTC0_d4  <= 0;  VTC1_d4  <= 0;  VTC2_d4  <= 0;  VTC3_d4  <= 0;  VTC4_d4  <= 0;  VTC5_d4  <= 0;  VTC6_d4  <= 0;  VTC7_d4  <= 0; 
		VTC8_d4  <= 0;  VTC9_d4  <= 0;  VTC10_d4 <= 0;  VTC11_d4 <= 0;  VTC12_d4 <= 0;  VTC13_d4 <= 0;  VTC14_d4 <= 0;  VTC15_d4 <= 0;
		VTC16_d4 <= 0;  VTC17_d4 <= 0;  VTC18_d4 <= 0;  VTC19_d4 <= 0;  VTC20_d4 <= 0;  VTC21_d4 <= 0;  VTC22_d4 <= 0;  VTC23_d4 <= 0;
		VTC24_d4 <= 0;  VTC25_d4 <= 0;  VTC26_d4 <= 0;  
	end
	else
	begin
		VTC0_d4  <= VTC0_d3;  VTC1_d4  <= VTC1_d3;  VTC2_d4  <= VTC2_d3;  VTC3_d4  <= VTC3_d3;  VTC4_d4  <= VTC4_d3;  VTC5_d4  <= VTC5_d3;  VTC6_d4  <= VTC6_d3;  VTC7_d4  <= VTC7_d3; 
		VTC8_d4  <= VTC8_d3;  VTC9_d4  <= VTC9_d3;  VTC10_d4 <= VTC10_d3; VTC11_d4 <= VTC11_d3; VTC12_d4 <= VTC12_d3; VTC13_d4 <= VTC13_d3; VTC14_d4 <= VTC14_d3; VTC15_d4 <= VTC15_d3;
		VTC16_d4 <= VTC16_d3; VTC17_d4 <= VTC17_d3; VTC18_d4 <= VTC18_d3; VTC19_d4 <= VTC19_d3; VTC20_d4 <= VTC20_d3; VTC21_d4 <= VTC21_d3; VTC22_d4 <= VTC22_d3; VTC23_d4 <= VTC23_d3;
		VTC24_d4 <= VTC24_d3; VTC25_d4 <= VTC25_d3; VTC26_d4 <= VTC26_d3;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		VTC0_d5  <= 0;  VTC1_d5  <= 0;  VTC2_d5  <= 0;  VTC3_d5  <= 0;  VTC4_d5  <= 0;  VTC5_d5  <= 0;  VTC6_d5  <= 0;  VTC7_d5  <= 0; 
		VTC8_d5  <= 0;  VTC9_d5  <= 0;  VTC10_d5 <= 0;  VTC11_d5 <= 0;  VTC12_d5 <= 0;  VTC13_d5 <= 0;  VTC14_d5 <= 0;  VTC15_d5 <= 0;
		VTC16_d5 <= 0;  VTC17_d5 <= 0;  VTC18_d5 <= 0;  VTC19_d5 <= 0;  VTC20_d5 <= 0;  VTC21_d5 <= 0;  VTC22_d5 <= 0;  VTC23_d5 <= 0;
		VTC24_d5 <= 0;  VTC25_d5 <= 0;  VTC26_d5 <= 0;  
	end
	else
	begin
		VTC0_d5  <= VTC0_d4;  VTC1_d5  <= VTC1_d4;  VTC2_d5  <= VTC2_d4;  VTC3_d5  <= VTC3_d4;  VTC4_d5  <= VTC4_d4;  VTC5_d5  <= VTC5_d4;  VTC6_d5  <= VTC6_d4;  VTC7_d5  <= VTC7_d4; 
		VTC8_d5  <= VTC8_d4;  VTC9_d5  <= VTC9_d4;  VTC10_d5 <= VTC10_d4; VTC11_d5 <= VTC11_d4; VTC12_d5 <= VTC12_d4; VTC13_d5 <= VTC13_d4; VTC14_d5 <= VTC14_d4; VTC15_d5 <= VTC15_d4;
		VTC16_d5 <= VTC16_d4; VTC17_d5 <= VTC17_d4; VTC18_d5 <= VTC18_d4; VTC19_d5 <= VTC19_d4; VTC20_d5 <= VTC20_d4; VTC21_d5 <= VTC21_d4; VTC22_d5 <= VTC22_d4; VTC23_d5 <= VTC23_d4;
		VTC24_d5 <= VTC24_d4; VTC25_d5 <= VTC25_d4; VTC26_d5 <= VTC26_d4;
	end
end

//compute absolute value

assign VTCabs0   = (~VTC0[`VAWidth-1])? VTC0 :(0-VTC0 );
assign VTCabs1   = (~VTC1[`VAWidth-1])? VTC1 :(0-VTC1 );
assign VTCabs2   = (~VTC2[`VAWidth-1])? VTC2 :(0-VTC2 );
assign VTCabs3   = (~VTC3[`VAWidth-1])? VTC3 :(0-VTC3 );
assign VTCabs4   = (~VTC4[`VAWidth-1])? VTC4 :(0-VTC4 );
assign VTCabs5   = (~VTC5[`VAWidth-1])? VTC5 :(0-VTC5 );
assign VTCabs6   = (~VTC6[`VAWidth-1])? VTC6 :(0-VTC6 );
assign VTCabs7   = (~VTC7[`VAWidth-1])? VTC7 :(0-VTC7 );
assign VTCabs8   = (~VTC8[`VAWidth-1])? VTC8 :(0-VTC8 );
assign VTCabs9   = (~VTC9[`VAWidth-1])? VTC9 :(0-VTC9 );
assign VTCabs10  = (~VTC10[`VAWidth-1])? VTC10 :(0-VTC10 );
assign VTCabs11  = (~VTC11[`VAWidth-1])? VTC11 :(0-VTC11 );
assign VTCabs12  = (~VTC12[`VAWidth-1])? VTC12 :(0-VTC12 );
assign VTCabs13  = (~VTC13[`VAWidth-1])? VTC13 :(0-VTC13 );
assign VTCabs14  = (~VTC14[`VAWidth-1])? VTC14 :(0-VTC14 );
assign VTCabs15  = (~VTC15[`VAWidth-1])? VTC15 :(0-VTC15 );
assign VTCabs16  = (~VTC16[`VAWidth-1])? VTC16 :(0-VTC16 );
assign VTCabs17  = (~VTC17[`VAWidth-1])? VTC17 :(0-VTC17 );
assign VTCabs18  = (~VTC18[`VAWidth-1])? VTC18 :(0-VTC18 );
assign VTCabs19  = (~VTC19[`VAWidth-1])? VTC19 :(0-VTC19 );
assign VTCabs20  = (~VTC20[`VAWidth-1])? VTC20 :(0-VTC20 );
assign VTCabs21  = (~VTC21[`VAWidth-1])? VTC21 :(0-VTC21 );
assign VTCabs22  = (~VTC22[`VAWidth-1])? VTC22 :(0-VTC22 );
assign VTCabs23  = (~VTC23[`VAWidth-1])? VTC23 :(0-VTC23 );
assign VTCabs24  = (~VTC24[`VAWidth-1])? VTC24 :(0-VTC24 );
assign VTCabs25  = (~VTC25[`VAWidth-1])? VTC25 :(0-VTC25 );
assign VTCabs26  = (~VTC26[`VAWidth-1])? VTC26 :(0-VTC26 );




//compute sign
//sign reg 
reg		[3:0] VTC_sign0, VTC_sign1, VTC_sign2, VTC_sign3;
reg		[3:0] VTC_sign4, VTC_sign5, VTC_sign6, VTC_sign7;
reg		[3:0] VTC_sign8, VTC_sign9, VTC_sign10, VTC_sign11;
reg		[3:0] VTC_sign12, VTC_sign13, VTC_sign14, VTC_sign15;
reg		[3:0] VTC_sign16, VTC_sign17, VTC_sign18, VTC_sign19;
reg		[3:0] VTC_sign20, VTC_sign21, VTC_sign22, VTC_sign23;
reg		[3:0] VTC_sign24, VTC_sign25, VTC_sign26;

// comput the sign sum
// reg		sign0_1, sign1_1, sign2_1, sign3_1, sign4_1, sign5_1, sign6_1, sign7_1;
// reg		sign8_1, sign9_1, sign10_1, sign11_1, sign12_1, sign13_1;
// reg		sign0_2, sign1_2, sign2_2, sign3_2, sign4_2, sign5_2, sign6_2;
// reg		sign0_3, sign1_3, sign2_3, sign3_3;
// reg		sign_sum;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		VTC_sign0  <= 0;	VTC_sign1 <= 0;		VTC_sign2 <= 0;		VTC_sign3 <= 0;		
		VTC_sign4  <= 0;	VTC_sign5 <= 0;		VTC_sign6 <= 0;		VTC_sign7 <= 0;		
		VTC_sign8  <= 0;	VTC_sign9 <= 0;		VTC_sign10 <= 0;	VTC_sign11 <= 0;	
		VTC_sign12 <= 0;	VTC_sign13 <= 0;	VTC_sign14 <= 0;	VTC_sign15 <= 0;	
		VTC_sign16 <= 0;	VTC_sign17 <= 0;	VTC_sign18 <= 0;	VTC_sign19 <= 0;	
		VTC_sign20 <= 0;	VTC_sign21 <= 0;	VTC_sign22 <= 0;	VTC_sign23 <= 0;	
		VTC_sign24 <= 0;	VTC_sign25 <= 0;	VTC_sign26 <= 0;	
		
		sign0_1 <= 0; sign1_1 <= 0; sign2_1  <= 0;sign3_1  <= 0;sign4_1  <= 0;sign5_1  <= 0;sign6_1  <= 0;sign7_1  <= 0;
		sign8_1 <= 0; sign9_1 <= 0; sign10_1 <= 0;sign11_1 <= 0;sign12_1 <= 0;sign13_1 <= 0;
		
		sign0_2 <= 0; sign1_2 <= 0; sign2_2  <= 0;sign3_2  <= 0;sign4_2  <= 0;sign5_2  <= 0;sign6_2  <= 0;
		
		sign0_3 <= 0; sign1_3 <= 0; sign2_3  <= 0;sign3_3 <= 0;
		
		sign_sum <=0;
	end
	else
	begin	
		VTC_sign0[3:0]  <= {VTC_sign0 [2:0],VTC0 [`VAWidth-1]};
		VTC_sign1[3:0]  <= {VTC_sign1 [2:0],VTC1 [`VAWidth-1]};
		VTC_sign2[3:0]  <= {VTC_sign2 [2:0],VTC2 [`VAWidth-1]};
		VTC_sign3[3:0]  <= {VTC_sign3 [2:0],VTC3 [`VAWidth-1]};
		VTC_sign4[3:0]  <= {VTC_sign4 [2:0],VTC4 [`VAWidth-1]};
		VTC_sign5[3:0]  <= {VTC_sign5 [2:0],VTC5 [`VAWidth-1]};
		VTC_sign6[3:0]  <= {VTC_sign6 [2:0],VTC6 [`VAWidth-1]};
		VTC_sign7[3:0]  <= {VTC_sign7 [2:0],VTC7 [`VAWidth-1]};
		VTC_sign8[3:0]  <= {VTC_sign8 [2:0],VTC8 [`VAWidth-1]};
		VTC_sign9[3:0]  <= {VTC_sign9 [2:0],VTC9 [`VAWidth-1]};
		VTC_sign10[3:0] <= {VTC_sign10[2:0],VTC10[`VAWidth-1]};
		VTC_sign11[3:0] <= {VTC_sign11[2:0],VTC11[`VAWidth-1]};
		VTC_sign12[3:0] <= {VTC_sign12[2:0],VTC12[`VAWidth-1]};
		VTC_sign13[3:0] <= {VTC_sign13[2:0],VTC13[`VAWidth-1]};
		VTC_sign14[3:0] <= {VTC_sign14[2:0],VTC14[`VAWidth-1]};
		VTC_sign15[3:0] <= {VTC_sign15[2:0],VTC15[`VAWidth-1]};
		VTC_sign16[3:0] <= {VTC_sign16[2:0],VTC16[`VAWidth-1]};
		VTC_sign17[3:0] <= {VTC_sign17[2:0],VTC17[`VAWidth-1]};
		VTC_sign18[3:0] <= {VTC_sign18[2:0],VTC18[`VAWidth-1]};
		VTC_sign19[3:0] <= {VTC_sign19[2:0],VTC19[`VAWidth-1]};
		VTC_sign20[3:0] <= {VTC_sign20[2:0],VTC20[`VAWidth-1]};
		VTC_sign21[3:0] <= {VTC_sign21[2:0],VTC21[`VAWidth-1]};
		VTC_sign22[3:0] <= {VTC_sign22[2:0],VTC22[`VAWidth-1]};
		VTC_sign23[3:0] <= {VTC_sign23[2:0],VTC23[`VAWidth-1]};
		VTC_sign24[3:0] <= {VTC_sign24[2:0],VTC24[`VAWidth-1]};
		VTC_sign25[3:0] <= {VTC_sign25[2:0],VTC25[`VAWidth-1]};
		VTC_sign26[3:0] <= {VTC_sign26[2:0],VTC26[`VAWidth-1]};

		//
		sign0_1  <=	VTC0[`VAWidth-1] ^ VTC1[`VAWidth-1] ;
		sign1_1  <= VTC2[`VAWidth-1] ^ VTC3[`VAWidth-1] ;
		sign2_1  <= VTC4[`VAWidth-1] ^ VTC5[`VAWidth-1] ;
		sign3_1  <= VTC6[`VAWidth-1] ^ VTC7[`VAWidth-1] ;
		sign4_1  <= VTC8[`VAWidth-1] ^ VTC9[`VAWidth-1] ;
		sign5_1  <= VTC10[`VAWidth-1]^ VTC11[`VAWidth-1];
		sign6_1  <= VTC12[`VAWidth-1]^ VTC13[`VAWidth-1];
		sign7_1  <= VTC14[`VAWidth-1]^ VTC15[`VAWidth-1];
		sign8_1  <= VTC16[`VAWidth-1]^ VTC17[`VAWidth-1];
		sign9_1  <= VTC18[`VAWidth-1]^ VTC19[`VAWidth-1];
		sign10_1 <= VTC20[`VAWidth-1]^ VTC21[`VAWidth-1];
		sign11_1 <= VTC22[`VAWidth-1]^ VTC23[`VAWidth-1];
		sign12_1 <= VTC24[`VAWidth-1]^ VTC25[`VAWidth-1];
		sign13_1 <= VTC26[`VAWidth-1];
		                    
		sign0_2 <= sign0_1  ^ sign1_1 ;
		sign1_2 <= sign2_1  ^ sign3_1 ;
		sign2_2 <= sign4_1  ^ sign5_1 ;
		sign3_2 <= sign6_1  ^ sign7_1 ;
		sign4_2 <= sign8_1  ^ sign9_1 ;
		sign5_2 <= sign10_1 ^ sign11_1;
		sign6_2 <= sign12_1 ^ sign13_1;


		sign0_3 <= sign0_2 ^ sign1_2;   
		sign1_3 <= sign2_2 ^ sign3_2;
		sign2_3 <= sign4_2 ^ sign5_2;
		sign3_3 <= sign6_2;
		
		sign_sum <= sign0_3 ^ sign1_3 ^sign2_3 ^ sign3_3;			
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        sign0  <= 0;
        sign1  <= 0;
        sign2  <= 0;
        sign3  <= 0;
        sign4  <= 0;
        sign5  <= 0;
        sign6  <= 0;
        sign7  <= 0;
        sign8  <= 0;
        sign9  <= 0;
        sign10 <= 0;
        sign11 <= 0;
        sign12 <= 0;
        sign13 <= 0;
        sign14 <= 0;
        sign15 <= 0;
        sign16 <= 0;
        sign17 <= 0;
        sign18 <= 0;
        sign19 <= 0;
        sign20 <= 0;
        sign21 <= 0;
        sign22 <= 0;
        sign23 <= 0;
        sign24 <= 0;
        sign25 <= 0;
        sign26 <= 0;
    end
    else begin
        sign0  <= sign_sum^VTC_sign0 [3];
        sign1  <= sign_sum^VTC_sign1 [3];
        sign2  <= sign_sum^VTC_sign2 [3];
        sign3  <= sign_sum^VTC_sign3 [3];
        sign4  <= sign_sum^VTC_sign4 [3];
        sign5  <= sign_sum^VTC_sign5 [3];
        sign6  <= sign_sum^VTC_sign6 [3];
        sign7  <= sign_sum^VTC_sign7 [3];
        sign8  <= sign_sum^VTC_sign8 [3];
        sign9  <= sign_sum^VTC_sign9 [3];
        sign10 <= sign_sum^VTC_sign10[3];
        sign11 <= sign_sum^VTC_sign11[3];
        sign12 <= sign_sum^VTC_sign12[3];
        sign13 <= sign_sum^VTC_sign13[3];
        sign14 <= sign_sum^VTC_sign14[3];
        sign15 <= sign_sum^VTC_sign15[3];
        sign16 <= sign_sum^VTC_sign16[3];
        sign17 <= sign_sum^VTC_sign17[3];
        sign18 <= sign_sum^VTC_sign18[3];
        sign19 <= sign_sum^VTC_sign19[3];
        sign20 <= sign_sum^VTC_sign20[3];
        sign21 <= sign_sum^VTC_sign21[3];
        sign22 <= sign_sum^VTC_sign22[3];
        sign23 <= sign_sum^VTC_sign23[3];
        sign24 <= sign_sum^VTC_sign24[3];
        sign25 <= sign_sum^VTC_sign25[3];
        sign26 <= sign_sum^VTC_sign26[3];
    end
    
end


//sort
reg [`VAWidth-2:0] Minabs, SubMinabs;
reg [4:0] Minabs_index;
wire [`VAWidth-2:0] Minabs_u0, SubMinabs_u0;
wire [4:0] Minabs_index_u0;
//normalize
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		Minabs <=0; SubMinabs <=0;
	end
	else
	begin
		Minabs <= {1'b0,Minabs_u0[`VAWidth-2:1]}+{2'b0,Minabs_u0[`VAWidth-2:2]};
		SubMinabs <= {1'b0,SubMinabs_u0[`VAWidth-2:1]}+{2'b0,SubMinabs_u0[`VAWidth-2:2]};

	end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        Minabs_index <= 0;
    end
    else
    begin
        Minabs_index <=Minabs_index_u0; 
    end
end
sort u_sort(.reset(!rst_n),.clock(clk),
            .Minabs(Minabs_u0),.SubMinabs(SubMinabs_u0),.Minabs_index(Minabs_index_u0),
            .PM0(VTCabs0),
            .PM1(VTCabs1),
            .PM2(VTCabs2),
            .PM3(VTCabs3),
            .PM4(VTCabs4),
            .PM5(VTCabs5),
            .PM6(VTCabs6),
            .PM7(VTCabs7),
            .PM8(VTCabs8),
            .PM9(VTCabs9),
            .PM10(VTCabs10),
            .PM11(VTCabs11),
            .PM12(VTCabs12),
            .PM13(VTCabs13),
            .PM14(VTCabs14),
            .PM15(VTCabs15),
            .PM16(VTCabs16),
            .PM17(VTCabs17),
            .PM18(VTCabs18),
            .PM19(VTCabs19),
            .PM20(VTCabs20),
            .PM21(VTCabs21),
            .PM22(VTCabs22),
            .PM23(VTCabs23),
            .PM24(VTCabs24),
            .PM25(VTCabs25),
            .PM26(VTCabs26),
            .PM27(Max1),
            .PM28(Max1),
            .PM29(Max1),
            .PM30(Max1),
            .PM31(Max1)
            );


reg signed [`VAWidth-1:0] MinSum0,MinSum1,MinSum2,MinSum3,MinSum4,MinSum5,MinSum6,MinSum7,MinSum8,MinSum9,
                  MinSum10,MinSum11,MinSum12,MinSum13,MinSum14,MinSum15,MinSum16,MinSum17,MinSum18,MinSum19,
                  MinSum20,MinSum21,MinSum22,MinSum23,MinSum24,MinSum25,MinSum26;
// Compare & Select
always @(posedge clk or negedge rst_n)	//鍖归厤鐩稿簲鍦版渶灏弙alue
begin
	if (!rst_n)
	begin
			MinSum0  <= 0;    MinSum1  <= 0;    MinSum2  <= 0;    MinSum3  <= 0;     MinSum4  <= 0;    MinSum5  <= 0;    MinSum6  <= 0;    MinSum7  <= 0;    
			MinSum8  <= 0;    MinSum9  <= 0;    MinSum10 <= 0;    MinSum11 <= 0;     MinSum12 <= 0;    MinSum13 <= 0;    MinSum14 <= 0;    MinSum15 <= 0;
			MinSum16 <= 0;    MinSum17 <= 0;    MinSum18 <= 0;    MinSum19 <= 0;     MinSum20 <= 0;    MinSum21 <= 0;    MinSum22 <= 0;    MinSum23 <= 0;
			MinSum24 <= 0;    MinSum25 <= 0;    MinSum26 <= 0;    
	end		
	else
	begin
		case (Minabs_index)
		5'd0: 
		begin
			MinSum0  <= SubMinabs; MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;     	  
		end                                                                    
		5'd1:                                                              
		begin                                                                  
			MinSum0  <= Minabs;    MinSum1  <= SubMinabs; MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd2: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= SubMinabs; MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd3: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= SubMinabs; MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;    
		end
		5'd4: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= SubMinabs; MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;   
		end
		5'd5: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= SubMinabs; MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;     
		end
		5'd6: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= SubMinabs; MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;    
		end
		5'd7: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= SubMinabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;     
		end
		5'd8: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= SubMinabs; MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;     
		end
		5'd9: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= SubMinabs; MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;   
		end
		5'd10: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= SubMinabs; MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd11: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= SubMinabs; MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd12: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= SubMinabs; MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;        
		end
		5'd13: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= SubMinabs; MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;        
		end
		5'd14: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= SubMinabs; MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd15: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= SubMinabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd16: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= SubMinabs; MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;     
		end
		5'd17: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= SubMinabs; MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;        
		end
		5'd18: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= SubMinabs; MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;        
		end
		5'd19: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= SubMinabs; MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;        
		end
		5'd20: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= SubMinabs; MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;      
		end
		5'd21:
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= SubMinabs; MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd22: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= SubMinabs; MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;     
		end
		5'd23: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= SubMinabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= Minabs;      
		end
		5'd24: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= SubMinabs; MinSum25 <= Minabs;    MinSum26 <= Minabs;       
		end
		5'd25: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= SubMinabs; MinSum26 <= Minabs;        
		end
		5'd26: 
		begin
			MinSum0  <= Minabs;    MinSum1  <= Minabs;    MinSum2  <= Minabs;    MinSum3  <= Minabs;    MinSum4  <= Minabs;    MinSum5  <= Minabs;    MinSum6  <= Minabs;    MinSum7  <= Minabs;    
			MinSum8  <= Minabs;    MinSum9  <= Minabs;    MinSum10 <= Minabs;    MinSum11 <= Minabs;    MinSum12 <= Minabs;    MinSum13 <= Minabs;    MinSum14 <= Minabs;    MinSum15 <= Minabs;    
			MinSum16 <= Minabs;    MinSum17 <= Minabs;    MinSum18 <= Minabs;    MinSum19 <= Minabs;    MinSum20 <= Minabs;    MinSum21 <= Minabs;    MinSum22 <= Minabs;    MinSum23 <= Minabs;   
			MinSum24 <= Minabs;    MinSum25 <= Minabs;    MinSum26 <= SubMinabs;    
		end
		default :
		begin
			MinSum0  <= 0;    MinSum1  <= 0;    MinSum2  <= 0;    MinSum3  <= 0;    MinSum4  <= 0;    MinSum5  <= 0;    MinSum6  <= 0;    MinSum7  <= 0;    
			MinSum8  <= 0;    MinSum9  <= 0;    MinSum10 <= 0;    MinSum11 <= 0;    MinSum12 <= 0;    MinSum13 <= 0;    MinSum14 <= 0;    MinSum15 <= 0;    
			MinSum16 <= 0;    MinSum17 <= 0;    MinSum18 <= 0;    MinSum19 <= 0;    MinSum20 <= 0;    MinSum21 <= 0;    MinSum22 <= 0;    MinSum23 <= 0;   
			MinSum24 <= 0;    MinSum25 <= 0;    MinSum26 <= 0;        
		end
		endcase
	end
end
//calculate the updated CTV message

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        CTVnew0  <= 0;
        CTVnew1  <= 0;
        CTVnew2  <= 0;
        CTVnew3  <= 0;
        CTVnew4  <= 0;
        CTVnew5  <= 0;
        CTVnew6  <= 0;
        CTVnew7  <= 0;
        CTVnew8  <= 0;
        CTVnew9  <= 0;
        CTVnew10 <= 0;
        CTVnew11 <= 0;
        CTVnew12 <= 0;
        CTVnew13 <= 0;
        CTVnew14 <= 0;
        CTVnew15 <= 0;
        CTVnew16 <= 0;
        CTVnew17 <= 0;
        CTVnew18 <= 0;
        CTVnew19 <= 0;
        CTVnew20 <= 0;
        CTVnew21 <= 0;
        CTVnew22 <= 0;
        CTVnew23 <= 0;
        CTVnew24 <= 0;
        CTVnew25 <= 0;
        CTVnew26 <= 0;
    end
    else begin
        CTVnew0  <= sign0 ?(0-MinSum0 ):MinSum0 ;
        CTVnew1  <= sign1 ?(0-MinSum1 ):MinSum1 ;
        CTVnew2  <= sign2 ?(0-MinSum2 ):MinSum2 ;
        CTVnew3  <= sign3 ?(0-MinSum3 ):MinSum3 ;
        CTVnew4  <= sign4 ?(0-MinSum4 ):MinSum4 ;
        CTVnew5  <= sign5 ?(0-MinSum5 ):MinSum5 ;
        CTVnew6  <= sign6 ?(0-MinSum6 ):MinSum6 ;
        CTVnew7  <= sign7 ?(0-MinSum7 ):MinSum7 ;
        CTVnew8  <= sign8 ?(0-MinSum8 ):MinSum8 ;
        CTVnew9  <= sign9 ?(0-MinSum9 ):MinSum9 ;
        CTVnew10 <= sign10?(0-MinSum10):MinSum10;
        CTVnew11 <= sign11?(0-MinSum11):MinSum11;
        CTVnew12 <= sign12?(0-MinSum12):MinSum12;
        CTVnew13 <= sign13?(0-MinSum13):MinSum13;
        CTVnew14 <= sign14?(0-MinSum14):MinSum14;
        CTVnew15 <= sign15?(0-MinSum15):MinSum15;
        CTVnew16 <= sign16?(0-MinSum16):MinSum16;
        CTVnew17 <= sign17?(0-MinSum17):MinSum17;
        CTVnew18 <= sign18?(0-MinSum18):MinSum18;
        CTVnew19 <= sign19?(0-MinSum19):MinSum19;
        CTVnew20 <= sign20?(0-MinSum20):MinSum20;
        CTVnew21 <= sign21?(0-MinSum21):MinSum21;
        CTVnew22 <= sign22?(0-MinSum22):MinSum22;
        CTVnew23 <= sign23?(0-MinSum23):MinSum23;
        CTVnew24 <= sign24?(0-MinSum24):MinSum24;
        CTVnew25 <= sign25?(0-MinSum25):MinSum25;
        CTVnew26 <= sign26?(0-MinSum26):MinSum26;  
    end
    
end

//calculate the new APP message
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        APPnew0  <= 0;
        APPnew1  <= 0;
        APPnew2  <= 0;
        APPnew3  <= 0;
        APPnew4  <= 0;
        APPnew5  <= 0;
        APPnew6  <= 0;
        APPnew7  <= 0;
        APPnew8  <= 0;
        APPnew9  <= 0;
        APPnew10 <= 0;
        APPnew11 <= 0;
        APPnew12 <= 0;
        APPnew13 <= 0;
        APPnew14 <= 0;
        APPnew15 <= 0;
        APPnew16 <= 0;
        APPnew17 <= 0;
        APPnew18 <= 0;
        APPnew19 <= 0;
        APPnew20 <= 0;
        APPnew21 <= 0;
        APPnew22 <= 0;
        APPnew23 <= 0;
        APPnew24 <= 0;
        APPnew25 <= 0;
        APPnew26 <= 0;
    end
    else begin
        APPnew0  <= (sign0 ?(0-MinSum0 ):MinSum0 ) + VTC0_d5;
        APPnew1  <= (sign1 ?(0-MinSum1 ):MinSum1 ) + VTC1_d5;
        APPnew2  <= (sign2 ?(0-MinSum2 ):MinSum2 ) + VTC2_d5;
        APPnew3  <= (sign3 ?(0-MinSum3 ):MinSum3 ) + VTC3_d5;
        APPnew4  <= (sign4 ?(0-MinSum4 ):MinSum4 ) + VTC4_d5;
        APPnew5  <= (sign5 ?(0-MinSum5 ):MinSum5 ) + VTC5_d5;
        APPnew6  <= (sign6 ?(0-MinSum6 ):MinSum6 ) + VTC6_d5;
        APPnew7  <= (sign7 ?(0-MinSum7 ):MinSum7 ) + VTC7_d5;
        APPnew8  <= (sign8 ?(0-MinSum8 ):MinSum8 ) + VTC8_d5;
        APPnew9  <= (sign9 ?(0-MinSum9 ):MinSum9 ) + VTC9_d5;
        APPnew10 <= (sign10?(0-MinSum10):MinSum10) + VTC10_d5;
        APPnew11 <= (sign11?(0-MinSum11):MinSum11) + VTC11_d5;
        APPnew12 <= (sign12?(0-MinSum12):MinSum12) + VTC12_d5;
        APPnew13 <= (sign13?(0-MinSum13):MinSum13) + VTC13_d5;
        APPnew14 <= (sign14?(0-MinSum14):MinSum14) + VTC14_d5;
        APPnew15 <= (sign15?(0-MinSum15):MinSum15) + VTC15_d5;
        APPnew16 <= (sign16?(0-MinSum16):MinSum16) + VTC16_d5;
        APPnew17 <= (sign17?(0-MinSum17):MinSum17) + VTC17_d5;
        APPnew18 <= (sign18?(0-MinSum18):MinSum18) + VTC18_d5;
        APPnew19 <= (sign19?(0-MinSum19):MinSum19) + VTC19_d5;
        APPnew20 <= (sign20?(0-MinSum20):MinSum20) + VTC20_d5;
        APPnew21 <= (sign21?(0-MinSum21):MinSum21) + VTC21_d5;
        APPnew22 <= (sign22?(0-MinSum22):MinSum22) + VTC22_d5;
        APPnew23 <= (sign23?(0-MinSum23):MinSum23) + VTC23_d5;
        APPnew24 <= (sign24?(0-MinSum24):MinSum24) + VTC24_d5;
        APPnew25 <= (sign25?(0-MinSum25):MinSum25) + VTC25_d5;
        APPnew26 <= (sign26?(0-MinSum26):MinSum26) + VTC26_d5; 

    end
end

wire signed	[`CWidth-1:0] CTV_out0, CTV_out1, CTV_out2, CTV_out3;
wire signed	[`CWidth-1:0] CTV_out4, CTV_out5, CTV_out6, CTV_out7;
wire signed	[`CWidth-1:0] CTV_out8, CTV_out9, CTV_out10,CTV_out11;
wire signed	[`CWidth-1:0] CTV_out12,CTV_out13,CTV_out14,CTV_out15;
wire signed	[`CWidth-1:0] CTV_out16,CTV_out17,CTV_out18,CTV_out19;
wire signed	[`CWidth-1:0] CTV_out20,CTV_out21,CTV_out22,CTV_out23;
wire signed	[`CWidth-1:0] CTV_out24,CTV_out25,CTV_out26;

assign CTV_out0  = flag[0 ]?0:CTV_quantize(CTVnew0 );
assign CTV_out1  = flag[1 ]?0:CTV_quantize(CTVnew1 );
assign CTV_out2  = flag[2 ]?0:CTV_quantize(CTVnew2 );
assign CTV_out3  = flag[3 ]?0:CTV_quantize(CTVnew3 );
assign CTV_out4  = flag[4 ]?0:CTV_quantize(CTVnew4 );
assign CTV_out5  = flag[5 ]?0:CTV_quantize(CTVnew5 );
assign CTV_out6  = flag[6 ]?0:CTV_quantize(CTVnew6 );
assign CTV_out7  = flag[7 ]?0:CTV_quantize(CTVnew7 );
assign CTV_out8  = flag[8 ]?0:CTV_quantize(CTVnew8 );
assign CTV_out9  = flag[9 ]?0:CTV_quantize(CTVnew9 );
assign CTV_out10 = flag[10]?0:CTV_quantize(CTVnew10);
assign CTV_out11 = flag[11]?0:CTV_quantize(CTVnew11);
assign CTV_out12 = flag[12]?0:CTV_quantize(CTVnew12);
assign CTV_out13 = flag[13]?0:CTV_quantize(CTVnew13);
assign CTV_out14 = flag[14]?0:CTV_quantize(CTVnew14);
assign CTV_out15 = flag[15]?0:CTV_quantize(CTVnew15);
assign CTV_out16 = flag[16]?0:CTV_quantize(CTVnew16);
assign CTV_out17 = flag[17]?0:CTV_quantize(CTVnew17);
assign CTV_out18 = flag[18]?0:CTV_quantize(CTVnew18);
assign CTV_out19 = flag[19]?0:CTV_quantize(CTVnew19);
assign CTV_out20 = flag[20]?0:CTV_quantize(CTVnew20);
assign CTV_out21 = flag[21]?0:CTV_quantize(CTVnew21);
assign CTV_out22 = flag[22]?0:CTV_quantize(CTVnew22);
assign CTV_out23 = flag[23]?0:CTV_quantize(CTVnew23);
assign CTV_out24 = flag[24]?0:CTV_quantize(CTVnew24);
assign CTV_out25 = flag[25]?0:CTV_quantize(CTVnew25);
assign CTV_out26 = flag[26]?0:CTV_quantize(CTVnew26);

/*assign  CTVdout = {CTV_out26,CTV_out25,CTV_out24,CTV_out23,CTV_out22,CTV_out21,CTV_out20,
                   CTV_out19,CTV_out18,CTV_out17,CTV_out16,CTV_out15,CTV_out14,CTV_out13,CTV_out12,CTV_out11,CTV_out10,
                   CTV_out9,CTV_out8,CTV_out7,CTV_out6,CTV_out5,CTV_out4,CTV_out3,CTV_out2,CTV_out1,CTV_out0};
*/
assign  CTVdout = {CTV_out0, CTV_out1, CTV_out2, CTV_out3,CTV_out4, CTV_out5, CTV_out6, CTV_out7,CTV_out8, CTV_out9, 
					CTV_out10,CTV_out11,CTV_out12,CTV_out13,CTV_out14,CTV_out15,CTV_out16,CTV_out17,CTV_out18,CTV_out19,
					CTV_out20,CTV_out21,CTV_out22,CTV_out23,CTV_out24,CTV_out25,CTV_out26};


wire signed	[`VWidth-1:0] APP_out0, APP_out1, APP_out2, APP_out3;
wire signed	[`VWidth-1:0] APP_out4, APP_out5, APP_out6, APP_out7;
wire signed	[`VWidth-1:0] APP_out8, APP_out9, APP_out10,APP_out11;
wire signed	[`VWidth-1:0] APP_out12,APP_out13,APP_out14,APP_out15;
wire signed	[`VWidth-1:0] APP_out16,APP_out17,APP_out18,APP_out19;
wire signed	[`VWidth-1:0] APP_out20,APP_out21,APP_out22,APP_out23;
wire signed	[`VWidth-1:0] APP_out24,APP_out25,APP_out26;

assign APP_out0  = APP_quantize(APPnew0 );
assign APP_out1  = APP_quantize(APPnew1 );
assign APP_out2  = APP_quantize(APPnew2 );
assign APP_out3  = APP_quantize(APPnew3 );
assign APP_out4  = APP_quantize(APPnew4 );
assign APP_out5  = APP_quantize(APPnew5 );
assign APP_out6  = APP_quantize(APPnew6 );
assign APP_out7  = APP_quantize(APPnew7 );
assign APP_out8  = APP_quantize(APPnew8 );
assign APP_out9  = APP_quantize(APPnew9 );
assign APP_out10 = APP_quantize(APPnew10);
assign APP_out11 = APP_quantize(APPnew11);
assign APP_out12 = APP_quantize(APPnew12);
assign APP_out13 = APP_quantize(APPnew13);
assign APP_out14 = APP_quantize(APPnew14);
assign APP_out15 = APP_quantize(APPnew15);
assign APP_out16 = APP_quantize(APPnew16);
assign APP_out17 = APP_quantize(APPnew17);
assign APP_out18 = APP_quantize(APPnew18);
assign APP_out19 = APP_quantize(APPnew19);
assign APP_out20 = APP_quantize(APPnew20);
assign APP_out21 = APP_quantize(APPnew21);
assign APP_out22 = APP_quantize(APPnew22);
assign APP_out23 = APP_quantize(APPnew23);
assign APP_out24 = APP_quantize(APPnew24);
assign APP_out25 = APP_quantize(APPnew25);
assign APP_out26 = APP_quantize(APPnew26);


/*assign  APPdout = {APP_out26,APP_out25,APP_out24,APP_out23,APP_out22,APP_out21,APP_out20,
                   APP_out19,APP_out18,APP_out17,APP_out16,APP_out15,APP_out14,APP_out13,APP_out12,APP_out11,APP_out10,
                   APP_out9,APP_out8,APP_out7,APP_out6,APP_out5,APP_out4,APP_out3,APP_out2,APP_out1,APP_out0};
*/

assign  APPdout = {APP_out0, APP_out1, APP_out2, APP_out3,APP_out4, APP_out5, APP_out6, APP_out7,APP_out8, APP_out9, 
					APP_out10,APP_out11,APP_out12,APP_out13,APP_out14,APP_out15,APP_out16,APP_out17,APP_out18,APP_out19,
					APP_out20,APP_out21,APP_out22,APP_out23,APP_out24,APP_out25,APP_out26};
//灏唖ign-10bit鐨刟pp杞崲鎴恠ign-9bit锛岄槻姝㈡暟鎹孩鍑�
function [`VWidth-1:0] APP_quantize;
input signed [`VRWidth-1:0] app_reg;
	if(app_reg > `VMax)
		APP_quantize = `VMax;
	else if(app_reg < `VMin)
		APP_quantize = `VMin;
	else
		APP_quantize = app_reg;
endfunction
//灏唖ign-9bit鐨刢tv杞崲鎴恠ign-7bit锛岄槻姝㈡暟鎹孩鍑�

function [`CWidth-1:0] CTV_quantize; //输出CWidth 4   
input signed [`AWidth-1:0] ctv_reg; //AWidth 8 输入CRWidth 8
	if(ctv_reg > `CMax)
		CTV_quantize = `CMax;
	else if(ctv_reg < `CMin)
		CTV_quantize = `CMin;
	else
		CTV_quantize = ctv_reg;
endfunction

endmodule