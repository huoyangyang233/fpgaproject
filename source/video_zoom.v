//双线性插值法模块，用于对视频分辨率大小进行缩放
//模块 `video_zoom` 使用双线性插值法对视频分辨率进行缩放。具体功能包括：
//
//### 输入端口
//- `clk`：时钟信号
//- `rstn`：复位信号，低电平有效
//- `vs_in`：垂直同步信号
//- `hs_in`：水平同步信号
//- `de_in`：数据有效信号，用于控制插值数据的存储和输出
//- `video_data_in`：输入视频像素数据，位宽由参数 `PIXEL_WIDTH` 定义
//
//### 输出端口
//- `de_out`：输出数据有效信号，指示插值数据的有效状态
//- `video_data_out`：插值后的视频数据输出，位宽与 `video_data_in` 相同
//
//### 参数
//- `PIXEL_WIDTH`：像素数据位宽，默认为32位
//- `VIDEO_LENGTH`：视频水平分辨率，默认为1920
//- `VIDEO_HIGTH`：视频垂直分辨率，默认为1080
//
//### 工作原理
//1. **数据捕获和暂存**：通过状态机 `interpolation_cnt_state` 将输入视频数据 `video_data_in` 分为 4 个像素块存储在 `pix_data0` 到 `pix_data3` 中，表示一个 2x2 的像素网格。
//  
//2. **一次线性插值**：对每两个水平相邻的像素进行线性插值，结果存储在 `RAM0` 和 `RAM1` 中。该步骤主要计算 `pix_data0` 与 `pix_data1` 的平均值、`pix_data2` 与 `pix_data3` 的平均值，并按行存储插值结果。
//
//3. **二次线性插值**：完成两个相邻行的线性插值后，读取 `RAM0` 和 `RAM1` 的数据，并对其进行垂直插值，最终计算得到缩放后的像素值输出到 `video_data_out`。在插值过程中，`de_out` 信号用于标识插值数据的有效性。
//
//4. **内存模块**：`user_interpolation_ram0` 和 `user_interpolation_ram1` 模块用于存储插值结果，以便进行下一步的插值计算。
//
//### 时序控制
//通过输入的 `vs_in` 和 `de_in` 信号的变化来控制插值计算流程，并利用 `DELAY_OUTPUT` 控制输出数据的延迟，以便确保数据与 `de_out` 信号同步输出。



`timescale 1ps/1ps
`define UD #1
module video_zoom #(
    parameter PIXEL_WIDTH          = 32          ,
    parameter VIDEO_LENGTH         = 12'd1920    ,
    parameter VIDEO_HIGTH          = 12'd1080     
)(
    input                                clk            ,
    input                                rstn           ,
    input                                vs_in          /* synthesis PAP_MARK_DEBUG="1" */,
    input                                hs_in          ,
    input                                de_in          /* synthesis PAP_MARK_DEBUG="1" */,
    input  [PIXEL_WIDTH - 1 : 0]         video_data_in  ,
    output reg                           de_out          /* synthesis PAP_MARK_DEBUG="1" */,
    output reg [PIXEL_WIDTH - 1 : 0]     video_data_out    /* synthesis PAP_MARK_DEBUG="1" */
   );
parameter VIDEO_WAIT = 2'd0;
parameter VIDEO_ZOOM = 2'd1;
parameter VIDEO_END  = 2'd2;

parameter FIRST_PIX   = 2'd0;
parameter SECOND_PIX  = 2'd1;
parameter THIRD_PIX   = 2'd2;
parameter FOURTH_PIX  = 2'd3;

parameter FIRST_LINE  = 2'd0;
parameter SECOND_LINE = 2'd1;
parameter THIRD_LINE  = 2'd2;
parameter FOURTH_LINE = 2'd3;


parameter DE_IN_WAIT  = 1'd0;
parameter DE_IN_CNT  = 1'd1;

parameter OFFSET_ADDR = 11'd0;
parameter DELAY_OUTPUT = 11'd2;

wire [PIXEL_WIDTH - 1 : 0] ram0_rd_data/* synthesis PAP_MARK_DEBUG="1" */;
wire [PIXEL_WIDTH - 1 : 0] ram1_rd_data/* synthesis PAP_MARK_DEBUG="1" */;
wire                       vs_rst/* synthesis PAP_MARK_DEBUG="1" */;


reg [PIXEL_WIDTH - 1 : 0] pix_data0/* synthesis PAP_MARK_DEBUG="1" */;//用于接收单个数据
reg [PIXEL_WIDTH - 1 : 0] pix_data1/* synthesis PAP_MARK_DEBUG="1" */;//每接收两个进行一次线性插
reg [PIXEL_WIDTH - 1 : 0] pix_data2/* synthesis PAP_MARK_DEBUG="1" */;
reg [PIXEL_WIDTH - 1 : 0] pix_data3/* synthesis PAP_MARK_DEBUG="1" */;

reg [PIXEL_WIDTH - 1 : 0] r_ram0_wr_data;
reg [10 : 0]              r_ram0_wr_addr/* synthesis PAP_MARK_DEBUG="1" */; 
reg [PIXEL_WIDTH - 1 : 0] r_ram1_wr_data;
reg [10 : 0] r_ram1_wr_addr                /* synthesis PAP_MARK_DEBUG="1" */; 
reg [10 : 0] r_ram0_rd_addr                /* synthesis PAP_MARK_DEBUG="1" */;
reg [10 : 0] r_ram1_rd_addr                /* synthesis PAP_MARK_DEBUG="1" */;

reg          r_ram0_wr_en                   /* synthesis PAP_MARK_DEBUG="1" */;
reg          r_ram1_wr_en                   /* synthesis PAP_MARK_DEBUG="1" */;


reg [1 : 0]  interpolation_cnt_state        /* synthesis PAP_MARK_DEBUG="1" */;      //单线性插值计数状态
reg          interpolation_data_save        /* synthesis PAP_MARK_DEBUG="1" */;      //单线性插值完成标志
reg          interpolation_data_save_flag   /* synthesis PAP_MARK_DEBUG="1" */; //用于切换pix_data存入RAM
reg          interpolation_done0            /* synthesis PAP_MARK_DEBUG="1" */;
reg          interpolation_done1            /* synthesis PAP_MARK_DEBUG="1" */;

reg [9 : 0]  interpolation_cnt              /* synthesis PAP_MARK_DEBUG="1" */;
reg [1 : 0]  interpolation_data_state       /* synthesis PAP_MARK_DEBUG="1" */;
reg [9 : 0]  bilinear_interpolation_cnt     /* synthesis PAP_MARK_DEBUG="1" */;
reg          bilinear_interpolation_flag    /* synthesis PAP_MARK_DEBUG="1" */;

reg          de_in_state;
reg [11 : 0] de_in_cnt    /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_in_d0     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_in_d1     /* synthesis PAP_MARK_DEBUG="1" */;
reg          vs_in_d0     /* synthesis PAP_MARK_DEBUG="1" */;
reg          vs_in_d1     /* synthesis PAP_MARK_DEBUG="1" */;

reg [10 : 0] pix_cnt      /* synthesis PAP_MARK_DEBUG="1" */;

reg          de_out_state;
reg [11 : 0] de_out_cnt    /* synthesis PAP_MARK_DEBUG="1" */;
wire         w_de_out /* synthesis PAP_MARK_DEBUG="1" */;
reg [19 : 0] de_out_ff     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d0     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d1     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d2     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d3     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d4     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d5     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d6     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d7     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d8     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d9     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d10     /* synthesis PAP_MARK_DEBUG="1" */;
reg          de_out_d11     /* synthesis PAP_MARK_DEBUG="1" */;
reg          ram0_rd_oce /* synthesis PAP_MARK_DEBUG="1" */;
reg          ram1_rd_oce /* synthesis PAP_MARK_DEBUG="1" */;
assign w_de_out = de_out;
assign vs_rst = !vs_in_d0 && vs_in_d1;

always @(posedge clk) begin//抓下降沿
    if(!rstn) begin  
        vs_in_d0 <= 'd0;
        vs_in_d1 <= 'd0;
        de_in_d0 <= 'd0;
        de_in_d1 <= 'd0;
        de_in_cnt <= 'd0; 
        de_in_state <= 'd0;
    end
    else begin
       vs_in_d0 <= vs_in;
       vs_in_d1 <= vs_in_d0;
       de_in_d0 <= de_in;
       de_in_d1 <= de_in_d0;
       case(de_in_state) 
            DE_IN_WAIT:
            begin
                if(!vs_in_d0 && vs_in_d1) begin
                    de_in_state <= DE_IN_CNT;//抓取vs_in下降沿，当抓到下降沿时开始计数
                end
            end
            DE_IN_CNT:
            begin
                if(de_in_d0 && !de_in_d1) begin
                    de_in_cnt <= de_in_cnt + 1'd1;//抓取de上升沿，de上升时计数
                end
                if(vs_in_d0 && !vs_in_d1) begin
                    de_in_cnt <= 'd0;
                    de_in_state <= DE_IN_WAIT;//抓取vs_in上升沿，当抓到上升沿时计数归零
                end
            end
        endcase  
    end
end




always @(posedge clk) begin//抓下降沿
    if(!rstn) begin  
        de_out_ff  <= 'd0;
        de_out_cnt <= 'd0; 
        de_out_state <= 'd0;
    end
    else begin
        de_out_ff <= {de_out_ff[18 : 0] , de_out};
        case(de_out_state) 
            DE_IN_WAIT:
            begin
                if(!vs_in_d0 && vs_in_d1) begin
                    de_out_state <= DE_IN_CNT;//抓取vs_in下降沿，当抓到下降沿时开始计数
                end
            end
            DE_IN_CNT:
            begin
                if(de_out_ff[0] && !de_out_ff[1]) begin
                    de_out_cnt <= de_out_cnt + 1'd1;//抓取de上升沿，de上升时计数
                end
                if(vs_in_d0 && !vs_in_d1) begin
                    de_out_cnt <= 'd0;
                    de_out_state <= DE_IN_WAIT;//抓取vs_in上升沿，当抓到上升沿时计数归零
                end
            end
        endcase  
    end
end



//对输入的数据进行暂存
always @(posedge clk) begin
    if(!rstn || vs_rst) begin
        interpolation_cnt_state <= 'd0;
        interpolation_data_save <= 'd0;
        interpolation_data_save_flag <= 'd0;
        pix_data0 <= 'd0;
        pix_data1 <= 'd0;
        pix_data2 <= 'd0;
        pix_data3 <= 'd0;
        pix_cnt   <= 'd0;
    end
    else if(de_in || de_in_d0) begin//de拉高后对输入的数据进行暂存
        pix_cnt <= pix_cnt + 'd1;
        case(interpolation_cnt_state) 
            FIRST_PIX: begin
                pix_data0 <= video_data_in;
                interpolation_data_save <= 1'b0;//暂存第一个数据
                interpolation_cnt_state <= 2'd1;
            end
            SECOND_PIX: begin
                pix_data1 <= video_data_in;//暂存第二个数据，然后拉高done
                interpolation_data_save_flag <= 'd0; 
                interpolation_data_save <= 1'b1;  
                interpolation_cnt_state <= 2'd2;
            end
            THIRD_PIX: begin
                pix_data2 <= video_data_in;//暂存第3个数据
                interpolation_cnt_state <= 2'd3; 
                interpolation_data_save <= 1'b0;
            end
            FOURTH_PIX: begin
                pix_data3 <= video_data_in;//暂存第4个数据，然后拉高save
                interpolation_data_save_flag <= 'd1;
                interpolation_data_save <= 1'b1;  
                interpolation_cnt_state <= 2'd0;
             
            end
        endcase
    end
    else begin
        pix_cnt <= 'd0;
        pix_data0 <= 'd0;
        pix_data1 <= 'd0;
        pix_data2 <= 'd0;
        pix_data3 <= 'd0;
        interpolation_cnt_state <= 1'b0;
        interpolation_data_save <= 1'b0;
        interpolation_data_save_flag <= 'd0;
    end         
end
//对输入的数据进行第一次线性插值
always @(posedge clk) begin
    if(!rstn || vs_rst) begin
        interpolation_cnt <= 'd0 + OFFSET_ADDR;
        interpolation_data_state <= 'd0;
        r_ram0_wr_en <= 1'b0;
        r_ram1_wr_en <= 1'b0;
        r_ram0_wr_data <= 'd0;
        r_ram1_wr_data <= 'd0;
        r_ram0_wr_addr <= 'd0;
        r_ram1_wr_addr <= 'd0;
        interpolation_done0 <= 'd0;
        interpolation_done1 <= 'd0;

    end
    else begin//done信号拉高后，对暂存的两个数据进行一次线性插值，同时计数，当插值达到视频纵向分辨率一半时结束插值
        case(interpolation_data_state)
            FIRST_LINE: 
            begin//第一行数据插值，存入ram0的page0中
                if(interpolation_data_save) begin                
                    r_ram0_wr_addr <= {1'b0,interpolation_cnt};
                    r_ram0_wr_en <= 1'b1;
                    interpolation_cnt <= interpolation_cnt + 1'b1;
                    if(interpolation_data_save_flag == 0) begin//当save_flag为0时，计算pix0pix1 写数据到ram0//切记进行分通道计算
                        //test
                        //r_ram0_wr_data <= pix_data0 / 2 + pix_data1 / 2;
                        r_ram0_wr_data[31:22] <= (pix_data0[31:22] / 2) + (pix_data1[31:22] / 2);
                        r_ram0_wr_data[21:12] <= (pix_data0[21:12] / 2) + (pix_data1[21:12] / 2);
                        r_ram0_wr_data[11: 2] <= (pix_data0[11: 2] / 2) + (pix_data1[11: 2] / 2);
                    end
                    else if(interpolation_data_save_flag == 1) begin
                        //test
                        //r_ram0_wr_data <= pix_data2 / 2 + pix_data3 / 2;
                        r_ram0_wr_data[31:22] <= (pix_data2[31:22] / 2) + (pix_data3[31:22] / 2);
                        r_ram0_wr_data[21:12] <= (pix_data2[21:12] / 2) + (pix_data3[21:12] / 2);
                        r_ram0_wr_data[11: 2] <= (pix_data2[11: 2] / 2) + (pix_data3[11: 2] / 2);
                    end
                end
                else if(interpolation_cnt == VIDEO_LENGTH/2 + OFFSET_ADDR) begin
                    r_ram0_wr_en <= 1'b0;
                    interpolation_cnt <= 'd0 + OFFSET_ADDR;
                    interpolation_done0 <= 'd0;
                    interpolation_done1 <= 'd0;               
                    interpolation_data_state <= 'd1;
                end
                else begin
                    r_ram0_wr_en <= 'd0;
                    r_ram1_wr_en <= 'd0;
                    interpolation_cnt <= interpolation_cnt;
                    interpolation_data_state <= interpolation_data_state;
                end
            end
            SECOND_LINE: 
            begin//第二行数据插值,存入ram1的page0中
                if(interpolation_data_save) begin
                    r_ram1_wr_addr <= {1'b0,interpolation_cnt};
                    r_ram1_wr_en <= 1'b1;
                    interpolation_cnt <= interpolation_cnt + 1'b1;
                    if(interpolation_data_save_flag == 0) begin//当save_flag为1时，计算pix2pix3 
                        //test
                        //r_ram1_wr_data <= pix_data0 / 2 + pix_data1 / 2;
                        r_ram1_wr_data[31:22] <= (pix_data0[31:22] / 2) + (pix_data1[31:22] / 2);
                        r_ram1_wr_data[21:12] <= (pix_data0[21:12] / 2) + (pix_data1[21:12] / 2);
                        r_ram1_wr_data[11: 2] <= (pix_data0[11: 2] / 2) + (pix_data1[11: 2] / 2);
                    end
                    else if(interpolation_data_save_flag == 1) begin
                        //test
                        //r_ram1_wr_data <= pix_data2 / 2 + pix_data3 / 2;
                        r_ram1_wr_data[31:22] <= (pix_data2[31:22] / 2) + (pix_data3[31:22] / 2);
                        r_ram1_wr_data[21:12] <= (pix_data2[21:12] / 2) + (pix_data3[21:12] / 2);
                        r_ram1_wr_data[11: 2] <= (pix_data2[11: 2] / 2) + (pix_data3[11: 2] / 2);
                    end
                end
                else if(interpolation_cnt == VIDEO_LENGTH/2 + OFFSET_ADDR) begin
                    r_ram1_wr_en <= 1'b0;
                    interpolation_cnt <= 'd0 + OFFSET_ADDR;
                    interpolation_done0 <= 'd1;
                    interpolation_data_state <= 'd2;
                end   
                else begin
                    r_ram0_wr_en <= 'd0;
                    r_ram1_wr_en <= 'd0;
                    interpolation_cnt <= interpolation_cnt;
                    interpolation_data_state <= interpolation_data_state;
                end
            end
            THIRD_LINE: 
            begin//由于前两行插值完成后需要进行计算，所以还需要第三第四行来进行暂存,第三行数据插值，存入ram0的page1中
                if(interpolation_data_save) begin
                    r_ram0_wr_addr <= {1'b1,interpolation_cnt};
                    r_ram0_wr_en <= 1'b1;
                    interpolation_cnt <= interpolation_cnt + 1'b1;
                    if(interpolation_data_save_flag == 0) begin
                        //test
                        //r_ram0_wr_data <= pix_data0 / 2 + pix_data1 / 2;
                        r_ram0_wr_data[31:22] <= (pix_data0[31:22] / 2) + (pix_data1[31:22] / 2);
                        r_ram0_wr_data[21:12] <= (pix_data0[21:12] / 2) + (pix_data1[21:12] / 2);
                        r_ram0_wr_data[11: 2] <= (pix_data0[11: 2] / 2) + (pix_data1[11: 2] / 2);
                    end
                    else if(interpolation_data_save_flag == 1) begin
                        //test
                        //r_ram0_wr_data <= pix_data2 / 2 + pix_data3 / 2;
                        r_ram0_wr_data[31:22] <= (pix_data2[31:22] / 2) + (pix_data3[31:22] / 2);
                        r_ram0_wr_data[21:12] <= (pix_data2[21:12] / 2) + (pix_data3[21:12] / 2);
                        r_ram0_wr_data[11: 2] <= (pix_data2[11: 2] / 2) + (pix_data3[11: 2] / 2);
                    end
                end
                else if(interpolation_cnt == VIDEO_LENGTH/2 + OFFSET_ADDR) begin
                    r_ram0_wr_en <= 1'b0;
                    interpolation_cnt <= 'd0 + OFFSET_ADDR;
                    interpolation_done0 <= 'd0;
                    interpolation_done1 <= 'd0;               
                    interpolation_data_state <= 'd3;
                end
                else begin
                    r_ram0_wr_en <= 'd0;
                    r_ram1_wr_en <= 'd0;
                    interpolation_cnt <= interpolation_cnt;
                    interpolation_data_state <= interpolation_data_state;
                end
            end     
            FOURTH_LINE: 
            begin//第4行数据插值，存入ram1的page1中
                if(interpolation_data_save) begin            
                    r_ram1_wr_addr <= {1'b1,interpolation_cnt};
                    r_ram1_wr_en <= 1'b1;
                    interpolation_cnt <= interpolation_cnt + 1'b1;
                    if(interpolation_data_save_flag == 0) begin
                        //test
                        //r_ram1_wr_data <= pix_data0 / 2 + pix_data1 / 2;
                        r_ram1_wr_data[31:22] <= (pix_data0[31:22] / 2) + (pix_data1[31:22] / 2);
                        r_ram1_wr_data[21:12] <= (pix_data0[21:12] / 2) + (pix_data1[21:12] / 2);
                        r_ram1_wr_data[11: 2] <= (pix_data0[11: 2] / 2) + (pix_data1[11: 2] / 2);
                    end
                    else if(interpolation_data_save_flag == 1) begin
                        //test
                        //r_ram1_wr_data <= pix_data2 / 2 + pix_data3 / 2;
                        r_ram1_wr_data[31:22] <= (pix_data2[31:22] / 2) + (pix_data3[31:22] / 2);
                        r_ram1_wr_data[21:12] <= (pix_data2[21:12] / 2) + (pix_data3[21:12] / 2);
                        r_ram1_wr_data[11: 2] <= (pix_data2[11: 2] / 2) + (pix_data3[11: 2] / 2);
                    end
                end
                else if(interpolation_cnt == VIDEO_LENGTH/2 + OFFSET_ADDR) begin
                    r_ram1_wr_en <= 1'b0;
                    interpolation_cnt <= 'd0 + OFFSET_ADDR;
                    interpolation_done1 <= 'd1; 
                    interpolation_data_state <= 'd0;
                end   
                else begin
                    r_ram0_wr_en <= 'd0;
                    r_ram1_wr_en <= 'd0;
                    interpolation_cnt <= interpolation_cnt;
                    interpolation_data_state <= interpolation_data_state;
                end
            end 
        endcase
    end
end
//完成两行的线性插值后，读出存入ram的第一次插值的数值，进行第二次线性插帧
always @(posedge clk) begin
    if(!rstn || vs_rst) begin
        bilinear_interpolation_cnt <= 'd0 + OFFSET_ADDR;
        r_ram0_rd_addr <= 'd0;
        r_ram1_rd_addr <= 'd0;
        video_data_out <= 'd0;
        de_out <= 'd0;
        bilinear_interpolation_flag <= 'd0;
    end
    else if(interpolation_done0 && !bilinear_interpolation_flag) begin        
        r_ram0_rd_addr <= {1'b0,bilinear_interpolation_cnt};
        r_ram1_rd_addr <= {1'b0,bilinear_interpolation_cnt};
        ram0_rd_oce <= 'd1;
        ram1_rd_oce <= 'd1;
        bilinear_interpolation_cnt <= bilinear_interpolation_cnt + 1'd1;
        if(bilinear_interpolation_cnt >= VIDEO_LENGTH/2  + OFFSET_ADDR ) begin
            ram0_rd_oce <= 'd0;
            ram1_rd_oce <= 'd0;        
        end
        if(bilinear_interpolation_cnt >= VIDEO_LENGTH/2  + OFFSET_ADDR + DELAY_OUTPUT) begin
            bilinear_interpolation_cnt <= 'd0 + OFFSET_ADDR;
            bilinear_interpolation_flag <= 'd1;
            de_out <= 'd0;
        end
        else if(bilinear_interpolation_cnt >= OFFSET_ADDR + DELAY_OUTPUT) begin //给RAM读地址后数据延迟三个周期才出来，这时候再拉高de_out输出数据
            de_out <= 'd1;
            //test
            //video_data_out <= ram0_rd_data / 2 + ram1_rd_data / 2;
            video_data_out[31:22] <= ram0_rd_data[31:22]/2 + ram1_rd_data[31:22]/2;
            video_data_out[21:12] <= ram0_rd_data[21:12]/2 + ram1_rd_data[21:12]/2;
            video_data_out[11: 2] <= ram0_rd_data[11: 2]/2 + ram1_rd_data[11: 2]/2;
        end
    end
    else if(interpolation_done1 && bilinear_interpolation_flag) begin
        r_ram0_rd_addr <= {1'b1,bilinear_interpolation_cnt};
        r_ram1_rd_addr <= {1'b1,bilinear_interpolation_cnt};
        ram0_rd_oce <= 'd1;
        ram1_rd_oce <= 'd1;
        bilinear_interpolation_cnt <= bilinear_interpolation_cnt + 1'd1;
        if(bilinear_interpolation_cnt >= VIDEO_LENGTH/2  + OFFSET_ADDR ) begin
            ram0_rd_oce <= 'd0;
            ram1_rd_oce <= 'd0;        
        end
        if(bilinear_interpolation_cnt >= VIDEO_LENGTH/2 + OFFSET_ADDR + DELAY_OUTPUT) begin
            bilinear_interpolation_cnt <= 'd0 + OFFSET_ADDR;
            bilinear_interpolation_flag <= 'd0;
            de_out <= 'd0;
        end
        else if(bilinear_interpolation_cnt >=  OFFSET_ADDR + DELAY_OUTPUT) begin
            de_out <= 'd1;
            //test
            //video_data_out <= ram0_rd_data / 2 + ram1_rd_data / 2;
            video_data_out[31:22] <= ram0_rd_data[31:22]/2 + ram1_rd_data[31:22]/2;
            video_data_out[21:12] <= ram0_rd_data[21:12]/2 + ram1_rd_data[21:12]/2;
            video_data_out[11: 2] <= ram0_rd_data[11: 2]/2 + ram1_rd_data[11: 2]/2;
        end
    end
    else begin
        video_data_out <= 'd0;
        de_out <= 'd0;
        ram0_rd_oce <= 'd0;
        ram1_rd_oce <= 'd0;
        if(bilinear_interpolation_flag) begin//提前复位地址
            r_ram0_rd_addr <= {1'b1,bilinear_interpolation_cnt};
            r_ram1_rd_addr <= {1'b1,bilinear_interpolation_cnt}; 
        end 
        else if(!bilinear_interpolation_flag)begin
            r_ram0_rd_addr <= {1'b0,bilinear_interpolation_cnt};
            r_ram1_rd_addr <= {1'b0,bilinear_interpolation_cnt};       
        end
    end
end

//ram为高复位
interpolation_ram user_interpolation_ram0 (
  .wr_data(r_ram0_wr_data),    // input [31:0]
  .wr_addr(r_ram0_wr_addr),    // input [10:0]
  .wr_en  (r_ram0_wr_en),      // input
  .wr_clk (clk),               // input
  .wr_rst (!rstn || vs_rst),             // input
  .rd_addr(r_ram0_rd_addr),    // input [10:0]
  .rd_data(ram0_rd_data),      // output [31:0]
  .rd_clk (clk),               // input
  //.rd_oce(ram0_rd_oce),              // input
  .rd_rst (!rstn)              // input
);

interpolation_ram user_interpolation_ram1 (
  .wr_data(r_ram1_wr_data),    // input [31:0]
  .wr_addr(r_ram1_wr_addr),    // input [10:0]
  .wr_en  (r_ram1_wr_en),      // input
  .wr_clk (clk),               // input
  .wr_rst (!rstn || vs_rst),             // input
  .rd_addr(r_ram1_rd_addr),    // input [10:0]
  .rd_data(ram1_rd_data),      // output [31:0]
  .rd_clk (clk),               // input
  //.rd_oce(ram1_rd_oce),      // input
  .rd_rst (!rstn)              // input
);

endmodule