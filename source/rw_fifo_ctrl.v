module rw_fifo_ctrl (
    // ϵͳ��λ
    input wire         rstn,

    // д���ڴ��ʱ�ӣ��ڴ� AXI4 �ӿ�ʱ�ӣ�
    input wire         ddr_clk,

    // д FIFO �ӿ�
    input wire         wfifo_wr_clk,           // д FIFO дʱ��
    input wire         wfifo_wr_en,            // д FIFO ����ʹ��
    input wire [31:0]  wfifo_wr_data32_in,     // д FIFO ��������, 32 bits
    input wire         wfifo_rd_req,           // д FIFO �����󣬵���������ͻ������ʱ����
    output wire [8:0]  wfifo_rd_water_level,   // д FIFO ��ˮλ������������ͻ������ʱ��ʼ����
    output wire [255:0] wfifo_rd_data256_out,   // д FIFO �����ݣ�256 bits      

    // �� FIFO �ӿ�
    input wire         rfifo_rd_clk,           // �� FIFO ��ʱ��
    input wire         rfifo_rd_en,            // �� FIFO ����ʹ��
    output wire [31:0] rfifo_rd_data32_out,    // �� FIFO �������, 32 bits
    input wire         rfifo_wr_req,           // �� FIFO д���󣬵���������ͻ������ʱ����
    output wire [8:0]  rfifo_wr_water_level,   // �� FIFO дˮλ��������С��ͻ������ʱ��ʼ����
    input wire [255:0] rfifo_wr_data256_in,    // �� FIFO д���ݣ�256 bits

    // ��λ�ź�
    input wire         vs_in,
    input wire         vs_out
);

    // ****************************** �������� ******************************
    // �޲�������

    // ****************************** �źŶ��� ******************************
    // д FIFO ��λ����ź�
    reg                r_vs_in_d0;
    reg [15:0]         r_vs_in_d1; 
    reg                r_wr_rst;              // д FIFO ��λ�ź�

    // �� FIFO ��λ����ź�
    reg                r_vs_out_d0;
    reg [15:0]         r_vs_out_d1;     
    reg                r_rd_rst;              // �� FIFO ��λ�ź�

    // ****************************** ����߼� ******************************

    // д FIFO ��λ�߼�
    always @(posedge wfifo_wr_clk) begin
        if (!rstn) begin
            r_vs_in_d0 <= 1'b0;
        end else begin 
            r_vs_in_d0 <= vs_in;
        end
    end

    // д FIFO λ�ƼĴ�
    always @(posedge wfifo_wr_clk) begin
        if (!rstn) begin
            r_vs_in_d1 <= 16'd0;
        end else begin 
            r_vs_in_d1 <= {r_vs_in_d1[14:0], r_vs_in_d0};
        end
    end

    // ����д FIFO �����ڸ�λ��ƽ������ FIFO ��λʱ��
    always @(posedge wfifo_wr_clk) begin
        if (!rstn) begin
            r_wr_rst <= 1'b0;
        end else if (r_vs_in_d1[0] && !r_vs_in_d1[14]) begin
            r_wr_rst <= 1'b1;
        end else begin
            r_wr_rst <= 1'b0;
        end
    end  

    // �� FIFO ��λ�߼�
    always @(posedge rfifo_rd_clk) begin
        if (!rstn) begin
            r_vs_out_d0 <= 1'b0;
        end else begin 
            r_vs_out_d0 <= vs_out;
        end
    end

    // �� FIFO λ�ƼĴ�
    always @(posedge rfifo_rd_clk) begin
        if (!rstn) begin
            r_vs_out_d1 <= 16'd0;
        end else begin 
            r_vs_out_d1 <= {r_vs_out_d1[14:0], r_vs_out_d0};
        end
    end

    // ���ɶ� FIFO �����ڸ�λ��ƽ������ FIFO ��λʱ��
    always @(posedge rfifo_rd_clk) begin
        if (!rstn) begin
            r_rd_rst <= 1'b0;
        end else if (r_vs_out_d1[0] && !r_vs_out_d1[14]) begin
            r_rd_rst <= 1'b1;
        end else begin
            r_rd_rst <= 1'b0;
        end
    end  

    // ****************************** FIFO ʵ���� ******************************

    // д FIFO ʵ����
    write_ddr_fifo user_write_ddr_fifo (
        .wr_clk          (wfifo_wr_clk),            // дʱ��
        .wr_rst          (~rstn | r_wr_rst),        // д��λ
        .wr_en           (wfifo_wr_en),             // дʹ��
        .wr_data         (wfifo_wr_data32_in),      // д���� [31:0]
        .wr_full         (),                         // д����־
        .wr_water_level  (),                         // дˮλ
        .almost_full     (),                         // ����д����־
        .rd_clk          (ddr_clk),                 // ��ʱ��
        .rd_rst          (~rstn | r_wr_rst),        // ����λ
        .rd_en           (wfifo_rd_req),            // ��ʹ��
        .rd_data         (wfifo_rd_data256_out),    // ������ [255:0]
        .rd_empty        (),                         // ���ձ�־
        .rd_water_level  (wfifo_rd_water_level),    // ��ˮλ
        .almost_empty    ()                          // �������ձ�־
    );

    // �� FIFO ʵ����
    read_ddr_fifo user_read_ddr_fifo (
        .wr_clk          (ddr_clk),                 // дʱ��
        .wr_rst          (~rstn | r_rd_rst),        // д��λ
        .wr_en           (rfifo_wr_req),            // дʹ��
        .wr_data         (rfifo_wr_data256_in),     // д���� [255:0]
        .wr_full         (),                         // д����־
        .wr_water_level  (rfifo_wr_water_level),    // дˮλ
        .almost_full     (),                         // ����д����־
        .rd_clk          (rfifo_rd_clk),            // ��ʱ��
        .rd_rst          (~rstn | r_rd_rst),        // ����λ
        .rd_en           (rfifo_rd_en),             // ��ʹ��
        .rd_data         (rfifo_rd_data32_out),     // ������ [31:0]
        .rd_empty        (),                         // ���ձ�־
        .rd_water_level  (),                         // ��ˮλ
        .almost_empty    ()                          // �������ձ�־
    );

endmodule
