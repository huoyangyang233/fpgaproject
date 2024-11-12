//�� `udp_top` ģ����һ������ GMII �ӿڵ� UDP �����շ�����ģ�顣ģ��ͨ����̫���ӿڷ��ͺͽ������ݰ�����ִ�� CRC У�飬�ʺ�Ƕ��ʽ����ͨ��Ӧ�á�
//
//### �˿�˵��
//
//- **��λ�ź�**
//  - `rst_n`: �͵�ƽ��Ч�ĸ�λ�źš�
//
//- **GMII �ӿ�**
//  - `gmii_rx_clk`: GMII ��������ʱ�ӡ�
//  - `gmii_rx_dv`: GMII ����������Ч�źš�
//  - `gmii_rxd[7:0]`: GMII �������ݡ�
//  - `gmii_tx_clk`: GMII ��������ʱ�ӡ�
//  - `gmii_tx_en`: GMII ���������Ч�źš�
//  - `gmii_txd[7:0]`: GMII ������ݡ�
//
//- **�û��ӿ�**
//  - `rec_pkt_done`: �������ݽ�������źš�
//  - `rec_en`: ��̫����������ʹ���źš�
//  - `rec_data[31:0]`: ��̫���������ݡ�
//  - `rec_byte_num[15:0]`: ���յ���Ч�ֽ�����
//  - `tx_start_en`: ���Ϳ�ʼ�źš�
//  - `tx_data[31:0]`: ���������ݡ�
//  - `tx_byte_num[15:0]`: ������Ч�ֽ�����
//  - `des_mac[47:0]`: Ŀ�� MAC ��ַ��
//  - `des_ip[31:0]`: Ŀ�� IP ��ַ��
//  - `tx_done`: ��������źš�
//  - `tx_req`: ��ȡ���������źš�
//
//### ����
//
//- `BOARD_MAC`: ������� MAC ��ַ��Ĭ��Ϊ `00:11:22:33:44:55`��
//- `BOARD_IP`: ������� IP ��ַ��Ĭ��Ϊ `192.168.1.10`��
//- `DES_MAC`: Ŀ�� MAC ��ַ��Ĭ��Ϊ�㲥��ַ `ff:ff:ff:ff:ff:ff`��
//- `DES_IP`: Ŀ�� IP ��ַ��Ĭ��Ϊ `192.168.1.102`��
//
//### ��Ҫģ����ź�����
//
//#### 1. ����ģ�� (`udp_rx`)
//
//- `udp_rx` ��ģ�鴦����̫�����ݵĽ��ղ�����
//- ���� `BOARD_MAC` �� `BOARD_IP` �����˱����豸�� MAC �� IP ��ַ�������жϽ��յ������Ƿ��͵���ǰ�豸��
//- ��Ҫ�����
//  - `rec_pkt_done`: ���ݰ�������ɡ�
//  - `rec_en`: ���ݽ���ʹ�ܡ�
//  - `rec_data`: ���յ������ݡ�
//  - `rec_byte_num`: �������ݵ��ֽ�����
//
//#### 2. ����ģ�� (`udp_tx`)
//
//- `udp_tx` ��ģ�鸺�����ݷ�װ����̫���������͡�
//- ���� `DES_MAC` �� `DES_IP` ������Ĭ�ϵ�Ŀ�� MAC �� IP ��ַ��
//- ��Ҫ���룺
//  - `tx_start_en`: �������͵��źš�
//  - `tx_data` �� `tx_byte_num`: Ҫ���͵����ݺ��ֽ�����
//  - `des_mac` �� `des_ip`: Ŀ�ĵ�ַ��
//  - `crc_data`: CRC У�����ݡ�
//  - `crc_next`: ��һ�� CRC У�����ݡ�
//- �����
//  - `tx_done`: ������ɱ�־��
//  - `tx_req`: ���������źš�
//  - `gmii_tx_en` �� `gmii_txd`: ���͵� GMII �����ݺ�ʹ���źš�
//
//#### 3. CRC У��ģ�� (`crc32_d8`)
//
//- `crc32_d8` ��������ݽ��� CRC У�飬����ȷ�����������ԡ�
//- �����ź� `crc_en` ���� CRC У��ʹ�ܣ�`crc_clr` ���Ƹ�λ�źš�
//- ���ɵ� `crc_data` �� `crc_next` �� `udp_tx` �������ݰ��ķ���У�顣
//
//### ��������
//
//1. **���ݽ���**��ͨ�� `udp_rx` ��ģ�������̫�����ݰ�����ͨ�� `rec_pkt_done`��`rec_en` �� `rec_data` �������״̬�����ݡ�
//
//2. **���ݷ���**��
//   - ���Ϳ����� `tx_start_en` ������
//   - �����͵�����ͨ�� `tx_data` �� `tx_byte_num` ���룬���� `udp_tx` �ڲ���װ�� UDP ����
//   - `crc32_d8` ģ����㲢У�����������ԡ�
//   - ���ݷ�����ɺ�`tx_done` �ź����ߣ���ʾһ�����ݷ��͵���ɡ�
//


module udp_top(
    input                rst_n       , //��λ�źţ��͵�ƽ��Ч
    //GMII�ӿ�
    input                gmii_rx_clk , //GMII��������ʱ��
    input                gmii_rx_dv  , //GMII����������Ч�ź�
    input        [7:0]   gmii_rxd    , //GMII��������
    input                gmii_tx_clk , //GMII��������ʱ��    
    output               gmii_tx_en  , //GMII���������Ч�ź�
    output       [7:0]   gmii_txd    , //GMII������� 
    //�û��ӿ�
    output               rec_pkt_done, //��̫���������ݽ�������ź�
    output               rec_en      , //��̫�����յ�����ʹ���ź�
    output       [31:0]  rec_data    , //��̫�����յ�����
    output       [15:0]  rec_byte_num, //��̫�����յ���Ч�ֽ��� ��λ:byte     
    input                tx_start_en , //��̫����ʼ�����ź�
    input        [31:0]  tx_data     , //��̫������������  
    input        [15:0]  tx_byte_num , //��̫�����͵���Ч�ֽ��� ��λ:byte  
    input        [47:0]  des_mac     , //���͵�Ŀ��MAC��ַ
    input        [31:0]  des_ip      , //���͵�Ŀ��IP��ַ    
    output               tx_done     , //��̫����������ź�
    output               tx_req        //�����������ź�    
    );

//parameter define
//������MAC��ַ 00-11-22-33-44-55
parameter BOARD_MAC = 48'h00_11_22_33_44_55;    
//������IP��ַ 192.168.1.10     
parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};
//Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
parameter  DES_MAC  = 48'hff_ff_ff_ff_ff_ff;
//Ŀ��IP��ַ 192.168.1.102     
parameter  DES_IP   = {8'd192,8'd168,8'd1,8'd102};

//wire define
wire          crc_en  ; //CRC��ʼУ��ʹ��
wire          crc_clr ; //CRC���ݸ�λ�ź� 
wire  [7:0]   crc_d8  ; //�����У��8λ����

wire  [31:0]  crc_data; //CRCУ������
wire  [31:0]  crc_next; //CRC�´�У���������

//*****************************************************
//**                    main code
//*****************************************************

assign  crc_d8 = gmii_txd;

//��̫������ģ��    
udp_rx 
   #(
    .BOARD_MAC       (BOARD_MAC),         //��������
    .BOARD_IP        (BOARD_IP )
    )
   u_udp_rx(
    .clk             (gmii_rx_clk ),        
    .rst_n           (rst_n       ),             
    .gmii_rx_dv      (gmii_rx_dv  ),                                 
    .gmii_rxd        (gmii_rxd    ),       
    .rec_pkt_done    (rec_pkt_done),      
    .rec_en          (rec_en      ),            
    .rec_data        (rec_data    ),          
    .rec_byte_num    (rec_byte_num)       
    );                                    

//��̫������ģ��
udp_tx
   #(
    .BOARD_MAC       (BOARD_MAC),         //��������
    .BOARD_IP        (BOARD_IP ),
    .DES_MAC         (DES_MAC  ),
    .DES_IP          (DES_IP   )
    )
   u_udp_tx(
    .clk             (gmii_tx_clk),        
    .rst_n           (rst_n      ),             
    .tx_start_en     (tx_start_en),                   
    .tx_data         (tx_data    ),           
    .tx_byte_num     (tx_byte_num),    
    .des_mac         (des_mac    ),
    .des_ip          (des_ip     ),    
    .crc_data        (crc_data   ),          
    .crc_next        (crc_next[31:24]),
    .tx_done         (tx_done    ),           
    .tx_req          (tx_req     ),            
    .gmii_tx_en      (gmii_tx_en ),         
    .gmii_txd        (gmii_txd   ),       
    .crc_en          (crc_en     ),            
    .crc_clr         (crc_clr    )            
    );                                      

//��̫������CRCУ��ģ��
crc32_d8   u_crc32_d8(
    .clk             (gmii_tx_clk),                      
    .rst_n           (rst_n      ),                          
    .data            (crc_d8     ),            
    .crc_en          (crc_en     ),                          
    .crc_clr         (crc_clr    ),                         
    .crc_data        (crc_data   ),                        
    .crc_next        (crc_next   )                         
    );

endmodule