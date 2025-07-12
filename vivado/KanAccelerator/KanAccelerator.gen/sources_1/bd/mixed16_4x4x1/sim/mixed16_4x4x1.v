//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
//Date        : Sat Jul 12 16:00:25 2025
//Host        : GV-LAPTOP-LOQ running 64-bit major release  (build 9200)
//Command     : generate_target mixed16_4x4x1.bd
//Design      : mixed16_4x4x1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module m00_couplers_imp_UOWV13
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [9:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [9:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [9:0]auto_cc_to_m00_regslice_ARADDR;
  wire [2:0]auto_cc_to_m00_regslice_ARPROT;
  wire auto_cc_to_m00_regslice_ARREADY;
  wire auto_cc_to_m00_regslice_ARVALID;
  wire [9:0]auto_cc_to_m00_regslice_AWADDR;
  wire [2:0]auto_cc_to_m00_regslice_AWPROT;
  wire auto_cc_to_m00_regslice_AWREADY;
  wire auto_cc_to_m00_regslice_AWVALID;
  wire auto_cc_to_m00_regslice_BREADY;
  wire [1:0]auto_cc_to_m00_regslice_BRESP;
  wire auto_cc_to_m00_regslice_BVALID;
  wire [31:0]auto_cc_to_m00_regslice_RDATA;
  wire auto_cc_to_m00_regslice_RREADY;
  wire [1:0]auto_cc_to_m00_regslice_RRESP;
  wire auto_cc_to_m00_regslice_RVALID;
  wire [31:0]auto_cc_to_m00_regslice_WDATA;
  wire auto_cc_to_m00_regslice_WREADY;
  wire [3:0]auto_cc_to_m00_regslice_WSTRB;
  wire auto_cc_to_m00_regslice_WVALID;
  wire [31:0]m00_couplers_to_m00_data_fifo_ARADDR;
  wire [2:0]m00_couplers_to_m00_data_fifo_ARPROT;
  wire m00_couplers_to_m00_data_fifo_ARREADY;
  wire m00_couplers_to_m00_data_fifo_ARVALID;
  wire [31:0]m00_couplers_to_m00_data_fifo_AWADDR;
  wire [2:0]m00_couplers_to_m00_data_fifo_AWPROT;
  wire m00_couplers_to_m00_data_fifo_AWREADY;
  wire m00_couplers_to_m00_data_fifo_AWVALID;
  wire m00_couplers_to_m00_data_fifo_BREADY;
  wire [1:0]m00_couplers_to_m00_data_fifo_BRESP;
  wire m00_couplers_to_m00_data_fifo_BVALID;
  wire [31:0]m00_couplers_to_m00_data_fifo_RDATA;
  wire m00_couplers_to_m00_data_fifo_RREADY;
  wire [1:0]m00_couplers_to_m00_data_fifo_RRESP;
  wire m00_couplers_to_m00_data_fifo_RVALID;
  wire [31:0]m00_couplers_to_m00_data_fifo_WDATA;
  wire m00_couplers_to_m00_data_fifo_WREADY;
  wire [3:0]m00_couplers_to_m00_data_fifo_WSTRB;
  wire m00_couplers_to_m00_data_fifo_WVALID;
  wire [9:0]m00_data_fifo_to_auto_cc_ARADDR;
  wire [2:0]m00_data_fifo_to_auto_cc_ARPROT;
  wire m00_data_fifo_to_auto_cc_ARREADY;
  wire m00_data_fifo_to_auto_cc_ARVALID;
  wire [9:0]m00_data_fifo_to_auto_cc_AWADDR;
  wire [2:0]m00_data_fifo_to_auto_cc_AWPROT;
  wire m00_data_fifo_to_auto_cc_AWREADY;
  wire m00_data_fifo_to_auto_cc_AWVALID;
  wire m00_data_fifo_to_auto_cc_BREADY;
  wire [1:0]m00_data_fifo_to_auto_cc_BRESP;
  wire m00_data_fifo_to_auto_cc_BVALID;
  wire [31:0]m00_data_fifo_to_auto_cc_RDATA;
  wire m00_data_fifo_to_auto_cc_RREADY;
  wire [1:0]m00_data_fifo_to_auto_cc_RRESP;
  wire m00_data_fifo_to_auto_cc_RVALID;
  wire [31:0]m00_data_fifo_to_auto_cc_WDATA;
  wire m00_data_fifo_to_auto_cc_WREADY;
  wire [3:0]m00_data_fifo_to_auto_cc_WSTRB;
  wire m00_data_fifo_to_auto_cc_WVALID;
  wire [9:0]m00_regslice_to_m00_couplers_ARADDR;
  wire m00_regslice_to_m00_couplers_ARREADY;
  wire m00_regslice_to_m00_couplers_ARVALID;
  wire [9:0]m00_regslice_to_m00_couplers_AWADDR;
  wire m00_regslice_to_m00_couplers_AWREADY;
  wire m00_regslice_to_m00_couplers_AWVALID;
  wire m00_regslice_to_m00_couplers_BREADY;
  wire [1:0]m00_regslice_to_m00_couplers_BRESP;
  wire m00_regslice_to_m00_couplers_BVALID;
  wire [31:0]m00_regslice_to_m00_couplers_RDATA;
  wire m00_regslice_to_m00_couplers_RREADY;
  wire [1:0]m00_regslice_to_m00_couplers_RRESP;
  wire m00_regslice_to_m00_couplers_RVALID;
  wire [31:0]m00_regslice_to_m00_couplers_WDATA;
  wire m00_regslice_to_m00_couplers_WREADY;
  wire m00_regslice_to_m00_couplers_WVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[9:0] = m00_regslice_to_m00_couplers_ARADDR;
  assign M_AXI_arvalid = m00_regslice_to_m00_couplers_ARVALID;
  assign M_AXI_awaddr[9:0] = m00_regslice_to_m00_couplers_AWADDR;
  assign M_AXI_awvalid = m00_regslice_to_m00_couplers_AWVALID;
  assign M_AXI_bready = m00_regslice_to_m00_couplers_BREADY;
  assign M_AXI_rready = m00_regslice_to_m00_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m00_regslice_to_m00_couplers_WDATA;
  assign M_AXI_wvalid = m00_regslice_to_m00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m00_couplers_to_m00_data_fifo_ARREADY;
  assign S_AXI_awready = m00_couplers_to_m00_data_fifo_AWREADY;
  assign S_AXI_bresp[1:0] = m00_couplers_to_m00_data_fifo_BRESP;
  assign S_AXI_bvalid = m00_couplers_to_m00_data_fifo_BVALID;
  assign S_AXI_rdata[31:0] = m00_couplers_to_m00_data_fifo_RDATA;
  assign S_AXI_rresp[1:0] = m00_couplers_to_m00_data_fifo_RRESP;
  assign S_AXI_rvalid = m00_couplers_to_m00_data_fifo_RVALID;
  assign S_AXI_wready = m00_couplers_to_m00_data_fifo_WREADY;
  assign m00_couplers_to_m00_data_fifo_ARADDR = S_AXI_araddr[31:0];
  assign m00_couplers_to_m00_data_fifo_ARPROT = S_AXI_arprot[2:0];
  assign m00_couplers_to_m00_data_fifo_ARVALID = S_AXI_arvalid;
  assign m00_couplers_to_m00_data_fifo_AWADDR = S_AXI_awaddr[31:0];
  assign m00_couplers_to_m00_data_fifo_AWPROT = S_AXI_awprot[2:0];
  assign m00_couplers_to_m00_data_fifo_AWVALID = S_AXI_awvalid;
  assign m00_couplers_to_m00_data_fifo_BREADY = S_AXI_bready;
  assign m00_couplers_to_m00_data_fifo_RREADY = S_AXI_rready;
  assign m00_couplers_to_m00_data_fifo_WDATA = S_AXI_wdata[31:0];
  assign m00_couplers_to_m00_data_fifo_WSTRB = S_AXI_wstrb[3:0];
  assign m00_couplers_to_m00_data_fifo_WVALID = S_AXI_wvalid;
  assign m00_regslice_to_m00_couplers_ARREADY = M_AXI_arready;
  assign m00_regslice_to_m00_couplers_AWREADY = M_AXI_awready;
  assign m00_regslice_to_m00_couplers_BRESP = M_AXI_bresp[1:0];
  assign m00_regslice_to_m00_couplers_BVALID = M_AXI_bvalid;
  assign m00_regslice_to_m00_couplers_RDATA = M_AXI_rdata[31:0];
  assign m00_regslice_to_m00_couplers_RRESP = M_AXI_rresp[1:0];
  assign m00_regslice_to_m00_couplers_RVALID = M_AXI_rvalid;
  assign m00_regslice_to_m00_couplers_WREADY = M_AXI_wready;
  mixed16_4x4x1_auto_cc_0 auto_cc
       (.m_axi_aclk(M_ACLK_1),
        .m_axi_araddr(auto_cc_to_m00_regslice_ARADDR),
        .m_axi_aresetn(M_ARESETN_1),
        .m_axi_arprot(auto_cc_to_m00_regslice_ARPROT),
        .m_axi_arready(auto_cc_to_m00_regslice_ARREADY),
        .m_axi_arvalid(auto_cc_to_m00_regslice_ARVALID),
        .m_axi_awaddr(auto_cc_to_m00_regslice_AWADDR),
        .m_axi_awprot(auto_cc_to_m00_regslice_AWPROT),
        .m_axi_awready(auto_cc_to_m00_regslice_AWREADY),
        .m_axi_awvalid(auto_cc_to_m00_regslice_AWVALID),
        .m_axi_bready(auto_cc_to_m00_regslice_BREADY),
        .m_axi_bresp(auto_cc_to_m00_regslice_BRESP),
        .m_axi_bvalid(auto_cc_to_m00_regslice_BVALID),
        .m_axi_rdata(auto_cc_to_m00_regslice_RDATA),
        .m_axi_rready(auto_cc_to_m00_regslice_RREADY),
        .m_axi_rresp(auto_cc_to_m00_regslice_RRESP),
        .m_axi_rvalid(auto_cc_to_m00_regslice_RVALID),
        .m_axi_wdata(auto_cc_to_m00_regslice_WDATA),
        .m_axi_wready(auto_cc_to_m00_regslice_WREADY),
        .m_axi_wstrb(auto_cc_to_m00_regslice_WSTRB),
        .m_axi_wvalid(auto_cc_to_m00_regslice_WVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_araddr(m00_data_fifo_to_auto_cc_ARADDR),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_arprot(m00_data_fifo_to_auto_cc_ARPROT),
        .s_axi_arready(m00_data_fifo_to_auto_cc_ARREADY),
        .s_axi_arvalid(m00_data_fifo_to_auto_cc_ARVALID),
        .s_axi_awaddr(m00_data_fifo_to_auto_cc_AWADDR),
        .s_axi_awprot(m00_data_fifo_to_auto_cc_AWPROT),
        .s_axi_awready(m00_data_fifo_to_auto_cc_AWREADY),
        .s_axi_awvalid(m00_data_fifo_to_auto_cc_AWVALID),
        .s_axi_bready(m00_data_fifo_to_auto_cc_BREADY),
        .s_axi_bresp(m00_data_fifo_to_auto_cc_BRESP),
        .s_axi_bvalid(m00_data_fifo_to_auto_cc_BVALID),
        .s_axi_rdata(m00_data_fifo_to_auto_cc_RDATA),
        .s_axi_rready(m00_data_fifo_to_auto_cc_RREADY),
        .s_axi_rresp(m00_data_fifo_to_auto_cc_RRESP),
        .s_axi_rvalid(m00_data_fifo_to_auto_cc_RVALID),
        .s_axi_wdata(m00_data_fifo_to_auto_cc_WDATA),
        .s_axi_wready(m00_data_fifo_to_auto_cc_WREADY),
        .s_axi_wstrb(m00_data_fifo_to_auto_cc_WSTRB),
        .s_axi_wvalid(m00_data_fifo_to_auto_cc_WVALID));
  mixed16_4x4x1_m00_data_fifo_0 m00_data_fifo
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(m00_data_fifo_to_auto_cc_ARADDR),
        .m_axi_arprot(m00_data_fifo_to_auto_cc_ARPROT),
        .m_axi_arready(m00_data_fifo_to_auto_cc_ARREADY),
        .m_axi_arvalid(m00_data_fifo_to_auto_cc_ARVALID),
        .m_axi_awaddr(m00_data_fifo_to_auto_cc_AWADDR),
        .m_axi_awprot(m00_data_fifo_to_auto_cc_AWPROT),
        .m_axi_awready(m00_data_fifo_to_auto_cc_AWREADY),
        .m_axi_awvalid(m00_data_fifo_to_auto_cc_AWVALID),
        .m_axi_bready(m00_data_fifo_to_auto_cc_BREADY),
        .m_axi_bresp(m00_data_fifo_to_auto_cc_BRESP),
        .m_axi_bvalid(m00_data_fifo_to_auto_cc_BVALID),
        .m_axi_rdata(m00_data_fifo_to_auto_cc_RDATA),
        .m_axi_rready(m00_data_fifo_to_auto_cc_RREADY),
        .m_axi_rresp(m00_data_fifo_to_auto_cc_RRESP),
        .m_axi_rvalid(m00_data_fifo_to_auto_cc_RVALID),
        .m_axi_wdata(m00_data_fifo_to_auto_cc_WDATA),
        .m_axi_wready(m00_data_fifo_to_auto_cc_WREADY),
        .m_axi_wstrb(m00_data_fifo_to_auto_cc_WSTRB),
        .m_axi_wvalid(m00_data_fifo_to_auto_cc_WVALID),
        .s_axi_araddr(m00_couplers_to_m00_data_fifo_ARADDR[9:0]),
        .s_axi_arprot(m00_couplers_to_m00_data_fifo_ARPROT),
        .s_axi_arready(m00_couplers_to_m00_data_fifo_ARREADY),
        .s_axi_arvalid(m00_couplers_to_m00_data_fifo_ARVALID),
        .s_axi_awaddr(m00_couplers_to_m00_data_fifo_AWADDR[9:0]),
        .s_axi_awprot(m00_couplers_to_m00_data_fifo_AWPROT),
        .s_axi_awready(m00_couplers_to_m00_data_fifo_AWREADY),
        .s_axi_awvalid(m00_couplers_to_m00_data_fifo_AWVALID),
        .s_axi_bready(m00_couplers_to_m00_data_fifo_BREADY),
        .s_axi_bresp(m00_couplers_to_m00_data_fifo_BRESP),
        .s_axi_bvalid(m00_couplers_to_m00_data_fifo_BVALID),
        .s_axi_rdata(m00_couplers_to_m00_data_fifo_RDATA),
        .s_axi_rready(m00_couplers_to_m00_data_fifo_RREADY),
        .s_axi_rresp(m00_couplers_to_m00_data_fifo_RRESP),
        .s_axi_rvalid(m00_couplers_to_m00_data_fifo_RVALID),
        .s_axi_wdata(m00_couplers_to_m00_data_fifo_WDATA),
        .s_axi_wready(m00_couplers_to_m00_data_fifo_WREADY),
        .s_axi_wstrb(m00_couplers_to_m00_data_fifo_WSTRB),
        .s_axi_wvalid(m00_couplers_to_m00_data_fifo_WVALID));
  mixed16_4x4x1_m00_regslice_0 m00_regslice
       (.aclk(M_ACLK_1),
        .aresetn(M_ARESETN_1),
        .m_axi_araddr(m00_regslice_to_m00_couplers_ARADDR),
        .m_axi_arready(m00_regslice_to_m00_couplers_ARREADY),
        .m_axi_arvalid(m00_regslice_to_m00_couplers_ARVALID),
        .m_axi_awaddr(m00_regslice_to_m00_couplers_AWADDR),
        .m_axi_awready(m00_regslice_to_m00_couplers_AWREADY),
        .m_axi_awvalid(m00_regslice_to_m00_couplers_AWVALID),
        .m_axi_bready(m00_regslice_to_m00_couplers_BREADY),
        .m_axi_bresp(m00_regslice_to_m00_couplers_BRESP),
        .m_axi_bvalid(m00_regslice_to_m00_couplers_BVALID),
        .m_axi_rdata(m00_regslice_to_m00_couplers_RDATA),
        .m_axi_rready(m00_regslice_to_m00_couplers_RREADY),
        .m_axi_rresp(m00_regslice_to_m00_couplers_RRESP),
        .m_axi_rvalid(m00_regslice_to_m00_couplers_RVALID),
        .m_axi_wdata(m00_regslice_to_m00_couplers_WDATA),
        .m_axi_wready(m00_regslice_to_m00_couplers_WREADY),
        .m_axi_wvalid(m00_regslice_to_m00_couplers_WVALID),
        .s_axi_araddr(auto_cc_to_m00_regslice_ARADDR),
        .s_axi_arprot(auto_cc_to_m00_regslice_ARPROT),
        .s_axi_arready(auto_cc_to_m00_regslice_ARREADY),
        .s_axi_arvalid(auto_cc_to_m00_regslice_ARVALID),
        .s_axi_awaddr(auto_cc_to_m00_regslice_AWADDR),
        .s_axi_awprot(auto_cc_to_m00_regslice_AWPROT),
        .s_axi_awready(auto_cc_to_m00_regslice_AWREADY),
        .s_axi_awvalid(auto_cc_to_m00_regslice_AWVALID),
        .s_axi_bready(auto_cc_to_m00_regslice_BREADY),
        .s_axi_bresp(auto_cc_to_m00_regslice_BRESP),
        .s_axi_bvalid(auto_cc_to_m00_regslice_BVALID),
        .s_axi_rdata(auto_cc_to_m00_regslice_RDATA),
        .s_axi_rready(auto_cc_to_m00_regslice_RREADY),
        .s_axi_rresp(auto_cc_to_m00_regslice_RRESP),
        .s_axi_rvalid(auto_cc_to_m00_regslice_RVALID),
        .s_axi_wdata(auto_cc_to_m00_regslice_WDATA),
        .s_axi_wready(auto_cc_to_m00_regslice_WREADY),
        .s_axi_wstrb(auto_cc_to_m00_regslice_WSTRB),
        .s_axi_wvalid(auto_cc_to_m00_regslice_WVALID));
endmodule

module m01_couplers_imp_1W8JCUB
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [13:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [13:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [13:0]auto_cc_to_m01_regslice_ARADDR;
  wire [2:0]auto_cc_to_m01_regslice_ARPROT;
  wire auto_cc_to_m01_regslice_ARREADY;
  wire auto_cc_to_m01_regslice_ARVALID;
  wire [13:0]auto_cc_to_m01_regslice_AWADDR;
  wire [2:0]auto_cc_to_m01_regslice_AWPROT;
  wire auto_cc_to_m01_regslice_AWREADY;
  wire auto_cc_to_m01_regslice_AWVALID;
  wire auto_cc_to_m01_regslice_BREADY;
  wire [1:0]auto_cc_to_m01_regslice_BRESP;
  wire auto_cc_to_m01_regslice_BVALID;
  wire [31:0]auto_cc_to_m01_regslice_RDATA;
  wire auto_cc_to_m01_regslice_RREADY;
  wire [1:0]auto_cc_to_m01_regslice_RRESP;
  wire auto_cc_to_m01_regslice_RVALID;
  wire [31:0]auto_cc_to_m01_regslice_WDATA;
  wire auto_cc_to_m01_regslice_WREADY;
  wire [3:0]auto_cc_to_m01_regslice_WSTRB;
  wire auto_cc_to_m01_regslice_WVALID;
  wire [31:0]m01_couplers_to_m01_data_fifo_ARADDR;
  wire [2:0]m01_couplers_to_m01_data_fifo_ARPROT;
  wire m01_couplers_to_m01_data_fifo_ARREADY;
  wire m01_couplers_to_m01_data_fifo_ARVALID;
  wire [31:0]m01_couplers_to_m01_data_fifo_AWADDR;
  wire [2:0]m01_couplers_to_m01_data_fifo_AWPROT;
  wire m01_couplers_to_m01_data_fifo_AWREADY;
  wire m01_couplers_to_m01_data_fifo_AWVALID;
  wire m01_couplers_to_m01_data_fifo_BREADY;
  wire [1:0]m01_couplers_to_m01_data_fifo_BRESP;
  wire m01_couplers_to_m01_data_fifo_BVALID;
  wire [31:0]m01_couplers_to_m01_data_fifo_RDATA;
  wire m01_couplers_to_m01_data_fifo_RREADY;
  wire [1:0]m01_couplers_to_m01_data_fifo_RRESP;
  wire m01_couplers_to_m01_data_fifo_RVALID;
  wire [31:0]m01_couplers_to_m01_data_fifo_WDATA;
  wire m01_couplers_to_m01_data_fifo_WREADY;
  wire [3:0]m01_couplers_to_m01_data_fifo_WSTRB;
  wire m01_couplers_to_m01_data_fifo_WVALID;
  wire [13:0]m01_data_fifo_to_auto_cc_ARADDR;
  wire [2:0]m01_data_fifo_to_auto_cc_ARPROT;
  wire m01_data_fifo_to_auto_cc_ARREADY;
  wire m01_data_fifo_to_auto_cc_ARVALID;
  wire [13:0]m01_data_fifo_to_auto_cc_AWADDR;
  wire [2:0]m01_data_fifo_to_auto_cc_AWPROT;
  wire m01_data_fifo_to_auto_cc_AWREADY;
  wire m01_data_fifo_to_auto_cc_AWVALID;
  wire m01_data_fifo_to_auto_cc_BREADY;
  wire [1:0]m01_data_fifo_to_auto_cc_BRESP;
  wire m01_data_fifo_to_auto_cc_BVALID;
  wire [31:0]m01_data_fifo_to_auto_cc_RDATA;
  wire m01_data_fifo_to_auto_cc_RREADY;
  wire [1:0]m01_data_fifo_to_auto_cc_RRESP;
  wire m01_data_fifo_to_auto_cc_RVALID;
  wire [31:0]m01_data_fifo_to_auto_cc_WDATA;
  wire m01_data_fifo_to_auto_cc_WREADY;
  wire [3:0]m01_data_fifo_to_auto_cc_WSTRB;
  wire m01_data_fifo_to_auto_cc_WVALID;
  wire [13:0]m01_regslice_to_m01_couplers_ARADDR;
  wire [2:0]m01_regslice_to_m01_couplers_ARPROT;
  wire m01_regslice_to_m01_couplers_ARREADY;
  wire m01_regslice_to_m01_couplers_ARVALID;
  wire [13:0]m01_regslice_to_m01_couplers_AWADDR;
  wire [2:0]m01_regslice_to_m01_couplers_AWPROT;
  wire m01_regslice_to_m01_couplers_AWREADY;
  wire m01_regslice_to_m01_couplers_AWVALID;
  wire m01_regslice_to_m01_couplers_BREADY;
  wire [1:0]m01_regslice_to_m01_couplers_BRESP;
  wire m01_regslice_to_m01_couplers_BVALID;
  wire [31:0]m01_regslice_to_m01_couplers_RDATA;
  wire m01_regslice_to_m01_couplers_RREADY;
  wire [1:0]m01_regslice_to_m01_couplers_RRESP;
  wire m01_regslice_to_m01_couplers_RVALID;
  wire [31:0]m01_regslice_to_m01_couplers_WDATA;
  wire m01_regslice_to_m01_couplers_WREADY;
  wire [3:0]m01_regslice_to_m01_couplers_WSTRB;
  wire m01_regslice_to_m01_couplers_WVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[13:0] = m01_regslice_to_m01_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = m01_regslice_to_m01_couplers_ARPROT;
  assign M_AXI_arvalid = m01_regslice_to_m01_couplers_ARVALID;
  assign M_AXI_awaddr[13:0] = m01_regslice_to_m01_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = m01_regslice_to_m01_couplers_AWPROT;
  assign M_AXI_awvalid = m01_regslice_to_m01_couplers_AWVALID;
  assign M_AXI_bready = m01_regslice_to_m01_couplers_BREADY;
  assign M_AXI_rready = m01_regslice_to_m01_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m01_regslice_to_m01_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m01_regslice_to_m01_couplers_WSTRB;
  assign M_AXI_wvalid = m01_regslice_to_m01_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m01_couplers_to_m01_data_fifo_ARREADY;
  assign S_AXI_awready = m01_couplers_to_m01_data_fifo_AWREADY;
  assign S_AXI_bresp[1:0] = m01_couplers_to_m01_data_fifo_BRESP;
  assign S_AXI_bvalid = m01_couplers_to_m01_data_fifo_BVALID;
  assign S_AXI_rdata[31:0] = m01_couplers_to_m01_data_fifo_RDATA;
  assign S_AXI_rresp[1:0] = m01_couplers_to_m01_data_fifo_RRESP;
  assign S_AXI_rvalid = m01_couplers_to_m01_data_fifo_RVALID;
  assign S_AXI_wready = m01_couplers_to_m01_data_fifo_WREADY;
  assign m01_couplers_to_m01_data_fifo_ARADDR = S_AXI_araddr[31:0];
  assign m01_couplers_to_m01_data_fifo_ARPROT = S_AXI_arprot[2:0];
  assign m01_couplers_to_m01_data_fifo_ARVALID = S_AXI_arvalid;
  assign m01_couplers_to_m01_data_fifo_AWADDR = S_AXI_awaddr[31:0];
  assign m01_couplers_to_m01_data_fifo_AWPROT = S_AXI_awprot[2:0];
  assign m01_couplers_to_m01_data_fifo_AWVALID = S_AXI_awvalid;
  assign m01_couplers_to_m01_data_fifo_BREADY = S_AXI_bready;
  assign m01_couplers_to_m01_data_fifo_RREADY = S_AXI_rready;
  assign m01_couplers_to_m01_data_fifo_WDATA = S_AXI_wdata[31:0];
  assign m01_couplers_to_m01_data_fifo_WSTRB = S_AXI_wstrb[3:0];
  assign m01_couplers_to_m01_data_fifo_WVALID = S_AXI_wvalid;
  assign m01_regslice_to_m01_couplers_ARREADY = M_AXI_arready;
  assign m01_regslice_to_m01_couplers_AWREADY = M_AXI_awready;
  assign m01_regslice_to_m01_couplers_BRESP = M_AXI_bresp[1:0];
  assign m01_regslice_to_m01_couplers_BVALID = M_AXI_bvalid;
  assign m01_regslice_to_m01_couplers_RDATA = M_AXI_rdata[31:0];
  assign m01_regslice_to_m01_couplers_RRESP = M_AXI_rresp[1:0];
  assign m01_regslice_to_m01_couplers_RVALID = M_AXI_rvalid;
  assign m01_regslice_to_m01_couplers_WREADY = M_AXI_wready;
  mixed16_4x4x1_auto_cc_1 auto_cc
       (.m_axi_aclk(M_ACLK_1),
        .m_axi_araddr(auto_cc_to_m01_regslice_ARADDR),
        .m_axi_aresetn(M_ARESETN_1),
        .m_axi_arprot(auto_cc_to_m01_regslice_ARPROT),
        .m_axi_arready(auto_cc_to_m01_regslice_ARREADY),
        .m_axi_arvalid(auto_cc_to_m01_regslice_ARVALID),
        .m_axi_awaddr(auto_cc_to_m01_regslice_AWADDR),
        .m_axi_awprot(auto_cc_to_m01_regslice_AWPROT),
        .m_axi_awready(auto_cc_to_m01_regslice_AWREADY),
        .m_axi_awvalid(auto_cc_to_m01_regslice_AWVALID),
        .m_axi_bready(auto_cc_to_m01_regslice_BREADY),
        .m_axi_bresp(auto_cc_to_m01_regslice_BRESP),
        .m_axi_bvalid(auto_cc_to_m01_regslice_BVALID),
        .m_axi_rdata(auto_cc_to_m01_regslice_RDATA),
        .m_axi_rready(auto_cc_to_m01_regslice_RREADY),
        .m_axi_rresp(auto_cc_to_m01_regslice_RRESP),
        .m_axi_rvalid(auto_cc_to_m01_regslice_RVALID),
        .m_axi_wdata(auto_cc_to_m01_regslice_WDATA),
        .m_axi_wready(auto_cc_to_m01_regslice_WREADY),
        .m_axi_wstrb(auto_cc_to_m01_regslice_WSTRB),
        .m_axi_wvalid(auto_cc_to_m01_regslice_WVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_araddr(m01_data_fifo_to_auto_cc_ARADDR),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_arprot(m01_data_fifo_to_auto_cc_ARPROT),
        .s_axi_arready(m01_data_fifo_to_auto_cc_ARREADY),
        .s_axi_arvalid(m01_data_fifo_to_auto_cc_ARVALID),
        .s_axi_awaddr(m01_data_fifo_to_auto_cc_AWADDR),
        .s_axi_awprot(m01_data_fifo_to_auto_cc_AWPROT),
        .s_axi_awready(m01_data_fifo_to_auto_cc_AWREADY),
        .s_axi_awvalid(m01_data_fifo_to_auto_cc_AWVALID),
        .s_axi_bready(m01_data_fifo_to_auto_cc_BREADY),
        .s_axi_bresp(m01_data_fifo_to_auto_cc_BRESP),
        .s_axi_bvalid(m01_data_fifo_to_auto_cc_BVALID),
        .s_axi_rdata(m01_data_fifo_to_auto_cc_RDATA),
        .s_axi_rready(m01_data_fifo_to_auto_cc_RREADY),
        .s_axi_rresp(m01_data_fifo_to_auto_cc_RRESP),
        .s_axi_rvalid(m01_data_fifo_to_auto_cc_RVALID),
        .s_axi_wdata(m01_data_fifo_to_auto_cc_WDATA),
        .s_axi_wready(m01_data_fifo_to_auto_cc_WREADY),
        .s_axi_wstrb(m01_data_fifo_to_auto_cc_WSTRB),
        .s_axi_wvalid(m01_data_fifo_to_auto_cc_WVALID));
  mixed16_4x4x1_m01_data_fifo_0 m01_data_fifo
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(m01_data_fifo_to_auto_cc_ARADDR),
        .m_axi_arprot(m01_data_fifo_to_auto_cc_ARPROT),
        .m_axi_arready(m01_data_fifo_to_auto_cc_ARREADY),
        .m_axi_arvalid(m01_data_fifo_to_auto_cc_ARVALID),
        .m_axi_awaddr(m01_data_fifo_to_auto_cc_AWADDR),
        .m_axi_awprot(m01_data_fifo_to_auto_cc_AWPROT),
        .m_axi_awready(m01_data_fifo_to_auto_cc_AWREADY),
        .m_axi_awvalid(m01_data_fifo_to_auto_cc_AWVALID),
        .m_axi_bready(m01_data_fifo_to_auto_cc_BREADY),
        .m_axi_bresp(m01_data_fifo_to_auto_cc_BRESP),
        .m_axi_bvalid(m01_data_fifo_to_auto_cc_BVALID),
        .m_axi_rdata(m01_data_fifo_to_auto_cc_RDATA),
        .m_axi_rready(m01_data_fifo_to_auto_cc_RREADY),
        .m_axi_rresp(m01_data_fifo_to_auto_cc_RRESP),
        .m_axi_rvalid(m01_data_fifo_to_auto_cc_RVALID),
        .m_axi_wdata(m01_data_fifo_to_auto_cc_WDATA),
        .m_axi_wready(m01_data_fifo_to_auto_cc_WREADY),
        .m_axi_wstrb(m01_data_fifo_to_auto_cc_WSTRB),
        .m_axi_wvalid(m01_data_fifo_to_auto_cc_WVALID),
        .s_axi_araddr(m01_couplers_to_m01_data_fifo_ARADDR[13:0]),
        .s_axi_arprot(m01_couplers_to_m01_data_fifo_ARPROT),
        .s_axi_arready(m01_couplers_to_m01_data_fifo_ARREADY),
        .s_axi_arvalid(m01_couplers_to_m01_data_fifo_ARVALID),
        .s_axi_awaddr(m01_couplers_to_m01_data_fifo_AWADDR[13:0]),
        .s_axi_awprot(m01_couplers_to_m01_data_fifo_AWPROT),
        .s_axi_awready(m01_couplers_to_m01_data_fifo_AWREADY),
        .s_axi_awvalid(m01_couplers_to_m01_data_fifo_AWVALID),
        .s_axi_bready(m01_couplers_to_m01_data_fifo_BREADY),
        .s_axi_bresp(m01_couplers_to_m01_data_fifo_BRESP),
        .s_axi_bvalid(m01_couplers_to_m01_data_fifo_BVALID),
        .s_axi_rdata(m01_couplers_to_m01_data_fifo_RDATA),
        .s_axi_rready(m01_couplers_to_m01_data_fifo_RREADY),
        .s_axi_rresp(m01_couplers_to_m01_data_fifo_RRESP),
        .s_axi_rvalid(m01_couplers_to_m01_data_fifo_RVALID),
        .s_axi_wdata(m01_couplers_to_m01_data_fifo_WDATA),
        .s_axi_wready(m01_couplers_to_m01_data_fifo_WREADY),
        .s_axi_wstrb(m01_couplers_to_m01_data_fifo_WSTRB),
        .s_axi_wvalid(m01_couplers_to_m01_data_fifo_WVALID));
  mixed16_4x4x1_m01_regslice_0 m01_regslice
       (.aclk(M_ACLK_1),
        .aresetn(M_ARESETN_1),
        .m_axi_araddr(m01_regslice_to_m01_couplers_ARADDR),
        .m_axi_arprot(m01_regslice_to_m01_couplers_ARPROT),
        .m_axi_arready(m01_regslice_to_m01_couplers_ARREADY),
        .m_axi_arvalid(m01_regslice_to_m01_couplers_ARVALID),
        .m_axi_awaddr(m01_regslice_to_m01_couplers_AWADDR),
        .m_axi_awprot(m01_regslice_to_m01_couplers_AWPROT),
        .m_axi_awready(m01_regslice_to_m01_couplers_AWREADY),
        .m_axi_awvalid(m01_regslice_to_m01_couplers_AWVALID),
        .m_axi_bready(m01_regslice_to_m01_couplers_BREADY),
        .m_axi_bresp(m01_regslice_to_m01_couplers_BRESP),
        .m_axi_bvalid(m01_regslice_to_m01_couplers_BVALID),
        .m_axi_rdata(m01_regslice_to_m01_couplers_RDATA),
        .m_axi_rready(m01_regslice_to_m01_couplers_RREADY),
        .m_axi_rresp(m01_regslice_to_m01_couplers_RRESP),
        .m_axi_rvalid(m01_regslice_to_m01_couplers_RVALID),
        .m_axi_wdata(m01_regslice_to_m01_couplers_WDATA),
        .m_axi_wready(m01_regslice_to_m01_couplers_WREADY),
        .m_axi_wstrb(m01_regslice_to_m01_couplers_WSTRB),
        .m_axi_wvalid(m01_regslice_to_m01_couplers_WVALID),
        .s_axi_araddr(auto_cc_to_m01_regslice_ARADDR),
        .s_axi_arprot(auto_cc_to_m01_regslice_ARPROT),
        .s_axi_arready(auto_cc_to_m01_regslice_ARREADY),
        .s_axi_arvalid(auto_cc_to_m01_regslice_ARVALID),
        .s_axi_awaddr(auto_cc_to_m01_regslice_AWADDR),
        .s_axi_awprot(auto_cc_to_m01_regslice_AWPROT),
        .s_axi_awready(auto_cc_to_m01_regslice_AWREADY),
        .s_axi_awvalid(auto_cc_to_m01_regslice_AWVALID),
        .s_axi_bready(auto_cc_to_m01_regslice_BREADY),
        .s_axi_bresp(auto_cc_to_m01_regslice_BRESP),
        .s_axi_bvalid(auto_cc_to_m01_regslice_BVALID),
        .s_axi_rdata(auto_cc_to_m01_regslice_RDATA),
        .s_axi_rready(auto_cc_to_m01_regslice_RREADY),
        .s_axi_rresp(auto_cc_to_m01_regslice_RRESP),
        .s_axi_rvalid(auto_cc_to_m01_regslice_RVALID),
        .s_axi_wdata(auto_cc_to_m01_regslice_WDATA),
        .s_axi_wready(auto_cc_to_m01_regslice_WREADY),
        .s_axi_wstrb(auto_cc_to_m01_regslice_WSTRB),
        .s_axi_wvalid(auto_cc_to_m01_regslice_WVALID));
endmodule

module m02_couplers_imp_10CYTQ6
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [14:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [14:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]m02_couplers_to_m02_data_fifo_ARADDR;
  wire [2:0]m02_couplers_to_m02_data_fifo_ARPROT;
  wire m02_couplers_to_m02_data_fifo_ARREADY;
  wire m02_couplers_to_m02_data_fifo_ARVALID;
  wire [31:0]m02_couplers_to_m02_data_fifo_AWADDR;
  wire [2:0]m02_couplers_to_m02_data_fifo_AWPROT;
  wire m02_couplers_to_m02_data_fifo_AWREADY;
  wire m02_couplers_to_m02_data_fifo_AWVALID;
  wire m02_couplers_to_m02_data_fifo_BREADY;
  wire [1:0]m02_couplers_to_m02_data_fifo_BRESP;
  wire m02_couplers_to_m02_data_fifo_BVALID;
  wire [31:0]m02_couplers_to_m02_data_fifo_RDATA;
  wire m02_couplers_to_m02_data_fifo_RREADY;
  wire [1:0]m02_couplers_to_m02_data_fifo_RRESP;
  wire m02_couplers_to_m02_data_fifo_RVALID;
  wire [31:0]m02_couplers_to_m02_data_fifo_WDATA;
  wire m02_couplers_to_m02_data_fifo_WREADY;
  wire [3:0]m02_couplers_to_m02_data_fifo_WSTRB;
  wire m02_couplers_to_m02_data_fifo_WVALID;
  wire [14:0]m02_data_fifo_to_m02_regslice_ARADDR;
  wire [2:0]m02_data_fifo_to_m02_regslice_ARPROT;
  wire m02_data_fifo_to_m02_regslice_ARREADY;
  wire m02_data_fifo_to_m02_regslice_ARVALID;
  wire [14:0]m02_data_fifo_to_m02_regslice_AWADDR;
  wire [2:0]m02_data_fifo_to_m02_regslice_AWPROT;
  wire m02_data_fifo_to_m02_regslice_AWREADY;
  wire m02_data_fifo_to_m02_regslice_AWVALID;
  wire m02_data_fifo_to_m02_regslice_BREADY;
  wire [1:0]m02_data_fifo_to_m02_regslice_BRESP;
  wire m02_data_fifo_to_m02_regslice_BVALID;
  wire [31:0]m02_data_fifo_to_m02_regslice_RDATA;
  wire m02_data_fifo_to_m02_regslice_RREADY;
  wire [1:0]m02_data_fifo_to_m02_regslice_RRESP;
  wire m02_data_fifo_to_m02_regslice_RVALID;
  wire [31:0]m02_data_fifo_to_m02_regslice_WDATA;
  wire m02_data_fifo_to_m02_regslice_WREADY;
  wire [3:0]m02_data_fifo_to_m02_regslice_WSTRB;
  wire m02_data_fifo_to_m02_regslice_WVALID;
  wire [14:0]m02_regslice_to_m02_couplers_ARADDR;
  wire [2:0]m02_regslice_to_m02_couplers_ARPROT;
  wire m02_regslice_to_m02_couplers_ARREADY;
  wire m02_regslice_to_m02_couplers_ARVALID;
  wire [14:0]m02_regslice_to_m02_couplers_AWADDR;
  wire [2:0]m02_regslice_to_m02_couplers_AWPROT;
  wire m02_regslice_to_m02_couplers_AWREADY;
  wire m02_regslice_to_m02_couplers_AWVALID;
  wire m02_regslice_to_m02_couplers_BREADY;
  wire [1:0]m02_regslice_to_m02_couplers_BRESP;
  wire m02_regslice_to_m02_couplers_BVALID;
  wire [31:0]m02_regslice_to_m02_couplers_RDATA;
  wire m02_regslice_to_m02_couplers_RREADY;
  wire [1:0]m02_regslice_to_m02_couplers_RRESP;
  wire m02_regslice_to_m02_couplers_RVALID;
  wire [31:0]m02_regslice_to_m02_couplers_WDATA;
  wire m02_regslice_to_m02_couplers_WREADY;
  wire [3:0]m02_regslice_to_m02_couplers_WSTRB;
  wire m02_regslice_to_m02_couplers_WVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[14:0] = m02_regslice_to_m02_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = m02_regslice_to_m02_couplers_ARPROT;
  assign M_AXI_arvalid = m02_regslice_to_m02_couplers_ARVALID;
  assign M_AXI_awaddr[14:0] = m02_regslice_to_m02_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = m02_regslice_to_m02_couplers_AWPROT;
  assign M_AXI_awvalid = m02_regslice_to_m02_couplers_AWVALID;
  assign M_AXI_bready = m02_regslice_to_m02_couplers_BREADY;
  assign M_AXI_rready = m02_regslice_to_m02_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m02_regslice_to_m02_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m02_regslice_to_m02_couplers_WSTRB;
  assign M_AXI_wvalid = m02_regslice_to_m02_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m02_couplers_to_m02_data_fifo_ARREADY;
  assign S_AXI_awready = m02_couplers_to_m02_data_fifo_AWREADY;
  assign S_AXI_bresp[1:0] = m02_couplers_to_m02_data_fifo_BRESP;
  assign S_AXI_bvalid = m02_couplers_to_m02_data_fifo_BVALID;
  assign S_AXI_rdata[31:0] = m02_couplers_to_m02_data_fifo_RDATA;
  assign S_AXI_rresp[1:0] = m02_couplers_to_m02_data_fifo_RRESP;
  assign S_AXI_rvalid = m02_couplers_to_m02_data_fifo_RVALID;
  assign S_AXI_wready = m02_couplers_to_m02_data_fifo_WREADY;
  assign m02_couplers_to_m02_data_fifo_ARADDR = S_AXI_araddr[31:0];
  assign m02_couplers_to_m02_data_fifo_ARPROT = S_AXI_arprot[2:0];
  assign m02_couplers_to_m02_data_fifo_ARVALID = S_AXI_arvalid;
  assign m02_couplers_to_m02_data_fifo_AWADDR = S_AXI_awaddr[31:0];
  assign m02_couplers_to_m02_data_fifo_AWPROT = S_AXI_awprot[2:0];
  assign m02_couplers_to_m02_data_fifo_AWVALID = S_AXI_awvalid;
  assign m02_couplers_to_m02_data_fifo_BREADY = S_AXI_bready;
  assign m02_couplers_to_m02_data_fifo_RREADY = S_AXI_rready;
  assign m02_couplers_to_m02_data_fifo_WDATA = S_AXI_wdata[31:0];
  assign m02_couplers_to_m02_data_fifo_WSTRB = S_AXI_wstrb[3:0];
  assign m02_couplers_to_m02_data_fifo_WVALID = S_AXI_wvalid;
  assign m02_regslice_to_m02_couplers_ARREADY = M_AXI_arready;
  assign m02_regslice_to_m02_couplers_AWREADY = M_AXI_awready;
  assign m02_regslice_to_m02_couplers_BRESP = M_AXI_bresp[1:0];
  assign m02_regslice_to_m02_couplers_BVALID = M_AXI_bvalid;
  assign m02_regslice_to_m02_couplers_RDATA = M_AXI_rdata[31:0];
  assign m02_regslice_to_m02_couplers_RRESP = M_AXI_rresp[1:0];
  assign m02_regslice_to_m02_couplers_RVALID = M_AXI_rvalid;
  assign m02_regslice_to_m02_couplers_WREADY = M_AXI_wready;
  mixed16_4x4x1_m02_data_fifo_0 m02_data_fifo
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(m02_data_fifo_to_m02_regslice_ARADDR),
        .m_axi_arprot(m02_data_fifo_to_m02_regslice_ARPROT),
        .m_axi_arready(m02_data_fifo_to_m02_regslice_ARREADY),
        .m_axi_arvalid(m02_data_fifo_to_m02_regslice_ARVALID),
        .m_axi_awaddr(m02_data_fifo_to_m02_regslice_AWADDR),
        .m_axi_awprot(m02_data_fifo_to_m02_regslice_AWPROT),
        .m_axi_awready(m02_data_fifo_to_m02_regslice_AWREADY),
        .m_axi_awvalid(m02_data_fifo_to_m02_regslice_AWVALID),
        .m_axi_bready(m02_data_fifo_to_m02_regslice_BREADY),
        .m_axi_bresp(m02_data_fifo_to_m02_regslice_BRESP),
        .m_axi_bvalid(m02_data_fifo_to_m02_regslice_BVALID),
        .m_axi_rdata(m02_data_fifo_to_m02_regslice_RDATA),
        .m_axi_rready(m02_data_fifo_to_m02_regslice_RREADY),
        .m_axi_rresp(m02_data_fifo_to_m02_regslice_RRESP),
        .m_axi_rvalid(m02_data_fifo_to_m02_regslice_RVALID),
        .m_axi_wdata(m02_data_fifo_to_m02_regslice_WDATA),
        .m_axi_wready(m02_data_fifo_to_m02_regslice_WREADY),
        .m_axi_wstrb(m02_data_fifo_to_m02_regslice_WSTRB),
        .m_axi_wvalid(m02_data_fifo_to_m02_regslice_WVALID),
        .s_axi_araddr(m02_couplers_to_m02_data_fifo_ARADDR[14:0]),
        .s_axi_arprot(m02_couplers_to_m02_data_fifo_ARPROT),
        .s_axi_arready(m02_couplers_to_m02_data_fifo_ARREADY),
        .s_axi_arvalid(m02_couplers_to_m02_data_fifo_ARVALID),
        .s_axi_awaddr(m02_couplers_to_m02_data_fifo_AWADDR[14:0]),
        .s_axi_awprot(m02_couplers_to_m02_data_fifo_AWPROT),
        .s_axi_awready(m02_couplers_to_m02_data_fifo_AWREADY),
        .s_axi_awvalid(m02_couplers_to_m02_data_fifo_AWVALID),
        .s_axi_bready(m02_couplers_to_m02_data_fifo_BREADY),
        .s_axi_bresp(m02_couplers_to_m02_data_fifo_BRESP),
        .s_axi_bvalid(m02_couplers_to_m02_data_fifo_BVALID),
        .s_axi_rdata(m02_couplers_to_m02_data_fifo_RDATA),
        .s_axi_rready(m02_couplers_to_m02_data_fifo_RREADY),
        .s_axi_rresp(m02_couplers_to_m02_data_fifo_RRESP),
        .s_axi_rvalid(m02_couplers_to_m02_data_fifo_RVALID),
        .s_axi_wdata(m02_couplers_to_m02_data_fifo_WDATA),
        .s_axi_wready(m02_couplers_to_m02_data_fifo_WREADY),
        .s_axi_wstrb(m02_couplers_to_m02_data_fifo_WSTRB),
        .s_axi_wvalid(m02_couplers_to_m02_data_fifo_WVALID));
  mixed16_4x4x1_m02_regslice_0 m02_regslice
       (.aclk(M_ACLK_1),
        .aresetn(M_ARESETN_1),
        .m_axi_araddr(m02_regslice_to_m02_couplers_ARADDR),
        .m_axi_arprot(m02_regslice_to_m02_couplers_ARPROT),
        .m_axi_arready(m02_regslice_to_m02_couplers_ARREADY),
        .m_axi_arvalid(m02_regslice_to_m02_couplers_ARVALID),
        .m_axi_awaddr(m02_regslice_to_m02_couplers_AWADDR),
        .m_axi_awprot(m02_regslice_to_m02_couplers_AWPROT),
        .m_axi_awready(m02_regslice_to_m02_couplers_AWREADY),
        .m_axi_awvalid(m02_regslice_to_m02_couplers_AWVALID),
        .m_axi_bready(m02_regslice_to_m02_couplers_BREADY),
        .m_axi_bresp(m02_regslice_to_m02_couplers_BRESP),
        .m_axi_bvalid(m02_regslice_to_m02_couplers_BVALID),
        .m_axi_rdata(m02_regslice_to_m02_couplers_RDATA),
        .m_axi_rready(m02_regslice_to_m02_couplers_RREADY),
        .m_axi_rresp(m02_regslice_to_m02_couplers_RRESP),
        .m_axi_rvalid(m02_regslice_to_m02_couplers_RVALID),
        .m_axi_wdata(m02_regslice_to_m02_couplers_WDATA),
        .m_axi_wready(m02_regslice_to_m02_couplers_WREADY),
        .m_axi_wstrb(m02_regslice_to_m02_couplers_WSTRB),
        .m_axi_wvalid(m02_regslice_to_m02_couplers_WVALID),
        .s_axi_araddr(m02_data_fifo_to_m02_regslice_ARADDR),
        .s_axi_arprot(m02_data_fifo_to_m02_regslice_ARPROT),
        .s_axi_arready(m02_data_fifo_to_m02_regslice_ARREADY),
        .s_axi_arvalid(m02_data_fifo_to_m02_regslice_ARVALID),
        .s_axi_awaddr(m02_data_fifo_to_m02_regslice_AWADDR),
        .s_axi_awprot(m02_data_fifo_to_m02_regslice_AWPROT),
        .s_axi_awready(m02_data_fifo_to_m02_regslice_AWREADY),
        .s_axi_awvalid(m02_data_fifo_to_m02_regslice_AWVALID),
        .s_axi_bready(m02_data_fifo_to_m02_regslice_BREADY),
        .s_axi_bresp(m02_data_fifo_to_m02_regslice_BRESP),
        .s_axi_bvalid(m02_data_fifo_to_m02_regslice_BVALID),
        .s_axi_rdata(m02_data_fifo_to_m02_regslice_RDATA),
        .s_axi_rready(m02_data_fifo_to_m02_regslice_RREADY),
        .s_axi_rresp(m02_data_fifo_to_m02_regslice_RRESP),
        .s_axi_rvalid(m02_data_fifo_to_m02_regslice_RVALID),
        .s_axi_wdata(m02_data_fifo_to_m02_regslice_WDATA),
        .s_axi_wready(m02_data_fifo_to_m02_regslice_WREADY),
        .s_axi_wstrb(m02_data_fifo_to_m02_regslice_WSTRB),
        .s_axi_wvalid(m02_data_fifo_to_m02_regslice_WVALID));
endmodule

module m03_couplers_imp_6SFL0Q
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [9:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [9:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]m03_couplers_to_m03_data_fifo_ARADDR;
  wire [2:0]m03_couplers_to_m03_data_fifo_ARPROT;
  wire m03_couplers_to_m03_data_fifo_ARREADY;
  wire m03_couplers_to_m03_data_fifo_ARVALID;
  wire [31:0]m03_couplers_to_m03_data_fifo_AWADDR;
  wire [2:0]m03_couplers_to_m03_data_fifo_AWPROT;
  wire m03_couplers_to_m03_data_fifo_AWREADY;
  wire m03_couplers_to_m03_data_fifo_AWVALID;
  wire m03_couplers_to_m03_data_fifo_BREADY;
  wire [1:0]m03_couplers_to_m03_data_fifo_BRESP;
  wire m03_couplers_to_m03_data_fifo_BVALID;
  wire [31:0]m03_couplers_to_m03_data_fifo_RDATA;
  wire m03_couplers_to_m03_data_fifo_RREADY;
  wire [1:0]m03_couplers_to_m03_data_fifo_RRESP;
  wire m03_couplers_to_m03_data_fifo_RVALID;
  wire [31:0]m03_couplers_to_m03_data_fifo_WDATA;
  wire m03_couplers_to_m03_data_fifo_WREADY;
  wire [3:0]m03_couplers_to_m03_data_fifo_WSTRB;
  wire m03_couplers_to_m03_data_fifo_WVALID;
  wire [9:0]m03_data_fifo_to_m03_regslice_ARADDR;
  wire [2:0]m03_data_fifo_to_m03_regslice_ARPROT;
  wire m03_data_fifo_to_m03_regslice_ARREADY;
  wire m03_data_fifo_to_m03_regslice_ARVALID;
  wire [9:0]m03_data_fifo_to_m03_regslice_AWADDR;
  wire [2:0]m03_data_fifo_to_m03_regslice_AWPROT;
  wire m03_data_fifo_to_m03_regslice_AWREADY;
  wire m03_data_fifo_to_m03_regslice_AWVALID;
  wire m03_data_fifo_to_m03_regslice_BREADY;
  wire [1:0]m03_data_fifo_to_m03_regslice_BRESP;
  wire m03_data_fifo_to_m03_regslice_BVALID;
  wire [31:0]m03_data_fifo_to_m03_regslice_RDATA;
  wire m03_data_fifo_to_m03_regslice_RREADY;
  wire [1:0]m03_data_fifo_to_m03_regslice_RRESP;
  wire m03_data_fifo_to_m03_regslice_RVALID;
  wire [31:0]m03_data_fifo_to_m03_regslice_WDATA;
  wire m03_data_fifo_to_m03_regslice_WREADY;
  wire [3:0]m03_data_fifo_to_m03_regslice_WSTRB;
  wire m03_data_fifo_to_m03_regslice_WVALID;
  wire [9:0]m03_regslice_to_m03_couplers_ARADDR;
  wire [2:0]m03_regslice_to_m03_couplers_ARPROT;
  wire m03_regslice_to_m03_couplers_ARREADY;
  wire m03_regslice_to_m03_couplers_ARVALID;
  wire [9:0]m03_regslice_to_m03_couplers_AWADDR;
  wire [2:0]m03_regslice_to_m03_couplers_AWPROT;
  wire m03_regslice_to_m03_couplers_AWREADY;
  wire m03_regslice_to_m03_couplers_AWVALID;
  wire m03_regslice_to_m03_couplers_BREADY;
  wire [1:0]m03_regslice_to_m03_couplers_BRESP;
  wire m03_regslice_to_m03_couplers_BVALID;
  wire [31:0]m03_regslice_to_m03_couplers_RDATA;
  wire m03_regslice_to_m03_couplers_RREADY;
  wire [1:0]m03_regslice_to_m03_couplers_RRESP;
  wire m03_regslice_to_m03_couplers_RVALID;
  wire [31:0]m03_regslice_to_m03_couplers_WDATA;
  wire m03_regslice_to_m03_couplers_WREADY;
  wire [3:0]m03_regslice_to_m03_couplers_WSTRB;
  wire m03_regslice_to_m03_couplers_WVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[9:0] = m03_regslice_to_m03_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = m03_regslice_to_m03_couplers_ARPROT;
  assign M_AXI_arvalid = m03_regslice_to_m03_couplers_ARVALID;
  assign M_AXI_awaddr[9:0] = m03_regslice_to_m03_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = m03_regslice_to_m03_couplers_AWPROT;
  assign M_AXI_awvalid = m03_regslice_to_m03_couplers_AWVALID;
  assign M_AXI_bready = m03_regslice_to_m03_couplers_BREADY;
  assign M_AXI_rready = m03_regslice_to_m03_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m03_regslice_to_m03_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m03_regslice_to_m03_couplers_WSTRB;
  assign M_AXI_wvalid = m03_regslice_to_m03_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m03_couplers_to_m03_data_fifo_ARREADY;
  assign S_AXI_awready = m03_couplers_to_m03_data_fifo_AWREADY;
  assign S_AXI_bresp[1:0] = m03_couplers_to_m03_data_fifo_BRESP;
  assign S_AXI_bvalid = m03_couplers_to_m03_data_fifo_BVALID;
  assign S_AXI_rdata[31:0] = m03_couplers_to_m03_data_fifo_RDATA;
  assign S_AXI_rresp[1:0] = m03_couplers_to_m03_data_fifo_RRESP;
  assign S_AXI_rvalid = m03_couplers_to_m03_data_fifo_RVALID;
  assign S_AXI_wready = m03_couplers_to_m03_data_fifo_WREADY;
  assign m03_couplers_to_m03_data_fifo_ARADDR = S_AXI_araddr[31:0];
  assign m03_couplers_to_m03_data_fifo_ARPROT = S_AXI_arprot[2:0];
  assign m03_couplers_to_m03_data_fifo_ARVALID = S_AXI_arvalid;
  assign m03_couplers_to_m03_data_fifo_AWADDR = S_AXI_awaddr[31:0];
  assign m03_couplers_to_m03_data_fifo_AWPROT = S_AXI_awprot[2:0];
  assign m03_couplers_to_m03_data_fifo_AWVALID = S_AXI_awvalid;
  assign m03_couplers_to_m03_data_fifo_BREADY = S_AXI_bready;
  assign m03_couplers_to_m03_data_fifo_RREADY = S_AXI_rready;
  assign m03_couplers_to_m03_data_fifo_WDATA = S_AXI_wdata[31:0];
  assign m03_couplers_to_m03_data_fifo_WSTRB = S_AXI_wstrb[3:0];
  assign m03_couplers_to_m03_data_fifo_WVALID = S_AXI_wvalid;
  assign m03_regslice_to_m03_couplers_ARREADY = M_AXI_arready;
  assign m03_regslice_to_m03_couplers_AWREADY = M_AXI_awready;
  assign m03_regslice_to_m03_couplers_BRESP = M_AXI_bresp[1:0];
  assign m03_regslice_to_m03_couplers_BVALID = M_AXI_bvalid;
  assign m03_regslice_to_m03_couplers_RDATA = M_AXI_rdata[31:0];
  assign m03_regslice_to_m03_couplers_RRESP = M_AXI_rresp[1:0];
  assign m03_regslice_to_m03_couplers_RVALID = M_AXI_rvalid;
  assign m03_regslice_to_m03_couplers_WREADY = M_AXI_wready;
  mixed16_4x4x1_m03_data_fifo_0 m03_data_fifo
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(m03_data_fifo_to_m03_regslice_ARADDR),
        .m_axi_arprot(m03_data_fifo_to_m03_regslice_ARPROT),
        .m_axi_arready(m03_data_fifo_to_m03_regslice_ARREADY),
        .m_axi_arvalid(m03_data_fifo_to_m03_regslice_ARVALID),
        .m_axi_awaddr(m03_data_fifo_to_m03_regslice_AWADDR),
        .m_axi_awprot(m03_data_fifo_to_m03_regslice_AWPROT),
        .m_axi_awready(m03_data_fifo_to_m03_regslice_AWREADY),
        .m_axi_awvalid(m03_data_fifo_to_m03_regslice_AWVALID),
        .m_axi_bready(m03_data_fifo_to_m03_regslice_BREADY),
        .m_axi_bresp(m03_data_fifo_to_m03_regslice_BRESP),
        .m_axi_bvalid(m03_data_fifo_to_m03_regslice_BVALID),
        .m_axi_rdata(m03_data_fifo_to_m03_regslice_RDATA),
        .m_axi_rready(m03_data_fifo_to_m03_regslice_RREADY),
        .m_axi_rresp(m03_data_fifo_to_m03_regslice_RRESP),
        .m_axi_rvalid(m03_data_fifo_to_m03_regslice_RVALID),
        .m_axi_wdata(m03_data_fifo_to_m03_regslice_WDATA),
        .m_axi_wready(m03_data_fifo_to_m03_regslice_WREADY),
        .m_axi_wstrb(m03_data_fifo_to_m03_regslice_WSTRB),
        .m_axi_wvalid(m03_data_fifo_to_m03_regslice_WVALID),
        .s_axi_araddr(m03_couplers_to_m03_data_fifo_ARADDR[9:0]),
        .s_axi_arprot(m03_couplers_to_m03_data_fifo_ARPROT),
        .s_axi_arready(m03_couplers_to_m03_data_fifo_ARREADY),
        .s_axi_arvalid(m03_couplers_to_m03_data_fifo_ARVALID),
        .s_axi_awaddr(m03_couplers_to_m03_data_fifo_AWADDR[9:0]),
        .s_axi_awprot(m03_couplers_to_m03_data_fifo_AWPROT),
        .s_axi_awready(m03_couplers_to_m03_data_fifo_AWREADY),
        .s_axi_awvalid(m03_couplers_to_m03_data_fifo_AWVALID),
        .s_axi_bready(m03_couplers_to_m03_data_fifo_BREADY),
        .s_axi_bresp(m03_couplers_to_m03_data_fifo_BRESP),
        .s_axi_bvalid(m03_couplers_to_m03_data_fifo_BVALID),
        .s_axi_rdata(m03_couplers_to_m03_data_fifo_RDATA),
        .s_axi_rready(m03_couplers_to_m03_data_fifo_RREADY),
        .s_axi_rresp(m03_couplers_to_m03_data_fifo_RRESP),
        .s_axi_rvalid(m03_couplers_to_m03_data_fifo_RVALID),
        .s_axi_wdata(m03_couplers_to_m03_data_fifo_WDATA),
        .s_axi_wready(m03_couplers_to_m03_data_fifo_WREADY),
        .s_axi_wstrb(m03_couplers_to_m03_data_fifo_WSTRB),
        .s_axi_wvalid(m03_couplers_to_m03_data_fifo_WVALID));
  mixed16_4x4x1_m03_regslice_0 m03_regslice
       (.aclk(M_ACLK_1),
        .aresetn(M_ARESETN_1),
        .m_axi_araddr(m03_regslice_to_m03_couplers_ARADDR),
        .m_axi_arprot(m03_regslice_to_m03_couplers_ARPROT),
        .m_axi_arready(m03_regslice_to_m03_couplers_ARREADY),
        .m_axi_arvalid(m03_regslice_to_m03_couplers_ARVALID),
        .m_axi_awaddr(m03_regslice_to_m03_couplers_AWADDR),
        .m_axi_awprot(m03_regslice_to_m03_couplers_AWPROT),
        .m_axi_awready(m03_regslice_to_m03_couplers_AWREADY),
        .m_axi_awvalid(m03_regslice_to_m03_couplers_AWVALID),
        .m_axi_bready(m03_regslice_to_m03_couplers_BREADY),
        .m_axi_bresp(m03_regslice_to_m03_couplers_BRESP),
        .m_axi_bvalid(m03_regslice_to_m03_couplers_BVALID),
        .m_axi_rdata(m03_regslice_to_m03_couplers_RDATA),
        .m_axi_rready(m03_regslice_to_m03_couplers_RREADY),
        .m_axi_rresp(m03_regslice_to_m03_couplers_RRESP),
        .m_axi_rvalid(m03_regslice_to_m03_couplers_RVALID),
        .m_axi_wdata(m03_regslice_to_m03_couplers_WDATA),
        .m_axi_wready(m03_regslice_to_m03_couplers_WREADY),
        .m_axi_wstrb(m03_regslice_to_m03_couplers_WSTRB),
        .m_axi_wvalid(m03_regslice_to_m03_couplers_WVALID),
        .s_axi_araddr(m03_data_fifo_to_m03_regslice_ARADDR),
        .s_axi_arprot(m03_data_fifo_to_m03_regslice_ARPROT),
        .s_axi_arready(m03_data_fifo_to_m03_regslice_ARREADY),
        .s_axi_arvalid(m03_data_fifo_to_m03_regslice_ARVALID),
        .s_axi_awaddr(m03_data_fifo_to_m03_regslice_AWADDR),
        .s_axi_awprot(m03_data_fifo_to_m03_regslice_AWPROT),
        .s_axi_awready(m03_data_fifo_to_m03_regslice_AWREADY),
        .s_axi_awvalid(m03_data_fifo_to_m03_regslice_AWVALID),
        .s_axi_bready(m03_data_fifo_to_m03_regslice_BREADY),
        .s_axi_bresp(m03_data_fifo_to_m03_regslice_BRESP),
        .s_axi_bvalid(m03_data_fifo_to_m03_regslice_BVALID),
        .s_axi_rdata(m03_data_fifo_to_m03_regslice_RDATA),
        .s_axi_rready(m03_data_fifo_to_m03_regslice_RREADY),
        .s_axi_rresp(m03_data_fifo_to_m03_regslice_RRESP),
        .s_axi_rvalid(m03_data_fifo_to_m03_regslice_RVALID),
        .s_axi_wdata(m03_data_fifo_to_m03_regslice_WDATA),
        .s_axi_wready(m03_data_fifo_to_m03_regslice_WREADY),
        .s_axi_wstrb(m03_data_fifo_to_m03_regslice_WSTRB),
        .s_axi_wvalid(m03_data_fifo_to_m03_regslice_WVALID));
endmodule

module m04_couplers_imp_UQAJR8
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [9:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [9:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]m04_couplers_to_m04_data_fifo_ARADDR;
  wire [2:0]m04_couplers_to_m04_data_fifo_ARPROT;
  wire m04_couplers_to_m04_data_fifo_ARREADY;
  wire m04_couplers_to_m04_data_fifo_ARVALID;
  wire [31:0]m04_couplers_to_m04_data_fifo_AWADDR;
  wire [2:0]m04_couplers_to_m04_data_fifo_AWPROT;
  wire m04_couplers_to_m04_data_fifo_AWREADY;
  wire m04_couplers_to_m04_data_fifo_AWVALID;
  wire m04_couplers_to_m04_data_fifo_BREADY;
  wire [1:0]m04_couplers_to_m04_data_fifo_BRESP;
  wire m04_couplers_to_m04_data_fifo_BVALID;
  wire [31:0]m04_couplers_to_m04_data_fifo_RDATA;
  wire m04_couplers_to_m04_data_fifo_RREADY;
  wire [1:0]m04_couplers_to_m04_data_fifo_RRESP;
  wire m04_couplers_to_m04_data_fifo_RVALID;
  wire [31:0]m04_couplers_to_m04_data_fifo_WDATA;
  wire m04_couplers_to_m04_data_fifo_WREADY;
  wire [3:0]m04_couplers_to_m04_data_fifo_WSTRB;
  wire m04_couplers_to_m04_data_fifo_WVALID;
  wire [9:0]m04_data_fifo_to_m04_regslice_ARADDR;
  wire [2:0]m04_data_fifo_to_m04_regslice_ARPROT;
  wire m04_data_fifo_to_m04_regslice_ARREADY;
  wire m04_data_fifo_to_m04_regslice_ARVALID;
  wire [9:0]m04_data_fifo_to_m04_regslice_AWADDR;
  wire [2:0]m04_data_fifo_to_m04_regslice_AWPROT;
  wire m04_data_fifo_to_m04_regslice_AWREADY;
  wire m04_data_fifo_to_m04_regslice_AWVALID;
  wire m04_data_fifo_to_m04_regslice_BREADY;
  wire [1:0]m04_data_fifo_to_m04_regslice_BRESP;
  wire m04_data_fifo_to_m04_regslice_BVALID;
  wire [31:0]m04_data_fifo_to_m04_regslice_RDATA;
  wire m04_data_fifo_to_m04_regslice_RREADY;
  wire [1:0]m04_data_fifo_to_m04_regslice_RRESP;
  wire m04_data_fifo_to_m04_regslice_RVALID;
  wire [31:0]m04_data_fifo_to_m04_regslice_WDATA;
  wire m04_data_fifo_to_m04_regslice_WREADY;
  wire [3:0]m04_data_fifo_to_m04_regslice_WSTRB;
  wire m04_data_fifo_to_m04_regslice_WVALID;
  wire [9:0]m04_regslice_to_m04_couplers_ARADDR;
  wire [2:0]m04_regslice_to_m04_couplers_ARPROT;
  wire m04_regslice_to_m04_couplers_ARREADY;
  wire m04_regslice_to_m04_couplers_ARVALID;
  wire [9:0]m04_regslice_to_m04_couplers_AWADDR;
  wire [2:0]m04_regslice_to_m04_couplers_AWPROT;
  wire m04_regslice_to_m04_couplers_AWREADY;
  wire m04_regslice_to_m04_couplers_AWVALID;
  wire m04_regslice_to_m04_couplers_BREADY;
  wire [1:0]m04_regslice_to_m04_couplers_BRESP;
  wire m04_regslice_to_m04_couplers_BVALID;
  wire [31:0]m04_regslice_to_m04_couplers_RDATA;
  wire m04_regslice_to_m04_couplers_RREADY;
  wire [1:0]m04_regslice_to_m04_couplers_RRESP;
  wire m04_regslice_to_m04_couplers_RVALID;
  wire [31:0]m04_regslice_to_m04_couplers_WDATA;
  wire m04_regslice_to_m04_couplers_WREADY;
  wire [3:0]m04_regslice_to_m04_couplers_WSTRB;
  wire m04_regslice_to_m04_couplers_WVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[9:0] = m04_regslice_to_m04_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = m04_regslice_to_m04_couplers_ARPROT;
  assign M_AXI_arvalid = m04_regslice_to_m04_couplers_ARVALID;
  assign M_AXI_awaddr[9:0] = m04_regslice_to_m04_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = m04_regslice_to_m04_couplers_AWPROT;
  assign M_AXI_awvalid = m04_regslice_to_m04_couplers_AWVALID;
  assign M_AXI_bready = m04_regslice_to_m04_couplers_BREADY;
  assign M_AXI_rready = m04_regslice_to_m04_couplers_RREADY;
  assign M_AXI_wdata[31:0] = m04_regslice_to_m04_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = m04_regslice_to_m04_couplers_WSTRB;
  assign M_AXI_wvalid = m04_regslice_to_m04_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m04_couplers_to_m04_data_fifo_ARREADY;
  assign S_AXI_awready = m04_couplers_to_m04_data_fifo_AWREADY;
  assign S_AXI_bresp[1:0] = m04_couplers_to_m04_data_fifo_BRESP;
  assign S_AXI_bvalid = m04_couplers_to_m04_data_fifo_BVALID;
  assign S_AXI_rdata[31:0] = m04_couplers_to_m04_data_fifo_RDATA;
  assign S_AXI_rresp[1:0] = m04_couplers_to_m04_data_fifo_RRESP;
  assign S_AXI_rvalid = m04_couplers_to_m04_data_fifo_RVALID;
  assign S_AXI_wready = m04_couplers_to_m04_data_fifo_WREADY;
  assign m04_couplers_to_m04_data_fifo_ARADDR = S_AXI_araddr[31:0];
  assign m04_couplers_to_m04_data_fifo_ARPROT = S_AXI_arprot[2:0];
  assign m04_couplers_to_m04_data_fifo_ARVALID = S_AXI_arvalid;
  assign m04_couplers_to_m04_data_fifo_AWADDR = S_AXI_awaddr[31:0];
  assign m04_couplers_to_m04_data_fifo_AWPROT = S_AXI_awprot[2:0];
  assign m04_couplers_to_m04_data_fifo_AWVALID = S_AXI_awvalid;
  assign m04_couplers_to_m04_data_fifo_BREADY = S_AXI_bready;
  assign m04_couplers_to_m04_data_fifo_RREADY = S_AXI_rready;
  assign m04_couplers_to_m04_data_fifo_WDATA = S_AXI_wdata[31:0];
  assign m04_couplers_to_m04_data_fifo_WSTRB = S_AXI_wstrb[3:0];
  assign m04_couplers_to_m04_data_fifo_WVALID = S_AXI_wvalid;
  assign m04_regslice_to_m04_couplers_ARREADY = M_AXI_arready;
  assign m04_regslice_to_m04_couplers_AWREADY = M_AXI_awready;
  assign m04_regslice_to_m04_couplers_BRESP = M_AXI_bresp[1:0];
  assign m04_regslice_to_m04_couplers_BVALID = M_AXI_bvalid;
  assign m04_regslice_to_m04_couplers_RDATA = M_AXI_rdata[31:0];
  assign m04_regslice_to_m04_couplers_RRESP = M_AXI_rresp[1:0];
  assign m04_regslice_to_m04_couplers_RVALID = M_AXI_rvalid;
  assign m04_regslice_to_m04_couplers_WREADY = M_AXI_wready;
  mixed16_4x4x1_m04_data_fifo_0 m04_data_fifo
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(m04_data_fifo_to_m04_regslice_ARADDR),
        .m_axi_arprot(m04_data_fifo_to_m04_regslice_ARPROT),
        .m_axi_arready(m04_data_fifo_to_m04_regslice_ARREADY),
        .m_axi_arvalid(m04_data_fifo_to_m04_regslice_ARVALID),
        .m_axi_awaddr(m04_data_fifo_to_m04_regslice_AWADDR),
        .m_axi_awprot(m04_data_fifo_to_m04_regslice_AWPROT),
        .m_axi_awready(m04_data_fifo_to_m04_regslice_AWREADY),
        .m_axi_awvalid(m04_data_fifo_to_m04_regslice_AWVALID),
        .m_axi_bready(m04_data_fifo_to_m04_regslice_BREADY),
        .m_axi_bresp(m04_data_fifo_to_m04_regslice_BRESP),
        .m_axi_bvalid(m04_data_fifo_to_m04_regslice_BVALID),
        .m_axi_rdata(m04_data_fifo_to_m04_regslice_RDATA),
        .m_axi_rready(m04_data_fifo_to_m04_regslice_RREADY),
        .m_axi_rresp(m04_data_fifo_to_m04_regslice_RRESP),
        .m_axi_rvalid(m04_data_fifo_to_m04_regslice_RVALID),
        .m_axi_wdata(m04_data_fifo_to_m04_regslice_WDATA),
        .m_axi_wready(m04_data_fifo_to_m04_regslice_WREADY),
        .m_axi_wstrb(m04_data_fifo_to_m04_regslice_WSTRB),
        .m_axi_wvalid(m04_data_fifo_to_m04_regslice_WVALID),
        .s_axi_araddr(m04_couplers_to_m04_data_fifo_ARADDR[9:0]),
        .s_axi_arprot(m04_couplers_to_m04_data_fifo_ARPROT),
        .s_axi_arready(m04_couplers_to_m04_data_fifo_ARREADY),
        .s_axi_arvalid(m04_couplers_to_m04_data_fifo_ARVALID),
        .s_axi_awaddr(m04_couplers_to_m04_data_fifo_AWADDR[9:0]),
        .s_axi_awprot(m04_couplers_to_m04_data_fifo_AWPROT),
        .s_axi_awready(m04_couplers_to_m04_data_fifo_AWREADY),
        .s_axi_awvalid(m04_couplers_to_m04_data_fifo_AWVALID),
        .s_axi_bready(m04_couplers_to_m04_data_fifo_BREADY),
        .s_axi_bresp(m04_couplers_to_m04_data_fifo_BRESP),
        .s_axi_bvalid(m04_couplers_to_m04_data_fifo_BVALID),
        .s_axi_rdata(m04_couplers_to_m04_data_fifo_RDATA),
        .s_axi_rready(m04_couplers_to_m04_data_fifo_RREADY),
        .s_axi_rresp(m04_couplers_to_m04_data_fifo_RRESP),
        .s_axi_rvalid(m04_couplers_to_m04_data_fifo_RVALID),
        .s_axi_wdata(m04_couplers_to_m04_data_fifo_WDATA),
        .s_axi_wready(m04_couplers_to_m04_data_fifo_WREADY),
        .s_axi_wstrb(m04_couplers_to_m04_data_fifo_WSTRB),
        .s_axi_wvalid(m04_couplers_to_m04_data_fifo_WVALID));
  mixed16_4x4x1_m04_regslice_0 m04_regslice
       (.aclk(M_ACLK_1),
        .aresetn(M_ARESETN_1),
        .m_axi_araddr(m04_regslice_to_m04_couplers_ARADDR),
        .m_axi_arprot(m04_regslice_to_m04_couplers_ARPROT),
        .m_axi_arready(m04_regslice_to_m04_couplers_ARREADY),
        .m_axi_arvalid(m04_regslice_to_m04_couplers_ARVALID),
        .m_axi_awaddr(m04_regslice_to_m04_couplers_AWADDR),
        .m_axi_awprot(m04_regslice_to_m04_couplers_AWPROT),
        .m_axi_awready(m04_regslice_to_m04_couplers_AWREADY),
        .m_axi_awvalid(m04_regslice_to_m04_couplers_AWVALID),
        .m_axi_bready(m04_regslice_to_m04_couplers_BREADY),
        .m_axi_bresp(m04_regslice_to_m04_couplers_BRESP),
        .m_axi_bvalid(m04_regslice_to_m04_couplers_BVALID),
        .m_axi_rdata(m04_regslice_to_m04_couplers_RDATA),
        .m_axi_rready(m04_regslice_to_m04_couplers_RREADY),
        .m_axi_rresp(m04_regslice_to_m04_couplers_RRESP),
        .m_axi_rvalid(m04_regslice_to_m04_couplers_RVALID),
        .m_axi_wdata(m04_regslice_to_m04_couplers_WDATA),
        .m_axi_wready(m04_regslice_to_m04_couplers_WREADY),
        .m_axi_wstrb(m04_regslice_to_m04_couplers_WSTRB),
        .m_axi_wvalid(m04_regslice_to_m04_couplers_WVALID),
        .s_axi_araddr(m04_data_fifo_to_m04_regslice_ARADDR),
        .s_axi_arprot(m04_data_fifo_to_m04_regslice_ARPROT),
        .s_axi_arready(m04_data_fifo_to_m04_regslice_ARREADY),
        .s_axi_arvalid(m04_data_fifo_to_m04_regslice_ARVALID),
        .s_axi_awaddr(m04_data_fifo_to_m04_regslice_AWADDR),
        .s_axi_awprot(m04_data_fifo_to_m04_regslice_AWPROT),
        .s_axi_awready(m04_data_fifo_to_m04_regslice_AWREADY),
        .s_axi_awvalid(m04_data_fifo_to_m04_regslice_AWVALID),
        .s_axi_bready(m04_data_fifo_to_m04_regslice_BREADY),
        .s_axi_bresp(m04_data_fifo_to_m04_regslice_BRESP),
        .s_axi_bvalid(m04_data_fifo_to_m04_regslice_BVALID),
        .s_axi_rdata(m04_data_fifo_to_m04_regslice_RDATA),
        .s_axi_rready(m04_data_fifo_to_m04_regslice_RREADY),
        .s_axi_rresp(m04_data_fifo_to_m04_regslice_RRESP),
        .s_axi_rvalid(m04_data_fifo_to_m04_regslice_RVALID),
        .s_axi_wdata(m04_data_fifo_to_m04_regslice_WDATA),
        .s_axi_wready(m04_data_fifo_to_m04_regslice_WREADY),
        .s_axi_wstrb(m04_data_fifo_to_m04_regslice_WSTRB),
        .s_axi_wvalid(m04_data_fifo_to_m04_regslice_WVALID));
endmodule

(* CORE_GENERATION_INFO = "mixed16_4x4x1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=mixed16_4x4x1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=33,numReposBlks=26,numNonXlnxBlks=0,numHierBlks=7,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,da_axi4_cnt=19,da_clkrst_cnt=40,da_ps7_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "mixed16_4x4x1.hwdef" *) 
module mixed16_4x4x1
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb);
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ADDR" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DDR, AXI_ARBITRATION_SCHEME TDM, BURST_LENGTH 8, CAN_DEBUG false, CAS_LATENCY 11, CAS_WRITE_LATENCY 11, CS_ENABLED true, DATA_MASK_ENABLED true, DATA_WIDTH 8, MEMORY_TYPE COMPONENTS, MEM_ADDR_MAP ROW_COLUMN_BANK, SLOT Single, TIMEPERIOD_PS 1250" *) inout [14:0]DDR_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR BA" *) inout [2:0]DDR_ba;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CAS_N" *) inout DDR_cas_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_N" *) inout DDR_ck_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_P" *) inout DDR_ck_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CKE" *) inout DDR_cke;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CS_N" *) inout DDR_cs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DM" *) inout [3:0]DDR_dm;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQ" *) inout [31:0]DDR_dq;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_N" *) inout [3:0]DDR_dqs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_P" *) inout [3:0]DDR_dqs_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ODT" *) inout DDR_odt;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RAS_N" *) inout DDR_ras_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RESET_N" *) inout DDR_reset_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR WE_N" *) inout DDR_we_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRN" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIXED_IO, CAN_DEBUG false" *) inout FIXED_IO_ddr_vrn;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRP" *) inout FIXED_IO_ddr_vrp;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO MIO" *) inout [53:0]FIXED_IO_mio;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_CLK" *) inout FIXED_IO_ps_clk;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_PORB" *) inout FIXED_IO_ps_porb;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_SRSTB" *) inout FIXED_IO_ps_srstb;

  wire [127:0]KanAcceleratorWrapper_0_m_axis_rslt_TDATA;
  wire [15:0]KanAcceleratorWrapper_0_m_axis_rslt_TKEEP;
  wire KanAcceleratorWrapper_0_m_axis_rslt_TLAST;
  wire KanAcceleratorWrapper_0_m_axis_rslt_TREADY;
  wire KanAcceleratorWrapper_0_m_axis_rslt_TVALID;
  wire KanAcceleratorWrapper_0_pl2ps_intr;
  wire [127:0]axi_weight_dma_M_AXIS_MM2S_TDATA;
  wire [15:0]axi_weight_dma_M_AXIS_MM2S_TKEEP;
  wire axi_weight_dma_M_AXIS_MM2S_TLAST;
  wire axi_weight_dma_M_AXIS_MM2S_TREADY;
  wire axi_weight_dma_M_AXIS_MM2S_TVALID;
  wire [31:0]axi_weight_dma_M_AXI_MM2S_ARADDR;
  wire [1:0]axi_weight_dma_M_AXI_MM2S_ARBURST;
  wire [3:0]axi_weight_dma_M_AXI_MM2S_ARCACHE;
  wire [7:0]axi_weight_dma_M_AXI_MM2S_ARLEN;
  wire [2:0]axi_weight_dma_M_AXI_MM2S_ARPROT;
  wire axi_weight_dma_M_AXI_MM2S_ARREADY;
  wire [2:0]axi_weight_dma_M_AXI_MM2S_ARSIZE;
  wire axi_weight_dma_M_AXI_MM2S_ARVALID;
  wire [127:0]axi_weight_dma_M_AXI_MM2S_RDATA;
  wire axi_weight_dma_M_AXI_MM2S_RLAST;
  wire axi_weight_dma_M_AXI_MM2S_RREADY;
  wire [1:0]axi_weight_dma_M_AXI_MM2S_RRESP;
  wire axi_weight_dma_M_AXI_MM2S_RVALID;
  wire [31:0]axi_weight_dma_M_AXI_S2MM_AWADDR;
  wire [1:0]axi_weight_dma_M_AXI_S2MM_AWBURST;
  wire [3:0]axi_weight_dma_M_AXI_S2MM_AWCACHE;
  wire [7:0]axi_weight_dma_M_AXI_S2MM_AWLEN;
  wire [2:0]axi_weight_dma_M_AXI_S2MM_AWPROT;
  wire axi_weight_dma_M_AXI_S2MM_AWREADY;
  wire [2:0]axi_weight_dma_M_AXI_S2MM_AWSIZE;
  wire axi_weight_dma_M_AXI_S2MM_AWVALID;
  wire axi_weight_dma_M_AXI_S2MM_BREADY;
  wire [1:0]axi_weight_dma_M_AXI_S2MM_BRESP;
  wire axi_weight_dma_M_AXI_S2MM_BVALID;
  wire [127:0]axi_weight_dma_M_AXI_S2MM_WDATA;
  wire axi_weight_dma_M_AXI_S2MM_WLAST;
  wire axi_weight_dma_M_AXI_S2MM_WREADY;
  wire [15:0]axi_weight_dma_M_AXI_S2MM_WSTRB;
  wire axi_weight_dma_M_AXI_S2MM_WVALID;
  wire axi_weight_dma_mm2s_introut;
  wire axi_weight_dma_mm2s_prmry_reset_out_n;
  wire axi_weight_dma_s2mm_introut;
  wire axi_weight_dma_s2mm_prmry_reset_out_n;
  wire [1:0]dma_nrst2rst_Res;
  wire [0:0]dma_rslt_rst_Dout;
  wire [0:0]dma_wght_rst_Dout;
  wire [14:0]processing_system7_0_DDR_ADDR;
  wire [2:0]processing_system7_0_DDR_BA;
  wire processing_system7_0_DDR_CAS_N;
  wire processing_system7_0_DDR_CKE;
  wire processing_system7_0_DDR_CK_N;
  wire processing_system7_0_DDR_CK_P;
  wire processing_system7_0_DDR_CS_N;
  wire [3:0]processing_system7_0_DDR_DM;
  wire [31:0]processing_system7_0_DDR_DQ;
  wire [3:0]processing_system7_0_DDR_DQS_N;
  wire [3:0]processing_system7_0_DDR_DQS_P;
  wire processing_system7_0_DDR_ODT;
  wire processing_system7_0_DDR_RAS_N;
  wire processing_system7_0_DDR_RESET_N;
  wire processing_system7_0_DDR_WE_N;
  wire processing_system7_0_FCLK_RESET0_N;
  wire processing_system7_0_FIXED_IO_DDR_VRN;
  wire processing_system7_0_FIXED_IO_DDR_VRP;
  wire [53:0]processing_system7_0_FIXED_IO_MIO;
  wire processing_system7_0_FIXED_IO_PS_CLK;
  wire processing_system7_0_FIXED_IO_PS_PORB;
  wire processing_system7_0_FIXED_IO_PS_SRSTB;
  wire processing_system7_FCLK_CLK0;
  wire processing_system7_FCLK_CLK1;
  wire processing_system7_FCLK_CLK2;
  wire [31:0]processing_system7_M_AXI_GP0_ARADDR;
  wire [1:0]processing_system7_M_AXI_GP0_ARBURST;
  wire [3:0]processing_system7_M_AXI_GP0_ARCACHE;
  wire [11:0]processing_system7_M_AXI_GP0_ARID;
  wire [3:0]processing_system7_M_AXI_GP0_ARLEN;
  wire [1:0]processing_system7_M_AXI_GP0_ARLOCK;
  wire [2:0]processing_system7_M_AXI_GP0_ARPROT;
  wire [3:0]processing_system7_M_AXI_GP0_ARQOS;
  wire processing_system7_M_AXI_GP0_ARREADY;
  wire [2:0]processing_system7_M_AXI_GP0_ARSIZE;
  wire processing_system7_M_AXI_GP0_ARVALID;
  wire [31:0]processing_system7_M_AXI_GP0_AWADDR;
  wire [1:0]processing_system7_M_AXI_GP0_AWBURST;
  wire [3:0]processing_system7_M_AXI_GP0_AWCACHE;
  wire [11:0]processing_system7_M_AXI_GP0_AWID;
  wire [3:0]processing_system7_M_AXI_GP0_AWLEN;
  wire [1:0]processing_system7_M_AXI_GP0_AWLOCK;
  wire [2:0]processing_system7_M_AXI_GP0_AWPROT;
  wire [3:0]processing_system7_M_AXI_GP0_AWQOS;
  wire processing_system7_M_AXI_GP0_AWREADY;
  wire [2:0]processing_system7_M_AXI_GP0_AWSIZE;
  wire processing_system7_M_AXI_GP0_AWVALID;
  wire [11:0]processing_system7_M_AXI_GP0_BID;
  wire processing_system7_M_AXI_GP0_BREADY;
  wire [1:0]processing_system7_M_AXI_GP0_BRESP;
  wire processing_system7_M_AXI_GP0_BVALID;
  wire [31:0]processing_system7_M_AXI_GP0_RDATA;
  wire [11:0]processing_system7_M_AXI_GP0_RID;
  wire processing_system7_M_AXI_GP0_RLAST;
  wire processing_system7_M_AXI_GP0_RREADY;
  wire [1:0]processing_system7_M_AXI_GP0_RRESP;
  wire processing_system7_M_AXI_GP0_RVALID;
  wire [31:0]processing_system7_M_AXI_GP0_WDATA;
  wire [11:0]processing_system7_M_AXI_GP0_WID;
  wire processing_system7_M_AXI_GP0_WLAST;
  wire processing_system7_M_AXI_GP0_WREADY;
  wire [3:0]processing_system7_M_AXI_GP0_WSTRB;
  wire processing_system7_M_AXI_GP0_WVALID;
  wire [9:0]ps7_axi_periph_M00_AXI_ARADDR;
  wire ps7_axi_periph_M00_AXI_ARREADY;
  wire ps7_axi_periph_M00_AXI_ARVALID;
  wire [9:0]ps7_axi_periph_M00_AXI_AWADDR;
  wire ps7_axi_periph_M00_AXI_AWREADY;
  wire ps7_axi_periph_M00_AXI_AWVALID;
  wire ps7_axi_periph_M00_AXI_BREADY;
  wire [1:0]ps7_axi_periph_M00_AXI_BRESP;
  wire ps7_axi_periph_M00_AXI_BVALID;
  wire [31:0]ps7_axi_periph_M00_AXI_RDATA;
  wire ps7_axi_periph_M00_AXI_RREADY;
  wire [1:0]ps7_axi_periph_M00_AXI_RRESP;
  wire ps7_axi_periph_M00_AXI_RVALID;
  wire [31:0]ps7_axi_periph_M00_AXI_WDATA;
  wire ps7_axi_periph_M00_AXI_WREADY;
  wire ps7_axi_periph_M00_AXI_WVALID;
  wire [13:0]ps7_axi_periph_M01_AXI_ARADDR;
  wire [2:0]ps7_axi_periph_M01_AXI_ARPROT;
  wire ps7_axi_periph_M01_AXI_ARREADY;
  wire ps7_axi_periph_M01_AXI_ARVALID;
  wire [13:0]ps7_axi_periph_M01_AXI_AWADDR;
  wire [2:0]ps7_axi_periph_M01_AXI_AWPROT;
  wire ps7_axi_periph_M01_AXI_AWREADY;
  wire ps7_axi_periph_M01_AXI_AWVALID;
  wire ps7_axi_periph_M01_AXI_BREADY;
  wire [1:0]ps7_axi_periph_M01_AXI_BRESP;
  wire ps7_axi_periph_M01_AXI_BVALID;
  wire [31:0]ps7_axi_periph_M01_AXI_RDATA;
  wire ps7_axi_periph_M01_AXI_RREADY;
  wire [1:0]ps7_axi_periph_M01_AXI_RRESP;
  wire ps7_axi_periph_M01_AXI_RVALID;
  wire [31:0]ps7_axi_periph_M01_AXI_WDATA;
  wire ps7_axi_periph_M01_AXI_WREADY;
  wire [3:0]ps7_axi_periph_M01_AXI_WSTRB;
  wire ps7_axi_periph_M01_AXI_WVALID;
  wire [14:0]ps7_axi_periph_M02_AXI_ARADDR;
  wire [2:0]ps7_axi_periph_M02_AXI_ARPROT;
  wire ps7_axi_periph_M02_AXI_ARREADY;
  wire ps7_axi_periph_M02_AXI_ARVALID;
  wire [14:0]ps7_axi_periph_M02_AXI_AWADDR;
  wire [2:0]ps7_axi_periph_M02_AXI_AWPROT;
  wire ps7_axi_periph_M02_AXI_AWREADY;
  wire ps7_axi_periph_M02_AXI_AWVALID;
  wire ps7_axi_periph_M02_AXI_BREADY;
  wire [1:0]ps7_axi_periph_M02_AXI_BRESP;
  wire ps7_axi_periph_M02_AXI_BVALID;
  wire [31:0]ps7_axi_periph_M02_AXI_RDATA;
  wire ps7_axi_periph_M02_AXI_RREADY;
  wire [1:0]ps7_axi_periph_M02_AXI_RRESP;
  wire ps7_axi_periph_M02_AXI_RVALID;
  wire [31:0]ps7_axi_periph_M02_AXI_WDATA;
  wire ps7_axi_periph_M02_AXI_WREADY;
  wire [3:0]ps7_axi_periph_M02_AXI_WSTRB;
  wire ps7_axi_periph_M02_AXI_WVALID;
  wire [9:0]ps7_axi_periph_M03_AXI_ARADDR;
  wire [2:0]ps7_axi_periph_M03_AXI_ARPROT;
  wire ps7_axi_periph_M03_AXI_ARREADY;
  wire ps7_axi_periph_M03_AXI_ARVALID;
  wire [9:0]ps7_axi_periph_M03_AXI_AWADDR;
  wire [2:0]ps7_axi_periph_M03_AXI_AWPROT;
  wire ps7_axi_periph_M03_AXI_AWREADY;
  wire ps7_axi_periph_M03_AXI_AWVALID;
  wire ps7_axi_periph_M03_AXI_BREADY;
  wire [1:0]ps7_axi_periph_M03_AXI_BRESP;
  wire ps7_axi_periph_M03_AXI_BVALID;
  wire [31:0]ps7_axi_periph_M03_AXI_RDATA;
  wire ps7_axi_periph_M03_AXI_RREADY;
  wire [1:0]ps7_axi_periph_M03_AXI_RRESP;
  wire ps7_axi_periph_M03_AXI_RVALID;
  wire [31:0]ps7_axi_periph_M03_AXI_WDATA;
  wire ps7_axi_periph_M03_AXI_WREADY;
  wire [3:0]ps7_axi_periph_M03_AXI_WSTRB;
  wire ps7_axi_periph_M03_AXI_WVALID;
  wire [9:0]ps7_axi_periph_M04_AXI_ARADDR;
  wire [2:0]ps7_axi_periph_M04_AXI_ARPROT;
  wire ps7_axi_periph_M04_AXI_ARREADY;
  wire ps7_axi_periph_M04_AXI_ARVALID;
  wire [9:0]ps7_axi_periph_M04_AXI_AWADDR;
  wire [2:0]ps7_axi_periph_M04_AXI_AWPROT;
  wire ps7_axi_periph_M04_AXI_AWREADY;
  wire ps7_axi_periph_M04_AXI_AWVALID;
  wire ps7_axi_periph_M04_AXI_BREADY;
  wire [1:0]ps7_axi_periph_M04_AXI_BRESP;
  wire ps7_axi_periph_M04_AXI_BVALID;
  wire [31:0]ps7_axi_periph_M04_AXI_RDATA;
  wire ps7_axi_periph_M04_AXI_RREADY;
  wire [1:0]ps7_axi_periph_M04_AXI_RRESP;
  wire ps7_axi_periph_M04_AXI_RVALID;
  wire [31:0]ps7_axi_periph_M04_AXI_WDATA;
  wire ps7_axi_periph_M04_AXI_WREADY;
  wire [3:0]ps7_axi_periph_M04_AXI_WSTRB;
  wire ps7_axi_periph_M04_AXI_WVALID;
  wire [0:0]rst_mem_clk_peripheral_reset;
  wire [0:0]rst_ps7_125M_peripheral_aresetn;
  wire [0:0]rst_ps7_62M_peripheral_aresetn;
  wire [0:0]rst_ps7_62M_peripheral_reset;
  wire [31:0]smartconnect_0_M00_AXI_ARADDR;
  wire [1:0]smartconnect_0_M00_AXI_ARBURST;
  wire [3:0]smartconnect_0_M00_AXI_ARCACHE;
  wire [3:0]smartconnect_0_M00_AXI_ARLEN;
  wire [1:0]smartconnect_0_M00_AXI_ARLOCK;
  wire [2:0]smartconnect_0_M00_AXI_ARPROT;
  wire [3:0]smartconnect_0_M00_AXI_ARQOS;
  wire smartconnect_0_M00_AXI_ARREADY;
  wire [2:0]smartconnect_0_M00_AXI_ARSIZE;
  wire smartconnect_0_M00_AXI_ARVALID;
  wire [31:0]smartconnect_0_M00_AXI_AWADDR;
  wire [1:0]smartconnect_0_M00_AXI_AWBURST;
  wire [3:0]smartconnect_0_M00_AXI_AWCACHE;
  wire [3:0]smartconnect_0_M00_AXI_AWLEN;
  wire [1:0]smartconnect_0_M00_AXI_AWLOCK;
  wire [2:0]smartconnect_0_M00_AXI_AWPROT;
  wire [3:0]smartconnect_0_M00_AXI_AWQOS;
  wire smartconnect_0_M00_AXI_AWREADY;
  wire [2:0]smartconnect_0_M00_AXI_AWSIZE;
  wire smartconnect_0_M00_AXI_AWVALID;
  wire smartconnect_0_M00_AXI_BREADY;
  wire [1:0]smartconnect_0_M00_AXI_BRESP;
  wire smartconnect_0_M00_AXI_BVALID;
  wire [63:0]smartconnect_0_M00_AXI_RDATA;
  wire smartconnect_0_M00_AXI_RLAST;
  wire smartconnect_0_M00_AXI_RREADY;
  wire [1:0]smartconnect_0_M00_AXI_RRESP;
  wire smartconnect_0_M00_AXI_RVALID;
  wire [63:0]smartconnect_0_M00_AXI_WDATA;
  wire smartconnect_0_M00_AXI_WLAST;
  wire smartconnect_0_M00_AXI_WREADY;
  wire [7:0]smartconnect_0_M00_AXI_WSTRB;
  wire smartconnect_0_M00_AXI_WVALID;
  wire [2:0]xlconcat_0_dout;
  wire [1:0]xlconcat_1_dout;

  mixed16_4x4x1_KanAccelerator_0 KanAccelerator
       (.core_clk(processing_system7_FCLK_CLK1),
        .fsm_clk(processing_system7_FCLK_CLK0),
        .fsm_rst(rst_ps7_62M_peripheral_reset),
        .m_axis_rslt_aclk(processing_system7_FCLK_CLK1),
        .m_axis_rslt_areset(dma_rslt_rst_Dout),
        .m_axis_rslt_tdata(KanAcceleratorWrapper_0_m_axis_rslt_TDATA),
        .m_axis_rslt_tkeep(KanAcceleratorWrapper_0_m_axis_rslt_TKEEP),
        .m_axis_rslt_tlast(KanAcceleratorWrapper_0_m_axis_rslt_TLAST),
        .m_axis_rslt_tready(KanAcceleratorWrapper_0_m_axis_rslt_TREADY),
        .m_axis_rslt_tvalid(KanAcceleratorWrapper_0_m_axis_rslt_TVALID),
        .pl2ps_intr(KanAcceleratorWrapper_0_pl2ps_intr),
        .s00_axil_data_aclk(processing_system7_FCLK_CLK1),
        .s00_axil_data_araddr(ps7_axi_periph_M02_AXI_ARADDR),
        .s00_axil_data_areset(rst_mem_clk_peripheral_reset),
        .s00_axil_data_arprot(ps7_axi_periph_M02_AXI_ARPROT),
        .s00_axil_data_arready(ps7_axi_periph_M02_AXI_ARREADY),
        .s00_axil_data_arvalid(ps7_axi_periph_M02_AXI_ARVALID),
        .s00_axil_data_awaddr(ps7_axi_periph_M02_AXI_AWADDR),
        .s00_axil_data_awprot(ps7_axi_periph_M02_AXI_AWPROT),
        .s00_axil_data_awready(ps7_axi_periph_M02_AXI_AWREADY),
        .s00_axil_data_awvalid(ps7_axi_periph_M02_AXI_AWVALID),
        .s00_axil_data_bready(ps7_axi_periph_M02_AXI_BREADY),
        .s00_axil_data_bresp(ps7_axi_periph_M02_AXI_BRESP),
        .s00_axil_data_bvalid(ps7_axi_periph_M02_AXI_BVALID),
        .s00_axil_data_rdata(ps7_axi_periph_M02_AXI_RDATA),
        .s00_axil_data_rready(ps7_axi_periph_M02_AXI_RREADY),
        .s00_axil_data_rresp(ps7_axi_periph_M02_AXI_RRESP),
        .s00_axil_data_rvalid(ps7_axi_periph_M02_AXI_RVALID),
        .s00_axil_data_wdata(ps7_axi_periph_M02_AXI_WDATA),
        .s00_axil_data_wready(ps7_axi_periph_M02_AXI_WREADY),
        .s00_axil_data_wstrb(ps7_axi_periph_M02_AXI_WSTRB),
        .s00_axil_data_wvalid(ps7_axi_periph_M02_AXI_WVALID),
        .s_axil_ctrl_araddr(ps7_axi_periph_M01_AXI_ARADDR),
        .s_axil_ctrl_arprot(ps7_axi_periph_M01_AXI_ARPROT),
        .s_axil_ctrl_arready(ps7_axi_periph_M01_AXI_ARREADY),
        .s_axil_ctrl_arvalid(ps7_axi_periph_M01_AXI_ARVALID),
        .s_axil_ctrl_awaddr(ps7_axi_periph_M01_AXI_AWADDR),
        .s_axil_ctrl_awprot(ps7_axi_periph_M01_AXI_AWPROT),
        .s_axil_ctrl_awready(ps7_axi_periph_M01_AXI_AWREADY),
        .s_axil_ctrl_awvalid(ps7_axi_periph_M01_AXI_AWVALID),
        .s_axil_ctrl_bready(ps7_axi_periph_M01_AXI_BREADY),
        .s_axil_ctrl_bresp(ps7_axi_periph_M01_AXI_BRESP),
        .s_axil_ctrl_bvalid(ps7_axi_periph_M01_AXI_BVALID),
        .s_axil_ctrl_rdata(ps7_axi_periph_M01_AXI_RDATA),
        .s_axil_ctrl_rready(ps7_axi_periph_M01_AXI_RREADY),
        .s_axil_ctrl_rresp(ps7_axi_periph_M01_AXI_RRESP),
        .s_axil_ctrl_rvalid(ps7_axi_periph_M01_AXI_RVALID),
        .s_axil_ctrl_wdata(ps7_axi_periph_M01_AXI_WDATA),
        .s_axil_ctrl_wready(ps7_axi_periph_M01_AXI_WREADY),
        .s_axil_ctrl_wstrb(ps7_axi_periph_M01_AXI_WSTRB),
        .s_axil_ctrl_wvalid(ps7_axi_periph_M01_AXI_WVALID),
        .s_axil_grid_aclk(processing_system7_FCLK_CLK1),
        .s_axil_grid_araddr(ps7_axi_periph_M03_AXI_ARADDR),
        .s_axil_grid_areset(rst_mem_clk_peripheral_reset),
        .s_axil_grid_arprot(ps7_axi_periph_M03_AXI_ARPROT),
        .s_axil_grid_arready(ps7_axi_periph_M03_AXI_ARREADY),
        .s_axil_grid_arvalid(ps7_axi_periph_M03_AXI_ARVALID),
        .s_axil_grid_awaddr(ps7_axi_periph_M03_AXI_AWADDR),
        .s_axil_grid_awprot(ps7_axi_periph_M03_AXI_AWPROT),
        .s_axil_grid_awready(ps7_axi_periph_M03_AXI_AWREADY),
        .s_axil_grid_awvalid(ps7_axi_periph_M03_AXI_AWVALID),
        .s_axil_grid_bready(ps7_axi_periph_M03_AXI_BREADY),
        .s_axil_grid_bresp(ps7_axi_periph_M03_AXI_BRESP),
        .s_axil_grid_bvalid(ps7_axi_periph_M03_AXI_BVALID),
        .s_axil_grid_rdata(ps7_axi_periph_M03_AXI_RDATA),
        .s_axil_grid_rready(ps7_axi_periph_M03_AXI_RREADY),
        .s_axil_grid_rresp(ps7_axi_periph_M03_AXI_RRESP),
        .s_axil_grid_rvalid(ps7_axi_periph_M03_AXI_RVALID),
        .s_axil_grid_wdata(ps7_axi_periph_M03_AXI_WDATA),
        .s_axil_grid_wready(ps7_axi_periph_M03_AXI_WREADY),
        .s_axil_grid_wstrb(ps7_axi_periph_M03_AXI_WSTRB),
        .s_axil_grid_wvalid(ps7_axi_periph_M03_AXI_WVALID),
        .s_axil_scle_aclk(processing_system7_FCLK_CLK1),
        .s_axil_scle_araddr(ps7_axi_periph_M04_AXI_ARADDR),
        .s_axil_scle_areset(rst_mem_clk_peripheral_reset),
        .s_axil_scle_arprot(ps7_axi_periph_M04_AXI_ARPROT),
        .s_axil_scle_arready(ps7_axi_periph_M04_AXI_ARREADY),
        .s_axil_scle_arvalid(ps7_axi_periph_M04_AXI_ARVALID),
        .s_axil_scle_awaddr(ps7_axi_periph_M04_AXI_AWADDR),
        .s_axil_scle_awprot(ps7_axi_periph_M04_AXI_AWPROT),
        .s_axil_scle_awready(ps7_axi_periph_M04_AXI_AWREADY),
        .s_axil_scle_awvalid(ps7_axi_periph_M04_AXI_AWVALID),
        .s_axil_scle_bready(ps7_axi_periph_M04_AXI_BREADY),
        .s_axil_scle_bresp(ps7_axi_periph_M04_AXI_BRESP),
        .s_axil_scle_bvalid(ps7_axi_periph_M04_AXI_BVALID),
        .s_axil_scle_rdata(ps7_axi_periph_M04_AXI_RDATA),
        .s_axil_scle_rready(ps7_axi_periph_M04_AXI_RREADY),
        .s_axil_scle_rresp(ps7_axi_periph_M04_AXI_RRESP),
        .s_axil_scle_rvalid(ps7_axi_periph_M04_AXI_RVALID),
        .s_axil_scle_wdata(ps7_axi_periph_M04_AXI_WDATA),
        .s_axil_scle_wready(ps7_axi_periph_M04_AXI_WREADY),
        .s_axil_scle_wstrb(ps7_axi_periph_M04_AXI_WSTRB),
        .s_axil_scle_wvalid(ps7_axi_periph_M04_AXI_WVALID),
        .s_axis_wght_aclk(processing_system7_FCLK_CLK1),
        .s_axis_wght_areset(dma_wght_rst_Dout),
        .s_axis_wght_tdata(axi_weight_dma_M_AXIS_MM2S_TDATA),
        .s_axis_wght_tdest(1'b0),
        .s_axis_wght_tid(1'b0),
        .s_axis_wght_tkeep(axi_weight_dma_M_AXIS_MM2S_TKEEP),
        .s_axis_wght_tlast(axi_weight_dma_M_AXIS_MM2S_TLAST),
        .s_axis_wght_tready(axi_weight_dma_M_AXIS_MM2S_TREADY),
        .s_axis_wght_tuser(1'b0),
        .s_axis_wght_tvalid(axi_weight_dma_M_AXIS_MM2S_TVALID));
  mixed16_4x4x1_axi_weight_dma_0 axi_weight_dma
       (.axi_resetn(rst_ps7_62M_peripheral_aresetn),
        .m_axi_mm2s_aclk(processing_system7_FCLK_CLK1),
        .m_axi_mm2s_araddr(axi_weight_dma_M_AXI_MM2S_ARADDR),
        .m_axi_mm2s_arburst(axi_weight_dma_M_AXI_MM2S_ARBURST),
        .m_axi_mm2s_arcache(axi_weight_dma_M_AXI_MM2S_ARCACHE),
        .m_axi_mm2s_arlen(axi_weight_dma_M_AXI_MM2S_ARLEN),
        .m_axi_mm2s_arprot(axi_weight_dma_M_AXI_MM2S_ARPROT),
        .m_axi_mm2s_arready(axi_weight_dma_M_AXI_MM2S_ARREADY),
        .m_axi_mm2s_arsize(axi_weight_dma_M_AXI_MM2S_ARSIZE),
        .m_axi_mm2s_arvalid(axi_weight_dma_M_AXI_MM2S_ARVALID),
        .m_axi_mm2s_rdata(axi_weight_dma_M_AXI_MM2S_RDATA),
        .m_axi_mm2s_rlast(axi_weight_dma_M_AXI_MM2S_RLAST),
        .m_axi_mm2s_rready(axi_weight_dma_M_AXI_MM2S_RREADY),
        .m_axi_mm2s_rresp(axi_weight_dma_M_AXI_MM2S_RRESP),
        .m_axi_mm2s_rvalid(axi_weight_dma_M_AXI_MM2S_RVALID),
        .m_axi_s2mm_aclk(processing_system7_FCLK_CLK1),
        .m_axi_s2mm_awaddr(axi_weight_dma_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(axi_weight_dma_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(axi_weight_dma_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(axi_weight_dma_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(axi_weight_dma_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(axi_weight_dma_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(axi_weight_dma_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(axi_weight_dma_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(axi_weight_dma_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(axi_weight_dma_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(axi_weight_dma_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(axi_weight_dma_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(axi_weight_dma_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(axi_weight_dma_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(axi_weight_dma_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(axi_weight_dma_M_AXI_S2MM_WVALID),
        .m_axis_mm2s_tdata(axi_weight_dma_M_AXIS_MM2S_TDATA),
        .m_axis_mm2s_tkeep(axi_weight_dma_M_AXIS_MM2S_TKEEP),
        .m_axis_mm2s_tlast(axi_weight_dma_M_AXIS_MM2S_TLAST),
        .m_axis_mm2s_tready(axi_weight_dma_M_AXIS_MM2S_TREADY),
        .m_axis_mm2s_tvalid(axi_weight_dma_M_AXIS_MM2S_TVALID),
        .mm2s_introut(axi_weight_dma_mm2s_introut),
        .mm2s_prmry_reset_out_n(axi_weight_dma_mm2s_prmry_reset_out_n),
        .s2mm_introut(axi_weight_dma_s2mm_introut),
        .s2mm_prmry_reset_out_n(axi_weight_dma_s2mm_prmry_reset_out_n),
        .s_axi_lite_aclk(processing_system7_FCLK_CLK0),
        .s_axi_lite_araddr(ps7_axi_periph_M00_AXI_ARADDR),
        .s_axi_lite_arready(ps7_axi_periph_M00_AXI_ARREADY),
        .s_axi_lite_arvalid(ps7_axi_periph_M00_AXI_ARVALID),
        .s_axi_lite_awaddr(ps7_axi_periph_M00_AXI_AWADDR),
        .s_axi_lite_awready(ps7_axi_periph_M00_AXI_AWREADY),
        .s_axi_lite_awvalid(ps7_axi_periph_M00_AXI_AWVALID),
        .s_axi_lite_bready(ps7_axi_periph_M00_AXI_BREADY),
        .s_axi_lite_bresp(ps7_axi_periph_M00_AXI_BRESP),
        .s_axi_lite_bvalid(ps7_axi_periph_M00_AXI_BVALID),
        .s_axi_lite_rdata(ps7_axi_periph_M00_AXI_RDATA),
        .s_axi_lite_rready(ps7_axi_periph_M00_AXI_RREADY),
        .s_axi_lite_rresp(ps7_axi_periph_M00_AXI_RRESP),
        .s_axi_lite_rvalid(ps7_axi_periph_M00_AXI_RVALID),
        .s_axi_lite_wdata(ps7_axi_periph_M00_AXI_WDATA),
        .s_axi_lite_wready(ps7_axi_periph_M00_AXI_WREADY),
        .s_axi_lite_wvalid(ps7_axi_periph_M00_AXI_WVALID),
        .s_axis_s2mm_tdata(KanAcceleratorWrapper_0_m_axis_rslt_TDATA),
        .s_axis_s2mm_tkeep(KanAcceleratorWrapper_0_m_axis_rslt_TKEEP),
        .s_axis_s2mm_tlast(KanAcceleratorWrapper_0_m_axis_rslt_TLAST),
        .s_axis_s2mm_tready(KanAcceleratorWrapper_0_m_axis_rslt_TREADY),
        .s_axis_s2mm_tvalid(KanAcceleratorWrapper_0_m_axis_rslt_TVALID));
  mixed16_4x4x1_dma_nrst_0 dma_nrst
       (.In0(axi_weight_dma_mm2s_prmry_reset_out_n),
        .In1(axi_weight_dma_s2mm_prmry_reset_out_n),
        .dout(xlconcat_1_dout));
  mixed16_4x4x1_dma_nrst2rst_0 dma_nrst2rst
       (.Op1(xlconcat_1_dout),
        .Res(dma_nrst2rst_Res));
  mixed16_4x4x1_dma_rslt_rst_0 dma_rslt_rst
       (.Din(dma_nrst2rst_Res),
        .Dout(dma_rslt_rst_Dout));
  mixed16_4x4x1_dma_wght_rst_0 dma_wght_rst
       (.Din(dma_nrst2rst_Res),
        .Dout(dma_wght_rst_Dout));
  mixed16_4x4x1_itr_concat_0 itr_concat
       (.In0(KanAcceleratorWrapper_0_pl2ps_intr),
        .In1(axi_weight_dma_mm2s_introut),
        .In2(axi_weight_dma_s2mm_introut),
        .dout(xlconcat_0_dout));
  mixed16_4x4x1_processing_system7_1 processing_system7
       (.DDR_Addr(DDR_addr[14:0]),
        .DDR_BankAddr(DDR_ba[2:0]),
        .DDR_CAS_n(DDR_cas_n),
        .DDR_CKE(DDR_cke),
        .DDR_CS_n(DDR_cs_n),
        .DDR_Clk(DDR_ck_p),
        .DDR_Clk_n(DDR_ck_n),
        .DDR_DM(DDR_dm[3:0]),
        .DDR_DQ(DDR_dq[31:0]),
        .DDR_DQS(DDR_dqs_p[3:0]),
        .DDR_DQS_n(DDR_dqs_n[3:0]),
        .DDR_DRSTB(DDR_reset_n),
        .DDR_ODT(DDR_odt),
        .DDR_RAS_n(DDR_ras_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_we_n),
        .FCLK_CLK0(processing_system7_FCLK_CLK0),
        .FCLK_CLK1(processing_system7_FCLK_CLK1),
        .FCLK_CLK2(processing_system7_FCLK_CLK2),
        .FCLK_RESET0_N(processing_system7_0_FCLK_RESET0_N),
        .IRQ_F2P(xlconcat_0_dout),
        .MIO(FIXED_IO_mio[53:0]),
        .M_AXI_GP0_ACLK(processing_system7_FCLK_CLK1),
        .M_AXI_GP0_ARADDR(processing_system7_M_AXI_GP0_ARADDR),
        .M_AXI_GP0_ARBURST(processing_system7_M_AXI_GP0_ARBURST),
        .M_AXI_GP0_ARCACHE(processing_system7_M_AXI_GP0_ARCACHE),
        .M_AXI_GP0_ARID(processing_system7_M_AXI_GP0_ARID),
        .M_AXI_GP0_ARLEN(processing_system7_M_AXI_GP0_ARLEN),
        .M_AXI_GP0_ARLOCK(processing_system7_M_AXI_GP0_ARLOCK),
        .M_AXI_GP0_ARPROT(processing_system7_M_AXI_GP0_ARPROT),
        .M_AXI_GP0_ARQOS(processing_system7_M_AXI_GP0_ARQOS),
        .M_AXI_GP0_ARREADY(processing_system7_M_AXI_GP0_ARREADY),
        .M_AXI_GP0_ARSIZE(processing_system7_M_AXI_GP0_ARSIZE),
        .M_AXI_GP0_ARVALID(processing_system7_M_AXI_GP0_ARVALID),
        .M_AXI_GP0_AWADDR(processing_system7_M_AXI_GP0_AWADDR),
        .M_AXI_GP0_AWBURST(processing_system7_M_AXI_GP0_AWBURST),
        .M_AXI_GP0_AWCACHE(processing_system7_M_AXI_GP0_AWCACHE),
        .M_AXI_GP0_AWID(processing_system7_M_AXI_GP0_AWID),
        .M_AXI_GP0_AWLEN(processing_system7_M_AXI_GP0_AWLEN),
        .M_AXI_GP0_AWLOCK(processing_system7_M_AXI_GP0_AWLOCK),
        .M_AXI_GP0_AWPROT(processing_system7_M_AXI_GP0_AWPROT),
        .M_AXI_GP0_AWQOS(processing_system7_M_AXI_GP0_AWQOS),
        .M_AXI_GP0_AWREADY(processing_system7_M_AXI_GP0_AWREADY),
        .M_AXI_GP0_AWSIZE(processing_system7_M_AXI_GP0_AWSIZE),
        .M_AXI_GP0_AWVALID(processing_system7_M_AXI_GP0_AWVALID),
        .M_AXI_GP0_BID(processing_system7_M_AXI_GP0_BID),
        .M_AXI_GP0_BREADY(processing_system7_M_AXI_GP0_BREADY),
        .M_AXI_GP0_BRESP(processing_system7_M_AXI_GP0_BRESP),
        .M_AXI_GP0_BVALID(processing_system7_M_AXI_GP0_BVALID),
        .M_AXI_GP0_RDATA(processing_system7_M_AXI_GP0_RDATA),
        .M_AXI_GP0_RID(processing_system7_M_AXI_GP0_RID),
        .M_AXI_GP0_RLAST(processing_system7_M_AXI_GP0_RLAST),
        .M_AXI_GP0_RREADY(processing_system7_M_AXI_GP0_RREADY),
        .M_AXI_GP0_RRESP(processing_system7_M_AXI_GP0_RRESP),
        .M_AXI_GP0_RVALID(processing_system7_M_AXI_GP0_RVALID),
        .M_AXI_GP0_WDATA(processing_system7_M_AXI_GP0_WDATA),
        .M_AXI_GP0_WID(processing_system7_M_AXI_GP0_WID),
        .M_AXI_GP0_WLAST(processing_system7_M_AXI_GP0_WLAST),
        .M_AXI_GP0_WREADY(processing_system7_M_AXI_GP0_WREADY),
        .M_AXI_GP0_WSTRB(processing_system7_M_AXI_GP0_WSTRB),
        .M_AXI_GP0_WVALID(processing_system7_M_AXI_GP0_WVALID),
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb),
        .S_AXI_HP2_ACLK(processing_system7_FCLK_CLK2),
        .S_AXI_HP2_ARADDR(smartconnect_0_M00_AXI_ARADDR),
        .S_AXI_HP2_ARBURST(smartconnect_0_M00_AXI_ARBURST),
        .S_AXI_HP2_ARCACHE(smartconnect_0_M00_AXI_ARCACHE),
        .S_AXI_HP2_ARID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP2_ARLEN(smartconnect_0_M00_AXI_ARLEN),
        .S_AXI_HP2_ARLOCK(smartconnect_0_M00_AXI_ARLOCK),
        .S_AXI_HP2_ARPROT(smartconnect_0_M00_AXI_ARPROT),
        .S_AXI_HP2_ARQOS(smartconnect_0_M00_AXI_ARQOS),
        .S_AXI_HP2_ARREADY(smartconnect_0_M00_AXI_ARREADY),
        .S_AXI_HP2_ARSIZE(smartconnect_0_M00_AXI_ARSIZE),
        .S_AXI_HP2_ARVALID(smartconnect_0_M00_AXI_ARVALID),
        .S_AXI_HP2_AWADDR(smartconnect_0_M00_AXI_AWADDR),
        .S_AXI_HP2_AWBURST(smartconnect_0_M00_AXI_AWBURST),
        .S_AXI_HP2_AWCACHE(smartconnect_0_M00_AXI_AWCACHE),
        .S_AXI_HP2_AWID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP2_AWLEN(smartconnect_0_M00_AXI_AWLEN),
        .S_AXI_HP2_AWLOCK(smartconnect_0_M00_AXI_AWLOCK),
        .S_AXI_HP2_AWPROT(smartconnect_0_M00_AXI_AWPROT),
        .S_AXI_HP2_AWQOS(smartconnect_0_M00_AXI_AWQOS),
        .S_AXI_HP2_AWREADY(smartconnect_0_M00_AXI_AWREADY),
        .S_AXI_HP2_AWSIZE(smartconnect_0_M00_AXI_AWSIZE),
        .S_AXI_HP2_AWVALID(smartconnect_0_M00_AXI_AWVALID),
        .S_AXI_HP2_BREADY(smartconnect_0_M00_AXI_BREADY),
        .S_AXI_HP2_BRESP(smartconnect_0_M00_AXI_BRESP),
        .S_AXI_HP2_BVALID(smartconnect_0_M00_AXI_BVALID),
        .S_AXI_HP2_RDATA(smartconnect_0_M00_AXI_RDATA),
        .S_AXI_HP2_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP2_RLAST(smartconnect_0_M00_AXI_RLAST),
        .S_AXI_HP2_RREADY(smartconnect_0_M00_AXI_RREADY),
        .S_AXI_HP2_RRESP(smartconnect_0_M00_AXI_RRESP),
        .S_AXI_HP2_RVALID(smartconnect_0_M00_AXI_RVALID),
        .S_AXI_HP2_WDATA(smartconnect_0_M00_AXI_WDATA),
        .S_AXI_HP2_WID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP2_WLAST(smartconnect_0_M00_AXI_WLAST),
        .S_AXI_HP2_WREADY(smartconnect_0_M00_AXI_WREADY),
        .S_AXI_HP2_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP2_WSTRB(smartconnect_0_M00_AXI_WSTRB),
        .S_AXI_HP2_WVALID(smartconnect_0_M00_AXI_WVALID),
        .USB0_VBUS_PWRFAULT(1'b0));
  mixed16_4x4x1_ps7_axi_periph_2 ps7_axi_periph
       (.ACLK(processing_system7_FCLK_CLK1),
        .ARESETN(rst_ps7_125M_peripheral_aresetn),
        .M00_ACLK(processing_system7_FCLK_CLK0),
        .M00_ARESETN(rst_ps7_62M_peripheral_aresetn),
        .M00_AXI_araddr(ps7_axi_periph_M00_AXI_ARADDR),
        .M00_AXI_arready(ps7_axi_periph_M00_AXI_ARREADY),
        .M00_AXI_arvalid(ps7_axi_periph_M00_AXI_ARVALID),
        .M00_AXI_awaddr(ps7_axi_periph_M00_AXI_AWADDR),
        .M00_AXI_awready(ps7_axi_periph_M00_AXI_AWREADY),
        .M00_AXI_awvalid(ps7_axi_periph_M00_AXI_AWVALID),
        .M00_AXI_bready(ps7_axi_periph_M00_AXI_BREADY),
        .M00_AXI_bresp(ps7_axi_periph_M00_AXI_BRESP),
        .M00_AXI_bvalid(ps7_axi_periph_M00_AXI_BVALID),
        .M00_AXI_rdata(ps7_axi_periph_M00_AXI_RDATA),
        .M00_AXI_rready(ps7_axi_periph_M00_AXI_RREADY),
        .M00_AXI_rresp(ps7_axi_periph_M00_AXI_RRESP),
        .M00_AXI_rvalid(ps7_axi_periph_M00_AXI_RVALID),
        .M00_AXI_wdata(ps7_axi_periph_M00_AXI_WDATA),
        .M00_AXI_wready(ps7_axi_periph_M00_AXI_WREADY),
        .M00_AXI_wvalid(ps7_axi_periph_M00_AXI_WVALID),
        .M01_ACLK(processing_system7_FCLK_CLK0),
        .M01_ARESETN(rst_ps7_62M_peripheral_aresetn),
        .M01_AXI_araddr(ps7_axi_periph_M01_AXI_ARADDR),
        .M01_AXI_arprot(ps7_axi_periph_M01_AXI_ARPROT),
        .M01_AXI_arready(ps7_axi_periph_M01_AXI_ARREADY),
        .M01_AXI_arvalid(ps7_axi_periph_M01_AXI_ARVALID),
        .M01_AXI_awaddr(ps7_axi_periph_M01_AXI_AWADDR),
        .M01_AXI_awprot(ps7_axi_periph_M01_AXI_AWPROT),
        .M01_AXI_awready(ps7_axi_periph_M01_AXI_AWREADY),
        .M01_AXI_awvalid(ps7_axi_periph_M01_AXI_AWVALID),
        .M01_AXI_bready(ps7_axi_periph_M01_AXI_BREADY),
        .M01_AXI_bresp(ps7_axi_periph_M01_AXI_BRESP),
        .M01_AXI_bvalid(ps7_axi_periph_M01_AXI_BVALID),
        .M01_AXI_rdata(ps7_axi_periph_M01_AXI_RDATA),
        .M01_AXI_rready(ps7_axi_periph_M01_AXI_RREADY),
        .M01_AXI_rresp(ps7_axi_periph_M01_AXI_RRESP),
        .M01_AXI_rvalid(ps7_axi_periph_M01_AXI_RVALID),
        .M01_AXI_wdata(ps7_axi_periph_M01_AXI_WDATA),
        .M01_AXI_wready(ps7_axi_periph_M01_AXI_WREADY),
        .M01_AXI_wstrb(ps7_axi_periph_M01_AXI_WSTRB),
        .M01_AXI_wvalid(ps7_axi_periph_M01_AXI_WVALID),
        .M02_ACLK(processing_system7_FCLK_CLK1),
        .M02_ARESETN(rst_ps7_125M_peripheral_aresetn),
        .M02_AXI_araddr(ps7_axi_periph_M02_AXI_ARADDR),
        .M02_AXI_arprot(ps7_axi_periph_M02_AXI_ARPROT),
        .M02_AXI_arready(ps7_axi_periph_M02_AXI_ARREADY),
        .M02_AXI_arvalid(ps7_axi_periph_M02_AXI_ARVALID),
        .M02_AXI_awaddr(ps7_axi_periph_M02_AXI_AWADDR),
        .M02_AXI_awprot(ps7_axi_periph_M02_AXI_AWPROT),
        .M02_AXI_awready(ps7_axi_periph_M02_AXI_AWREADY),
        .M02_AXI_awvalid(ps7_axi_periph_M02_AXI_AWVALID),
        .M02_AXI_bready(ps7_axi_periph_M02_AXI_BREADY),
        .M02_AXI_bresp(ps7_axi_periph_M02_AXI_BRESP),
        .M02_AXI_bvalid(ps7_axi_periph_M02_AXI_BVALID),
        .M02_AXI_rdata(ps7_axi_periph_M02_AXI_RDATA),
        .M02_AXI_rready(ps7_axi_periph_M02_AXI_RREADY),
        .M02_AXI_rresp(ps7_axi_periph_M02_AXI_RRESP),
        .M02_AXI_rvalid(ps7_axi_periph_M02_AXI_RVALID),
        .M02_AXI_wdata(ps7_axi_periph_M02_AXI_WDATA),
        .M02_AXI_wready(ps7_axi_periph_M02_AXI_WREADY),
        .M02_AXI_wstrb(ps7_axi_periph_M02_AXI_WSTRB),
        .M02_AXI_wvalid(ps7_axi_periph_M02_AXI_WVALID),
        .M03_ACLK(processing_system7_FCLK_CLK1),
        .M03_ARESETN(rst_ps7_125M_peripheral_aresetn),
        .M03_AXI_araddr(ps7_axi_periph_M03_AXI_ARADDR),
        .M03_AXI_arprot(ps7_axi_periph_M03_AXI_ARPROT),
        .M03_AXI_arready(ps7_axi_periph_M03_AXI_ARREADY),
        .M03_AXI_arvalid(ps7_axi_periph_M03_AXI_ARVALID),
        .M03_AXI_awaddr(ps7_axi_periph_M03_AXI_AWADDR),
        .M03_AXI_awprot(ps7_axi_periph_M03_AXI_AWPROT),
        .M03_AXI_awready(ps7_axi_periph_M03_AXI_AWREADY),
        .M03_AXI_awvalid(ps7_axi_periph_M03_AXI_AWVALID),
        .M03_AXI_bready(ps7_axi_periph_M03_AXI_BREADY),
        .M03_AXI_bresp(ps7_axi_periph_M03_AXI_BRESP),
        .M03_AXI_bvalid(ps7_axi_periph_M03_AXI_BVALID),
        .M03_AXI_rdata(ps7_axi_periph_M03_AXI_RDATA),
        .M03_AXI_rready(ps7_axi_periph_M03_AXI_RREADY),
        .M03_AXI_rresp(ps7_axi_periph_M03_AXI_RRESP),
        .M03_AXI_rvalid(ps7_axi_periph_M03_AXI_RVALID),
        .M03_AXI_wdata(ps7_axi_periph_M03_AXI_WDATA),
        .M03_AXI_wready(ps7_axi_periph_M03_AXI_WREADY),
        .M03_AXI_wstrb(ps7_axi_periph_M03_AXI_WSTRB),
        .M03_AXI_wvalid(ps7_axi_periph_M03_AXI_WVALID),
        .M04_ACLK(processing_system7_FCLK_CLK1),
        .M04_ARESETN(rst_ps7_125M_peripheral_aresetn),
        .M04_AXI_araddr(ps7_axi_periph_M04_AXI_ARADDR),
        .M04_AXI_arprot(ps7_axi_periph_M04_AXI_ARPROT),
        .M04_AXI_arready(ps7_axi_periph_M04_AXI_ARREADY),
        .M04_AXI_arvalid(ps7_axi_periph_M04_AXI_ARVALID),
        .M04_AXI_awaddr(ps7_axi_periph_M04_AXI_AWADDR),
        .M04_AXI_awprot(ps7_axi_periph_M04_AXI_AWPROT),
        .M04_AXI_awready(ps7_axi_periph_M04_AXI_AWREADY),
        .M04_AXI_awvalid(ps7_axi_periph_M04_AXI_AWVALID),
        .M04_AXI_bready(ps7_axi_periph_M04_AXI_BREADY),
        .M04_AXI_bresp(ps7_axi_periph_M04_AXI_BRESP),
        .M04_AXI_bvalid(ps7_axi_periph_M04_AXI_BVALID),
        .M04_AXI_rdata(ps7_axi_periph_M04_AXI_RDATA),
        .M04_AXI_rready(ps7_axi_periph_M04_AXI_RREADY),
        .M04_AXI_rresp(ps7_axi_periph_M04_AXI_RRESP),
        .M04_AXI_rvalid(ps7_axi_periph_M04_AXI_RVALID),
        .M04_AXI_wdata(ps7_axi_periph_M04_AXI_WDATA),
        .M04_AXI_wready(ps7_axi_periph_M04_AXI_WREADY),
        .M04_AXI_wstrb(ps7_axi_periph_M04_AXI_WSTRB),
        .M04_AXI_wvalid(ps7_axi_periph_M04_AXI_WVALID),
        .S00_ACLK(processing_system7_FCLK_CLK1),
        .S00_ARESETN(rst_ps7_125M_peripheral_aresetn),
        .S00_AXI_araddr(processing_system7_M_AXI_GP0_ARADDR),
        .S00_AXI_arburst(processing_system7_M_AXI_GP0_ARBURST),
        .S00_AXI_arcache(processing_system7_M_AXI_GP0_ARCACHE),
        .S00_AXI_arid(processing_system7_M_AXI_GP0_ARID),
        .S00_AXI_arlen(processing_system7_M_AXI_GP0_ARLEN),
        .S00_AXI_arlock(processing_system7_M_AXI_GP0_ARLOCK),
        .S00_AXI_arprot(processing_system7_M_AXI_GP0_ARPROT),
        .S00_AXI_arqos(processing_system7_M_AXI_GP0_ARQOS),
        .S00_AXI_arready(processing_system7_M_AXI_GP0_ARREADY),
        .S00_AXI_arsize(processing_system7_M_AXI_GP0_ARSIZE),
        .S00_AXI_arvalid(processing_system7_M_AXI_GP0_ARVALID),
        .S00_AXI_awaddr(processing_system7_M_AXI_GP0_AWADDR),
        .S00_AXI_awburst(processing_system7_M_AXI_GP0_AWBURST),
        .S00_AXI_awcache(processing_system7_M_AXI_GP0_AWCACHE),
        .S00_AXI_awid(processing_system7_M_AXI_GP0_AWID),
        .S00_AXI_awlen(processing_system7_M_AXI_GP0_AWLEN),
        .S00_AXI_awlock(processing_system7_M_AXI_GP0_AWLOCK),
        .S00_AXI_awprot(processing_system7_M_AXI_GP0_AWPROT),
        .S00_AXI_awqos(processing_system7_M_AXI_GP0_AWQOS),
        .S00_AXI_awready(processing_system7_M_AXI_GP0_AWREADY),
        .S00_AXI_awsize(processing_system7_M_AXI_GP0_AWSIZE),
        .S00_AXI_awvalid(processing_system7_M_AXI_GP0_AWVALID),
        .S00_AXI_bid(processing_system7_M_AXI_GP0_BID),
        .S00_AXI_bready(processing_system7_M_AXI_GP0_BREADY),
        .S00_AXI_bresp(processing_system7_M_AXI_GP0_BRESP),
        .S00_AXI_bvalid(processing_system7_M_AXI_GP0_BVALID),
        .S00_AXI_rdata(processing_system7_M_AXI_GP0_RDATA),
        .S00_AXI_rid(processing_system7_M_AXI_GP0_RID),
        .S00_AXI_rlast(processing_system7_M_AXI_GP0_RLAST),
        .S00_AXI_rready(processing_system7_M_AXI_GP0_RREADY),
        .S00_AXI_rresp(processing_system7_M_AXI_GP0_RRESP),
        .S00_AXI_rvalid(processing_system7_M_AXI_GP0_RVALID),
        .S00_AXI_wdata(processing_system7_M_AXI_GP0_WDATA),
        .S00_AXI_wid(processing_system7_M_AXI_GP0_WID),
        .S00_AXI_wlast(processing_system7_M_AXI_GP0_WLAST),
        .S00_AXI_wready(processing_system7_M_AXI_GP0_WREADY),
        .S00_AXI_wstrb(processing_system7_M_AXI_GP0_WSTRB),
        .S00_AXI_wvalid(processing_system7_M_AXI_GP0_WVALID));
  mixed16_4x4x1_rst_fsm_clk_0 rst_fsm_clk
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_ps7_62M_peripheral_aresetn),
        .peripheral_reset(rst_ps7_62M_peripheral_reset),
        .slowest_sync_clk(processing_system7_FCLK_CLK0));
  mixed16_4x4x1_rst_mem_clk_0 rst_mem_clk
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_ps7_125M_peripheral_aresetn),
        .peripheral_reset(rst_mem_clk_peripheral_reset),
        .slowest_sync_clk(processing_system7_FCLK_CLK1));
  mixed16_4x4x1_smartconnect_0_2 smartconnect_0
       (.M00_AXI_araddr(smartconnect_0_M00_AXI_ARADDR),
        .M00_AXI_arburst(smartconnect_0_M00_AXI_ARBURST),
        .M00_AXI_arcache(smartconnect_0_M00_AXI_ARCACHE),
        .M00_AXI_arlen(smartconnect_0_M00_AXI_ARLEN),
        .M00_AXI_arlock(smartconnect_0_M00_AXI_ARLOCK),
        .M00_AXI_arprot(smartconnect_0_M00_AXI_ARPROT),
        .M00_AXI_arqos(smartconnect_0_M00_AXI_ARQOS),
        .M00_AXI_arready(smartconnect_0_M00_AXI_ARREADY),
        .M00_AXI_arsize(smartconnect_0_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(smartconnect_0_M00_AXI_ARVALID),
        .M00_AXI_awaddr(smartconnect_0_M00_AXI_AWADDR),
        .M00_AXI_awburst(smartconnect_0_M00_AXI_AWBURST),
        .M00_AXI_awcache(smartconnect_0_M00_AXI_AWCACHE),
        .M00_AXI_awlen(smartconnect_0_M00_AXI_AWLEN),
        .M00_AXI_awlock(smartconnect_0_M00_AXI_AWLOCK),
        .M00_AXI_awprot(smartconnect_0_M00_AXI_AWPROT),
        .M00_AXI_awqos(smartconnect_0_M00_AXI_AWQOS),
        .M00_AXI_awready(smartconnect_0_M00_AXI_AWREADY),
        .M00_AXI_awsize(smartconnect_0_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(smartconnect_0_M00_AXI_AWVALID),
        .M00_AXI_bready(smartconnect_0_M00_AXI_BREADY),
        .M00_AXI_bresp(smartconnect_0_M00_AXI_BRESP),
        .M00_AXI_bvalid(smartconnect_0_M00_AXI_BVALID),
        .M00_AXI_rdata(smartconnect_0_M00_AXI_RDATA),
        .M00_AXI_rlast(smartconnect_0_M00_AXI_RLAST),
        .M00_AXI_rready(smartconnect_0_M00_AXI_RREADY),
        .M00_AXI_rresp(smartconnect_0_M00_AXI_RRESP),
        .M00_AXI_rvalid(smartconnect_0_M00_AXI_RVALID),
        .M00_AXI_wdata(smartconnect_0_M00_AXI_WDATA),
        .M00_AXI_wlast(smartconnect_0_M00_AXI_WLAST),
        .M00_AXI_wready(smartconnect_0_M00_AXI_WREADY),
        .M00_AXI_wstrb(smartconnect_0_M00_AXI_WSTRB),
        .M00_AXI_wvalid(smartconnect_0_M00_AXI_WVALID),
        .S00_AXI_araddr(axi_weight_dma_M_AXI_MM2S_ARADDR),
        .S00_AXI_arburst(axi_weight_dma_M_AXI_MM2S_ARBURST),
        .S00_AXI_arcache(axi_weight_dma_M_AXI_MM2S_ARCACHE),
        .S00_AXI_arlen(axi_weight_dma_M_AXI_MM2S_ARLEN),
        .S00_AXI_arlock(1'b0),
        .S00_AXI_arprot(axi_weight_dma_M_AXI_MM2S_ARPROT),
        .S00_AXI_arqos({1'b0,1'b0,1'b0,1'b0}),
        .S00_AXI_arready(axi_weight_dma_M_AXI_MM2S_ARREADY),
        .S00_AXI_arsize(axi_weight_dma_M_AXI_MM2S_ARSIZE),
        .S00_AXI_arvalid(axi_weight_dma_M_AXI_MM2S_ARVALID),
        .S00_AXI_rdata(axi_weight_dma_M_AXI_MM2S_RDATA),
        .S00_AXI_rlast(axi_weight_dma_M_AXI_MM2S_RLAST),
        .S00_AXI_rready(axi_weight_dma_M_AXI_MM2S_RREADY),
        .S00_AXI_rresp(axi_weight_dma_M_AXI_MM2S_RRESP),
        .S00_AXI_rvalid(axi_weight_dma_M_AXI_MM2S_RVALID),
        .S01_AXI_awaddr(axi_weight_dma_M_AXI_S2MM_AWADDR),
        .S01_AXI_awburst(axi_weight_dma_M_AXI_S2MM_AWBURST),
        .S01_AXI_awcache(axi_weight_dma_M_AXI_S2MM_AWCACHE),
        .S01_AXI_awlen(axi_weight_dma_M_AXI_S2MM_AWLEN),
        .S01_AXI_awlock(1'b0),
        .S01_AXI_awprot(axi_weight_dma_M_AXI_S2MM_AWPROT),
        .S01_AXI_awqos({1'b0,1'b0,1'b0,1'b0}),
        .S01_AXI_awready(axi_weight_dma_M_AXI_S2MM_AWREADY),
        .S01_AXI_awsize(axi_weight_dma_M_AXI_S2MM_AWSIZE),
        .S01_AXI_awvalid(axi_weight_dma_M_AXI_S2MM_AWVALID),
        .S01_AXI_bready(axi_weight_dma_M_AXI_S2MM_BREADY),
        .S01_AXI_bresp(axi_weight_dma_M_AXI_S2MM_BRESP),
        .S01_AXI_bvalid(axi_weight_dma_M_AXI_S2MM_BVALID),
        .S01_AXI_wdata(axi_weight_dma_M_AXI_S2MM_WDATA),
        .S01_AXI_wlast(axi_weight_dma_M_AXI_S2MM_WLAST),
        .S01_AXI_wready(axi_weight_dma_M_AXI_S2MM_WREADY),
        .S01_AXI_wstrb(axi_weight_dma_M_AXI_S2MM_WSTRB),
        .S01_AXI_wvalid(axi_weight_dma_M_AXI_S2MM_WVALID),
        .aclk(processing_system7_FCLK_CLK1),
        .aclk1(processing_system7_FCLK_CLK2),
        .aresetn(rst_ps7_125M_peripheral_aresetn));
endmodule

module mixed16_4x4x1_ps7_axi_periph_2
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arready,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awready,
    M00_AXI_awvalid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wready,
    M00_AXI_wvalid,
    M01_ACLK,
    M01_ARESETN,
    M01_AXI_araddr,
    M01_AXI_arprot,
    M01_AXI_arready,
    M01_AXI_arvalid,
    M01_AXI_awaddr,
    M01_AXI_awprot,
    M01_AXI_awready,
    M01_AXI_awvalid,
    M01_AXI_bready,
    M01_AXI_bresp,
    M01_AXI_bvalid,
    M01_AXI_rdata,
    M01_AXI_rready,
    M01_AXI_rresp,
    M01_AXI_rvalid,
    M01_AXI_wdata,
    M01_AXI_wready,
    M01_AXI_wstrb,
    M01_AXI_wvalid,
    M02_ACLK,
    M02_ARESETN,
    M02_AXI_araddr,
    M02_AXI_arprot,
    M02_AXI_arready,
    M02_AXI_arvalid,
    M02_AXI_awaddr,
    M02_AXI_awprot,
    M02_AXI_awready,
    M02_AXI_awvalid,
    M02_AXI_bready,
    M02_AXI_bresp,
    M02_AXI_bvalid,
    M02_AXI_rdata,
    M02_AXI_rready,
    M02_AXI_rresp,
    M02_AXI_rvalid,
    M02_AXI_wdata,
    M02_AXI_wready,
    M02_AXI_wstrb,
    M02_AXI_wvalid,
    M03_ACLK,
    M03_ARESETN,
    M03_AXI_araddr,
    M03_AXI_arprot,
    M03_AXI_arready,
    M03_AXI_arvalid,
    M03_AXI_awaddr,
    M03_AXI_awprot,
    M03_AXI_awready,
    M03_AXI_awvalid,
    M03_AXI_bready,
    M03_AXI_bresp,
    M03_AXI_bvalid,
    M03_AXI_rdata,
    M03_AXI_rready,
    M03_AXI_rresp,
    M03_AXI_rvalid,
    M03_AXI_wdata,
    M03_AXI_wready,
    M03_AXI_wstrb,
    M03_AXI_wvalid,
    M04_ACLK,
    M04_ARESETN,
    M04_AXI_araddr,
    M04_AXI_arprot,
    M04_AXI_arready,
    M04_AXI_arvalid,
    M04_AXI_awaddr,
    M04_AXI_awprot,
    M04_AXI_awready,
    M04_AXI_awvalid,
    M04_AXI_bready,
    M04_AXI_bresp,
    M04_AXI_bvalid,
    M04_AXI_rdata,
    M04_AXI_rready,
    M04_AXI_rresp,
    M04_AXI_rvalid,
    M04_AXI_wdata,
    M04_AXI_wready,
    M04_AXI_wstrb,
    M04_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_araddr,
    S00_AXI_arburst,
    S00_AXI_arcache,
    S00_AXI_arid,
    S00_AXI_arlen,
    S00_AXI_arlock,
    S00_AXI_arprot,
    S00_AXI_arqos,
    S00_AXI_arready,
    S00_AXI_arsize,
    S00_AXI_arvalid,
    S00_AXI_awaddr,
    S00_AXI_awburst,
    S00_AXI_awcache,
    S00_AXI_awid,
    S00_AXI_awlen,
    S00_AXI_awlock,
    S00_AXI_awprot,
    S00_AXI_awqos,
    S00_AXI_awready,
    S00_AXI_awsize,
    S00_AXI_awvalid,
    S00_AXI_bid,
    S00_AXI_bready,
    S00_AXI_bresp,
    S00_AXI_bvalid,
    S00_AXI_rdata,
    S00_AXI_rid,
    S00_AXI_rlast,
    S00_AXI_rready,
    S00_AXI_rresp,
    S00_AXI_rvalid,
    S00_AXI_wdata,
    S00_AXI_wid,
    S00_AXI_wlast,
    S00_AXI_wready,
    S00_AXI_wstrb,
    S00_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [9:0]M00_AXI_araddr;
  input M00_AXI_arready;
  output M00_AXI_arvalid;
  output [9:0]M00_AXI_awaddr;
  input M00_AXI_awready;
  output M00_AXI_awvalid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  input [31:0]M00_AXI_rdata;
  output M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input M00_AXI_rvalid;
  output [31:0]M00_AXI_wdata;
  input M00_AXI_wready;
  output M00_AXI_wvalid;
  input M01_ACLK;
  input M01_ARESETN;
  output [13:0]M01_AXI_araddr;
  output [2:0]M01_AXI_arprot;
  input M01_AXI_arready;
  output M01_AXI_arvalid;
  output [13:0]M01_AXI_awaddr;
  output [2:0]M01_AXI_awprot;
  input M01_AXI_awready;
  output M01_AXI_awvalid;
  output M01_AXI_bready;
  input [1:0]M01_AXI_bresp;
  input M01_AXI_bvalid;
  input [31:0]M01_AXI_rdata;
  output M01_AXI_rready;
  input [1:0]M01_AXI_rresp;
  input M01_AXI_rvalid;
  output [31:0]M01_AXI_wdata;
  input M01_AXI_wready;
  output [3:0]M01_AXI_wstrb;
  output M01_AXI_wvalid;
  input M02_ACLK;
  input M02_ARESETN;
  output [14:0]M02_AXI_araddr;
  output [2:0]M02_AXI_arprot;
  input M02_AXI_arready;
  output M02_AXI_arvalid;
  output [14:0]M02_AXI_awaddr;
  output [2:0]M02_AXI_awprot;
  input M02_AXI_awready;
  output M02_AXI_awvalid;
  output M02_AXI_bready;
  input [1:0]M02_AXI_bresp;
  input M02_AXI_bvalid;
  input [31:0]M02_AXI_rdata;
  output M02_AXI_rready;
  input [1:0]M02_AXI_rresp;
  input M02_AXI_rvalid;
  output [31:0]M02_AXI_wdata;
  input M02_AXI_wready;
  output [3:0]M02_AXI_wstrb;
  output M02_AXI_wvalid;
  input M03_ACLK;
  input M03_ARESETN;
  output [9:0]M03_AXI_araddr;
  output [2:0]M03_AXI_arprot;
  input M03_AXI_arready;
  output M03_AXI_arvalid;
  output [9:0]M03_AXI_awaddr;
  output [2:0]M03_AXI_awprot;
  input M03_AXI_awready;
  output M03_AXI_awvalid;
  output M03_AXI_bready;
  input [1:0]M03_AXI_bresp;
  input M03_AXI_bvalid;
  input [31:0]M03_AXI_rdata;
  output M03_AXI_rready;
  input [1:0]M03_AXI_rresp;
  input M03_AXI_rvalid;
  output [31:0]M03_AXI_wdata;
  input M03_AXI_wready;
  output [3:0]M03_AXI_wstrb;
  output M03_AXI_wvalid;
  input M04_ACLK;
  input M04_ARESETN;
  output [9:0]M04_AXI_araddr;
  output [2:0]M04_AXI_arprot;
  input M04_AXI_arready;
  output M04_AXI_arvalid;
  output [9:0]M04_AXI_awaddr;
  output [2:0]M04_AXI_awprot;
  input M04_AXI_awready;
  output M04_AXI_awvalid;
  output M04_AXI_bready;
  input [1:0]M04_AXI_bresp;
  input M04_AXI_bvalid;
  input [31:0]M04_AXI_rdata;
  output M04_AXI_rready;
  input [1:0]M04_AXI_rresp;
  input M04_AXI_rvalid;
  output [31:0]M04_AXI_wdata;
  input M04_AXI_wready;
  output [3:0]M04_AXI_wstrb;
  output M04_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_araddr;
  input [1:0]S00_AXI_arburst;
  input [3:0]S00_AXI_arcache;
  input [11:0]S00_AXI_arid;
  input [3:0]S00_AXI_arlen;
  input [1:0]S00_AXI_arlock;
  input [2:0]S00_AXI_arprot;
  input [3:0]S00_AXI_arqos;
  output S00_AXI_arready;
  input [2:0]S00_AXI_arsize;
  input S00_AXI_arvalid;
  input [31:0]S00_AXI_awaddr;
  input [1:0]S00_AXI_awburst;
  input [3:0]S00_AXI_awcache;
  input [11:0]S00_AXI_awid;
  input [3:0]S00_AXI_awlen;
  input [1:0]S00_AXI_awlock;
  input [2:0]S00_AXI_awprot;
  input [3:0]S00_AXI_awqos;
  output S00_AXI_awready;
  input [2:0]S00_AXI_awsize;
  input S00_AXI_awvalid;
  output [11:0]S00_AXI_bid;
  input S00_AXI_bready;
  output [1:0]S00_AXI_bresp;
  output S00_AXI_bvalid;
  output [31:0]S00_AXI_rdata;
  output [11:0]S00_AXI_rid;
  output S00_AXI_rlast;
  input S00_AXI_rready;
  output [1:0]S00_AXI_rresp;
  output S00_AXI_rvalid;
  input [31:0]S00_AXI_wdata;
  input [11:0]S00_AXI_wid;
  input S00_AXI_wlast;
  output S00_AXI_wready;
  input [3:0]S00_AXI_wstrb;
  input S00_AXI_wvalid;

  wire M00_ACLK_1;
  wire M00_ARESETN_1;
  wire M01_ACLK_1;
  wire M01_ARESETN_1;
  wire M02_ACLK_1;
  wire M02_ARESETN_1;
  wire M03_ACLK_1;
  wire M03_ARESETN_1;
  wire M04_ACLK_1;
  wire M04_ARESETN_1;
  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire [9:0]m00_couplers_to_ps7_axi_periph_ARADDR;
  wire m00_couplers_to_ps7_axi_periph_ARREADY;
  wire m00_couplers_to_ps7_axi_periph_ARVALID;
  wire [9:0]m00_couplers_to_ps7_axi_periph_AWADDR;
  wire m00_couplers_to_ps7_axi_periph_AWREADY;
  wire m00_couplers_to_ps7_axi_periph_AWVALID;
  wire m00_couplers_to_ps7_axi_periph_BREADY;
  wire [1:0]m00_couplers_to_ps7_axi_periph_BRESP;
  wire m00_couplers_to_ps7_axi_periph_BVALID;
  wire [31:0]m00_couplers_to_ps7_axi_periph_RDATA;
  wire m00_couplers_to_ps7_axi_periph_RREADY;
  wire [1:0]m00_couplers_to_ps7_axi_periph_RRESP;
  wire m00_couplers_to_ps7_axi_periph_RVALID;
  wire [31:0]m00_couplers_to_ps7_axi_periph_WDATA;
  wire m00_couplers_to_ps7_axi_periph_WREADY;
  wire m00_couplers_to_ps7_axi_periph_WVALID;
  wire [13:0]m01_couplers_to_ps7_axi_periph_ARADDR;
  wire [2:0]m01_couplers_to_ps7_axi_periph_ARPROT;
  wire m01_couplers_to_ps7_axi_periph_ARREADY;
  wire m01_couplers_to_ps7_axi_periph_ARVALID;
  wire [13:0]m01_couplers_to_ps7_axi_periph_AWADDR;
  wire [2:0]m01_couplers_to_ps7_axi_periph_AWPROT;
  wire m01_couplers_to_ps7_axi_periph_AWREADY;
  wire m01_couplers_to_ps7_axi_periph_AWVALID;
  wire m01_couplers_to_ps7_axi_periph_BREADY;
  wire [1:0]m01_couplers_to_ps7_axi_periph_BRESP;
  wire m01_couplers_to_ps7_axi_periph_BVALID;
  wire [31:0]m01_couplers_to_ps7_axi_periph_RDATA;
  wire m01_couplers_to_ps7_axi_periph_RREADY;
  wire [1:0]m01_couplers_to_ps7_axi_periph_RRESP;
  wire m01_couplers_to_ps7_axi_periph_RVALID;
  wire [31:0]m01_couplers_to_ps7_axi_periph_WDATA;
  wire m01_couplers_to_ps7_axi_periph_WREADY;
  wire [3:0]m01_couplers_to_ps7_axi_periph_WSTRB;
  wire m01_couplers_to_ps7_axi_periph_WVALID;
  wire [14:0]m02_couplers_to_ps7_axi_periph_ARADDR;
  wire [2:0]m02_couplers_to_ps7_axi_periph_ARPROT;
  wire m02_couplers_to_ps7_axi_periph_ARREADY;
  wire m02_couplers_to_ps7_axi_periph_ARVALID;
  wire [14:0]m02_couplers_to_ps7_axi_periph_AWADDR;
  wire [2:0]m02_couplers_to_ps7_axi_periph_AWPROT;
  wire m02_couplers_to_ps7_axi_periph_AWREADY;
  wire m02_couplers_to_ps7_axi_periph_AWVALID;
  wire m02_couplers_to_ps7_axi_periph_BREADY;
  wire [1:0]m02_couplers_to_ps7_axi_periph_BRESP;
  wire m02_couplers_to_ps7_axi_periph_BVALID;
  wire [31:0]m02_couplers_to_ps7_axi_periph_RDATA;
  wire m02_couplers_to_ps7_axi_periph_RREADY;
  wire [1:0]m02_couplers_to_ps7_axi_periph_RRESP;
  wire m02_couplers_to_ps7_axi_periph_RVALID;
  wire [31:0]m02_couplers_to_ps7_axi_periph_WDATA;
  wire m02_couplers_to_ps7_axi_periph_WREADY;
  wire [3:0]m02_couplers_to_ps7_axi_periph_WSTRB;
  wire m02_couplers_to_ps7_axi_periph_WVALID;
  wire [9:0]m03_couplers_to_ps7_axi_periph_ARADDR;
  wire [2:0]m03_couplers_to_ps7_axi_periph_ARPROT;
  wire m03_couplers_to_ps7_axi_periph_ARREADY;
  wire m03_couplers_to_ps7_axi_periph_ARVALID;
  wire [9:0]m03_couplers_to_ps7_axi_periph_AWADDR;
  wire [2:0]m03_couplers_to_ps7_axi_periph_AWPROT;
  wire m03_couplers_to_ps7_axi_periph_AWREADY;
  wire m03_couplers_to_ps7_axi_periph_AWVALID;
  wire m03_couplers_to_ps7_axi_periph_BREADY;
  wire [1:0]m03_couplers_to_ps7_axi_periph_BRESP;
  wire m03_couplers_to_ps7_axi_periph_BVALID;
  wire [31:0]m03_couplers_to_ps7_axi_periph_RDATA;
  wire m03_couplers_to_ps7_axi_periph_RREADY;
  wire [1:0]m03_couplers_to_ps7_axi_periph_RRESP;
  wire m03_couplers_to_ps7_axi_periph_RVALID;
  wire [31:0]m03_couplers_to_ps7_axi_periph_WDATA;
  wire m03_couplers_to_ps7_axi_periph_WREADY;
  wire [3:0]m03_couplers_to_ps7_axi_periph_WSTRB;
  wire m03_couplers_to_ps7_axi_periph_WVALID;
  wire [9:0]m04_couplers_to_ps7_axi_periph_ARADDR;
  wire [2:0]m04_couplers_to_ps7_axi_periph_ARPROT;
  wire m04_couplers_to_ps7_axi_periph_ARREADY;
  wire m04_couplers_to_ps7_axi_periph_ARVALID;
  wire [9:0]m04_couplers_to_ps7_axi_periph_AWADDR;
  wire [2:0]m04_couplers_to_ps7_axi_periph_AWPROT;
  wire m04_couplers_to_ps7_axi_periph_AWREADY;
  wire m04_couplers_to_ps7_axi_periph_AWVALID;
  wire m04_couplers_to_ps7_axi_periph_BREADY;
  wire [1:0]m04_couplers_to_ps7_axi_periph_BRESP;
  wire m04_couplers_to_ps7_axi_periph_BVALID;
  wire [31:0]m04_couplers_to_ps7_axi_periph_RDATA;
  wire m04_couplers_to_ps7_axi_periph_RREADY;
  wire [1:0]m04_couplers_to_ps7_axi_periph_RRESP;
  wire m04_couplers_to_ps7_axi_periph_RVALID;
  wire [31:0]m04_couplers_to_ps7_axi_periph_WDATA;
  wire m04_couplers_to_ps7_axi_periph_WREADY;
  wire [3:0]m04_couplers_to_ps7_axi_periph_WSTRB;
  wire m04_couplers_to_ps7_axi_periph_WVALID;
  wire ps7_axi_periph_ACLK_net;
  wire ps7_axi_periph_ARESETN_net;
  wire [31:0]ps7_axi_periph_to_s00_couplers_ARADDR;
  wire [1:0]ps7_axi_periph_to_s00_couplers_ARBURST;
  wire [3:0]ps7_axi_periph_to_s00_couplers_ARCACHE;
  wire [11:0]ps7_axi_periph_to_s00_couplers_ARID;
  wire [3:0]ps7_axi_periph_to_s00_couplers_ARLEN;
  wire [1:0]ps7_axi_periph_to_s00_couplers_ARLOCK;
  wire [2:0]ps7_axi_periph_to_s00_couplers_ARPROT;
  wire [3:0]ps7_axi_periph_to_s00_couplers_ARQOS;
  wire ps7_axi_periph_to_s00_couplers_ARREADY;
  wire [2:0]ps7_axi_periph_to_s00_couplers_ARSIZE;
  wire ps7_axi_periph_to_s00_couplers_ARVALID;
  wire [31:0]ps7_axi_periph_to_s00_couplers_AWADDR;
  wire [1:0]ps7_axi_periph_to_s00_couplers_AWBURST;
  wire [3:0]ps7_axi_periph_to_s00_couplers_AWCACHE;
  wire [11:0]ps7_axi_periph_to_s00_couplers_AWID;
  wire [3:0]ps7_axi_periph_to_s00_couplers_AWLEN;
  wire [1:0]ps7_axi_periph_to_s00_couplers_AWLOCK;
  wire [2:0]ps7_axi_periph_to_s00_couplers_AWPROT;
  wire [3:0]ps7_axi_periph_to_s00_couplers_AWQOS;
  wire ps7_axi_periph_to_s00_couplers_AWREADY;
  wire [2:0]ps7_axi_periph_to_s00_couplers_AWSIZE;
  wire ps7_axi_periph_to_s00_couplers_AWVALID;
  wire [11:0]ps7_axi_periph_to_s00_couplers_BID;
  wire ps7_axi_periph_to_s00_couplers_BREADY;
  wire [1:0]ps7_axi_periph_to_s00_couplers_BRESP;
  wire ps7_axi_periph_to_s00_couplers_BVALID;
  wire [31:0]ps7_axi_periph_to_s00_couplers_RDATA;
  wire [11:0]ps7_axi_periph_to_s00_couplers_RID;
  wire ps7_axi_periph_to_s00_couplers_RLAST;
  wire ps7_axi_periph_to_s00_couplers_RREADY;
  wire [1:0]ps7_axi_periph_to_s00_couplers_RRESP;
  wire ps7_axi_periph_to_s00_couplers_RVALID;
  wire [31:0]ps7_axi_periph_to_s00_couplers_WDATA;
  wire [11:0]ps7_axi_periph_to_s00_couplers_WID;
  wire ps7_axi_periph_to_s00_couplers_WLAST;
  wire ps7_axi_periph_to_s00_couplers_WREADY;
  wire [3:0]ps7_axi_periph_to_s00_couplers_WSTRB;
  wire ps7_axi_periph_to_s00_couplers_WVALID;
  wire [31:0]s00_couplers_to_xbar_ARADDR;
  wire [2:0]s00_couplers_to_xbar_ARPROT;
  wire [0:0]s00_couplers_to_xbar_ARREADY;
  wire s00_couplers_to_xbar_ARVALID;
  wire [31:0]s00_couplers_to_xbar_AWADDR;
  wire [2:0]s00_couplers_to_xbar_AWPROT;
  wire [0:0]s00_couplers_to_xbar_AWREADY;
  wire s00_couplers_to_xbar_AWVALID;
  wire s00_couplers_to_xbar_BREADY;
  wire [1:0]s00_couplers_to_xbar_BRESP;
  wire [0:0]s00_couplers_to_xbar_BVALID;
  wire [31:0]s00_couplers_to_xbar_RDATA;
  wire s00_couplers_to_xbar_RREADY;
  wire [1:0]s00_couplers_to_xbar_RRESP;
  wire [0:0]s00_couplers_to_xbar_RVALID;
  wire [31:0]s00_couplers_to_xbar_WDATA;
  wire [0:0]s00_couplers_to_xbar_WREADY;
  wire [3:0]s00_couplers_to_xbar_WSTRB;
  wire s00_couplers_to_xbar_WVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [2:0]xbar_to_m00_couplers_ARPROT;
  wire xbar_to_m00_couplers_ARREADY;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [2:0]xbar_to_m00_couplers_AWPROT;
  wire xbar_to_m00_couplers_AWREADY;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire xbar_to_m00_couplers_BVALID;
  wire [31:0]xbar_to_m00_couplers_RDATA;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire xbar_to_m00_couplers_RVALID;
  wire [31:0]xbar_to_m00_couplers_WDATA;
  wire xbar_to_m00_couplers_WREADY;
  wire [3:0]xbar_to_m00_couplers_WSTRB;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [63:32]xbar_to_m01_couplers_ARADDR;
  wire [5:3]xbar_to_m01_couplers_ARPROT;
  wire xbar_to_m01_couplers_ARREADY;
  wire [1:1]xbar_to_m01_couplers_ARVALID;
  wire [63:32]xbar_to_m01_couplers_AWADDR;
  wire [5:3]xbar_to_m01_couplers_AWPROT;
  wire xbar_to_m01_couplers_AWREADY;
  wire [1:1]xbar_to_m01_couplers_AWVALID;
  wire [1:1]xbar_to_m01_couplers_BREADY;
  wire [1:0]xbar_to_m01_couplers_BRESP;
  wire xbar_to_m01_couplers_BVALID;
  wire [31:0]xbar_to_m01_couplers_RDATA;
  wire [1:1]xbar_to_m01_couplers_RREADY;
  wire [1:0]xbar_to_m01_couplers_RRESP;
  wire xbar_to_m01_couplers_RVALID;
  wire [63:32]xbar_to_m01_couplers_WDATA;
  wire xbar_to_m01_couplers_WREADY;
  wire [7:4]xbar_to_m01_couplers_WSTRB;
  wire [1:1]xbar_to_m01_couplers_WVALID;
  wire [95:64]xbar_to_m02_couplers_ARADDR;
  wire [8:6]xbar_to_m02_couplers_ARPROT;
  wire xbar_to_m02_couplers_ARREADY;
  wire [2:2]xbar_to_m02_couplers_ARVALID;
  wire [95:64]xbar_to_m02_couplers_AWADDR;
  wire [8:6]xbar_to_m02_couplers_AWPROT;
  wire xbar_to_m02_couplers_AWREADY;
  wire [2:2]xbar_to_m02_couplers_AWVALID;
  wire [2:2]xbar_to_m02_couplers_BREADY;
  wire [1:0]xbar_to_m02_couplers_BRESP;
  wire xbar_to_m02_couplers_BVALID;
  wire [31:0]xbar_to_m02_couplers_RDATA;
  wire [2:2]xbar_to_m02_couplers_RREADY;
  wire [1:0]xbar_to_m02_couplers_RRESP;
  wire xbar_to_m02_couplers_RVALID;
  wire [95:64]xbar_to_m02_couplers_WDATA;
  wire xbar_to_m02_couplers_WREADY;
  wire [11:8]xbar_to_m02_couplers_WSTRB;
  wire [2:2]xbar_to_m02_couplers_WVALID;
  wire [127:96]xbar_to_m03_couplers_ARADDR;
  wire [11:9]xbar_to_m03_couplers_ARPROT;
  wire xbar_to_m03_couplers_ARREADY;
  wire [3:3]xbar_to_m03_couplers_ARVALID;
  wire [127:96]xbar_to_m03_couplers_AWADDR;
  wire [11:9]xbar_to_m03_couplers_AWPROT;
  wire xbar_to_m03_couplers_AWREADY;
  wire [3:3]xbar_to_m03_couplers_AWVALID;
  wire [3:3]xbar_to_m03_couplers_BREADY;
  wire [1:0]xbar_to_m03_couplers_BRESP;
  wire xbar_to_m03_couplers_BVALID;
  wire [31:0]xbar_to_m03_couplers_RDATA;
  wire [3:3]xbar_to_m03_couplers_RREADY;
  wire [1:0]xbar_to_m03_couplers_RRESP;
  wire xbar_to_m03_couplers_RVALID;
  wire [127:96]xbar_to_m03_couplers_WDATA;
  wire xbar_to_m03_couplers_WREADY;
  wire [15:12]xbar_to_m03_couplers_WSTRB;
  wire [3:3]xbar_to_m03_couplers_WVALID;
  wire [159:128]xbar_to_m04_couplers_ARADDR;
  wire [14:12]xbar_to_m04_couplers_ARPROT;
  wire xbar_to_m04_couplers_ARREADY;
  wire [4:4]xbar_to_m04_couplers_ARVALID;
  wire [159:128]xbar_to_m04_couplers_AWADDR;
  wire [14:12]xbar_to_m04_couplers_AWPROT;
  wire xbar_to_m04_couplers_AWREADY;
  wire [4:4]xbar_to_m04_couplers_AWVALID;
  wire [4:4]xbar_to_m04_couplers_BREADY;
  wire [1:0]xbar_to_m04_couplers_BRESP;
  wire xbar_to_m04_couplers_BVALID;
  wire [31:0]xbar_to_m04_couplers_RDATA;
  wire [4:4]xbar_to_m04_couplers_RREADY;
  wire [1:0]xbar_to_m04_couplers_RRESP;
  wire xbar_to_m04_couplers_RVALID;
  wire [159:128]xbar_to_m04_couplers_WDATA;
  wire xbar_to_m04_couplers_WREADY;
  wire [19:16]xbar_to_m04_couplers_WSTRB;
  wire [4:4]xbar_to_m04_couplers_WVALID;

  assign M00_ACLK_1 = M00_ACLK;
  assign M00_ARESETN_1 = M00_ARESETN;
  assign M00_AXI_araddr[9:0] = m00_couplers_to_ps7_axi_periph_ARADDR;
  assign M00_AXI_arvalid = m00_couplers_to_ps7_axi_periph_ARVALID;
  assign M00_AXI_awaddr[9:0] = m00_couplers_to_ps7_axi_periph_AWADDR;
  assign M00_AXI_awvalid = m00_couplers_to_ps7_axi_periph_AWVALID;
  assign M00_AXI_bready = m00_couplers_to_ps7_axi_periph_BREADY;
  assign M00_AXI_rready = m00_couplers_to_ps7_axi_periph_RREADY;
  assign M00_AXI_wdata[31:0] = m00_couplers_to_ps7_axi_periph_WDATA;
  assign M00_AXI_wvalid = m00_couplers_to_ps7_axi_periph_WVALID;
  assign M01_ACLK_1 = M01_ACLK;
  assign M01_ARESETN_1 = M01_ARESETN;
  assign M01_AXI_araddr[13:0] = m01_couplers_to_ps7_axi_periph_ARADDR;
  assign M01_AXI_arprot[2:0] = m01_couplers_to_ps7_axi_periph_ARPROT;
  assign M01_AXI_arvalid = m01_couplers_to_ps7_axi_periph_ARVALID;
  assign M01_AXI_awaddr[13:0] = m01_couplers_to_ps7_axi_periph_AWADDR;
  assign M01_AXI_awprot[2:0] = m01_couplers_to_ps7_axi_periph_AWPROT;
  assign M01_AXI_awvalid = m01_couplers_to_ps7_axi_periph_AWVALID;
  assign M01_AXI_bready = m01_couplers_to_ps7_axi_periph_BREADY;
  assign M01_AXI_rready = m01_couplers_to_ps7_axi_periph_RREADY;
  assign M01_AXI_wdata[31:0] = m01_couplers_to_ps7_axi_periph_WDATA;
  assign M01_AXI_wstrb[3:0] = m01_couplers_to_ps7_axi_periph_WSTRB;
  assign M01_AXI_wvalid = m01_couplers_to_ps7_axi_periph_WVALID;
  assign M02_ACLK_1 = M02_ACLK;
  assign M02_ARESETN_1 = M02_ARESETN;
  assign M02_AXI_araddr[14:0] = m02_couplers_to_ps7_axi_periph_ARADDR;
  assign M02_AXI_arprot[2:0] = m02_couplers_to_ps7_axi_periph_ARPROT;
  assign M02_AXI_arvalid = m02_couplers_to_ps7_axi_periph_ARVALID;
  assign M02_AXI_awaddr[14:0] = m02_couplers_to_ps7_axi_periph_AWADDR;
  assign M02_AXI_awprot[2:0] = m02_couplers_to_ps7_axi_periph_AWPROT;
  assign M02_AXI_awvalid = m02_couplers_to_ps7_axi_periph_AWVALID;
  assign M02_AXI_bready = m02_couplers_to_ps7_axi_periph_BREADY;
  assign M02_AXI_rready = m02_couplers_to_ps7_axi_periph_RREADY;
  assign M02_AXI_wdata[31:0] = m02_couplers_to_ps7_axi_periph_WDATA;
  assign M02_AXI_wstrb[3:0] = m02_couplers_to_ps7_axi_periph_WSTRB;
  assign M02_AXI_wvalid = m02_couplers_to_ps7_axi_periph_WVALID;
  assign M03_ACLK_1 = M03_ACLK;
  assign M03_ARESETN_1 = M03_ARESETN;
  assign M03_AXI_araddr[9:0] = m03_couplers_to_ps7_axi_periph_ARADDR;
  assign M03_AXI_arprot[2:0] = m03_couplers_to_ps7_axi_periph_ARPROT;
  assign M03_AXI_arvalid = m03_couplers_to_ps7_axi_periph_ARVALID;
  assign M03_AXI_awaddr[9:0] = m03_couplers_to_ps7_axi_periph_AWADDR;
  assign M03_AXI_awprot[2:0] = m03_couplers_to_ps7_axi_periph_AWPROT;
  assign M03_AXI_awvalid = m03_couplers_to_ps7_axi_periph_AWVALID;
  assign M03_AXI_bready = m03_couplers_to_ps7_axi_periph_BREADY;
  assign M03_AXI_rready = m03_couplers_to_ps7_axi_periph_RREADY;
  assign M03_AXI_wdata[31:0] = m03_couplers_to_ps7_axi_periph_WDATA;
  assign M03_AXI_wstrb[3:0] = m03_couplers_to_ps7_axi_periph_WSTRB;
  assign M03_AXI_wvalid = m03_couplers_to_ps7_axi_periph_WVALID;
  assign M04_ACLK_1 = M04_ACLK;
  assign M04_ARESETN_1 = M04_ARESETN;
  assign M04_AXI_araddr[9:0] = m04_couplers_to_ps7_axi_periph_ARADDR;
  assign M04_AXI_arprot[2:0] = m04_couplers_to_ps7_axi_periph_ARPROT;
  assign M04_AXI_arvalid = m04_couplers_to_ps7_axi_periph_ARVALID;
  assign M04_AXI_awaddr[9:0] = m04_couplers_to_ps7_axi_periph_AWADDR;
  assign M04_AXI_awprot[2:0] = m04_couplers_to_ps7_axi_periph_AWPROT;
  assign M04_AXI_awvalid = m04_couplers_to_ps7_axi_periph_AWVALID;
  assign M04_AXI_bready = m04_couplers_to_ps7_axi_periph_BREADY;
  assign M04_AXI_rready = m04_couplers_to_ps7_axi_periph_RREADY;
  assign M04_AXI_wdata[31:0] = m04_couplers_to_ps7_axi_periph_WDATA;
  assign M04_AXI_wstrb[3:0] = m04_couplers_to_ps7_axi_periph_WSTRB;
  assign M04_AXI_wvalid = m04_couplers_to_ps7_axi_periph_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_arready = ps7_axi_periph_to_s00_couplers_ARREADY;
  assign S00_AXI_awready = ps7_axi_periph_to_s00_couplers_AWREADY;
  assign S00_AXI_bid[11:0] = ps7_axi_periph_to_s00_couplers_BID;
  assign S00_AXI_bresp[1:0] = ps7_axi_periph_to_s00_couplers_BRESP;
  assign S00_AXI_bvalid = ps7_axi_periph_to_s00_couplers_BVALID;
  assign S00_AXI_rdata[31:0] = ps7_axi_periph_to_s00_couplers_RDATA;
  assign S00_AXI_rid[11:0] = ps7_axi_periph_to_s00_couplers_RID;
  assign S00_AXI_rlast = ps7_axi_periph_to_s00_couplers_RLAST;
  assign S00_AXI_rresp[1:0] = ps7_axi_periph_to_s00_couplers_RRESP;
  assign S00_AXI_rvalid = ps7_axi_periph_to_s00_couplers_RVALID;
  assign S00_AXI_wready = ps7_axi_periph_to_s00_couplers_WREADY;
  assign m00_couplers_to_ps7_axi_periph_ARREADY = M00_AXI_arready;
  assign m00_couplers_to_ps7_axi_periph_AWREADY = M00_AXI_awready;
  assign m00_couplers_to_ps7_axi_periph_BRESP = M00_AXI_bresp[1:0];
  assign m00_couplers_to_ps7_axi_periph_BVALID = M00_AXI_bvalid;
  assign m00_couplers_to_ps7_axi_periph_RDATA = M00_AXI_rdata[31:0];
  assign m00_couplers_to_ps7_axi_periph_RRESP = M00_AXI_rresp[1:0];
  assign m00_couplers_to_ps7_axi_periph_RVALID = M00_AXI_rvalid;
  assign m00_couplers_to_ps7_axi_periph_WREADY = M00_AXI_wready;
  assign m01_couplers_to_ps7_axi_periph_ARREADY = M01_AXI_arready;
  assign m01_couplers_to_ps7_axi_periph_AWREADY = M01_AXI_awready;
  assign m01_couplers_to_ps7_axi_periph_BRESP = M01_AXI_bresp[1:0];
  assign m01_couplers_to_ps7_axi_periph_BVALID = M01_AXI_bvalid;
  assign m01_couplers_to_ps7_axi_periph_RDATA = M01_AXI_rdata[31:0];
  assign m01_couplers_to_ps7_axi_periph_RRESP = M01_AXI_rresp[1:0];
  assign m01_couplers_to_ps7_axi_periph_RVALID = M01_AXI_rvalid;
  assign m01_couplers_to_ps7_axi_periph_WREADY = M01_AXI_wready;
  assign m02_couplers_to_ps7_axi_periph_ARREADY = M02_AXI_arready;
  assign m02_couplers_to_ps7_axi_periph_AWREADY = M02_AXI_awready;
  assign m02_couplers_to_ps7_axi_periph_BRESP = M02_AXI_bresp[1:0];
  assign m02_couplers_to_ps7_axi_periph_BVALID = M02_AXI_bvalid;
  assign m02_couplers_to_ps7_axi_periph_RDATA = M02_AXI_rdata[31:0];
  assign m02_couplers_to_ps7_axi_periph_RRESP = M02_AXI_rresp[1:0];
  assign m02_couplers_to_ps7_axi_periph_RVALID = M02_AXI_rvalid;
  assign m02_couplers_to_ps7_axi_periph_WREADY = M02_AXI_wready;
  assign m03_couplers_to_ps7_axi_periph_ARREADY = M03_AXI_arready;
  assign m03_couplers_to_ps7_axi_periph_AWREADY = M03_AXI_awready;
  assign m03_couplers_to_ps7_axi_periph_BRESP = M03_AXI_bresp[1:0];
  assign m03_couplers_to_ps7_axi_periph_BVALID = M03_AXI_bvalid;
  assign m03_couplers_to_ps7_axi_periph_RDATA = M03_AXI_rdata[31:0];
  assign m03_couplers_to_ps7_axi_periph_RRESP = M03_AXI_rresp[1:0];
  assign m03_couplers_to_ps7_axi_periph_RVALID = M03_AXI_rvalid;
  assign m03_couplers_to_ps7_axi_periph_WREADY = M03_AXI_wready;
  assign m04_couplers_to_ps7_axi_periph_ARREADY = M04_AXI_arready;
  assign m04_couplers_to_ps7_axi_periph_AWREADY = M04_AXI_awready;
  assign m04_couplers_to_ps7_axi_periph_BRESP = M04_AXI_bresp[1:0];
  assign m04_couplers_to_ps7_axi_periph_BVALID = M04_AXI_bvalid;
  assign m04_couplers_to_ps7_axi_periph_RDATA = M04_AXI_rdata[31:0];
  assign m04_couplers_to_ps7_axi_periph_RRESP = M04_AXI_rresp[1:0];
  assign m04_couplers_to_ps7_axi_periph_RVALID = M04_AXI_rvalid;
  assign m04_couplers_to_ps7_axi_periph_WREADY = M04_AXI_wready;
  assign ps7_axi_periph_ACLK_net = ACLK;
  assign ps7_axi_periph_ARESETN_net = ARESETN;
  assign ps7_axi_periph_to_s00_couplers_ARADDR = S00_AXI_araddr[31:0];
  assign ps7_axi_periph_to_s00_couplers_ARBURST = S00_AXI_arburst[1:0];
  assign ps7_axi_periph_to_s00_couplers_ARCACHE = S00_AXI_arcache[3:0];
  assign ps7_axi_periph_to_s00_couplers_ARID = S00_AXI_arid[11:0];
  assign ps7_axi_periph_to_s00_couplers_ARLEN = S00_AXI_arlen[3:0];
  assign ps7_axi_periph_to_s00_couplers_ARLOCK = S00_AXI_arlock[1:0];
  assign ps7_axi_periph_to_s00_couplers_ARPROT = S00_AXI_arprot[2:0];
  assign ps7_axi_periph_to_s00_couplers_ARQOS = S00_AXI_arqos[3:0];
  assign ps7_axi_periph_to_s00_couplers_ARSIZE = S00_AXI_arsize[2:0];
  assign ps7_axi_periph_to_s00_couplers_ARVALID = S00_AXI_arvalid;
  assign ps7_axi_periph_to_s00_couplers_AWADDR = S00_AXI_awaddr[31:0];
  assign ps7_axi_periph_to_s00_couplers_AWBURST = S00_AXI_awburst[1:0];
  assign ps7_axi_periph_to_s00_couplers_AWCACHE = S00_AXI_awcache[3:0];
  assign ps7_axi_periph_to_s00_couplers_AWID = S00_AXI_awid[11:0];
  assign ps7_axi_periph_to_s00_couplers_AWLEN = S00_AXI_awlen[3:0];
  assign ps7_axi_periph_to_s00_couplers_AWLOCK = S00_AXI_awlock[1:0];
  assign ps7_axi_periph_to_s00_couplers_AWPROT = S00_AXI_awprot[2:0];
  assign ps7_axi_periph_to_s00_couplers_AWQOS = S00_AXI_awqos[3:0];
  assign ps7_axi_periph_to_s00_couplers_AWSIZE = S00_AXI_awsize[2:0];
  assign ps7_axi_periph_to_s00_couplers_AWVALID = S00_AXI_awvalid;
  assign ps7_axi_periph_to_s00_couplers_BREADY = S00_AXI_bready;
  assign ps7_axi_periph_to_s00_couplers_RREADY = S00_AXI_rready;
  assign ps7_axi_periph_to_s00_couplers_WDATA = S00_AXI_wdata[31:0];
  assign ps7_axi_periph_to_s00_couplers_WID = S00_AXI_wid[11:0];
  assign ps7_axi_periph_to_s00_couplers_WLAST = S00_AXI_wlast;
  assign ps7_axi_periph_to_s00_couplers_WSTRB = S00_AXI_wstrb[3:0];
  assign ps7_axi_periph_to_s00_couplers_WVALID = S00_AXI_wvalid;
  m00_couplers_imp_UOWV13 m00_couplers
       (.M_ACLK(M00_ACLK_1),
        .M_ARESETN(M00_ARESETN_1),
        .M_AXI_araddr(m00_couplers_to_ps7_axi_periph_ARADDR),
        .M_AXI_arready(m00_couplers_to_ps7_axi_periph_ARREADY),
        .M_AXI_arvalid(m00_couplers_to_ps7_axi_periph_ARVALID),
        .M_AXI_awaddr(m00_couplers_to_ps7_axi_periph_AWADDR),
        .M_AXI_awready(m00_couplers_to_ps7_axi_periph_AWREADY),
        .M_AXI_awvalid(m00_couplers_to_ps7_axi_periph_AWVALID),
        .M_AXI_bready(m00_couplers_to_ps7_axi_periph_BREADY),
        .M_AXI_bresp(m00_couplers_to_ps7_axi_periph_BRESP),
        .M_AXI_bvalid(m00_couplers_to_ps7_axi_periph_BVALID),
        .M_AXI_rdata(m00_couplers_to_ps7_axi_periph_RDATA),
        .M_AXI_rready(m00_couplers_to_ps7_axi_periph_RREADY),
        .M_AXI_rresp(m00_couplers_to_ps7_axi_periph_RRESP),
        .M_AXI_rvalid(m00_couplers_to_ps7_axi_periph_RVALID),
        .M_AXI_wdata(m00_couplers_to_ps7_axi_periph_WDATA),
        .M_AXI_wready(m00_couplers_to_ps7_axi_periph_WREADY),
        .M_AXI_wvalid(m00_couplers_to_ps7_axi_periph_WVALID),
        .S_ACLK(ps7_axi_periph_ACLK_net),
        .S_ARESETN(ps7_axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m00_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m00_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m00_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  m01_couplers_imp_1W8JCUB m01_couplers
       (.M_ACLK(M01_ACLK_1),
        .M_ARESETN(M01_ARESETN_1),
        .M_AXI_araddr(m01_couplers_to_ps7_axi_periph_ARADDR),
        .M_AXI_arprot(m01_couplers_to_ps7_axi_periph_ARPROT),
        .M_AXI_arready(m01_couplers_to_ps7_axi_periph_ARREADY),
        .M_AXI_arvalid(m01_couplers_to_ps7_axi_periph_ARVALID),
        .M_AXI_awaddr(m01_couplers_to_ps7_axi_periph_AWADDR),
        .M_AXI_awprot(m01_couplers_to_ps7_axi_periph_AWPROT),
        .M_AXI_awready(m01_couplers_to_ps7_axi_periph_AWREADY),
        .M_AXI_awvalid(m01_couplers_to_ps7_axi_periph_AWVALID),
        .M_AXI_bready(m01_couplers_to_ps7_axi_periph_BREADY),
        .M_AXI_bresp(m01_couplers_to_ps7_axi_periph_BRESP),
        .M_AXI_bvalid(m01_couplers_to_ps7_axi_periph_BVALID),
        .M_AXI_rdata(m01_couplers_to_ps7_axi_periph_RDATA),
        .M_AXI_rready(m01_couplers_to_ps7_axi_periph_RREADY),
        .M_AXI_rresp(m01_couplers_to_ps7_axi_periph_RRESP),
        .M_AXI_rvalid(m01_couplers_to_ps7_axi_periph_RVALID),
        .M_AXI_wdata(m01_couplers_to_ps7_axi_periph_WDATA),
        .M_AXI_wready(m01_couplers_to_ps7_axi_periph_WREADY),
        .M_AXI_wstrb(m01_couplers_to_ps7_axi_periph_WSTRB),
        .M_AXI_wvalid(m01_couplers_to_ps7_axi_periph_WVALID),
        .S_ACLK(ps7_axi_periph_ACLK_net),
        .S_ARESETN(ps7_axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m01_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m01_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m01_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m01_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m01_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m01_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m01_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m01_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m01_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m01_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m01_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m01_couplers_RDATA),
        .S_AXI_rready(xbar_to_m01_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m01_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m01_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m01_couplers_WDATA),
        .S_AXI_wready(xbar_to_m01_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m01_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m01_couplers_WVALID));
  m02_couplers_imp_10CYTQ6 m02_couplers
       (.M_ACLK(M02_ACLK_1),
        .M_ARESETN(M02_ARESETN_1),
        .M_AXI_araddr(m02_couplers_to_ps7_axi_periph_ARADDR),
        .M_AXI_arprot(m02_couplers_to_ps7_axi_periph_ARPROT),
        .M_AXI_arready(m02_couplers_to_ps7_axi_periph_ARREADY),
        .M_AXI_arvalid(m02_couplers_to_ps7_axi_periph_ARVALID),
        .M_AXI_awaddr(m02_couplers_to_ps7_axi_periph_AWADDR),
        .M_AXI_awprot(m02_couplers_to_ps7_axi_periph_AWPROT),
        .M_AXI_awready(m02_couplers_to_ps7_axi_periph_AWREADY),
        .M_AXI_awvalid(m02_couplers_to_ps7_axi_periph_AWVALID),
        .M_AXI_bready(m02_couplers_to_ps7_axi_periph_BREADY),
        .M_AXI_bresp(m02_couplers_to_ps7_axi_periph_BRESP),
        .M_AXI_bvalid(m02_couplers_to_ps7_axi_periph_BVALID),
        .M_AXI_rdata(m02_couplers_to_ps7_axi_periph_RDATA),
        .M_AXI_rready(m02_couplers_to_ps7_axi_periph_RREADY),
        .M_AXI_rresp(m02_couplers_to_ps7_axi_periph_RRESP),
        .M_AXI_rvalid(m02_couplers_to_ps7_axi_periph_RVALID),
        .M_AXI_wdata(m02_couplers_to_ps7_axi_periph_WDATA),
        .M_AXI_wready(m02_couplers_to_ps7_axi_periph_WREADY),
        .M_AXI_wstrb(m02_couplers_to_ps7_axi_periph_WSTRB),
        .M_AXI_wvalid(m02_couplers_to_ps7_axi_periph_WVALID),
        .S_ACLK(ps7_axi_periph_ACLK_net),
        .S_ARESETN(ps7_axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m02_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m02_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m02_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m02_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m02_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m02_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m02_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m02_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m02_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m02_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m02_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m02_couplers_RDATA),
        .S_AXI_rready(xbar_to_m02_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m02_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m02_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m02_couplers_WDATA),
        .S_AXI_wready(xbar_to_m02_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m02_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m02_couplers_WVALID));
  m03_couplers_imp_6SFL0Q m03_couplers
       (.M_ACLK(M03_ACLK_1),
        .M_ARESETN(M03_ARESETN_1),
        .M_AXI_araddr(m03_couplers_to_ps7_axi_periph_ARADDR),
        .M_AXI_arprot(m03_couplers_to_ps7_axi_periph_ARPROT),
        .M_AXI_arready(m03_couplers_to_ps7_axi_periph_ARREADY),
        .M_AXI_arvalid(m03_couplers_to_ps7_axi_periph_ARVALID),
        .M_AXI_awaddr(m03_couplers_to_ps7_axi_periph_AWADDR),
        .M_AXI_awprot(m03_couplers_to_ps7_axi_periph_AWPROT),
        .M_AXI_awready(m03_couplers_to_ps7_axi_periph_AWREADY),
        .M_AXI_awvalid(m03_couplers_to_ps7_axi_periph_AWVALID),
        .M_AXI_bready(m03_couplers_to_ps7_axi_periph_BREADY),
        .M_AXI_bresp(m03_couplers_to_ps7_axi_periph_BRESP),
        .M_AXI_bvalid(m03_couplers_to_ps7_axi_periph_BVALID),
        .M_AXI_rdata(m03_couplers_to_ps7_axi_periph_RDATA),
        .M_AXI_rready(m03_couplers_to_ps7_axi_periph_RREADY),
        .M_AXI_rresp(m03_couplers_to_ps7_axi_periph_RRESP),
        .M_AXI_rvalid(m03_couplers_to_ps7_axi_periph_RVALID),
        .M_AXI_wdata(m03_couplers_to_ps7_axi_periph_WDATA),
        .M_AXI_wready(m03_couplers_to_ps7_axi_periph_WREADY),
        .M_AXI_wstrb(m03_couplers_to_ps7_axi_periph_WSTRB),
        .M_AXI_wvalid(m03_couplers_to_ps7_axi_periph_WVALID),
        .S_ACLK(ps7_axi_periph_ACLK_net),
        .S_ARESETN(ps7_axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m03_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m03_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m03_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m03_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m03_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m03_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m03_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m03_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m03_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m03_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m03_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m03_couplers_RDATA),
        .S_AXI_rready(xbar_to_m03_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m03_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m03_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m03_couplers_WDATA),
        .S_AXI_wready(xbar_to_m03_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m03_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m03_couplers_WVALID));
  m04_couplers_imp_UQAJR8 m04_couplers
       (.M_ACLK(M04_ACLK_1),
        .M_ARESETN(M04_ARESETN_1),
        .M_AXI_araddr(m04_couplers_to_ps7_axi_periph_ARADDR),
        .M_AXI_arprot(m04_couplers_to_ps7_axi_periph_ARPROT),
        .M_AXI_arready(m04_couplers_to_ps7_axi_periph_ARREADY),
        .M_AXI_arvalid(m04_couplers_to_ps7_axi_periph_ARVALID),
        .M_AXI_awaddr(m04_couplers_to_ps7_axi_periph_AWADDR),
        .M_AXI_awprot(m04_couplers_to_ps7_axi_periph_AWPROT),
        .M_AXI_awready(m04_couplers_to_ps7_axi_periph_AWREADY),
        .M_AXI_awvalid(m04_couplers_to_ps7_axi_periph_AWVALID),
        .M_AXI_bready(m04_couplers_to_ps7_axi_periph_BREADY),
        .M_AXI_bresp(m04_couplers_to_ps7_axi_periph_BRESP),
        .M_AXI_bvalid(m04_couplers_to_ps7_axi_periph_BVALID),
        .M_AXI_rdata(m04_couplers_to_ps7_axi_periph_RDATA),
        .M_AXI_rready(m04_couplers_to_ps7_axi_periph_RREADY),
        .M_AXI_rresp(m04_couplers_to_ps7_axi_periph_RRESP),
        .M_AXI_rvalid(m04_couplers_to_ps7_axi_periph_RVALID),
        .M_AXI_wdata(m04_couplers_to_ps7_axi_periph_WDATA),
        .M_AXI_wready(m04_couplers_to_ps7_axi_periph_WREADY),
        .M_AXI_wstrb(m04_couplers_to_ps7_axi_periph_WSTRB),
        .M_AXI_wvalid(m04_couplers_to_ps7_axi_periph_WVALID),
        .S_ACLK(ps7_axi_periph_ACLK_net),
        .S_ARESETN(ps7_axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m04_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m04_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m04_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m04_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m04_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m04_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m04_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m04_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m04_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m04_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m04_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m04_couplers_RDATA),
        .S_AXI_rready(xbar_to_m04_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m04_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m04_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m04_couplers_WDATA),
        .S_AXI_wready(xbar_to_m04_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m04_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m04_couplers_WVALID));
  s00_couplers_imp_VG94YW s00_couplers
       (.M_ACLK(ps7_axi_periph_ACLK_net),
        .M_ARESETN(ps7_axi_periph_ARESETN_net),
        .M_AXI_araddr(s00_couplers_to_xbar_ARADDR),
        .M_AXI_arprot(s00_couplers_to_xbar_ARPROT),
        .M_AXI_arready(s00_couplers_to_xbar_ARREADY),
        .M_AXI_arvalid(s00_couplers_to_xbar_ARVALID),
        .M_AXI_awaddr(s00_couplers_to_xbar_AWADDR),
        .M_AXI_awprot(s00_couplers_to_xbar_AWPROT),
        .M_AXI_awready(s00_couplers_to_xbar_AWREADY),
        .M_AXI_awvalid(s00_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s00_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s00_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s00_couplers_to_xbar_BVALID),
        .M_AXI_rdata(s00_couplers_to_xbar_RDATA),
        .M_AXI_rready(s00_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s00_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s00_couplers_to_xbar_RVALID),
        .M_AXI_wdata(s00_couplers_to_xbar_WDATA),
        .M_AXI_wready(s00_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s00_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s00_couplers_to_xbar_WVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_araddr(ps7_axi_periph_to_s00_couplers_ARADDR),
        .S_AXI_arburst(ps7_axi_periph_to_s00_couplers_ARBURST),
        .S_AXI_arcache(ps7_axi_periph_to_s00_couplers_ARCACHE),
        .S_AXI_arid(ps7_axi_periph_to_s00_couplers_ARID),
        .S_AXI_arlen(ps7_axi_periph_to_s00_couplers_ARLEN),
        .S_AXI_arlock(ps7_axi_periph_to_s00_couplers_ARLOCK),
        .S_AXI_arprot(ps7_axi_periph_to_s00_couplers_ARPROT),
        .S_AXI_arqos(ps7_axi_periph_to_s00_couplers_ARQOS),
        .S_AXI_arready(ps7_axi_periph_to_s00_couplers_ARREADY),
        .S_AXI_arsize(ps7_axi_periph_to_s00_couplers_ARSIZE),
        .S_AXI_arvalid(ps7_axi_periph_to_s00_couplers_ARVALID),
        .S_AXI_awaddr(ps7_axi_periph_to_s00_couplers_AWADDR),
        .S_AXI_awburst(ps7_axi_periph_to_s00_couplers_AWBURST),
        .S_AXI_awcache(ps7_axi_periph_to_s00_couplers_AWCACHE),
        .S_AXI_awid(ps7_axi_periph_to_s00_couplers_AWID),
        .S_AXI_awlen(ps7_axi_periph_to_s00_couplers_AWLEN),
        .S_AXI_awlock(ps7_axi_periph_to_s00_couplers_AWLOCK),
        .S_AXI_awprot(ps7_axi_periph_to_s00_couplers_AWPROT),
        .S_AXI_awqos(ps7_axi_periph_to_s00_couplers_AWQOS),
        .S_AXI_awready(ps7_axi_periph_to_s00_couplers_AWREADY),
        .S_AXI_awsize(ps7_axi_periph_to_s00_couplers_AWSIZE),
        .S_AXI_awvalid(ps7_axi_periph_to_s00_couplers_AWVALID),
        .S_AXI_bid(ps7_axi_periph_to_s00_couplers_BID),
        .S_AXI_bready(ps7_axi_periph_to_s00_couplers_BREADY),
        .S_AXI_bresp(ps7_axi_periph_to_s00_couplers_BRESP),
        .S_AXI_bvalid(ps7_axi_periph_to_s00_couplers_BVALID),
        .S_AXI_rdata(ps7_axi_periph_to_s00_couplers_RDATA),
        .S_AXI_rid(ps7_axi_periph_to_s00_couplers_RID),
        .S_AXI_rlast(ps7_axi_periph_to_s00_couplers_RLAST),
        .S_AXI_rready(ps7_axi_periph_to_s00_couplers_RREADY),
        .S_AXI_rresp(ps7_axi_periph_to_s00_couplers_RRESP),
        .S_AXI_rvalid(ps7_axi_periph_to_s00_couplers_RVALID),
        .S_AXI_wdata(ps7_axi_periph_to_s00_couplers_WDATA),
        .S_AXI_wid(ps7_axi_periph_to_s00_couplers_WID),
        .S_AXI_wlast(ps7_axi_periph_to_s00_couplers_WLAST),
        .S_AXI_wready(ps7_axi_periph_to_s00_couplers_WREADY),
        .S_AXI_wstrb(ps7_axi_periph_to_s00_couplers_WSTRB),
        .S_AXI_wvalid(ps7_axi_periph_to_s00_couplers_WVALID));
  mixed16_4x4x1_xbar_4 xbar
       (.aclk(ps7_axi_periph_ACLK_net),
        .aresetn(ps7_axi_periph_ARESETN_net),
        .m_axi_araddr({xbar_to_m04_couplers_ARADDR,xbar_to_m03_couplers_ARADDR,xbar_to_m02_couplers_ARADDR,xbar_to_m01_couplers_ARADDR,xbar_to_m00_couplers_ARADDR}),
        .m_axi_arprot({xbar_to_m04_couplers_ARPROT,xbar_to_m03_couplers_ARPROT,xbar_to_m02_couplers_ARPROT,xbar_to_m01_couplers_ARPROT,xbar_to_m00_couplers_ARPROT}),
        .m_axi_arready({xbar_to_m04_couplers_ARREADY,xbar_to_m03_couplers_ARREADY,xbar_to_m02_couplers_ARREADY,xbar_to_m01_couplers_ARREADY,xbar_to_m00_couplers_ARREADY}),
        .m_axi_arvalid({xbar_to_m04_couplers_ARVALID,xbar_to_m03_couplers_ARVALID,xbar_to_m02_couplers_ARVALID,xbar_to_m01_couplers_ARVALID,xbar_to_m00_couplers_ARVALID}),
        .m_axi_awaddr({xbar_to_m04_couplers_AWADDR,xbar_to_m03_couplers_AWADDR,xbar_to_m02_couplers_AWADDR,xbar_to_m01_couplers_AWADDR,xbar_to_m00_couplers_AWADDR}),
        .m_axi_awprot({xbar_to_m04_couplers_AWPROT,xbar_to_m03_couplers_AWPROT,xbar_to_m02_couplers_AWPROT,xbar_to_m01_couplers_AWPROT,xbar_to_m00_couplers_AWPROT}),
        .m_axi_awready({xbar_to_m04_couplers_AWREADY,xbar_to_m03_couplers_AWREADY,xbar_to_m02_couplers_AWREADY,xbar_to_m01_couplers_AWREADY,xbar_to_m00_couplers_AWREADY}),
        .m_axi_awvalid({xbar_to_m04_couplers_AWVALID,xbar_to_m03_couplers_AWVALID,xbar_to_m02_couplers_AWVALID,xbar_to_m01_couplers_AWVALID,xbar_to_m00_couplers_AWVALID}),
        .m_axi_bready({xbar_to_m04_couplers_BREADY,xbar_to_m03_couplers_BREADY,xbar_to_m02_couplers_BREADY,xbar_to_m01_couplers_BREADY,xbar_to_m00_couplers_BREADY}),
        .m_axi_bresp({xbar_to_m04_couplers_BRESP,xbar_to_m03_couplers_BRESP,xbar_to_m02_couplers_BRESP,xbar_to_m01_couplers_BRESP,xbar_to_m00_couplers_BRESP}),
        .m_axi_bvalid({xbar_to_m04_couplers_BVALID,xbar_to_m03_couplers_BVALID,xbar_to_m02_couplers_BVALID,xbar_to_m01_couplers_BVALID,xbar_to_m00_couplers_BVALID}),
        .m_axi_rdata({xbar_to_m04_couplers_RDATA,xbar_to_m03_couplers_RDATA,xbar_to_m02_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m00_couplers_RDATA}),
        .m_axi_rready({xbar_to_m04_couplers_RREADY,xbar_to_m03_couplers_RREADY,xbar_to_m02_couplers_RREADY,xbar_to_m01_couplers_RREADY,xbar_to_m00_couplers_RREADY}),
        .m_axi_rresp({xbar_to_m04_couplers_RRESP,xbar_to_m03_couplers_RRESP,xbar_to_m02_couplers_RRESP,xbar_to_m01_couplers_RRESP,xbar_to_m00_couplers_RRESP}),
        .m_axi_rvalid({xbar_to_m04_couplers_RVALID,xbar_to_m03_couplers_RVALID,xbar_to_m02_couplers_RVALID,xbar_to_m01_couplers_RVALID,xbar_to_m00_couplers_RVALID}),
        .m_axi_wdata({xbar_to_m04_couplers_WDATA,xbar_to_m03_couplers_WDATA,xbar_to_m02_couplers_WDATA,xbar_to_m01_couplers_WDATA,xbar_to_m00_couplers_WDATA}),
        .m_axi_wready({xbar_to_m04_couplers_WREADY,xbar_to_m03_couplers_WREADY,xbar_to_m02_couplers_WREADY,xbar_to_m01_couplers_WREADY,xbar_to_m00_couplers_WREADY}),
        .m_axi_wstrb({xbar_to_m04_couplers_WSTRB,xbar_to_m03_couplers_WSTRB,xbar_to_m02_couplers_WSTRB,xbar_to_m01_couplers_WSTRB,xbar_to_m00_couplers_WSTRB}),
        .m_axi_wvalid({xbar_to_m04_couplers_WVALID,xbar_to_m03_couplers_WVALID,xbar_to_m02_couplers_WVALID,xbar_to_m01_couplers_WVALID,xbar_to_m00_couplers_WVALID}),
        .s_axi_araddr(s00_couplers_to_xbar_ARADDR),
        .s_axi_arprot(s00_couplers_to_xbar_ARPROT),
        .s_axi_arready(s00_couplers_to_xbar_ARREADY),
        .s_axi_arvalid(s00_couplers_to_xbar_ARVALID),
        .s_axi_awaddr(s00_couplers_to_xbar_AWADDR),
        .s_axi_awprot(s00_couplers_to_xbar_AWPROT),
        .s_axi_awready(s00_couplers_to_xbar_AWREADY),
        .s_axi_awvalid(s00_couplers_to_xbar_AWVALID),
        .s_axi_bready(s00_couplers_to_xbar_BREADY),
        .s_axi_bresp(s00_couplers_to_xbar_BRESP),
        .s_axi_bvalid(s00_couplers_to_xbar_BVALID),
        .s_axi_rdata(s00_couplers_to_xbar_RDATA),
        .s_axi_rready(s00_couplers_to_xbar_RREADY),
        .s_axi_rresp(s00_couplers_to_xbar_RRESP),
        .s_axi_rvalid(s00_couplers_to_xbar_RVALID),
        .s_axi_wdata(s00_couplers_to_xbar_WDATA),
        .s_axi_wready(s00_couplers_to_xbar_WREADY),
        .s_axi_wstrb(s00_couplers_to_xbar_WSTRB),
        .s_axi_wvalid(s00_couplers_to_xbar_WVALID));
endmodule

module s00_couplers_imp_VG94YW
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wid,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [11:0]S_AXI_arid;
  input [3:0]S_AXI_arlen;
  input [1:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [11:0]S_AXI_awid;
  input [3:0]S_AXI_awlen;
  input [1:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [11:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  output [11:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  input [11:0]S_AXI_wid;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_s00_couplers_ARADDR;
  wire [2:0]auto_pc_to_s00_couplers_ARPROT;
  wire auto_pc_to_s00_couplers_ARREADY;
  wire auto_pc_to_s00_couplers_ARVALID;
  wire [31:0]auto_pc_to_s00_couplers_AWADDR;
  wire [2:0]auto_pc_to_s00_couplers_AWPROT;
  wire auto_pc_to_s00_couplers_AWREADY;
  wire auto_pc_to_s00_couplers_AWVALID;
  wire auto_pc_to_s00_couplers_BREADY;
  wire [1:0]auto_pc_to_s00_couplers_BRESP;
  wire auto_pc_to_s00_couplers_BVALID;
  wire [31:0]auto_pc_to_s00_couplers_RDATA;
  wire auto_pc_to_s00_couplers_RREADY;
  wire [1:0]auto_pc_to_s00_couplers_RRESP;
  wire auto_pc_to_s00_couplers_RVALID;
  wire [31:0]auto_pc_to_s00_couplers_WDATA;
  wire auto_pc_to_s00_couplers_WREADY;
  wire [3:0]auto_pc_to_s00_couplers_WSTRB;
  wire auto_pc_to_s00_couplers_WVALID;
  wire [31:0]s00_couplers_to_s00_regslice_ARADDR;
  wire [1:0]s00_couplers_to_s00_regslice_ARBURST;
  wire [3:0]s00_couplers_to_s00_regslice_ARCACHE;
  wire [11:0]s00_couplers_to_s00_regslice_ARID;
  wire [3:0]s00_couplers_to_s00_regslice_ARLEN;
  wire [1:0]s00_couplers_to_s00_regslice_ARLOCK;
  wire [2:0]s00_couplers_to_s00_regslice_ARPROT;
  wire [3:0]s00_couplers_to_s00_regslice_ARQOS;
  wire s00_couplers_to_s00_regslice_ARREADY;
  wire [2:0]s00_couplers_to_s00_regslice_ARSIZE;
  wire s00_couplers_to_s00_regslice_ARVALID;
  wire [31:0]s00_couplers_to_s00_regslice_AWADDR;
  wire [1:0]s00_couplers_to_s00_regslice_AWBURST;
  wire [3:0]s00_couplers_to_s00_regslice_AWCACHE;
  wire [11:0]s00_couplers_to_s00_regslice_AWID;
  wire [3:0]s00_couplers_to_s00_regslice_AWLEN;
  wire [1:0]s00_couplers_to_s00_regslice_AWLOCK;
  wire [2:0]s00_couplers_to_s00_regslice_AWPROT;
  wire [3:0]s00_couplers_to_s00_regslice_AWQOS;
  wire s00_couplers_to_s00_regslice_AWREADY;
  wire [2:0]s00_couplers_to_s00_regslice_AWSIZE;
  wire s00_couplers_to_s00_regslice_AWVALID;
  wire [11:0]s00_couplers_to_s00_regslice_BID;
  wire s00_couplers_to_s00_regslice_BREADY;
  wire [1:0]s00_couplers_to_s00_regslice_BRESP;
  wire s00_couplers_to_s00_regslice_BVALID;
  wire [31:0]s00_couplers_to_s00_regslice_RDATA;
  wire [11:0]s00_couplers_to_s00_regslice_RID;
  wire s00_couplers_to_s00_regslice_RLAST;
  wire s00_couplers_to_s00_regslice_RREADY;
  wire [1:0]s00_couplers_to_s00_regslice_RRESP;
  wire s00_couplers_to_s00_regslice_RVALID;
  wire [31:0]s00_couplers_to_s00_regslice_WDATA;
  wire [11:0]s00_couplers_to_s00_regslice_WID;
  wire s00_couplers_to_s00_regslice_WLAST;
  wire s00_couplers_to_s00_regslice_WREADY;
  wire [3:0]s00_couplers_to_s00_regslice_WSTRB;
  wire s00_couplers_to_s00_regslice_WVALID;
  wire [31:0]s00_regslice_to_auto_pc_ARADDR;
  wire [1:0]s00_regslice_to_auto_pc_ARBURST;
  wire [3:0]s00_regslice_to_auto_pc_ARCACHE;
  wire [11:0]s00_regslice_to_auto_pc_ARID;
  wire [3:0]s00_regslice_to_auto_pc_ARLEN;
  wire [1:0]s00_regslice_to_auto_pc_ARLOCK;
  wire [2:0]s00_regslice_to_auto_pc_ARPROT;
  wire [3:0]s00_regslice_to_auto_pc_ARQOS;
  wire s00_regslice_to_auto_pc_ARREADY;
  wire [2:0]s00_regslice_to_auto_pc_ARSIZE;
  wire s00_regslice_to_auto_pc_ARVALID;
  wire [31:0]s00_regslice_to_auto_pc_AWADDR;
  wire [1:0]s00_regslice_to_auto_pc_AWBURST;
  wire [3:0]s00_regslice_to_auto_pc_AWCACHE;
  wire [11:0]s00_regslice_to_auto_pc_AWID;
  wire [3:0]s00_regslice_to_auto_pc_AWLEN;
  wire [1:0]s00_regslice_to_auto_pc_AWLOCK;
  wire [2:0]s00_regslice_to_auto_pc_AWPROT;
  wire [3:0]s00_regslice_to_auto_pc_AWQOS;
  wire s00_regslice_to_auto_pc_AWREADY;
  wire [2:0]s00_regslice_to_auto_pc_AWSIZE;
  wire s00_regslice_to_auto_pc_AWVALID;
  wire [11:0]s00_regslice_to_auto_pc_BID;
  wire s00_regslice_to_auto_pc_BREADY;
  wire [1:0]s00_regslice_to_auto_pc_BRESP;
  wire s00_regslice_to_auto_pc_BVALID;
  wire [31:0]s00_regslice_to_auto_pc_RDATA;
  wire [11:0]s00_regslice_to_auto_pc_RID;
  wire s00_regslice_to_auto_pc_RLAST;
  wire s00_regslice_to_auto_pc_RREADY;
  wire [1:0]s00_regslice_to_auto_pc_RRESP;
  wire s00_regslice_to_auto_pc_RVALID;
  wire [31:0]s00_regslice_to_auto_pc_WDATA;
  wire [11:0]s00_regslice_to_auto_pc_WID;
  wire s00_regslice_to_auto_pc_WLAST;
  wire s00_regslice_to_auto_pc_WREADY;
  wire [3:0]s00_regslice_to_auto_pc_WSTRB;
  wire s00_regslice_to_auto_pc_WVALID;

  assign M_AXI_araddr[31:0] = auto_pc_to_s00_couplers_ARADDR;
  assign M_AXI_arprot[2:0] = auto_pc_to_s00_couplers_ARPROT;
  assign M_AXI_arvalid = auto_pc_to_s00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_pc_to_s00_couplers_AWADDR;
  assign M_AXI_awprot[2:0] = auto_pc_to_s00_couplers_AWPROT;
  assign M_AXI_awvalid = auto_pc_to_s00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_s00_couplers_BREADY;
  assign M_AXI_rready = auto_pc_to_s00_couplers_RREADY;
  assign M_AXI_wdata[31:0] = auto_pc_to_s00_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = auto_pc_to_s00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_s00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = s00_couplers_to_s00_regslice_ARREADY;
  assign S_AXI_awready = s00_couplers_to_s00_regslice_AWREADY;
  assign S_AXI_bid[11:0] = s00_couplers_to_s00_regslice_BID;
  assign S_AXI_bresp[1:0] = s00_couplers_to_s00_regslice_BRESP;
  assign S_AXI_bvalid = s00_couplers_to_s00_regslice_BVALID;
  assign S_AXI_rdata[31:0] = s00_couplers_to_s00_regslice_RDATA;
  assign S_AXI_rid[11:0] = s00_couplers_to_s00_regslice_RID;
  assign S_AXI_rlast = s00_couplers_to_s00_regslice_RLAST;
  assign S_AXI_rresp[1:0] = s00_couplers_to_s00_regslice_RRESP;
  assign S_AXI_rvalid = s00_couplers_to_s00_regslice_RVALID;
  assign S_AXI_wready = s00_couplers_to_s00_regslice_WREADY;
  assign auto_pc_to_s00_couplers_ARREADY = M_AXI_arready;
  assign auto_pc_to_s00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_s00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_s00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_s00_couplers_RDATA = M_AXI_rdata[31:0];
  assign auto_pc_to_s00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_pc_to_s00_couplers_RVALID = M_AXI_rvalid;
  assign auto_pc_to_s00_couplers_WREADY = M_AXI_wready;
  assign s00_couplers_to_s00_regslice_ARADDR = S_AXI_araddr[31:0];
  assign s00_couplers_to_s00_regslice_ARBURST = S_AXI_arburst[1:0];
  assign s00_couplers_to_s00_regslice_ARCACHE = S_AXI_arcache[3:0];
  assign s00_couplers_to_s00_regslice_ARID = S_AXI_arid[11:0];
  assign s00_couplers_to_s00_regslice_ARLEN = S_AXI_arlen[3:0];
  assign s00_couplers_to_s00_regslice_ARLOCK = S_AXI_arlock[1:0];
  assign s00_couplers_to_s00_regslice_ARPROT = S_AXI_arprot[2:0];
  assign s00_couplers_to_s00_regslice_ARQOS = S_AXI_arqos[3:0];
  assign s00_couplers_to_s00_regslice_ARSIZE = S_AXI_arsize[2:0];
  assign s00_couplers_to_s00_regslice_ARVALID = S_AXI_arvalid;
  assign s00_couplers_to_s00_regslice_AWADDR = S_AXI_awaddr[31:0];
  assign s00_couplers_to_s00_regslice_AWBURST = S_AXI_awburst[1:0];
  assign s00_couplers_to_s00_regslice_AWCACHE = S_AXI_awcache[3:0];
  assign s00_couplers_to_s00_regslice_AWID = S_AXI_awid[11:0];
  assign s00_couplers_to_s00_regslice_AWLEN = S_AXI_awlen[3:0];
  assign s00_couplers_to_s00_regslice_AWLOCK = S_AXI_awlock[1:0];
  assign s00_couplers_to_s00_regslice_AWPROT = S_AXI_awprot[2:0];
  assign s00_couplers_to_s00_regslice_AWQOS = S_AXI_awqos[3:0];
  assign s00_couplers_to_s00_regslice_AWSIZE = S_AXI_awsize[2:0];
  assign s00_couplers_to_s00_regslice_AWVALID = S_AXI_awvalid;
  assign s00_couplers_to_s00_regslice_BREADY = S_AXI_bready;
  assign s00_couplers_to_s00_regslice_RREADY = S_AXI_rready;
  assign s00_couplers_to_s00_regslice_WDATA = S_AXI_wdata[31:0];
  assign s00_couplers_to_s00_regslice_WID = S_AXI_wid[11:0];
  assign s00_couplers_to_s00_regslice_WLAST = S_AXI_wlast;
  assign s00_couplers_to_s00_regslice_WSTRB = S_AXI_wstrb[3:0];
  assign s00_couplers_to_s00_regslice_WVALID = S_AXI_wvalid;
  mixed16_4x4x1_auto_pc_0 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(auto_pc_to_s00_couplers_ARADDR),
        .m_axi_arprot(auto_pc_to_s00_couplers_ARPROT),
        .m_axi_arready(auto_pc_to_s00_couplers_ARREADY),
        .m_axi_arvalid(auto_pc_to_s00_couplers_ARVALID),
        .m_axi_awaddr(auto_pc_to_s00_couplers_AWADDR),
        .m_axi_awprot(auto_pc_to_s00_couplers_AWPROT),
        .m_axi_awready(auto_pc_to_s00_couplers_AWREADY),
        .m_axi_awvalid(auto_pc_to_s00_couplers_AWVALID),
        .m_axi_bready(auto_pc_to_s00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_s00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_s00_couplers_BVALID),
        .m_axi_rdata(auto_pc_to_s00_couplers_RDATA),
        .m_axi_rready(auto_pc_to_s00_couplers_RREADY),
        .m_axi_rresp(auto_pc_to_s00_couplers_RRESP),
        .m_axi_rvalid(auto_pc_to_s00_couplers_RVALID),
        .m_axi_wdata(auto_pc_to_s00_couplers_WDATA),
        .m_axi_wready(auto_pc_to_s00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_s00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_s00_couplers_WVALID),
        .s_axi_araddr(s00_regslice_to_auto_pc_ARADDR),
        .s_axi_arburst(s00_regslice_to_auto_pc_ARBURST),
        .s_axi_arcache(s00_regslice_to_auto_pc_ARCACHE),
        .s_axi_arid(s00_regslice_to_auto_pc_ARID),
        .s_axi_arlen(s00_regslice_to_auto_pc_ARLEN),
        .s_axi_arlock(s00_regslice_to_auto_pc_ARLOCK),
        .s_axi_arprot(s00_regslice_to_auto_pc_ARPROT),
        .s_axi_arqos(s00_regslice_to_auto_pc_ARQOS),
        .s_axi_arready(s00_regslice_to_auto_pc_ARREADY),
        .s_axi_arsize(s00_regslice_to_auto_pc_ARSIZE),
        .s_axi_arvalid(s00_regslice_to_auto_pc_ARVALID),
        .s_axi_awaddr(s00_regslice_to_auto_pc_AWADDR),
        .s_axi_awburst(s00_regslice_to_auto_pc_AWBURST),
        .s_axi_awcache(s00_regslice_to_auto_pc_AWCACHE),
        .s_axi_awid(s00_regslice_to_auto_pc_AWID),
        .s_axi_awlen(s00_regslice_to_auto_pc_AWLEN),
        .s_axi_awlock(s00_regslice_to_auto_pc_AWLOCK),
        .s_axi_awprot(s00_regslice_to_auto_pc_AWPROT),
        .s_axi_awqos(s00_regslice_to_auto_pc_AWQOS),
        .s_axi_awready(s00_regslice_to_auto_pc_AWREADY),
        .s_axi_awsize(s00_regslice_to_auto_pc_AWSIZE),
        .s_axi_awvalid(s00_regslice_to_auto_pc_AWVALID),
        .s_axi_bid(s00_regslice_to_auto_pc_BID),
        .s_axi_bready(s00_regslice_to_auto_pc_BREADY),
        .s_axi_bresp(s00_regslice_to_auto_pc_BRESP),
        .s_axi_bvalid(s00_regslice_to_auto_pc_BVALID),
        .s_axi_rdata(s00_regslice_to_auto_pc_RDATA),
        .s_axi_rid(s00_regslice_to_auto_pc_RID),
        .s_axi_rlast(s00_regslice_to_auto_pc_RLAST),
        .s_axi_rready(s00_regslice_to_auto_pc_RREADY),
        .s_axi_rresp(s00_regslice_to_auto_pc_RRESP),
        .s_axi_rvalid(s00_regslice_to_auto_pc_RVALID),
        .s_axi_wdata(s00_regslice_to_auto_pc_WDATA),
        .s_axi_wid(s00_regslice_to_auto_pc_WID),
        .s_axi_wlast(s00_regslice_to_auto_pc_WLAST),
        .s_axi_wready(s00_regslice_to_auto_pc_WREADY),
        .s_axi_wstrb(s00_regslice_to_auto_pc_WSTRB),
        .s_axi_wvalid(s00_regslice_to_auto_pc_WVALID));
  mixed16_4x4x1_s00_regslice_0 s00_regslice
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(s00_regslice_to_auto_pc_ARADDR),
        .m_axi_arburst(s00_regslice_to_auto_pc_ARBURST),
        .m_axi_arcache(s00_regslice_to_auto_pc_ARCACHE),
        .m_axi_arid(s00_regslice_to_auto_pc_ARID),
        .m_axi_arlen(s00_regslice_to_auto_pc_ARLEN),
        .m_axi_arlock(s00_regslice_to_auto_pc_ARLOCK),
        .m_axi_arprot(s00_regslice_to_auto_pc_ARPROT),
        .m_axi_arqos(s00_regslice_to_auto_pc_ARQOS),
        .m_axi_arready(s00_regslice_to_auto_pc_ARREADY),
        .m_axi_arsize(s00_regslice_to_auto_pc_ARSIZE),
        .m_axi_arvalid(s00_regslice_to_auto_pc_ARVALID),
        .m_axi_awaddr(s00_regslice_to_auto_pc_AWADDR),
        .m_axi_awburst(s00_regslice_to_auto_pc_AWBURST),
        .m_axi_awcache(s00_regslice_to_auto_pc_AWCACHE),
        .m_axi_awid(s00_regslice_to_auto_pc_AWID),
        .m_axi_awlen(s00_regslice_to_auto_pc_AWLEN),
        .m_axi_awlock(s00_regslice_to_auto_pc_AWLOCK),
        .m_axi_awprot(s00_regslice_to_auto_pc_AWPROT),
        .m_axi_awqos(s00_regslice_to_auto_pc_AWQOS),
        .m_axi_awready(s00_regslice_to_auto_pc_AWREADY),
        .m_axi_awsize(s00_regslice_to_auto_pc_AWSIZE),
        .m_axi_awvalid(s00_regslice_to_auto_pc_AWVALID),
        .m_axi_bid(s00_regslice_to_auto_pc_BID),
        .m_axi_bready(s00_regslice_to_auto_pc_BREADY),
        .m_axi_bresp(s00_regslice_to_auto_pc_BRESP),
        .m_axi_bvalid(s00_regslice_to_auto_pc_BVALID),
        .m_axi_rdata(s00_regslice_to_auto_pc_RDATA),
        .m_axi_rid(s00_regslice_to_auto_pc_RID),
        .m_axi_rlast(s00_regslice_to_auto_pc_RLAST),
        .m_axi_rready(s00_regslice_to_auto_pc_RREADY),
        .m_axi_rresp(s00_regslice_to_auto_pc_RRESP),
        .m_axi_rvalid(s00_regslice_to_auto_pc_RVALID),
        .m_axi_wdata(s00_regslice_to_auto_pc_WDATA),
        .m_axi_wid(s00_regslice_to_auto_pc_WID),
        .m_axi_wlast(s00_regslice_to_auto_pc_WLAST),
        .m_axi_wready(s00_regslice_to_auto_pc_WREADY),
        .m_axi_wstrb(s00_regslice_to_auto_pc_WSTRB),
        .m_axi_wvalid(s00_regslice_to_auto_pc_WVALID),
        .s_axi_araddr(s00_couplers_to_s00_regslice_ARADDR),
        .s_axi_arburst(s00_couplers_to_s00_regslice_ARBURST),
        .s_axi_arcache(s00_couplers_to_s00_regslice_ARCACHE),
        .s_axi_arid(s00_couplers_to_s00_regslice_ARID),
        .s_axi_arlen(s00_couplers_to_s00_regslice_ARLEN),
        .s_axi_arlock(s00_couplers_to_s00_regslice_ARLOCK),
        .s_axi_arprot(s00_couplers_to_s00_regslice_ARPROT),
        .s_axi_arqos(s00_couplers_to_s00_regslice_ARQOS),
        .s_axi_arready(s00_couplers_to_s00_regslice_ARREADY),
        .s_axi_arsize(s00_couplers_to_s00_regslice_ARSIZE),
        .s_axi_arvalid(s00_couplers_to_s00_regslice_ARVALID),
        .s_axi_awaddr(s00_couplers_to_s00_regslice_AWADDR),
        .s_axi_awburst(s00_couplers_to_s00_regslice_AWBURST),
        .s_axi_awcache(s00_couplers_to_s00_regslice_AWCACHE),
        .s_axi_awid(s00_couplers_to_s00_regslice_AWID),
        .s_axi_awlen(s00_couplers_to_s00_regslice_AWLEN),
        .s_axi_awlock(s00_couplers_to_s00_regslice_AWLOCK),
        .s_axi_awprot(s00_couplers_to_s00_regslice_AWPROT),
        .s_axi_awqos(s00_couplers_to_s00_regslice_AWQOS),
        .s_axi_awready(s00_couplers_to_s00_regslice_AWREADY),
        .s_axi_awsize(s00_couplers_to_s00_regslice_AWSIZE),
        .s_axi_awvalid(s00_couplers_to_s00_regslice_AWVALID),
        .s_axi_bid(s00_couplers_to_s00_regslice_BID),
        .s_axi_bready(s00_couplers_to_s00_regslice_BREADY),
        .s_axi_bresp(s00_couplers_to_s00_regslice_BRESP),
        .s_axi_bvalid(s00_couplers_to_s00_regslice_BVALID),
        .s_axi_rdata(s00_couplers_to_s00_regslice_RDATA),
        .s_axi_rid(s00_couplers_to_s00_regslice_RID),
        .s_axi_rlast(s00_couplers_to_s00_regslice_RLAST),
        .s_axi_rready(s00_couplers_to_s00_regslice_RREADY),
        .s_axi_rresp(s00_couplers_to_s00_regslice_RRESP),
        .s_axi_rvalid(s00_couplers_to_s00_regslice_RVALID),
        .s_axi_wdata(s00_couplers_to_s00_regslice_WDATA),
        .s_axi_wid(s00_couplers_to_s00_regslice_WID),
        .s_axi_wlast(s00_couplers_to_s00_regslice_WLAST),
        .s_axi_wready(s00_couplers_to_s00_regslice_WREADY),
        .s_axi_wstrb(s00_couplers_to_s00_regslice_WSTRB),
        .s_axi_wvalid(s00_couplers_to_s00_regslice_WVALID));
endmodule
