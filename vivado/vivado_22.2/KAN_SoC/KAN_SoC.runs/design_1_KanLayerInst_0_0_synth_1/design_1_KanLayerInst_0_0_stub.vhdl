-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
-- Date        : Sun May 18 22:15:40 2025
-- Host        : yannos running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ design_1_KanLayerInst_0_0_stub.vhdl
-- Design      : design_1_KanLayerInst_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z007sclg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    fsm_clk : in STD_LOGIC;
    fsm_rst : in STD_LOGIC;
    core_clk : in STD_LOGIC;
    core_rst : out STD_LOGIC;
    dma_clk : in STD_LOGIC;
    dma_rst : in STD_LOGIC;
    operation_busy : out STD_LOGIC;
    operation_complete : out STD_LOGIC;
    operation_error : out STD_LOGIC;
    locked : out STD_LOGIC;
    pl2ps_intr : out STD_LOGIC;
    bram00_ctrl_data_clk : in STD_LOGIC;
    bram00_ctrl_data_rst : in STD_LOGIC;
    bram00_ctrl_data_en : in STD_LOGIC;
    bram00_ctrl_data_we : in STD_LOGIC_VECTOR ( 3 downto 0 );
    bram00_ctrl_data_addr : in STD_LOGIC_VECTOR ( 12 downto 0 );
    bram00_ctrl_data_din : in STD_LOGIC_VECTOR ( 31 downto 0 );
    bram00_ctrl_data_dout : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_grid_aclk : in STD_LOGIC;
    s_axil_grid_areset : in STD_LOGIC;
    s_axil_grid_awaddr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    s_axil_grid_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axil_grid_awvalid : in STD_LOGIC;
    s_axil_grid_awready : out STD_LOGIC;
    s_axil_grid_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_grid_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axil_grid_wvalid : in STD_LOGIC;
    s_axil_grid_wready : out STD_LOGIC;
    s_axil_grid_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axil_grid_bvalid : out STD_LOGIC;
    s_axil_grid_bready : in STD_LOGIC;
    s_axil_grid_araddr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    s_axil_grid_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axil_grid_arvalid : in STD_LOGIC;
    s_axil_grid_arready : out STD_LOGIC;
    s_axil_grid_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_grid_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axil_grid_rvalid : out STD_LOGIC;
    s_axil_grid_rready : in STD_LOGIC;
    s_axil_scle_aclk : in STD_LOGIC;
    s_axil_scle_areset : in STD_LOGIC;
    s_axil_scle_awaddr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    s_axil_scle_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axil_scle_awvalid : in STD_LOGIC;
    s_axil_scle_awready : out STD_LOGIC;
    s_axil_scle_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_scle_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axil_scle_wvalid : in STD_LOGIC;
    s_axil_scle_wready : out STD_LOGIC;
    s_axil_scle_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axil_scle_bvalid : out STD_LOGIC;
    s_axil_scle_bready : in STD_LOGIC;
    s_axil_scle_araddr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    s_axil_scle_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axil_scle_arvalid : in STD_LOGIC;
    s_axil_scle_arready : out STD_LOGIC;
    s_axil_scle_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_scle_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axil_scle_rvalid : out STD_LOGIC;
    s_axil_scle_rready : in STD_LOGIC;
    s_axil_ctrl_awaddr : in STD_LOGIC_VECTOR ( 12 downto 0 );
    s_axil_ctrl_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axil_ctrl_awvalid : in STD_LOGIC;
    s_axil_ctrl_awready : out STD_LOGIC;
    s_axil_ctrl_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_ctrl_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axil_ctrl_wvalid : in STD_LOGIC;
    s_axil_ctrl_wready : out STD_LOGIC;
    s_axil_ctrl_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axil_ctrl_bvalid : out STD_LOGIC;
    s_axil_ctrl_bready : in STD_LOGIC;
    s_axil_ctrl_araddr : in STD_LOGIC_VECTOR ( 12 downto 0 );
    s_axil_ctrl_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axil_ctrl_arvalid : in STD_LOGIC;
    s_axil_ctrl_arready : out STD_LOGIC;
    s_axil_ctrl_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axil_ctrl_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axil_ctrl_rvalid : out STD_LOGIC;
    s_axil_ctrl_rready : in STD_LOGIC;
    s_axis_wght_tdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    s_axis_wght_tkeep : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_axis_wght_tvalid : in STD_LOGIC;
    s_axis_wght_tready : out STD_LOGIC;
    s_axis_wght_tlast : in STD_LOGIC;
    s_axis_wght_tid : in STD_LOGIC_VECTOR ( 0 to 0 );
    s_axis_wght_tdest : in STD_LOGIC_VECTOR ( 0 to 0 );
    s_axis_wght_tuser : in STD_LOGIC_VECTOR ( 0 to 0 );
    m_axis_rslt_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_rslt_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_rslt_tvalid : out STD_LOGIC;
    m_axis_rslt_tready : in STD_LOGIC;
    m_axis_rslt_tlast : out STD_LOGIC;
    m_axis_rslt_tid : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axis_rslt_tdest : out STD_LOGIC_VECTOR ( 0 to 0 );
    m_axis_rslt_tuser : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "fsm_clk,fsm_rst,core_clk,core_rst,dma_clk,dma_rst,operation_busy,operation_complete,operation_error,locked,pl2ps_intr,bram00_ctrl_data_clk,bram00_ctrl_data_rst,bram00_ctrl_data_en,bram00_ctrl_data_we[3:0],bram00_ctrl_data_addr[12:0],bram00_ctrl_data_din[31:0],bram00_ctrl_data_dout[31:0],s_axil_grid_aclk,s_axil_grid_areset,s_axil_grid_awaddr[4:0],s_axil_grid_awprot[2:0],s_axil_grid_awvalid,s_axil_grid_awready,s_axil_grid_wdata[31:0],s_axil_grid_wstrb[3:0],s_axil_grid_wvalid,s_axil_grid_wready,s_axil_grid_bresp[1:0],s_axil_grid_bvalid,s_axil_grid_bready,s_axil_grid_araddr[4:0],s_axil_grid_arprot[2:0],s_axil_grid_arvalid,s_axil_grid_arready,s_axil_grid_rdata[31:0],s_axil_grid_rresp[1:0],s_axil_grid_rvalid,s_axil_grid_rready,s_axil_scle_aclk,s_axil_scle_areset,s_axil_scle_awaddr[4:0],s_axil_scle_awprot[2:0],s_axil_scle_awvalid,s_axil_scle_awready,s_axil_scle_wdata[31:0],s_axil_scle_wstrb[3:0],s_axil_scle_wvalid,s_axil_scle_wready,s_axil_scle_bresp[1:0],s_axil_scle_bvalid,s_axil_scle_bready,s_axil_scle_araddr[4:0],s_axil_scle_arprot[2:0],s_axil_scle_arvalid,s_axil_scle_arready,s_axil_scle_rdata[31:0],s_axil_scle_rresp[1:0],s_axil_scle_rvalid,s_axil_scle_rready,s_axil_ctrl_awaddr[12:0],s_axil_ctrl_awprot[2:0],s_axil_ctrl_awvalid,s_axil_ctrl_awready,s_axil_ctrl_wdata[31:0],s_axil_ctrl_wstrb[3:0],s_axil_ctrl_wvalid,s_axil_ctrl_wready,s_axil_ctrl_bresp[1:0],s_axil_ctrl_bvalid,s_axil_ctrl_bready,s_axil_ctrl_araddr[12:0],s_axil_ctrl_arprot[2:0],s_axil_ctrl_arvalid,s_axil_ctrl_arready,s_axil_ctrl_rdata[31:0],s_axil_ctrl_rresp[1:0],s_axil_ctrl_rvalid,s_axil_ctrl_rready,s_axis_wght_tdata[63:0],s_axis_wght_tkeep[7:0],s_axis_wght_tvalid,s_axis_wght_tready,s_axis_wght_tlast,s_axis_wght_tid[0:0],s_axis_wght_tdest[0:0],s_axis_wght_tuser[0:0],m_axis_rslt_tdata[63:0],m_axis_rslt_tkeep[7:0],m_axis_rslt_tvalid,m_axis_rslt_tready,m_axis_rslt_tlast,m_axis_rslt_tid[0:0],m_axis_rslt_tdest[0:0],m_axis_rslt_tuser[0:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "KanLayerInst,Vivado 2022.2";
begin
end;
