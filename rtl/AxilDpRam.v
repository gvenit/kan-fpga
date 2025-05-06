module AxilDpRam #(
    parameter ADDR_WIDTH = 9,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter DATA_WIDTH_ITRL = 16
) (
    input  wire                   clk,
    input  wire                   rst,

    /*-----------------------------------------
        Port A AXI-Lite
    -----------------------------------------*/

    input  wire [ADDR_WIDTH-1:0]  s_axil_a_awaddr,
    input  wire [2:0]             s_axil_a_awprot,
    input  wire                   s_axil_a_awvalid,
    output wire                   s_axil_a_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_a_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_a_wstrb,
    input  wire                   s_axil_a_wvalid,
    output wire                   s_axil_a_wready,
    output wire [1:0]             s_axil_a_bresp,
    output wire                   s_axil_a_bvalid,
    input  wire                   s_axil_a_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_a_araddr,
    input  wire [2:0]             s_axil_a_arprot,
    input  wire                   s_axil_a_arvalid,
    output wire                   s_axil_a_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_a_rdata,
    output wire [1:0]             s_axil_a_rresp,
    output wire                   s_axil_a_rvalid,
    input  wire                   s_axil_a_rready,

    /*-----------------------------------------
        Port B AXI-Lite
    -----------------------------------------*/

    input  wire [ADDR_WIDTH-1:0]  s_axil_b_awaddr,
    input  wire [2:0]             s_axil_b_awprot,
    input  wire                   s_axil_b_awvalid,
    output wire                   s_axil_b_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_b_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_b_wstrb,
    input  wire                   s_axil_b_wvalid,
    output wire                   s_axil_b_wready,
    output wire [1:0]             s_axil_b_bresp,
    output wire                   s_axil_b_bvalid,
    input  wire                   s_axil_b_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_b_araddr,
    input  wire [2:0]             s_axil_b_arprot,
    input  wire                   s_axil_b_arvalid,
    output wire                   s_axil_b_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_b_rdata,
    output wire [1:0]             s_axil_b_rresp,
    output wire                   s_axil_b_rvalid,
    input  wire                   s_axil_b_rready
);

/********************************
 Internal Signals & localparams
********************************/

localparam STRB_WIDTH_ITRL = (DATA_WIDTH_ITRL/8);

wire [ADDR_WIDTH-1:0]       s_axil_a_itrl_awaddr;
wire [2:0]                  s_axil_a_itrl_awprot;
wire                        s_axil_a_itrl_awvalid;
wire                        s_axil_a_itrl_awready;
wire [DATA_WIDTH_ITRL-1:0]  s_axil_a_itrl_wdata;
wire [STRB_WIDTH_ITRL-1:0]  s_axil_a_itrl_wstrb;
wire                        s_axil_a_itrl_wvalid;
wire                        s_axil_a_itrl_wready;
wire [1:0]                  s_axil_a_itrl_bresp;
wire                        s_axil_a_itrl_bvalid;
wire                        s_axil_a_itrl_bready;
wire [ADDR_WIDTH-1:0]       s_axil_a_itrl_araddr;
wire [2:0]                  s_axil_a_itrl_arprot;
wire                        s_axil_a_itrl_arvalid;
wire                        s_axil_a_itrl_arready;
wire [DATA_WIDTH_ITRL-1:0]  s_axil_a_itrl_rdata;
wire [1:0]                  s_axil_a_itrl_rresp;
wire                        s_axil_a_itrl_rvalid;
wire                        s_axil_a_itrl_rready;

wire [ADDR_WIDTH-1:0]       s_axil_b_itrl_awaddr;
wire [2:0]                  s_axil_b_itrl_awprot;
wire                        s_axil_b_itrl_awvalid;
wire                        s_axil_b_itrl_awready;
wire [DATA_WIDTH_ITRL-1:0]  s_axil_b_itrl_wdata;
wire [STRB_WIDTH_ITRL-1:0]  s_axil_b_itrl_wstrb;
wire                        s_axil_b_itrl_wvalid;
wire                        s_axil_b_itrl_wready;
wire [1:0]                  s_axil_b_itrl_bresp;
wire                        s_axil_b_itrl_bvalid;
wire                        s_axil_b_itrl_bready;
wire [ADDR_WIDTH-1:0]       s_axil_b_itrl_araddr;
wire [2:0]                  s_axil_b_itrl_arprot;
wire                        s_axil_b_itrl_arvalid;
wire                        s_axil_b_itrl_arready;
wire [DATA_WIDTH_ITRL-1:0]  s_axil_b_itrl_rdata;
wire [1:0]                  s_axil_b_itrl_rresp;
wire                        s_axil_b_itrl_rvalid;
wire                        s_axil_b_itrl_rready;

/********************************
 Direct Assignments
********************************/

/********************************
 Module instantiations
********************************/

axil_adapter #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .S_DATA_WIDTH(DATA_WIDTH),
    .M_DATA_WIDTH(DATA_WIDTH_ITRL)
) axil_adapter_port_a_inst (
    .clk(clk),
    .rst(rst),
    .s_axil_awaddr(s_axil_a_awaddr),
    .s_axil_awprot(s_axil_a_awprot),
    .s_axil_awvalid(s_axil_a_awvalid),
    .s_axil_awready(s_axil_a_awready),
    .s_axil_wdata(s_axil_a_wdata),
    .s_axil_wstrb(s_axil_a_wstrb),
    .s_axil_wvalid(s_axil_a_wvalid),
    .s_axil_wready(s_axil_a_wready),
    .s_axil_bresp(s_axil_a_bresp),
    .s_axil_bvalid(s_axil_a_bvalid),
    .s_axil_bready(s_axil_a_bready),
    .s_axil_araddr(s_axil_a_araddr),
    .s_axil_arprot(s_axil_a_arprot),
    .s_axil_arvalid(s_axil_a_arvalid),
    .s_axil_arready(s_axil_a_arready),
    .s_axil_rdata(s_axil_a_rdata),
    .s_axil_rresp(s_axil_a_rresp),
    .s_axil_rvalid(s_axil_a_rvalid),
    .s_axil_rready(s_axil_a_rready),
    .m_axil_awaddr(s_axil_a_itrl_awaddr),
    .m_axil_awprot(s_axil_a_itrl_awprot),
    .m_axil_awvalid(s_axil_a_itrl_awvalid),
    .m_axil_awready(s_axil_a_itrl_awready),
    .m_axil_wdata(s_axil_a_itrl_wdata),
    .m_axil_wstrb(s_axil_a_itrl_wstrb),
    .m_axil_wvalid(s_axil_a_itrl_wvalid),
    .m_axil_wready(s_axil_a_itrl_wready),
    .m_axil_bresp(s_axil_a_itrl_bresp),
    .m_axil_bvalid(s_axil_a_itrl_bvalid),
    .m_axil_bready(s_axil_a_itrl_bready),
    .m_axil_araddr(s_axil_a_itrl_araddr),
    .m_axil_arprot(s_axil_a_itrl_arprot),
    .m_axil_arvalid(s_axil_a_itrl_arvalid),
    .m_axil_arready(s_axil_a_itrl_arready),
    .m_axil_rdata(s_axil_a_itrl_rdata),
    .m_axil_rresp(s_axil_a_itrl_rresp),
    .m_axil_rvalid(s_axil_a_itrl_rvalid),
    .m_axil_rready(s_axil_a_itrl_rready)
);

axil_adapter #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .S_DATA_WIDTH(DATA_WIDTH),
    .M_DATA_WIDTH(DATA_WIDTH_ITRL)
) axil_adapter_port_b_inst (
    .clk(clk),
    .rst(rst),
    .s_axil_awaddr(s_axil_b_awaddr),
    .s_axil_awprot(s_axil_b_awprot),
    .s_axil_awvalid(s_axil_b_awvalid),
    .s_axil_awready(s_axil_b_awready),
    .s_axil_wdata(s_axil_b_wdata),
    .s_axil_wstrb(s_axil_b_wstrb),
    .s_axil_wvalid(s_axil_b_wvalid),
    .s_axil_wready(s_axil_b_wready),
    .s_axil_bresp(s_axil_b_bresp),
    .s_axil_bvalid(s_axil_b_bvalid),
    .s_axil_bready(s_axil_b_bready),
    .s_axil_araddr(s_axil_b_araddr),
    .s_axil_arprot(s_axil_b_arprot),
    .s_axil_arvalid(s_axil_b_arvalid),
    .s_axil_arready(s_axil_b_arready),
    .s_axil_rdata(s_axil_b_rdata),
    .s_axil_rresp(s_axil_b_rresp),
    .s_axil_rvalid(s_axil_b_rvalid),
    .s_axil_rready(s_axil_b_rready),
    .m_axil_awaddr(s_axil_b_itrl_awaddr),
    .m_axil_awprot(s_axil_b_itrl_awprot),
    .m_axil_awvalid(s_axil_b_itrl_awvalid),
    .m_axil_awready(s_axil_b_itrl_awready),
    .m_axil_wdata(s_axil_b_itrl_wdata),
    .m_axil_wstrb(s_axil_b_itrl_wstrb),
    .m_axil_wvalid(s_axil_b_itrl_wvalid),
    .m_axil_wready(s_axil_b_itrl_wready),
    .m_axil_bresp(s_axil_b_itrl_bresp),
    .m_axil_bvalid(s_axil_b_itrl_bvalid),
    .m_axil_bready(s_axil_b_itrl_bready),
    .m_axil_araddr(s_axil_b_itrl_araddr),
    .m_axil_arprot(s_axil_b_itrl_arprot),
    .m_axil_arvalid(s_axil_b_itrl_arvalid),
    .m_axil_arready(s_axil_b_itrl_arready),
    .m_axil_rdata(s_axil_b_itrl_rdata),
    .m_axil_rresp(s_axil_b_itrl_rresp),
    .m_axil_rvalid(s_axil_b_itrl_rvalid),
    .m_axil_rready(s_axil_b_itrl_rready)
);

AxilRam #(
    .DATA_WIDTH(DATA_WIDTH_ITRL),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIPELINE_OUTPUT(0)
) axil_dp_ram_inst (
    .clk(clk),
    .rstn(~rst),
    .s_axil_a_awaddr(s_axil_a_itrl_awaddr),
    .s_axil_a_awprot(s_axil_a_itrl_awprot),
    .s_axil_a_awvalid(s_axil_a_itrl_awvalid),
    .s_axil_a_awready(s_axil_a_itrl_awready),
    .s_axil_a_wdata(s_axil_a_itrl_wdata),
    .s_axil_a_wstrb(s_axil_a_itrl_wstrb),
    .s_axil_a_wvalid(s_axil_a_itrl_wvalid),
    .s_axil_a_wready(s_axil_a_itrl_wready),
    .s_axil_a_bresp(s_axil_a_itrl_bresp),
    .s_axil_a_bvalid(s_axil_a_itrl_bvalid),
    .s_axil_a_bready(s_axil_a_itrl_bready),
    .s_axil_a_araddr(s_axil_a_itrl_araddr),
    .s_axil_a_arprot(s_axil_a_itrl_arprot),
    .s_axil_a_arvalid(s_axil_a_itrl_arvalid),
    .s_axil_a_arready(s_axil_a_itrl_arready),
    .s_axil_a_rdata(s_axil_a_itrl_rdata),
    .s_axil_a_rresp(s_axil_a_itrl_rresp),
    .s_axil_a_rvalid(s_axil_a_itrl_rvalid),
    .s_axil_a_rready(s_axil_a_itrl_rready),
    .s_axil_b_awaddr(s_axil_b_itrl_awaddr),
    .s_axil_b_awprot(s_axil_b_itrl_awprot),
    .s_axil_b_awvalid(s_axil_b_itrl_awvalid),
    .s_axil_b_awready(s_axil_b_itrl_awready),
    .s_axil_b_wdata(s_axil_b_itrl_wdata),
    .s_axil_b_wstrb(s_axil_b_itrl_wstrb),
    .s_axil_b_wvalid(s_axil_b_itrl_wvalid),
    .s_axil_b_wready(s_axil_b_itrl_wready),
    .s_axil_b_bresp(s_axil_b_itrl_bresp),
    .s_axil_b_bvalid(s_axil_b_itrl_bvalid),
    .s_axil_b_bready(s_axil_b_itrl_bready),
    .s_axil_b_araddr(s_axil_b_itrl_araddr),
    .s_axil_b_arprot(s_axil_b_itrl_arprot),
    .s_axil_b_arvalid(s_axil_b_itrl_arvalid),
    .s_axil_b_arready(s_axil_b_itrl_arready),
    .s_axil_b_rdata(s_axil_b_itrl_rdata),
    .s_axil_b_rresp(s_axil_b_itrl_rresp),
    .s_axil_b_rvalid(s_axil_b_itrl_rvalid),
    .s_axil_b_rready(s_axil_b_itrl_rready)
);

    
endmodule