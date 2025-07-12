-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
-- Date        : Mon Jul  7 22:26:07 2025
-- Host        : GV-LAPTOP-LOQ running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim -rename_top int16_4x2x1_dma_nrst2rst_0 -prefix
--               int16_4x2x1_dma_nrst2rst_0_ mixed16_4x4x2_dma_nrst2rst_0_sim_netlist.vhdl
-- Design      : mixed16_4x4x2_dma_nrst2rst_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7z007sclg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity int16_4x2x1_dma_nrst2rst_0_util_vector_logic_v2_0_2_util_vector_logic is
  port (
    Res : out STD_LOGIC_VECTOR ( 1 downto 0 );
    Op1 : in STD_LOGIC_VECTOR ( 1 downto 0 )
  );
end int16_4x2x1_dma_nrst2rst_0_util_vector_logic_v2_0_2_util_vector_logic;

architecture STRUCTURE of int16_4x2x1_dma_nrst2rst_0_util_vector_logic_v2_0_2_util_vector_logic is
begin
\Res[0]_INST_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => Op1(0),
      O => Res(0)
    );
\Res[1]_INST_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => Op1(1),
      O => Res(1)
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity int16_4x2x1_dma_nrst2rst_0 is
  port (
    Op1 : in STD_LOGIC_VECTOR ( 1 downto 0 );
    Res : out STD_LOGIC_VECTOR ( 1 downto 0 )
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of int16_4x2x1_dma_nrst2rst_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of int16_4x2x1_dma_nrst2rst_0 : entity is "mixed16_4x4x2_dma_nrst2rst_0,util_vector_logic_v2_0_2_util_vector_logic,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of int16_4x2x1_dma_nrst2rst_0 : entity is "yes";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of int16_4x2x1_dma_nrst2rst_0 : entity is "util_vector_logic_v2_0_2_util_vector_logic,Vivado 2022.1";
end int16_4x2x1_dma_nrst2rst_0;

architecture STRUCTURE of int16_4x2x1_dma_nrst2rst_0 is
begin
inst: entity work.int16_4x2x1_dma_nrst2rst_0_util_vector_logic_v2_0_2_util_vector_logic
     port map (
      Op1(1 downto 0) => Op1(1 downto 0),
      Res(1 downto 0) => Res(1 downto 0)
    );
end STRUCTURE;
