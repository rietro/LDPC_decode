`timescale 1ns / 1ps
`include "Decoder_Parameters.v"
module test_Dec;
reg clk;
reg rst_n;

reg [2:0] iLs;
reg [2:0] jLs;

wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_0_23 ,APPmsg_ini_subx_0_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_1_23 ,APPmsg_ini_subx_1_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_2_23 ,APPmsg_ini_subx_2_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_3_23 ,APPmsg_ini_subx_3_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_4_23 ,APPmsg_ini_subx_4_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_5_23 ,APPmsg_ini_subx_5_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_6_23 ,APPmsg_ini_subx_6_78;
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_7_23 ,APPmsg_ini_subx_7_78;

wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_0 = (iLs == 1) ? APPmsg_ini_subx_0_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_0_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_1= (iLs == 1) ? APPmsg_ini_subx_1_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_1_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_2= (iLs == 1) ? APPmsg_ini_subx_2_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_2_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_3= (iLs == 1) ? APPmsg_ini_subx_3_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_3_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_4 = (iLs == 1) ? APPmsg_ini_subx_4_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_4_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_5= (iLs == 1) ? APPmsg_ini_subx_5_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_5_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_6= (iLs == 1) ? APPmsg_ini_subx_6_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_6_78 : 0);
                                            
wire [`Zc*`VWidth-1:0] APPmsg_ini_subx_7= (iLs == 1) ? APPmsg_ini_subx_7_23 :
                                            ((iLs == 2)? APPmsg_ini_subx_7_78 : 0);

reg [1:0] APPmsg_ini_sub_x;
reg buffer_valid;
reg buffer_start;
reg buffer_last;

reg buffer_valid_P1,buffer_valid_P2;

reg [5:0] P;
reg [`APP_addr_width-1:0] APP_addr_max;
reg [`APP_addr_width-2:0] APP_addr_rd_max;
reg ready;

reg end_all;

reg [7:0] cnt_32;
reg [7:0] cnt_128;
reg [1:0] buffer_addr_0, buffer_addr_1, buffer_addr_2, buffer_addr_3, buffer_addr_4, buffer_addr_5,buffer_addr_6,buffer_addr_7;

wire buffer_ready;
wire decode_valid;
wire [2:0] decode_valid_cnt;
wire [`Zc*`DecOut_lifting-1:0] APPmsg_decode_out;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		iLs <= 0;
		jLs <= 0;
		P   <= 6'd32;
		APP_addr_max <= 6'd16; //深度
		APP_addr_rd_max <= 5'd15;

	end
	else begin
		iLs <= 3'd2; // 1:2/3码率 2：7/8码率
		jLs <= 3'd1;
		P   <= 6'd32;
		APP_addr_max <= 5'd16;//深度32
		APP_addr_rd_max <= 4'd15;
	end
end


initial begin
    clk = 0;
    rst_n = 1;
    ready = 0;
    #15 rst_n = 0;

    #15 rst_n = 1;
	
	#50 ready = 1;

end

always #5 clk = ~clk;

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
		if(ready && buffer_ready && !end_all)
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
		if(ready && buffer_ready && !end_all)
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
		end_all <= 0;
	end
	else if(decode_valid_cnt == `BlkNumperDecoder-1)
	begin
		end_all <= 1;
	end
	else
	begin
		end_all <= end_all;
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

	else if(ready) 
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

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		buffer_addr_0 <= 2'd0;
		buffer_addr_1 <= 2'd0;
		buffer_addr_2 <= 2'd0;
		buffer_addr_3 <= 2'd0;
		buffer_addr_4 <= 2'd0;
		buffer_addr_5 <= 2'd0;
		buffer_addr_6 <= 2'd0;
		buffer_addr_7 <= 2'd0;
	end
	else if(buffer_valid)
	begin
		if( iLs == 1)
		begin
			if( (cnt_32 == 8'd12 && APPmsg_ini_sub_x < 3) || (cnt_32 == 8'd124 && APPmsg_ini_sub_x == 3))
			begin
			buffer_addr_0 <= buffer_addr_0 + 2'd1;
			buffer_addr_1 <= buffer_addr_1 + 2'd1;
			buffer_addr_2 <= buffer_addr_2 + 2'd1;
			buffer_addr_3 <= buffer_addr_3 + 2'd1;
			buffer_addr_4 <= buffer_addr_4 + 2'd1;
			buffer_addr_5 <= buffer_addr_5 + 2'd1;
			buffer_addr_6 <= buffer_addr_6 + 2'd1;
			buffer_addr_7 <= buffer_addr_7 + 2'd1;
			end
		end

		else if (iLs == 2)
		begin
			if( cnt_32 == 8'd12 && APPmsg_ini_sub_x < 2 )
			begin
			buffer_addr_0 <= buffer_addr_0 + 2'd1;
			buffer_addr_1 <= buffer_addr_1 + 2'd1;
			buffer_addr_2 <= buffer_addr_2 + 2'd1;
			buffer_addr_3 <= buffer_addr_3 + 2'd1;
			buffer_addr_4 <= buffer_addr_4 + 2'd1;
			buffer_addr_5 <= buffer_addr_5 + 2'd1;
			buffer_addr_6 <= buffer_addr_6 + 2'd1;
			buffer_addr_7 <= buffer_addr_7 + 2'd1;
			end
			else if ( cnt_32 == 8'd12 && APPmsg_ini_sub_x == 2 )
			begin
				buffer_addr_0 <= 2'd0;
				buffer_addr_1 <= 2'd0;
				buffer_addr_2 <= 2'd0;
				buffer_addr_3 <= 2'd0;
				buffer_addr_4 <= 2'd0;
				buffer_addr_5 <= 2'd0;
				buffer_addr_6 <= 2'd0;
				buffer_addr_7 <= 2'd0;
			end
		end
	end
	else
	begin
		buffer_addr_0 <= 2'd0;
		buffer_addr_1 <= 2'd0;
		buffer_addr_2 <= 2'd0;
		buffer_addr_3 <= 2'd0;
		buffer_addr_4 <= 2'd0;
		buffer_addr_5 <= 2'd0;
		buffer_addr_6 <= 2'd0;
		buffer_addr_7 <= 2'd0;
	end
end

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

APPmsg_input_buffer_0 u0_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_0),
	.douta(APPmsg_ini_subx_0_23)
);
APPmsg_input_buffer_1 u1_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_1),
	.douta(APPmsg_ini_subx_1_23)
);
APPmsg_input_buffer_2 u2_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_2),
	.douta(APPmsg_ini_subx_2_23)
);
APPmsg_input_buffer_3 u3_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_3),
	.douta(APPmsg_ini_subx_3_23)
);
APPmsg_input_buffer_4 u4_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_4),
	.douta(APPmsg_ini_subx_4_23)
);
APPmsg_input_buffer_5 u5_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_5),
	.douta(APPmsg_ini_subx_5_23)
);
APPmsg_input_buffer_6 u6_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_6),
	.douta(APPmsg_ini_subx_6_23)
);
APPmsg_input_buffer_7 u7_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_7),
	.douta(APPmsg_ini_subx_7_23)
);

////////////////////78
APPmsg_input_buffer_78_0 u_78_0_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_0),
	.douta(APPmsg_ini_subx_0_78)
);
APPmsg_input_buffer_78_1 u_78_1_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_1),
	.douta(APPmsg_ini_subx_1_78)
);
APPmsg_input_buffer_78_2 u_78_2_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_2),
	.douta(APPmsg_ini_subx_2_78)
);
APPmsg_input_buffer_78_3 u_78_3_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_3),
	.douta(APPmsg_ini_subx_3_78)
);
APPmsg_input_buffer_78_4 u_78_4_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_4),
	.douta(APPmsg_ini_subx_4_78)
);
APPmsg_input_buffer_78_5 u_78_5_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_5),
	.douta(APPmsg_ini_subx_5_78)
);
APPmsg_input_buffer_78_6 u_78_6_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_6),
	.douta(APPmsg_ini_subx_6_78)
);
APPmsg_input_buffer_78_7 u_78_7_APPmsg_input_buffer(
	.clka(clk),
	.addra(buffer_addr_7),
	.douta(APPmsg_ini_subx_7_78)
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


