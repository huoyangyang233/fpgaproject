module Gauss_Filter(
	 input        clk,
	 input        rst_n,
	 input        [7:0]     data_in,
	 input        data_in_en,
	 output reg   [7:0]    data_out,
	 output reg   data_out_en
);
//------------------------------------
// 三行像素缓存
//----------------------------------- 
wire [7:0] line0;
wire [7:0] line1;
wire [7:0] line2;
//-----------------------------------------
// 3x3 像素矩阵中的像素点
//-----------------------------------------
reg [7:0] line0_data0;
reg [7:0] line0_data1;
reg [7:0] line0_data2;
reg [7:0] line1_data0;
reg [7:0] line1_data1;
reg [7:0] line1_data2;
reg [7:0] line2_data0;
reg [7:0] line2_data1;
reg [7:0] line2_data2;

wire   mat_flag; 
reg    mat_flag_1; 
reg    mat_flag_2; 
reg    mat_flag_3; 
reg    mat_flag_4; 

reg    [16:0]    data_o;
reg    [16:0]    sum_00_02_20_22;
reg    [16:0]    sum_01_10_12_21;

always @(posedge clk)begin
        mat_flag_1          <=          mat_flag;      
        mat_flag_2          <=          mat_flag_1;      
        mat_flag_3          <=          mat_flag_2;      
        mat_flag_4          <=          mat_flag_3; 
end


//---------------------------------------------
// 获取3*3的图像矩阵
//---------------------------------------------
Matrix_3x3 matrix_3x3_inst(
    .clk (clk),
    .rst_n(rst_n),
    .din (data_in),
    .valid_in(data_in_en),
    .dout(),
    .dout_r0(line0),
    .dout_r1(line1),
    .dout_r2(line2),
    .mat_flag(mat_flag)
);
//--------------------------------------------------
// Form an image matrix of three multiplied by three
//--------------------------------------------------
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
	 line0_data0 <= 8'b0;
	 line0_data1 <= 8'b0;
	 line0_data2 <= 8'b0;
	 
	 line1_data0 <= 8'b0;
	 line1_data1 <= 8'b0;
	 line1_data2 <= 8'b0;
	 
	 line2_data0 <= 8'b0;
	 line2_data1 <= 8'b0;
	 line2_data2 <= 8'b0;
 end
 else if(data_in_en) begin //像素有效信号
	 line0_data0 <= line0;
	 line0_data1 <= line0_data0;
	 line0_data2 <= line0_data1;
	 
	 line1_data0 <= line1;
	 line1_data1 <= line1_data0;
	 line1_data2 <= line1_data1;
	 
	 line2_data0 <= line2;
	 line2_data1 <= line2_data0;
	 line2_data2 <= line2_data1; 
 end
end

//--------------------------------------------------------------------------
// 计算最终结果
//--------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
 	sum_00_02_20_22 <= 16'b0;
    sum_01_10_12_21 <= 16'b0;
    end
 else if(data_in_en) begin
    sum_00_02_20_22 <= line0_data0 + line0_data2 + line2_data0 + line2_data2;
    sum_01_10_12_21 <= line0_data1 + line1_data0 + line1_data2 + line2_data1;
    end
 else ;
end


always @(posedge clk or negedge rst_n) begin
 if(!rst_n)
 	data_o <= 16'b0;
 else if(data_in_en)
    data_o <= sum_00_02_20_22*1 + sum_01_10_12_21*2 + line1_data1*4;
 else ;
end

always @(posedge clk or negedge rst_n) begin
 if(!rst_n)
 	data_out <= 8'b0;
 else if(data_in_en)
    data_out <= data_o>>4;
 else ;
end


always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        data_out_en  <= 1'b0;
    else if(mat_flag_3 == 1'b1 && mat_flag_4 == 1'b1) 
        data_out_en  <= 1'b1;
    else
        data_out_en  <= 1'b0;
end

endmodule

