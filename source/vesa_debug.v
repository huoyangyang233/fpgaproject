//此 `vesa_debug` 模块的主要功能是生成一个简单的递增调试数据流。它根据 `de`（数据有效）信号和 `vs`（垂直同步）信号来控制输出 `vesa_data`。当 `de` 信号为高电平时，`vesa_data` 会从初始值 `16'hA500` 开始递增，并在 `de` 信号下降沿时将 `vesa_data` 重置为初始值。这种设计通常用于视频信号处理中的调试和测试场景，以便生成一个不断递增的数据流，便于观察和调试信号行为。
//
//### 关键模块说明
//
//1. **参数定义**：
//   - `PIX_WIGHT`：数据位宽，默认为 16 位。
//   
//2. **输入信号**：
//   - `pix_clk`：像素时钟。
//   - `rstn`：复位信号，低电平复位。
//   - `vs`：垂直同步信号。
//   - `de`：数据有效信号，高电平表示有效数据。
//
//3. **输出信号**：
//   - `vesa_data`：输出的 16 位数据流，用于测试和调试。
//
//4. **内部信号**：
//   - `de_d0` 和 `de_d1`：用于捕获 `de` 信号的上升沿和下降沿。
//   - `de_pos` 和 `de_neg`：用于检测 `de` 信号的上升沿和下降沿，以便控制 `vesa_data` 的递增和复位。
//
//### 模块逻辑分析
//
//- **数据递增控制**：当 `de` 为高电平时，`vesa_data` 以 1 的步长递增。递增操作在 `de` 的上升沿触发，表示当前帧中的有效数据。
//  
//- **数据复位**：当 `de` 下降沿（`de_neg`）时，将 `vesa_data` 重置为 `16'hA500`，表示每帧数据的起始值相同。
//
//- **同步信号更新**：`de_d0` 和 `de_d1` 实现对 `de` 信号的延迟，以检测 `de` 的上升沿和下降沿。`vs` 信号也用于复位 `vesa_data`，确保在每帧开始时重置数据。
//
//此模块通过简单的计数器输出调试数据，能够清晰地展示每帧的开始和结束，适合用于图像处理系统的调试。

module vesa_debug#(
parameter PIX_WIGHT = 16
)
(
input wire    pix_clk,
input wire    rstn,
input wire    vs,
input wire    de,
output reg [15 : 0]   vesa_data
);
reg de_d0;
reg de_d1;
wire de_pos;
wire de_neg;
assign de_pos_d0 = de && !de_d0;
assign de_neg = !de_d0 && de_d1;
always @(posedge pix_clk)begin
    if(!rstn||vs) begin
        vesa_data <= 16'hA500;
    end
    else if(de) begin
        vesa_data <= vesa_data + 'd1;
    end
    else if(de_neg) begin
        vesa_data <= 16'hA500;
    end
end
always @(posedge pix_clk)begin
    if(!rstn||vs) begin
        de_d0 <= 'd0;
    end
    else begin
        de_d0 <= de;
        de_d1 <= de_d0;
    end
end
endmodule