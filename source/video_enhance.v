//模块 `video_enhance` 主要用于对视频信号的亮度和对比度进行增强处理。该模块首先将 RGB 信号转换为 YUV 色彩空间，在 Y 通道（亮度）上进行调节后，再将增强后的 YUV 信号转换回 RGB。
//
//### 输入端口
//- `pix_clk`：像素时钟信号
//- `vs_in`：垂直同步信号
//- `hs_in`：水平同步信号
//- `de_in`：数据有效信号
//- `r_in`、`g_in`、`b_in`：8位的 RGB 输入信号
//- `video_enhance_lightdown_num`：调节高亮区域的值
//- `video_enhance_lightdown_sw`：高亮区域调节开关
//- `video_enhance_darkup_num`：调节暗部区域的值
//- `video_enhance_darkup_sw`：暗部区域调节开关
//
//### 输出端口
//- `vs_out`：增强后的视频垂直同步信号
//- `hs_out`：增强后的视频水平同步信号
//- `de_out`：增强后的视频数据有效信号
//- `r_out`、`g_out`、`b_out`：增强后的 RGB 输出信号
//
//### 内部信号
//- `y_out`、`u_out`、`v_out`：中间的 YUV 数据，分别表示亮度和色度分量
//- `yuv_vs_out`、`yuv_hs_out`、`yuv_de_out`：转换到 YUV 后的同步和数据有效信号
//
//### 工作原理
//1. **RGB 转 YUV**：模块 `rgb2yuv` 负责将输入的 RGB 信号转换成 YUV 色彩空间，并在亮度（Y通道）上根据输入的调节参数进行增强。可以通过设置 `video_enhance_lightdown_num` 和 `video_enhance_darkup_num` 的值，配合 `video_enhance_lightdown_sw` 和 `video_enhance_darkup_sw` 开关，来降低高亮区域的亮度或提高暗部区域的亮度。
//
//2. **YUV 转 RGB**：增强后的 YUV 信号经过 `yuv2rgb` 模块转换回 RGB 色彩空间，并输出到 `r_out`、`g_out`、`b_out`。
//
//### 调节功能
//- `video_enhance_lightdown_num` 和 `video_enhance_lightdown_sw` 用于调节亮度高的区域，减少亮度。
//- `video_enhance_darkup_num` 和 `video_enhance_darkup_sw` 用于调节暗部区域，提高亮度。
//
//该模块整体架构简洁，通过 YUV 转换实现视频亮度增强，适用于图像视频的简单实时增强应用。


module video_enhance(
input  wire            pix_clk,
input  wire            vs_in,
input  wire            hs_in,
input  wire            de_in,
input  wire [7 : 0]    r_in,
input  wire [7 : 0]    g_in,
input  wire [7 : 0]    b_in,

output wire            vs_out,
output wire            hs_out,
output wire            de_out,
output wire [7 : 0]    r_out,
output wire [7 : 0]    g_out,
output wire [7 : 0]    b_out,

input  wire [7 : 0]   video_enhance_lightdown_num,
input  wire           video_enhance_lightdown_sw ,
input  wire [7 : 0]   video_enhance_darkup_num   ,
input  wire           video_enhance_darkup_sw    

   );

wire [7 : 0] y_out;
wire [7 : 0] u_out;
wire [7 : 0] v_out;


wire         yuv_vs_out;
wire         yuv_hs_out;
wire         yuv_de_out;

rgb2yuv video_enhance_rgb2yuv(
.clk   (pix_clk),//input        
.r_in  (r_in),//input  [7:0] 
.g_in  (g_in),//input  [7:0] 
.b_in  (b_in),//input  [7:0] 
.vs_in (vs_in),//input        
.hs_in (hs_in),//input        
.de_in (de_in),//input        
.y_out (y_out),//output [7:0] 
.u_out (u_out),//output [7:0] 
.v_out (v_out),//output [7:0] 
.vs_out(yuv_vs_out),//output       
.hs_out(yuv_hs_out),//output       
.de_out(yuv_de_out), //output
.video_enhance_lightdown_num(video_enhance_lightdown_num),// input  wire [7 : 0]          
.video_enhance_lightdown_sw (video_enhance_lightdown_sw ),// input  wire           
.video_enhance_darkup_num   (video_enhance_darkup_num   ),// input  wire [7 : 0]   
.video_enhance_darkup_sw    (video_enhance_darkup_sw    ) // input  wire           
         
);

yuv2rgb video_enhance_yuv2rgb(
.clk   (pix_clk),//input       
.y_in  (y_out),//input [7:0] 
.u_in  (u_out),//input [7:0] 
.v_in  (v_out),//input [7:0] 
.vs_in (yuv_vs_out),//input       
.hs_in (yuv_hs_out),//input       
.de_in (yuv_de_out),//input       
.r_out (r_out),//output [7:0]
.g_out (g_out),//output [7:0]
.b_out (b_out),//output [7:0]
.vs_out(vs_out),//output      
.hs_out(hs_out),//output      
.de_out(de_out) //output      
);

endmodule