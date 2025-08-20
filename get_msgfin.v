`include "Decoder_Parameters.v"
module get_msgfin(
    input clk,
    input rst_n,
    input [`inNum*`VWidth-1:0] data_in, //32 * 6
    input [`APP_addr_width-2:0] addr_in, //同样输入地址
	input en_in,
    output reg [`Zc-1:0] data_out //  4096/32 = 128 deepth               dataout0，1,2,3=32大小 每送进来一个datain 就是 送进来分隔的32个数据，重新分发到原位置 一共送128次进来，对应APP128层
);
reg [`APPRam_depth-1:0] data_out0,data_out1,data_out2,data_out3,data_out4,data_out5,data_out6,data_out7,data_out8,data_out9,data_out10,data_out11,data_out12,data_out13,data_out14,data_out15,data_out16,data_out17,data_out18,data_out19,data_out20,data_out21,data_out22,data_out23,data_out24,data_out25,data_out26,data_out27,data_out28,data_out29,data_out30,data_out31;
reg [`APP_addr_width-2:0] addr_in_D1,addr_in_D2,addr_in_D3;
reg [`APP_addr_width-2:0] addr_in_D2_C0,addr_in_D2_C1,addr_in_D2_C2,addr_in_D2_C3,addr_in_D2_C4,addr_in_D2_C5,addr_in_D2_C6,addr_in_D2_C7,addr_in_D2_C8,addr_in_D2_C9,addr_in_D2_C10,addr_in_D2_C11,addr_in_D2_C12,addr_in_D2_C13,addr_in_D2_C14,addr_in_D2_C15,addr_in_D2_C16,addr_in_D2_C17,addr_in_D2_C18,addr_in_D2_C19,addr_in_D2_C20,addr_in_D2_C21,addr_in_D2_C22,addr_in_D2_C23,addr_in_D2_C24,addr_in_D2_C25,addr_in_D2_C26,addr_in_D2_C27,addr_in_D2_C28,addr_in_D2_C29,addr_in_D2_C30,addr_in_D2_C31;

reg en_in_D1,en_in_D2;
reg en_in_D2_C0,en_in_D2_C1,en_in_D2_C2,en_in_D2_C3,en_in_D2_C4,en_in_D2_C5,en_in_D2_C6,en_in_D2_C7,en_in_D2_C8,en_in_D2_C9,en_in_D2_C10,en_in_D2_C11,en_in_D2_C12,en_in_D2_C13,en_in_D2_C14,en_in_D2_C15,en_in_D2_C16,en_in_D2_C17,en_in_D2_C18,en_in_D2_C19,en_in_D2_C20,en_in_D2_C21,en_in_D2_C22,en_in_D2_C23,en_in_D2_C24,en_in_D2_C25,en_in_D2_C26,en_in_D2_C27,en_in_D2_C28,en_in_D2_C29,en_in_D2_C30,en_in_D2_C31;
reg en_in_D3_C0,en_in_D3_C1,en_in_D3_C2,en_in_D3_C3,en_in_D3_C4,en_in_D3_C5,en_in_D3_C6,en_in_D3_C7,en_in_D3_C8,en_in_D3_C9,en_in_D3_C10,en_in_D3_C11,en_in_D3_C12,en_in_D3_C13,en_in_D3_C14,en_in_D3_C15,en_in_D3_C16,en_in_D3_C17,en_in_D3_C18,en_in_D3_C19,en_in_D3_C20,en_in_D3_C21,en_in_D3_C22,en_in_D3_C23,en_in_D3_C24,en_in_D3_C25,en_in_D3_C26,en_in_D3_C27,en_in_D3_C28,en_in_D3_C29,en_in_D3_C30,en_in_D3_C31;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        addr_in_D1 <= 0;
        addr_in_D2 <= 0;
		addr_in_D3 <= 0;
    end
    else
    begin
        addr_in_D1 <= addr_in;
        addr_in_D2 <= addr_in_D1;
		addr_in_D3 <= addr_in_D2;
    end
end

// addr_in_D2_x are 32 copies of 1 clk delayed version of addr_in_D1
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		addr_in_D2_C0 <= 0;
		addr_in_D2_C1 <= 0;
		addr_in_D2_C2 <= 0;
		addr_in_D2_C3 <= 0;
		addr_in_D2_C4 <= 0;
		addr_in_D2_C5 <= 0;
		addr_in_D2_C6 <= 0;
		addr_in_D2_C7 <= 0;
		addr_in_D2_C8 <= 0;
		addr_in_D2_C9 <= 0;
		addr_in_D2_C10 <= 0;
		addr_in_D2_C11 <= 0;
		addr_in_D2_C12 <= 0;
		addr_in_D2_C13 <= 0;
		addr_in_D2_C14 <= 0;
		addr_in_D2_C15 <= 0;
		addr_in_D2_C16 <= 0;
		addr_in_D2_C17 <= 0;
		addr_in_D2_C18 <= 0;
		addr_in_D2_C19 <= 0;
		addr_in_D2_C20 <= 0;
		addr_in_D2_C21 <= 0;
		addr_in_D2_C22 <= 0;
		addr_in_D2_C23 <= 0;
		addr_in_D2_C24 <= 0;
		addr_in_D2_C25 <= 0;
		addr_in_D2_C26 <= 0;
		addr_in_D2_C27 <= 0;
		addr_in_D2_C28 <= 0;
		addr_in_D2_C29 <= 0;
		addr_in_D2_C30 <= 0;
		addr_in_D2_C31 <= 0;
	end
	else
	begin
		addr_in_D2_C0 <= addr_in_D1;
		addr_in_D2_C1 <= addr_in_D1;
		addr_in_D2_C2 <= addr_in_D1;
		addr_in_D2_C3 <= addr_in_D1;
		addr_in_D2_C4 <= addr_in_D1;
		addr_in_D2_C5 <= addr_in_D1;
		addr_in_D2_C6 <= addr_in_D1;
		addr_in_D2_C7 <= addr_in_D1;
		addr_in_D2_C8 <= addr_in_D1;
		addr_in_D2_C9 <= addr_in_D1;
		addr_in_D2_C10 <= addr_in_D1;
		addr_in_D2_C11 <= addr_in_D1;
		addr_in_D2_C12 <= addr_in_D1;
		addr_in_D2_C13 <= addr_in_D1;
		addr_in_D2_C14 <= addr_in_D1;
		addr_in_D2_C15 <= addr_in_D1;
		addr_in_D2_C16 <= addr_in_D1;
		addr_in_D2_C17 <= addr_in_D1;
		addr_in_D2_C18 <= addr_in_D1;
		addr_in_D2_C19 <= addr_in_D1;
		addr_in_D2_C20 <= addr_in_D1;
		addr_in_D2_C21 <= addr_in_D1;
		addr_in_D2_C22 <= addr_in_D1;
		addr_in_D2_C23 <= addr_in_D1;
		addr_in_D2_C24 <= addr_in_D1;
		addr_in_D2_C25 <= addr_in_D1;
		addr_in_D2_C26 <= addr_in_D1;
		addr_in_D2_C27 <= addr_in_D1;
		addr_in_D2_C28 <= addr_in_D1;
		addr_in_D2_C29 <= addr_in_D1;
		addr_in_D2_C30 <= addr_in_D1;
		addr_in_D2_C31 <= addr_in_D1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		en_in_D1 <= 0;
		en_in_D2 <= 0;
	end
	else
	begin
		en_in_D1 <= en_in;
		en_in_D2 <= en_in_D1;
	end
end

// en_in_D2_x are 32 copies of 1 clk delayed version of en_in_D1
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		en_in_D2_C0 <= 0;
		en_in_D2_C1 <= 0;
		en_in_D2_C2 <= 0;
		en_in_D2_C3 <= 0;
		en_in_D2_C4 <= 0;
		en_in_D2_C5 <= 0;
		en_in_D2_C6 <= 0;
		en_in_D2_C7 <= 0;
		en_in_D2_C8 <= 0;
		en_in_D2_C9 <= 0;
		en_in_D2_C10 <= 0;
		en_in_D2_C11 <= 0;
		en_in_D2_C12 <= 0;
		en_in_D2_C13 <= 0;
		en_in_D2_C14 <= 0;
		en_in_D2_C15 <= 0;
		en_in_D2_C16 <= 0;
		en_in_D2_C17 <= 0;
		en_in_D2_C18 <= 0;
		en_in_D2_C19 <= 0;
		en_in_D2_C20 <= 0;
		en_in_D2_C21 <= 0;
		en_in_D2_C22 <= 0;
		en_in_D2_C23 <= 0;
		en_in_D2_C24 <= 0;
		en_in_D2_C25 <= 0;
		en_in_D2_C26 <= 0;
		en_in_D2_C27 <= 0;
		en_in_D2_C28 <= 0;
		en_in_D2_C29 <= 0;
		en_in_D2_C30 <= 0;	
		en_in_D2_C31 <= 0;
	end
	else
	begin
		en_in_D2_C0 <= en_in_D1;
		en_in_D2_C1 <= en_in_D1;
		en_in_D2_C2 <= en_in_D1;
		en_in_D2_C3 <= en_in_D1;
		en_in_D2_C4 <= en_in_D1;
		en_in_D2_C5 <= en_in_D1;
		en_in_D2_C6 <= en_in_D1;
		en_in_D2_C7 <= en_in_D1;
		en_in_D2_C8 <= en_in_D1;
		en_in_D2_C9 <= en_in_D1;
		en_in_D2_C10 <= en_in_D1;
		en_in_D2_C11 <= en_in_D1;
		en_in_D2_C12 <= en_in_D1;
		en_in_D2_C13 <= en_in_D1;
		en_in_D2_C14 <= en_in_D1;
		en_in_D2_C15 <= en_in_D1;
		en_in_D2_C16 <= en_in_D1;
		en_in_D2_C17 <= en_in_D1;
		en_in_D2_C18 <= en_in_D1;
		en_in_D2_C19 <= en_in_D1;
		en_in_D2_C20 <= en_in_D1;
		en_in_D2_C21 <= en_in_D1;
		en_in_D2_C22 <= en_in_D1;
		en_in_D2_C23 <= en_in_D1;
		en_in_D2_C24 <= en_in_D1;
		en_in_D2_C25 <= en_in_D1;
		en_in_D2_C26 <= en_in_D1;
		en_in_D2_C27 <= en_in_D1;
		en_in_D2_C28 <= en_in_D1;
		en_in_D2_C29 <= en_in_D1;
		en_in_D2_C30 <= en_in_D1;	
		en_in_D2_C31 <= en_in_D1;
	end
end
// en_in_D3_x are 32 copies of 1 clk delayed version of en_in_D2
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		en_in_D3_C0 <= 0;
		en_in_D3_C1 <= 0;
		en_in_D3_C2 <= 0;
		en_in_D3_C3 <= 0;
		en_in_D3_C4 <= 0;
		en_in_D3_C5 <= 0;
		en_in_D3_C6 <= 0;
		en_in_D3_C7 <= 0;
		en_in_D3_C8 <= 0;
		en_in_D3_C9 <= 0;
		en_in_D3_C10 <= 0;
		en_in_D3_C11 <= 0;
		en_in_D3_C12 <= 0;
		en_in_D3_C13 <= 0;
		en_in_D3_C14 <= 0;
		en_in_D3_C15 <= 0;
		en_in_D3_C16 <= 0;
		en_in_D3_C17 <= 0;
		en_in_D3_C18 <= 0;
		en_in_D3_C19 <= 0;
		en_in_D3_C20 <= 0;
		en_in_D3_C21 <= 0;
		en_in_D3_C22 <= 0;
		en_in_D3_C23 <= 0;
		en_in_D3_C24 <= 0;
		en_in_D3_C25 <= 0;
		en_in_D3_C26 <= 0;
		en_in_D3_C27 <= 0;
		en_in_D3_C28 <= 0;
		en_in_D3_C29 <= 0;
		en_in_D3_C30 <= 0;	
		en_in_D3_C31 <= 0;
	end
	else
	begin
		en_in_D3_C0 <= en_in_D2;
		en_in_D3_C1 <= en_in_D2;
		en_in_D3_C2 <= en_in_D2;
		en_in_D3_C3 <= en_in_D2;
		en_in_D3_C4 <= en_in_D2;
		en_in_D3_C5 <= en_in_D2;
		en_in_D3_C6 <= en_in_D2;
		en_in_D3_C7 <= en_in_D2;
		en_in_D3_C8 <= en_in_D2;
		en_in_D3_C9 <= en_in_D2;
		en_in_D3_C10 <= en_in_D2;
		en_in_D3_C11 <= en_in_D2;
		en_in_D3_C12 <= en_in_D2;
		en_in_D3_C13 <= en_in_D2;
		en_in_D3_C14 <= en_in_D2;
		en_in_D3_C15 <= en_in_D2;
		en_in_D3_C16 <= en_in_D2;
		en_in_D3_C17 <= en_in_D2;
		en_in_D3_C18 <= en_in_D2;
		en_in_D3_C19 <= en_in_D2;
		en_in_D3_C20 <= en_in_D2;
		en_in_D3_C21 <= en_in_D2;
		en_in_D3_C22 <= en_in_D2;
		en_in_D3_C23 <= en_in_D2;
		en_in_D3_C24 <= en_in_D2;
		en_in_D3_C25 <= en_in_D2;
		en_in_D3_C26 <= en_in_D2;
		en_in_D3_C27 <= en_in_D2;
		en_in_D3_C28 <= en_in_D2;
		en_in_D3_C29 <= en_in_D2;
		en_in_D3_C30 <= en_in_D2;	
		en_in_D3_C31 <= en_in_D2;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out <= 0;
	end
	else
	begin
		data_out = {data_out31,data_out30,data_out29,data_out28,data_out27,data_out26,data_out25,data_out24,data_out23,data_out22,data_out21,data_out20,data_out19,data_out18,data_out17,data_out16,data_out15,data_out14,data_out13,data_out12,data_out11,data_out10,data_out9,data_out8,data_out7,data_out6,data_out5,data_out4,data_out3,data_out2,data_out1,data_out0};
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out0 <= 0;
	end
	else if(en_in_D2_C0)
	begin
		data_out0 <= {data_in[(0+1)*`VWidth-1],data_out0[`APPRam_depth-1:1]}; //用输入的一个新比特刷新移位寄存器，把原来的内容右移一位。 只需要符号，直接代表 0,1
	end
	else
	begin
		data_out0 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out1 <= 0;
	end
	else if(en_in_D2_C1)
	begin
		data_out1 <= {data_in[(1+1)*`VWidth-1],data_out1[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out1 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out2 <= 0;
	end
	else if(en_in_D2_C2)
	begin
		data_out2 <= {data_in[(2+1)*`VWidth-1],data_out2[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out2 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out3 <= 0;
	end
	else if(en_in_D2_C3)
	begin
		data_out3 <= {data_in[(3+1)*`VWidth-1],data_out3[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out3 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out4 <= 0;
	end
	else if(en_in_D2_C4)
	begin
		data_out4 <= {data_in[(4+1)*`VWidth-1],data_out4[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out4 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out5 <= 0;
	end
	else if(en_in_D2_C5)
	begin
		data_out5 <= {data_in[(5+1)*`VWidth-1],data_out5[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out5 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out6 <= 0;
	end
	else if(en_in_D2_C6)
	begin
		data_out6 <= {data_in[(6+1)*`VWidth-1],data_out6[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out6 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out7 <= 0;
	end
	else if(en_in_D2_C7)
	begin
		data_out7 <= {data_in[(7+1)*`VWidth-1],data_out7[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out7 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out8 <= 0;
	end
	else if(en_in_D2_C8)
	begin
		data_out8 <= {data_in[(8+1)*`VWidth-1],data_out8[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out8 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out9 <= 0;
	end
	else if(en_in_D2_C9)
	begin
		data_out9 <= {data_in[(9+1)*`VWidth-1],data_out9[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out9 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out10 <= 0;
	end
	else if(en_in_D2_C10)
	begin
		data_out10 <= {data_in[(10+1)*`VWidth-1],data_out10[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out10 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out11 <= 0;
	end
	else if(en_in_D2_C11)
	begin
		data_out11 <= {data_in[(11+1)*`VWidth-1],data_out11[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out11 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out12 <= 0;
	end
	else if(en_in_D2_C12)
	begin
		data_out12 <= {data_in[(12+1)*`VWidth-1],data_out12[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out12 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out13 <= 0;
	end
	else if(en_in_D2_C13)
	begin
		data_out13 <= {data_in[(13+1)*`VWidth-1],data_out13[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out13 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out14 <= 0;
	end
	else if(en_in_D2_C14)
	begin
		data_out14 <= {data_in[(14+1)*`VWidth-1],data_out14[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out14 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out15 <= 0;
	end
	else if(en_in_D2_C15)
	begin
		data_out15 <= {data_in[(15+1)*`VWidth-1],data_out15[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out15 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out16 <= 0;
	end
	else if(en_in_D2_C16)
	begin
		data_out16 <= {data_in[(16+1)*`VWidth-1],data_out16[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out16 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out17 <= 0;
	end
	else if(en_in_D2_C17)
	begin
		data_out17 <= {data_in[(17+1)*`VWidth-1],data_out17[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out17 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out18 <= 0;
	end
	else if(en_in_D2_C18)
	begin
		data_out18 <= {data_in[(18+1)*`VWidth-1],data_out18[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out18 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out19 <= 0;
	end
	else if(en_in_D2_C19)
	begin
		data_out19 <= {data_in[(19+1)*`VWidth-1],data_out19[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out19 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out20 <= 0;
	end
	else if(en_in_D2_C20)
	begin
		data_out20 <= {data_in[(20+1)*`VWidth-1],data_out20[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out20 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out21 <= 0;
	end
	else if(en_in_D2_C21)
	begin
		data_out21 <= {data_in[(21+1)*`VWidth-1],data_out21[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out21 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out22 <= 0;
	end
	else if(en_in_D2_C22)
	begin
		data_out22 <= {data_in[(22+1)*`VWidth-1],data_out22[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out22 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out23 <= 0;
	end
	else if(en_in_D2_C23)
	begin
		data_out23 <= {data_in[(23+1)*`VWidth-1],data_out23[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out23 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out24 <= 0;
	end
	else if(en_in_D2_C24)
	begin
		data_out24 <= {data_in[(24+1)*`VWidth-1],data_out24[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out24 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out25 <= 0;
	end
	else if(en_in_D2_C25)
	begin
		data_out25 <= {data_in[(25+1)*`VWidth-1],data_out25[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out25 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out26 <= 0;
	end
	else if(en_in_D2_C26)
	begin
		data_out26 <= {data_in[(26+1)*`VWidth-1],data_out26[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out26 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out27 <= 0;
	end
	else if(en_in_D2_C27)
	begin
		data_out27 <= {data_in[(27+1)*`VWidth-1],data_out27[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out27 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out28 <= 0;
	end
	else if(en_in_D2_C28)
	begin
		data_out28 <= {data_in[(28+1)*`VWidth-1],data_out28[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out28 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out29 <= 0;
	end
	else if(en_in_D2_C29)
	begin
		data_out29 <= {data_in[(29+1)*`VWidth-1],data_out29[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out29 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out30 <= 0;
	end
	else if(en_in_D2_C30)
	begin
		data_out30 <= {data_in[(30+1)*`VWidth-1],data_out30[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out30 <= 0;
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out31 <= 0;
	end
	else if(en_in_D2_C31)
	begin
		data_out31 <= {data_in[(31+1)*`VWidth-1],data_out31[`APPRam_depth-1:1]};
	end
	else
	begin
		data_out31 <= 0;
	end
end


endmodule