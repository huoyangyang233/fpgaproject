module L_Buffer#(
    parameter    width = 8,
    parameter    img_width = 1280)(
    input    clk,
    input    rst_n,
    input    [width-1:0] din,
    output   [width-1:0] dout,
    input    valid_in,  //输入数据有效，写使能
    output   valid_out  //输出给下一级的valid_in，也即上一级开始读的同时下一级就可以开始写入
   );
wire    rd_en;  //读使能
reg     [10:0] cnt;  //这里的宽度注意要根据IMG_WIDTH的值来设置，需要满足cnt的范围≥图像宽度
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= {11{1'b0}};
    else if(valid_in)
        if(cnt == img_width)
            cnt <= img_width;
        else
            cnt <= cnt +1'b1;
    else
        cnt <= cnt;
end

assign rd_en = ((cnt == img_width) && (valid_in)) ? 1'b1:1'b0;
assign valid_out = rd_en;

L_FIFO Line_FIFO (
  .clk(clk),                      // input
  .rst(!rst_n),                      // input
  .wr_en(valid_in),                  // input
  .wr_data(din),              // input [7:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_en(rd_en),                  // input
  .rd_data(dout),              // output [7:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

endmodule