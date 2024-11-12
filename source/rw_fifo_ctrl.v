module rw_fifo_ctrl (
    // 系统复位
    input wire         rstn,

    // 写入内存的时钟（内存 AXI4 接口时钟）
    input wire         ddr_clk,

    // 写 FIFO 接口
    input wire         wfifo_wr_clk,           // 写 FIFO 写时钟
    input wire         wfifo_wr_en,            // 写 FIFO 输入使能
    input wire [31:0]  wfifo_wr_data32_in,     // 写 FIFO 输入数据, 32 bits
    input wire         wfifo_rd_req,           // 写 FIFO 读请求，当数量大于突发长度时拉高
    output wire [8:0]  wfifo_rd_water_level,   // 写 FIFO 读水位，当数量大于突发长度时开始传输
    output wire [255:0] wfifo_rd_data256_out,   // 写 FIFO 读数据，256 bits      

    // 读 FIFO 接口
    input wire         rfifo_rd_clk,           // 读 FIFO 读时钟
    input wire         rfifo_rd_en,            // 读 FIFO 输入使能
    output wire [31:0] rfifo_rd_data32_out,    // 读 FIFO 输出数据, 32 bits
    input wire         rfifo_wr_req,           // 读 FIFO 写请求，当数量大于突发长度时拉高
    output wire [8:0]  rfifo_wr_water_level,   // 读 FIFO 写水位，当数量小于突发长度时开始传输
    input wire [255:0] rfifo_wr_data256_in,    // 读 FIFO 写数据，256 bits

    // 复位信号
    input wire         vs_in,
    input wire         vs_out
);

    // ****************************** 参数定义 ******************************
    // 无参数定义

    // ****************************** 信号定义 ******************************
    // 写 FIFO 复位相关信号
    reg                r_vs_in_d0;
    reg [15:0]         r_vs_in_d1; 
    reg                r_wr_rst;              // 写 FIFO 复位信号

    // 读 FIFO 复位相关信号
    reg                r_vs_out_d0;
    reg [15:0]         r_vs_out_d1;     
    reg                r_rd_rst;              // 读 FIFO 复位信号

    // ****************************** 组合逻辑 ******************************

    // 写 FIFO 复位逻辑
    always @(posedge wfifo_wr_clk) begin
        if (!rstn) begin
            r_vs_in_d0 <= 1'b0;
        end else begin 
            r_vs_in_d0 <= vs_in;
        end
    end

    // 写 FIFO 位移寄存
    always @(posedge wfifo_wr_clk) begin
        if (!rstn) begin
            r_vs_in_d1 <= 16'd0;
        end else begin 
            r_vs_in_d1 <= {r_vs_in_d1[14:0], r_vs_in_d0};
        end
    end

    // 生成写 FIFO 多周期复位电平，满足 FIFO 复位时序
    always @(posedge wfifo_wr_clk) begin
        if (!rstn) begin
            r_wr_rst <= 1'b0;
        end else if (r_vs_in_d1[0] && !r_vs_in_d1[14]) begin
            r_wr_rst <= 1'b1;
        end else begin
            r_wr_rst <= 1'b0;
        end
    end  

    // 读 FIFO 复位逻辑
    always @(posedge rfifo_rd_clk) begin
        if (!rstn) begin
            r_vs_out_d0 <= 1'b0;
        end else begin 
            r_vs_out_d0 <= vs_out;
        end
    end

    // 读 FIFO 位移寄存
    always @(posedge rfifo_rd_clk) begin
        if (!rstn) begin
            r_vs_out_d1 <= 16'd0;
        end else begin 
            r_vs_out_d1 <= {r_vs_out_d1[14:0], r_vs_out_d0};
        end
    end

    // 生成读 FIFO 多周期复位电平，满足 FIFO 复位时序
    always @(posedge rfifo_rd_clk) begin
        if (!rstn) begin
            r_rd_rst <= 1'b0;
        end else if (r_vs_out_d1[0] && !r_vs_out_d1[14]) begin
            r_rd_rst <= 1'b1;
        end else begin
            r_rd_rst <= 1'b0;
        end
    end  

    // ****************************** FIFO 实例化 ******************************

    // 写 FIFO 实例化
    write_ddr_fifo user_write_ddr_fifo (
        .wr_clk          (wfifo_wr_clk),            // 写时钟
        .wr_rst          (~rstn | r_wr_rst),        // 写复位
        .wr_en           (wfifo_wr_en),             // 写使能
        .wr_data         (wfifo_wr_data32_in),      // 写数据 [31:0]
        .wr_full         (),                         // 写满标志
        .wr_water_level  (),                         // 写水位
        .almost_full     (),                         // 几乎写满标志
        .rd_clk          (ddr_clk),                 // 读时钟
        .rd_rst          (~rstn | r_wr_rst),        // 读复位
        .rd_en           (wfifo_rd_req),            // 读使能
        .rd_data         (wfifo_rd_data256_out),    // 读数据 [255:0]
        .rd_empty        (),                         // 读空标志
        .rd_water_level  (wfifo_rd_water_level),    // 读水位
        .almost_empty    ()                          // 几乎读空标志
    );

    // 读 FIFO 实例化
    read_ddr_fifo user_read_ddr_fifo (
        .wr_clk          (ddr_clk),                 // 写时钟
        .wr_rst          (~rstn | r_rd_rst),        // 写复位
        .wr_en           (rfifo_wr_req),            // 写使能
        .wr_data         (rfifo_wr_data256_in),     // 写数据 [255:0]
        .wr_full         (),                         // 写满标志
        .wr_water_level  (rfifo_wr_water_level),    // 写水位
        .almost_full     (),                         // 几乎写满标志
        .rd_clk          (rfifo_rd_clk),            // 读时钟
        .rd_rst          (~rstn | r_rd_rst),        // 读复位
        .rd_en           (rfifo_rd_en),             // 读使能
        .rd_data         (rfifo_rd_data32_out),     // 读数据 [31:0]
        .rd_empty        (),                         // 读空标志
        .rd_water_level  (),                         // 读水位
        .almost_empty    ()                          // 几乎读空标志
    );

endmodule
