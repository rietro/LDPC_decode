`include "Decoder_Parameters.v"
module LDPC_decode_top(
    input clk,
    input rst_n,
    input[1:0] mode, // 1:23 2:78
    
    output reg W_READY,
    input W_VALID,
    input W_LAST,
    input [`Zc*`VWidth-1:0] W_DATA, //输入512长
    
    input R_READY,
    output reg R_VALID,
    output reg R_LAST,
    output [`Zc*`VWidth-1:0] R_DATA
);

reg [2:0] iLs;
reg [2:0] jLs;

wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_0;                                    
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_1;                                  
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_2;                                       
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_3;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_4;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_5;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_6;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_7;
reg [1:0] APPmsg_ini_sub_x;

reg buffer_valid;
reg buffer_start;
reg buffer_last;
reg buffer_valid_P1,buffer_valid_P2;
reg [5:0] P;
reg [`APP_addr_width-1:0] APP_addr_max;
reg [`APP_addr_width-2:0] APP_addr_rd_max;


reg [7:0] cnt_32;
reg [7:0] cnt_128;

wire buffer_ready;
wire decode_valid;
wire [2:0] decode_valid_cnt;

wire [`Zc*`DecOut_lifting-1:0] APPmsg_decode_out;
reg new_storaged_data_not_in_use; //暂存的数据，在存储完成后为1，在完全输入译码器后为0
reg new_storaged_out_not_in_use; //暂存的数据，在存储完成后为1，在完全输入译码器后为0

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		iLs <= 0;
		jLs <= 0;
		P   <= 6'd32;
		APP_addr_max <= 6'd16; //深度
		APP_addr_rd_max <= 5'd15;

	end
	else begin
		iLs <= mode; // 1:2/3码率 2：7/8码率
		jLs <= 3'd1;
		P   <= 6'd32;
		APP_addr_max <= 5'd16;//深度32
		APP_addr_rd_max <= 4'd15;
	end
end

//首先是写入数据到中转站中
reg[4:0] llr_in_cnt;
reg[4:0] out_cnt;

reg [`Zc*`VWidth-1:0] llr_in_0,llr_in_1,llr_in_2,llr_in_3,llr_in_4,llr_in_5,llr_in_6,llr_in_7; 

reg [`Zc*`VWidth-1:0] llr_in_8,llr_in_9,llr_in_10,llr_in_11,llr_in_12,llr_in_13,llr_in_14,llr_in_15;

reg [`Zc*`VWidth-1:0] llr_in_16,llr_in_17,llr_in_18,llr_in_19,llr_in_20,llr_in_21,llr_in_22,llr_in_23;

reg [`Zc*`VWidth-1:0] llr_in_24,llr_in_25,llr_in_26,llr_in_27,llr_in_28,llr_in_29,llr_in_30,llr_in_31;

//中转站暂存数据

//根据模式实现不同码率的数据暂存 23码率需要24拍, 78码率需要16拍
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
     llr_in_cnt <= 0;
    end
    else if(W_LAST)
    begin
        llr_in_cnt <= 0;
    end
    else if(W_VALID && iLs == 1) //23码率
    begin
        if( llr_in_cnt < 5'd31)
            llr_in_cnt <= llr_in_cnt + 5'd1;
        else if (llr_in_cnt == 5'd31)
            llr_in_cnt <= 0;
    end
    else if(W_VALID && iLs == 2) //78码率
     begin
        if( llr_in_cnt < 5'd23)
            llr_in_cnt <= llr_in_cnt + 5'd1;
        else if (llr_in_cnt == 5'd23)
            llr_in_cnt <= 0;
    end
end

//将信息存入暂存器
always @(*)
begin
    if(!rst_n)
    begin
        llr_in_0<= 0;llr_in_1<= 0;llr_in_2<= 0;llr_in_3<= 0;llr_in_4<= 0;llr_in_5<= 0;llr_in_6<= 0;llr_in_7<= 0;
        llr_in_8<= 0;llr_in_9<= 0;llr_in_10<= 0;llr_in_11<= 0;llr_in_12<= 0;llr_in_13<= 0;llr_in_14<= 0;llr_in_15<= 0;
        llr_in_16<= 0;llr_in_17<= 0;llr_in_18<= 0;llr_in_19<= 0;llr_in_20<= 0;llr_in_21<= 0;llr_in_22<= 0;llr_in_23<= 0;
        llr_in_24<= 0;llr_in_25<= 0;llr_in_26<= 0;llr_in_27<= 0;llr_in_28<= 0;llr_in_29<= 0;llr_in_30<= 0;llr_in_31<= 0;
    end
    else if(W_VALID)
    begin
        case(llr_in_cnt)
            5'd0: llr_in_0<=W_DATA;
            5'd1: llr_in_1<=W_DATA;
            5'd2: llr_in_2<=W_DATA;
            5'd3: llr_in_3<=W_DATA;
            5'd4: llr_in_4<=W_DATA;
            5'd5: llr_in_5<=W_DATA;
            5'd6: llr_in_6<=W_DATA;
            5'd7: llr_in_7<=W_DATA;
            5'd8: llr_in_8<=W_DATA;
            5'd9: llr_in_9<=W_DATA;
            5'd10: llr_in_10<=W_DATA;
            5'd11: llr_in_11<=W_DATA;
            5'd12: llr_in_12<=W_DATA;
            5'd13: llr_in_13<=W_DATA;
            5'd14: llr_in_14<=W_DATA;
            5'd15: llr_in_15<=W_DATA;
            5'd16: llr_in_16<=W_DATA;
            5'd17: llr_in_17<=W_DATA;
            5'd18: llr_in_18<=W_DATA;
            5'd19: llr_in_19<=W_DATA;
            5'd20: llr_in_20<=W_DATA;
            5'd21: llr_in_21<=W_DATA;
            5'd22: llr_in_22<=W_DATA;
            5'd23: llr_in_23<=W_DATA;
            5'd24: llr_in_24<=W_DATA;
            5'd25: llr_in_25<=W_DATA;
            5'd26: llr_in_26<=W_DATA;
            5'd27: llr_in_27<=W_DATA;
            5'd28: llr_in_28<=W_DATA;
            5'd29: llr_in_29<=W_DATA;
            5'd30: llr_in_30<=W_DATA;
            5'd31: llr_in_31<=W_DATA;
        endcase      
    end
end //存入完毕

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        new_storaged_data_not_in_use <= 0;
    end
    else if(W_LAST) //数据暂存完毕置1
        new_storaged_data_not_in_use <= 1;
    else if( buffer_last )  //数据存入译码器完毕置 0
	    new_storaged_data_not_in_use <= 0;  
end

always @(posedge clk or negedge rst_n) //受到两个控制，首先是和内部buffer_ready相同，但是在数据存储完成后到存储数据到内部译码器的时间需要置0，随后再相同
begin
    if(!rst_n)
    begin
        W_READY <= 0;
    end
    else if(W_LAST)
        W_READY <=0;
    else if( new_storaged_data_not_in_use ) // 但是在数据存储完成后到存储数据到内部译码器的时间需要置0，随后再相同
	    W_READY <=0;  
	else if ( !new_storaged_data_not_in_use)
		W_READY <=1;  
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_valid <= 0;
	end
	else
	begin
		buffer_valid <= buffer_valid_P1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_valid_P1 <= 0;
	end
	else
	begin
		buffer_valid_P1 <= buffer_valid_P2;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_valid_P2 <= 0;
	end

	else if (iLs ==1)
	begin
		if( new_storaged_data_not_in_use && buffer_ready)
		begin
			if(cnt_128 == 8'd175)
			begin 
				buffer_valid_P2 <= 0;
			end
			else
			begin
			buffer_valid_P2 <= 1;
			end
		end
		else if(cnt_128 == 8'd175)
		begin
			buffer_valid_P2 <= 0;
		end
	end

	else if (iLs ==2)
	begin
		if( new_storaged_data_not_in_use && buffer_ready)
		begin
			if(cnt_128 == 8'd47)
			begin 
				buffer_valid_P2 <= 0;
			end
			else
			begin
			buffer_valid_P2 <= 1;
			end
		end
		else if(cnt_128 == 8'd47)
		begin
			buffer_valid_P2 <= 0;
		end
	end

	else
	begin
		buffer_valid_P2 <= buffer_valid_P2;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_start <= 0;
	end
	else if(buffer_valid_P1 && !buffer_valid && buffer_ready)
	begin
		buffer_start <= 1;
	end
	else
	begin
		buffer_start <= 0;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		cnt_128 <= 0;
	end

	else if (buffer_valid)
	begin
		if(iLs == 1)
		begin
			if(cnt_128 == 8'd175)
			begin
				cnt_128 <= 0;
			end
			else
			begin
				cnt_128 <= cnt_128 + 1;
			end
		end

		else if (iLs == 2)
		begin
			if(cnt_128 == 8'd47)
			begin
				cnt_128 <= 0;
			end
			else
			begin
				cnt_128 <= cnt_128 + 1;
			end
		end
	end

	else
	begin
		cnt_128 <= 0;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		cnt_32 <= 0;
	end
	else if(buffer_valid)
	begin
		if((cnt_32 == 8'd15 && APPmsg_ini_sub_x < 3) || (cnt_32 == 8'd127 && APPmsg_ini_sub_x == 3) )
		begin
			cnt_32 <= 0;
		end
		else
		begin
			cnt_32 <= cnt_32 + 1;
		end
	end
	else
	begin
	   cnt_32 <= 0;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_last <= 0;
	end

	else if(buffer_valid) 
	begin
		if(iLs ==1)
		begin
			if(cnt_128 == 8'd174)
			begin
				buffer_last <= 1;
			end
			else
			begin
				buffer_last <= 0;
			end
		end

		else if (iLs ==2 )
		begin
			if(cnt_128 == 8'd46 )
			begin
				buffer_last <= 1;
			end
			else
			begin
				buffer_last <= 0;
			end
		end
	end

	else
	begin
		buffer_last <= 0;
	end
end

wire [`Zc*`VWidth*8-1:0] APPmsg_ini_sub_x_in ;

assign APPmsg_ini_sub_x_in = APPmsg_ini_sub_x==0 ? {llr_in_7,llr_in_6,llr_in_5,llr_in_4,llr_in_3,llr_in_2,llr_in_1,llr_in_0} :
							(APPmsg_ini_sub_x==1 ? {llr_in_15,llr_in_14,llr_in_13,llr_in_12,llr_in_11,llr_in_10,llr_in_9,llr_in_8} :
							(APPmsg_ini_sub_x==2 ? {llr_in_23,llr_in_22,llr_in_21,llr_in_20,llr_in_19,llr_in_18,llr_in_17,llr_in_16} :
							(APPmsg_ini_sub_x==3 ? {llr_in_31,llr_in_30,llr_in_29,llr_in_28,llr_in_27,llr_in_26,llr_in_25,llr_in_24} : 0 )));

assign APPmsg_ini_subx_0 = APPmsg_ini_sub_x_in[`Zc*`VWidth*1-1:`Zc*`VWidth*0];
assign APPmsg_ini_subx_1 = APPmsg_ini_sub_x_in[`Zc*`VWidth*2-1:`Zc*`VWidth*1];
assign APPmsg_ini_subx_2 = APPmsg_ini_sub_x_in[`Zc*`VWidth*3-1:`Zc*`VWidth*2];
assign APPmsg_ini_subx_3 = APPmsg_ini_sub_x_in[`Zc*`VWidth*4-1:`Zc*`VWidth*3];
assign APPmsg_ini_subx_4 = APPmsg_ini_sub_x_in[`Zc*`VWidth*5-1:`Zc*`VWidth*4];
assign APPmsg_ini_subx_5 = APPmsg_ini_sub_x_in[`Zc*`VWidth*6-1:`Zc*`VWidth*5];
assign APPmsg_ini_subx_6 = APPmsg_ini_sub_x_in[`Zc*`VWidth*7-1:`Zc*`VWidth*6];
assign APPmsg_ini_subx_7 = APPmsg_ini_sub_x_in[`Zc*`VWidth*8-1:`Zc*`VWidth*7];

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		APPmsg_ini_sub_x <= 0;
	end	
	else if( iLs == 1)
	begin
		if((cnt_32 == 8'd15 && APPmsg_ini_sub_x < 3) ||  (cnt_32 == 8'd127 && APPmsg_ini_sub_x == 3))
		begin
			APPmsg_ini_sub_x <= APPmsg_ini_sub_x + 1;
		end
	end
	else if( iLs == 2 )
	begin
		if(cnt_32 == 8'd15 && APPmsg_ini_sub_x < 2)
			APPmsg_ini_sub_x <= APPmsg_ini_sub_x + 1;
		else if(cnt_32 == 8'd15 && APPmsg_ini_sub_x == 2)
			APPmsg_ini_sub_x <= 0;
	end
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        new_storaged_out_not_in_use <= 0;
    end
    else if(decode_valid) //数据暂存完毕置1
        new_storaged_out_not_in_use <=1;
    else if( R_LAST )  //数据存入译码器完毕置 0
	    new_storaged_out_not_in_use <=0;  
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        R_VALID <= 0;
    end
    else if(new_storaged_out_not_in_use) //数据暂存完毕置1
        R_VALID <=1;
    else if( R_LAST || !new_storaged_out_not_in_use )  //数据存入译码器完毕置 0
	    R_VALID <= 0;  
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        R_LAST <= 0;
    end
    else if( out_cnt == 5'd31 && iLs == 1) //数据暂存完毕置1
        R_LAST <=1;
    else if( out_cnt == 5'd23 && iLs == 2 )  //数据存入译码器完毕置 0
	    R_LAST <= 1;  
	else
		R_LAST <= 0;  
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
     out_cnt <= 0;
    end
    else if(R_LAST)
    begin
        out_cnt <= 0;
    end
    else if(R_VALID && iLs == 1) //23码率
    begin
        if( out_cnt < 5'd23)
            out_cnt <= out_cnt + 5'd1;
        else if (out_cnt == 5'd23)
            out_cnt <= 0;
    end
    else if(R_VALID && iLs == 2) //78码率
     begin
        if( out_cnt < 5'd15)
            out_cnt <= out_cnt + 5'd1;
        else if (out_cnt == 5'd15)
            out_cnt <= 0;
    end
end

reg [`Zc*`DecOut_lifting-1:0] APPmsg_decode_out_reg;
always @(*)
begin
    if(!rst_n)
    begin
        APPmsg_decode_out_reg <= 0;
    end
    else if(decode_valid)
    begin
        APPmsg_decode_out_reg <= APPmsg_decode_out;
    end
end


LDPC_Dec u_LDPC_Dec(
    .clk(clk),
	.rst_n(rst_n),
	.APPmsg_ini_subx_0(APPmsg_ini_subx_0),
	.APPmsg_ini_subx_1(APPmsg_ini_subx_1),
	.APPmsg_ini_subx_2(APPmsg_ini_subx_2),
	.APPmsg_ini_subx_3(APPmsg_ini_subx_3),
	.APPmsg_ini_subx_4(APPmsg_ini_subx_4),
	.APPmsg_ini_subx_5(APPmsg_ini_subx_5),
	.APPmsg_ini_subx_6(APPmsg_ini_subx_6),
	.APPmsg_ini_subx_7(APPmsg_ini_subx_7),
	
	.APPmsg_ini_sub_x(APPmsg_ini_sub_x),
	.buffer_valid(buffer_valid),
	.buffer_start(buffer_start),
	.buffer_last(buffer_last),
	.iLs(iLs),
	.jLs(jLs),
	.P(P),
	.APP_addr_max(APP_addr_max),
	.APP_addr_rd_max(APP_addr_rd_max),

	.buffer_ready(buffer_ready),
	.decode_valid(decode_valid),
	.decode_valid_cnt(decode_valid_cnt),
	.APPmsg_decode_out(APPmsg_decode_out)
);

integer fp;

initial begin
    fp = $fopen("data_out.txt", "w");  // 打开文件
    if (fp == 0) begin
        $display("无法打开文件！");
        $finish;
    end
end

always @(*) begin
    if (decode_valid) begin
        // 写入二进制字符串
        $fwrite(fp, "%b\n", APPmsg_decode_out);  
        // %b 表示二进制格式
        // 每个 data_out 占一行
    end
end
endmodule	


