`timescale 1ns / 1ps
//输入数据：
//- `pclk`（时钟信号）
//- `rst_n`（复位信号，低电平有效）
//- `de_i`（数据使能输入）
//- `pdata_i`（8位并行输入数据）
//- `vs_i`（垂直同步信号）
//
//输出数据：
//- `pixel_clk`（降频时钟输出，用于像素时钟）
//- `de_o`（数据使能输出）
//- `pdata_o`（16位并行输出数据）
//
//功能介绍：
//该模块`cmos_8_16bit`用于将8位的并行数据转换为16位输出数据，并在特定条件下同步控制数据的有效性信号（de信号）和像素时钟信号。其主要功能如下：
//1. 当`de_i`有效时，通过两个时钟周期的计数累积，将连续的两个8位`pdata_i`数据拼接成16位并输出为`pdata_o`。
//2. 通过信号处理，对`de_i`上升沿和下降沿进行检测，生成数据使能输出信号`de_o`。
//3. 通过`GTP_IOCLKDIV`模块将输入时钟`pclk`降频为`pixel_clk`，用于输出数据的像素时钟。
//将两个8bit数据拼成一个16bit RGB565数据；
`timescale 1ns/1ns

module cmos_8_16bit(
	input 				   pclk 		,   
	input 				   rst_n		,
	input				   de_i	        ,
	input	[7:0]	       pdata_i	    ,
    input                  vs_i         ,

    output  wire           pixel_clk    ,
 	output	reg			   de_o         ,
	output  reg [15:0]	   pdata_o
); 
reg			de_out1          ;
reg [15:0]	pdata_out1       ;
reg			de_out2          ;
reg [15:0]	pdata_out2       ;    
reg [1:0]   cnt             ;
wire        pclk_IOCLKBUF   ;
reg         vs_i_reg        ;
reg         enble           ;
reg [7:0] pdata_i_reg;
reg de_i_r,de_i_r1;
reg			de_out3          ;
reg [15:0]	pdata_out3       ;  
always @(posedge pclk)begin
       vs_i_reg <= vs_i ;
end
    always@(posedge pclk)
        begin
            if(!rst_n)
                enble <= 1'b0;
            else if(!vs_i_reg&&vs_i)
                enble <= 1'b1;
            else
                enble <= enble;
        end

GTP_IOCLKBUF #(
    .GATE_EN("FALSE")//
) u_GTP_IOCLKBUF (
    .CLKOUT(pclk_IOCLKBUF),// OUTPUT  
    .CLKIN(pclk), // INPUT  
    .DI(1'b1)     // INPUT  
);

GTP_IOCLKDIV #(
    .GRS_EN("TRUE"),
    .DIV_FACTOR("2")
) u_GTP_IOCLKDIV (
    .CLKDIVOUT(pixel_clk),// OUTPUT  
    .CLKIN(pclk_IOCLKBUF),    // INPUT  
    .RST_N(rst_n)     // INPUT  
);

    always@(posedge pclk)
        begin
            if(!rst_n)
                cnt <= 2'b0;
            else if(de_i == 1'b1 && cnt == 2'd1)
                cnt <= 2'b0;
            else if(de_i == 1'b1)
                cnt <= cnt + 1'b1;
        end
    

    always@(posedge pclk)
        begin
            if(!rst_n)
                pdata_i_reg <= 8'b0;
            else if(de_i == 1'b1)
                pdata_i_reg <= pdata_i;
        end
    
    always@(posedge pclk)
        begin
            if(!rst_n)
                pdata_out1 <= 16'b0;
            else if(de_i == 1'b1 && cnt == 2'd1)
                pdata_out1 <= {pdata_i_reg,pdata_i};
        end
  

   always@(posedge pclk)begin
        de_i_r <= de_i;
        de_i_r1 <= de_i_r;
   end
    always@(posedge pclk)
        begin
            if(!rst_n)
                de_out1 <= 1'b0;
            else if(!de_i_r1 && de_i_r )//上升沿
                de_out1 <= 1'b1;
            else if(de_i_r1 && !de_i_r )//下降沿
                de_out1 <= 1'b0;
            else
                de_out1 <= de_out1;
        end


 
    always@(posedge pixel_clk)begin
        de_out2<=de_out1;
        de_out3<=de_out2;
        de_o   <=de_out3;
    end
    always@(posedge pixel_clk)begin
        pdata_out2<=pdata_out1;
        pdata_out3<=pdata_out2;
        pdata_o   <=pdata_out3;
    end
endmodule