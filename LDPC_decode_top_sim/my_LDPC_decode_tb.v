`timescale 1ns/1ps

module my_LDPC_decode_tb;

// 数据大小
parameter DEPTH = 32;             // 数据个数
parameter WIDTH = 512 * 6;        // 每个 数据宽度3072
parameter TOTAL = WIDTH * DEPTH;  // 总bit数 = 98304

// 存储器
reg [WIDTH-1:0] mem [0:DEPTH-1];

integer i;

reg clk;
reg rst_n;
reg ready;
reg [1:0] mode;

initial begin

    

    clk = 0;
    rst_n = 1;
    ready = 0;
    mode = 1;
    #15 rst_n = 0;

    #15 rst_n = 1;
	
	



    // 从文件中读取数据
    // txt 文件格式要求：每行一个 32 位二进制数
    // 例如：
    // 00000000000000000000000000000001
    // 00000000000000000000000000000010
    // ...
    $readmemb("data_in.txt", mem);

    // 打印前几行数据验证
    for (i = 31; i < 32; i = i + 1) begin
        $display("mem[%0d] = %b", i, mem[i]);
    end
    #50 ready = 1;

end

always #5 clk = ~clk;

wire W_READY,R_VALID,R_LAST;
reg W_VALID,W_LAST,R_READY;
reg [`Zc*`VWidth-1:0] W_DATA;
wire [`Zc-1:0]R_DATA;

reg [4:0] w_data_cnt;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	begin
		w_data_cnt <= 0;
    end
    else if(W_LAST)
    begin
        w_data_cnt <= 0;
    end
    else if(W_VALID && mode == 1) //23码率
    begin
        if( w_data_cnt < 5'd31)
            w_data_cnt <= w_data_cnt + 5'd1;
        else if (w_data_cnt == 5'd31)
            w_data_cnt <= 0;
    end
    else if(W_VALID && mode == 2) //78码率
     begin
        if( w_data_cnt < 5'd23)
            w_data_cnt <= w_data_cnt + 5'd1;
        else if (w_data_cnt == 5'd23)
            w_data_cnt <= 0;
    end
end




always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	begin
		W_VALID <= 0;
    end

    else if (mode == 1)
    begin
        if( w_data_cnt ==  5'd31)
            W_VALID <= 0;
        else if (W_READY && ready)
            W_VALID <= 1;
    end

    else if (mode == 2)
    begin
        if( w_data_cnt ==  5'd23)
            W_VALID <= 0;
        else if (W_READY && ready)
            W_VALID <= 1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	begin
		W_LAST <= 0;
    end

    else if (mode == 1)
    begin
        if( W_VALID &&w_data_cnt ==  5'd30)
            W_LAST <= 1;
        else 
            W_LAST <= 0;
    end

    else if (mode == 2)
    begin
        if( W_VALID &&w_data_cnt ==  5'd22)
            W_LAST <= 1;
        else 
            W_LAST <= 0;
    end
end

always @(*)
begin
    if(!rst_n)
    begin
        W_DATA <=0;
    end
    else if(W_VALID)
    begin
        case(w_data_cnt)
            5'd0: W_DATA<= mem[0];
            5'd1: W_DATA<= mem[1];
            5'd2: W_DATA<= mem[2];
            5'd3: W_DATA<= mem[3];
            5'd4: W_DATA<= mem[4];
            5'd5: W_DATA<= mem[5];
            5'd6: W_DATA<= mem[6];
            5'd7: W_DATA<= mem[7];
            5'd8: W_DATA<= mem[8];
            5'd9: W_DATA<= mem[9];
            5'd10: W_DATA<= mem[10];
            5'd11: W_DATA<= mem[11];
            5'd12: W_DATA<= mem[12];
            5'd13: W_DATA<= mem[13];
            5'd14: W_DATA<= mem[14];
            5'd15: W_DATA<= mem[15];
            5'd16: W_DATA<= mem[16];
            5'd17: W_DATA<= mem[17];
            5'd18: W_DATA<= mem[18];
            5'd19: W_DATA<= mem[19];
            5'd20: W_DATA<= mem[20];
            5'd21: W_DATA<= mem[21];
            5'd22: W_DATA<= mem[22];
            5'd23: W_DATA<= mem[23];
            5'd24: W_DATA<= mem[24];
            5'd25: W_DATA<= mem[25];
            5'd26: W_DATA<= mem[26];
            5'd27: W_DATA<= mem[27];
            5'd28: W_DATA<= mem[28];
            5'd29: W_DATA<= mem[29];
            5'd30: W_DATA<= mem[30];
            5'd31: W_DATA<= mem[31];
        endcase      
    end
end //存入完毕




LDPC_decode_top LDPC_decode_top_0 (
    .clk     (clk),
    .rst_n   (rst_n),
    .mode    (mode),

    .W_READY (W_READY),
    .W_VALID (W_VALID),
    .W_LAST  (W_LAST),
    .W_DATA  (W_DATA),

    .R_READY (1),
    .R_VALID (R_VALID),
    .R_LAST  (R_LAST),
    .R_DATA  (R_DATA)
);


endmodule