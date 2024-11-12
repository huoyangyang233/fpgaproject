//该 `udp_top` 模块是一个基于 GMII 接口的 UDP 数据收发顶层模块。模块通过以太网接口发送和接收数据包，并执行 CRC 校验，适合嵌入式网络通信应用。
//
//### 端口说明
//
//- **复位信号**
//  - `rst_n`: 低电平有效的复位信号。
//
//- **GMII 接口**
//  - `gmii_rx_clk`: GMII 接收数据时钟。
//  - `gmii_rx_dv`: GMII 输入数据有效信号。
//  - `gmii_rxd[7:0]`: GMII 输入数据。
//  - `gmii_tx_clk`: GMII 发送数据时钟。
//  - `gmii_tx_en`: GMII 输出数据有效信号。
//  - `gmii_txd[7:0]`: GMII 输出数据。
//
//- **用户接口**
//  - `rec_pkt_done`: 单包数据接收完成信号。
//  - `rec_en`: 以太网接收数据使能信号。
//  - `rec_data[31:0]`: 以太网接收数据。
//  - `rec_byte_num[15:0]`: 接收的有效字节数。
//  - `tx_start_en`: 发送开始信号。
//  - `tx_data[31:0]`: 待发送数据。
//  - `tx_byte_num[15:0]`: 发送有效字节数。
//  - `des_mac[47:0]`: 目标 MAC 地址。
//  - `des_ip[31:0]`: 目标 IP 地址。
//  - `tx_done`: 发送完成信号。
//  - `tx_req`: 读取数据请求信号。
//
//### 参数
//
//- `BOARD_MAC`: 开发板的 MAC 地址，默认为 `00:11:22:33:44:55`。
//- `BOARD_IP`: 开发板的 IP 地址，默认为 `192.168.1.10`。
//- `DES_MAC`: 目的 MAC 地址，默认为广播地址 `ff:ff:ff:ff:ff:ff`。
//- `DES_IP`: 目的 IP 地址，默认为 `192.168.1.102`。
//
//### 主要模块和信号连接
//
//#### 1. 接收模块 (`udp_rx`)
//
//- `udp_rx` 子模块处理以太网数据的接收操作。
//- 参数 `BOARD_MAC` 和 `BOARD_IP` 定义了本地设备的 MAC 和 IP 地址，用于判断接收的数据是否发送到当前设备。
//- 主要输出：
//  - `rec_pkt_done`: 数据包接收完成。
//  - `rec_en`: 数据接收使能。
//  - `rec_data`: 接收到的数据。
//  - `rec_byte_num`: 接收数据的字节数。
//
//#### 2. 发送模块 (`udp_tx`)
//
//- `udp_tx` 子模块负责将数据封装成以太网包并发送。
//- 参数 `DES_MAC` 和 `DES_IP` 定义了默认的目的 MAC 和 IP 地址。
//- 主要输入：
//  - `tx_start_en`: 启动发送的信号。
//  - `tx_data` 和 `tx_byte_num`: 要发送的数据和字节数。
//  - `des_mac` 和 `des_ip`: 目的地址。
//  - `crc_data`: CRC 校验数据。
//  - `crc_next`: 下一次 CRC 校验数据。
//- 输出：
//  - `tx_done`: 发送完成标志。
//  - `tx_req`: 数据请求信号。
//  - `gmii_tx_en` 和 `gmii_txd`: 发送到 GMII 的数据和使能信号。
//
//#### 3. CRC 校验模块 (`crc32_d8`)
//
//- `crc32_d8` 负责对数据进行 CRC 校验，用于确保数据完整性。
//- 输入信号 `crc_en` 控制 CRC 校验使能，`crc_clr` 控制复位信号。
//- 生成的 `crc_data` 和 `crc_next` 被 `udp_tx` 用于数据包的发送校验。
//
//### 工作流程
//
//1. **数据接收**：通过 `udp_rx` 子模块接收以太网数据包，并通过 `rec_pkt_done`、`rec_en` 和 `rec_data` 输出接收状态和数据。
//
//2. **数据发送**：
//   - 发送控制由 `tx_start_en` 触发。
//   - 待发送的数据通过 `tx_data` 和 `tx_byte_num` 输入，并在 `udp_tx` 内部封装成 UDP 包。
//   - `crc32_d8` 模块计算并校验数据完整性。
//   - 数据发送完成后，`tx_done` 信号拉高，表示一次数据发送的完成。
//


module udp_top(
    input                rst_n       , //复位信号，低电平有效
    //GMII接口
    input                gmii_rx_clk , //GMII接收数据时钟
    input                gmii_rx_dv  , //GMII输入数据有效信号
    input        [7:0]   gmii_rxd    , //GMII输入数据
    input                gmii_tx_clk , //GMII发送数据时钟    
    output               gmii_tx_en  , //GMII输出数据有效信号
    output       [7:0]   gmii_txd    , //GMII输出数据 
    //用户接口
    output               rec_pkt_done, //以太网单包数据接收完成信号
    output               rec_en      , //以太网接收的数据使能信号
    output       [31:0]  rec_data    , //以太网接收的数据
    output       [15:0]  rec_byte_num, //以太网接收的有效字节数 单位:byte     
    input                tx_start_en , //以太网开始发送信号
    input        [31:0]  tx_data     , //以太网待发送数据  
    input        [15:0]  tx_byte_num , //以太网发送的有效字节数 单位:byte  
    input        [47:0]  des_mac     , //发送的目标MAC地址
    input        [31:0]  des_ip      , //发送的目标IP地址    
    output               tx_done     , //以太网发送完成信号
    output               tx_req        //读数据请求信号    
    );

//parameter define
//开发板MAC地址 00-11-22-33-44-55
parameter BOARD_MAC = 48'h00_11_22_33_44_55;    
//开发板IP地址 192.168.1.10     
parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};
//目的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC  = 48'hff_ff_ff_ff_ff_ff;
//目的IP地址 192.168.1.102     
parameter  DES_IP   = {8'd192,8'd168,8'd1,8'd102};

//wire define
wire          crc_en  ; //CRC开始校验使能
wire          crc_clr ; //CRC数据复位信号 
wire  [7:0]   crc_d8  ; //输入待校验8位数据

wire  [31:0]  crc_data; //CRC校验数据
wire  [31:0]  crc_next; //CRC下次校验完成数据

//*****************************************************
//**                    main code
//*****************************************************

assign  crc_d8 = gmii_txd;

//以太网接收模块    
udp_rx 
   #(
    .BOARD_MAC       (BOARD_MAC),         //参数例化
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

//以太网发送模块
udp_tx
   #(
    .BOARD_MAC       (BOARD_MAC),         //参数例化
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

//以太网发送CRC校验模块
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