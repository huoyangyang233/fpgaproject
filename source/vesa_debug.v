//�� `vesa_debug` ģ�����Ҫ����������һ���򵥵ĵ��������������������� `de`��������Ч���źź� `vs`����ֱͬ�����ź���������� `vesa_data`���� `de` �ź�Ϊ�ߵ�ƽʱ��`vesa_data` ��ӳ�ʼֵ `16'hA500` ��ʼ���������� `de` �ź��½���ʱ�� `vesa_data` ����Ϊ��ʼֵ���������ͨ��������Ƶ�źŴ����еĵ��ԺͲ��Գ������Ա�����һ�����ϵ����������������ڹ۲�͵����ź���Ϊ��
//
//### �ؼ�ģ��˵��
//
//1. **��������**��
//   - `PIX_WIGHT`������λ��Ĭ��Ϊ 16 λ��
//   
//2. **�����ź�**��
//   - `pix_clk`������ʱ�ӡ�
//   - `rstn`����λ�źţ��͵�ƽ��λ��
//   - `vs`����ֱͬ���źš�
//   - `de`��������Ч�źţ��ߵ�ƽ��ʾ��Ч���ݡ�
//
//3. **����ź�**��
//   - `vesa_data`������� 16 λ�����������ڲ��Ժ͵��ԡ�
//
//4. **�ڲ��ź�**��
//   - `de_d0` �� `de_d1`�����ڲ��� `de` �źŵ������غ��½��ء�
//   - `de_pos` �� `de_neg`�����ڼ�� `de` �źŵ������غ��½��أ��Ա���� `vesa_data` �ĵ����͸�λ��
//
//### ģ���߼�����
//
//- **���ݵ�������**���� `de` Ϊ�ߵ�ƽʱ��`vesa_data` �� 1 �Ĳ������������������� `de` �������ش�������ʾ��ǰ֡�е���Ч���ݡ�
//  
//- **���ݸ�λ**���� `de` �½��أ�`de_neg`��ʱ���� `vesa_data` ����Ϊ `16'hA500`����ʾÿ֡���ݵ���ʼֵ��ͬ��
//
//- **ͬ���źŸ���**��`de_d0` �� `de_d1` ʵ�ֶ� `de` �źŵ��ӳ٣��Լ�� `de` �������غ��½��ء�`vs` �ź�Ҳ���ڸ�λ `vesa_data`��ȷ����ÿ֡��ʼʱ�������ݡ�
//
//��ģ��ͨ���򵥵ļ���������������ݣ��ܹ�������չʾÿ֡�Ŀ�ʼ�ͽ������ʺ�����ͼ����ϵͳ�ĵ��ԡ�

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