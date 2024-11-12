`timescale 1ns / 1ps
//输入数据：
//- `clk_50M`（时钟信号，50MHz）
//- `reset_n`（复位信号，低电平有效）
//
//输出数据：
//- `camera1_rstn`（摄像头1复位信号）
//- `camera2_rstn`（摄像头2复位信号）
//- `camera_pwnd`（摄像头电源控制信号）
//- `initial_en`（初始化使能信号）
//
//功能介绍：
//该模块`ov5640_power_on_delay`用于管理OV5640摄像头的上电延时序列，确保摄像头的电源和复位信号按规定的时间顺序进行切换。模块通过三个计数器（`cnt1`、`cnt2`和`cnt3`）生成延时：
//1. `cnt1`实现摄像头上电稳定后延时5ms再拉低`camera_pwnd`信号；
//2. `cnt2`在`camera_pwnd`低电平后延时1.3ms再拉高复位信号`camera_rstn_reg`；
//3. `cnt3`在复位信号拉高后延时21ms，最后将`initial_en`信号拉高，指示摄像头已完成上电延时，进入初始化状态。
//camera power on timing requirement
module ov5640_power_on_delay(                  
    input  clk_50M        ,
    input  reset_n        ,
    output camera1_rstn   ,
    output camera2_rstn   ,
    output camera_pwnd    ,
    output reg initial_en
);
reg [18:0]cnt1;
reg [15:0]cnt2;
reg [19:0]cnt3;
reg camera_rstn_reg;
reg camera_pwnd_reg;

assign camera1_rstn=camera_rstn_reg;
assign camera2_rstn=camera_rstn_reg;
assign camera_pwnd=camera_pwnd_reg;

//5ms, delay from sensor power up stable to Pwdn pull down
always@(posedge clk_50M)begin
  if(reset_n==1'b0) begin
	    cnt1<=0;
		camera_pwnd_reg<=1'b1;// 1'b1 
  end
  else if(cnt1<19'h40000) begin
       cnt1<=cnt1+1'b1;
       camera_pwnd_reg<=1'b1;
  end
  else
     camera_pwnd_reg<=1'b0;         
end

//1.3ms, delay from pwdn low to resetb pull up
always@(posedge clk_50M)begin
  if(camera_pwnd_reg==1)  begin
	 cnt2<=0;
     camera_rstn_reg<=1'b0;  
  end
  else if(cnt2<16'hffff) begin
       cnt2<=cnt2+1'b1;
       camera_rstn_reg<=1'b0;
  end
  else
     camera_rstn_reg<=1'b1;         
end

//21ms, delay from resetb pul high to SCCB initialization
always@(posedge clk_50M)begin
  if(camera_rstn_reg==0) begin
         cnt3<=0;
         initial_en<=1'b0;
  end
  else if(cnt3<20'hfffff) begin
        cnt3<=cnt3+1'b1;
        initial_en<=1'b0;
  end
  else
       initial_en<=1'b1;    
end

endmodule
