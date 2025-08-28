`define VWidth 6 //每个 LLR/APP 消息用 6 bit 表示（范围 -32 ~ +31）。
`define VMax 31 // 2^(VWidth-1)-1
`define VMin -31 // -2^(VWidth-1) APP/LLR 的饱和范围，避免数值溢出。
`define VAWidth 7 // 目前没用到 APP 地址宽度，2^7 = 128，对应 APP RAM 深度。
`define VRWidth 8 // 目前没用到 可能是 APP 或 QSN 累加值的内部更宽位宽，用于避免溢出。
`define PM  32 //DPU 并行度参数。
`define b  5 //QSN 移位值参数宽度
`define P_num  27 //APP_RAM个数 确定flag位数，通过flag确定一行连接关系
`define inWidth  32 //目前没有用到
`define inNum 32 //输入数据宽度 32bit，输入通道数 32。
`define AWidth 8 //目前没有用到   累加器宽度，用于在 CN 更新时存储和累加。
`define CWidth 4 //CTV 消息（check-to-variable message）的位宽，范围 -7 ~ +7。
`define CMax 7 // 2^(CWidth-1)-1
`define CMin -7 // -2^(CWidth-1) 对 CTV 消息的饱和范围。
`define CRWidth `AWidth //CTV 结果寄存器的宽度，和累加器对齐。

`define DPUdata_Len `P_num*`VWidth //一个DPU需要输入数据长度 27*6
`define DPUctvdata_Len `P_num*`CWidth //一个DPU输出数据长度

`define QSNshiftLen `QSNdata_Len-`VWidth // 移位大小限制？
`define APPdata_Len `inNum*`VWidth //一行32*6
`define QSNdata_Len `PM*`VWidth //32个DPU，向32个DPU分发数据

`define APP_ProcessTime 14 //输入 APP 消息需要 14 个周期完成。
`define CTV_ProcessTime 7 //CN 更新消息需要 7 个周期完成。

`define HijWidth 10 //每个 H 矩阵元素的存储宽度。存 shift 值 (0 ~ Zc-1)。 因为 Zc=512，log2(512)=9，所以用 13 bit 存储移位量。
`define maxIterNum 8 // number of iterations 
`define TotalLayernum 13
`define Total_DPU_small_process_num `TotalLayernum*`APP_addr_max-1 //CTV RAM num

`define APP_addr_width 5
`define APP_addr_max 5'd16
`define APP_addr_rd_max 4'd15

`define HROM_cols 26 //H 矩阵基图每行的最大列数 = 26。
`define HROM_Width `HijWidth*`HROM_cols //每行存储宽度。

`define Zc 512 //lifting size，LDPC 码扩展因子。
`define APPRam_depth 16 //APP RAM 的深度 = 16，存放 APP 输入 LLR。 16*32 
`define DecOut_lifting 22 //解码输出 lifting size（22 组输出）。
