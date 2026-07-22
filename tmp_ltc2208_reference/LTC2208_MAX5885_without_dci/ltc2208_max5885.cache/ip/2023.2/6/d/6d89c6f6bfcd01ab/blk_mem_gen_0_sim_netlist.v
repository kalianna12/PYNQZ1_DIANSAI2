// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Mon Mar 10 22:13:38 2025
// Host        : AYJT running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ blk_mem_gen_0_sim_netlist.v
// Design      : blk_mem_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z020clg484-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_0,blk_mem_gen_v8_4_7,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_7,Vivado 2023.2" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (clka,
    ena,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [11:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [15:0]douta;

  wire [11:0]addra;
  wire clka;
  wire [15:0]douta;
  wire ena;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [15:0]NLW_U0_doutb_UNCONNECTED;
  wire [11:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [11:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [15:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "12" *) 
  (* C_ADDRB_WIDTH = "12" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     4.652799 mW" *) 
  (* C_FAMILY = "zynq" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "1" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "blk_mem_gen_0.mem" *) 
  (* C_INIT_FILE_NAME = "blk_mem_gen_0.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "4096" *) 
  (* C_READ_DEPTH_B = "4096" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "16" *) 
  (* C_READ_WIDTH_B = "16" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "4096" *) 
  (* C_WRITE_DEPTH_B = "4096" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "16" *) 
  (* C_WRITE_WIDTH_B = "16" *) 
  (* C_XDEVICEFAMILY = "zynq" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_blk_mem_gen_v8_4_7 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[15:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[11:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[11:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[15:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(1'b0),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2023.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
jLV29U0rrfMIZhYJzdoUrPoqB9eHQ5NXmWyCdqnN3Wgm+GU4C3zthrN1m4QGiaj0thPCIynZbX+0
7yjtkv+T5ByJ6NhiofAwWseGLvPXlYu6ERAPvi4SAYpF2VUqQHtPAbPmnPubGdDRgIEpeobF7hsz
rEcpEru1pyiScUriyuo=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
vsoizVrOONWw/DhjRLEYrtRmtji+Ok63CbpSg/l9VnoKAi8tAzqRbQ57atGB2N6IGGbKHkbK2Uzh
EHgWvYZeyt4hE+bpQX91vc9PNxfjQMGzPoFD3jCWk30EmEk+AND39eWx+DhJ8xhFuucoOQ2GwyAk
B+Mjs15naPE7DvlHel8hnD4dfSdYhGKp96oozu8JeBto8aHG6poOuYkxSwaut7NCI+mabCkMxtMp
RrydgmRuTvhRTbJMyx5CxFSZTRDrS5aU1vaRlnMiqKCI7g2KY9pemYaJsFeVodBuo6IyKGynyEhs
wr+VtUhQDtaVhMkwB95WwmMoDk9F2L5Au1I+TQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
W081dPMCWhKs5YlQD7n3zvf7+PTcnb8eFWxoVs8+zHLkxDMA1klITbsfztGYvJFce8Yao5XQLLqZ
oUE5Pq2arq+zwICFUcLjdMsmP1WmL82znHOPHm83zNwrxWMloHkySAqzFbgJeHa973uZqj0M8ydc
sYmzCYVlGVjt0QX0xqA=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Zpc3MmdLWaVOv+S4z2POuoyslYoAbWc+Npxq2UyQRtDwf566IId3uwAetolMAgfLo/G3ezuSOXMn
8NznS37h9XvmVrxA50SAux68P87WgkLtiUYqM3CMBKkxNlZ/TR8WzTuQyFdvzkOE9lp8HC7LXnk5
RDsnOM+su46FW7ysY01COslo9Xc7rhs6WFqx29+Xcqk8+ZMLSzaJfuwZdNmJFS3Q1vhlq3ZeYqMl
wMieB731KsPxjxp7VKNHpTbgFryC2isqc4ohBDOt52M/Bz4B/rIpFeHfZ7X3jWSiKtSuBsDN2NXf
EMjfAT248dlK7NxJ+NBNPhS5sLxTiGyQhta57A==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rPMYqnkKhJKV1wltOfDrKos9ZbucaoX3WGTuqsdLkGpcKObzslHBwlGrKtWV7bZYmS2SM+QuEMfa
CE+tCUdsSiprp+n5BuSQlJa6BJ8mlqccjoo/JLw2QEmUhyMXQ3TLGomGGoZdeTmMPXhUBAOyLPea
Ddc8mgtTN8Kpy117GOTXDKP+IKJqW01fLrPJpgEhFiJCbyElLgtCRWmI94gX+y4XNVS0Cd1YwNw6
4nHgnEdC7fXARDKcYO3VsWC/pdzPQgursXloNLrVYa6i2xr+8E1V0+nSWwNYQZP7XUIVqXKMU8Ea
bT4acXrRCF/5tJJ5B9JparYI0zxXSbaakn1dIw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2022_10", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mfroTgL8g2pyIXQ/mGO9YHm19cd5mOlJ++qpusOYeVxGmkIhvF4aKx+AyIUz2yGGAeCtOzIasHty
pyqKgZhibSqxcpHgR0m6GOxXXOXJiHaK8NzxUzXeRJovcBI/WjtDhXeb1LRMI1J97jVBtJPJQH0Y
fGOD7jWvkvQwxnrZdyLp6kPWgSIcavHHDbO7iJv4gnyGp6W3/FCDo2RKWNLoW+SNjSdLZ6YRP8a+
ldaGU8TYvJ03KWlmik7repuN6AwxCjg2KeQ+x1sBAEXzROXomuSbvX3ZAo8UiIKAQY1SJumHLG3L
QI/S4Wbl1Hz6LDTsttMwP480gq6+tb6s1E4oWw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QJIabgm8dx/gVHbOQFwt8maOKVHFgkpZTPR6dzD8fqoGo9M9oGPTqBqchtPZWgv2UYFF2KEUSlV4
L3SDXBKrLs+NsAVTcICaEMiEi6j82zj/C1LsPkQfS8RLrg0ab8lbDMb5YqJ7lkHs3iM65x2iN1Mf
66cTgCbkAdl3rDpab75btpTQt5ZKiq5CSY3RZfyIW0uWbTGTELm6liuRKM9+K8BQwTU7A+FFFQBA
/9eJwQYzNNA/iwoYJ2WTPd6pBlzXriNLu9M+/2bYicNBSuH1PBR9v2ESrTB6k7EiV1zvBXV9NuG/
sFt4MumWMuSNwP2W38bQATxxW/l0IrmaXGOC/w==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
lhKf/Vgj6pHpme1ji4HVe36BU8pMkam/2I9lFeyOiBnIbzgdEGfLJBcEvkL33A7s0hxa6LFbHnkT
upgMpPjmIghBz3xUQ13vpiY152thFec6qvlcdg1r+GTmnBOSFl6g/OfZ3eFUhfsve6ZjQHpXnKFo
a55hN2+eP1EG9+VxGeM7XkHaeFhEIry52qtnmg072KEFIwRiGs2d/TJ4AqupuIdIiP1kTN9k+oqa
2ta1vdtqPY0dDHqrf+5YSd0CejkhQeCqg/bauLP3755SwdOPRgooG5ANT8hUpTiFMFXtU+GC9NSp
evJtMHUy1NbgMmhFHO+w3URLEdjSaBxZPD7YLdWkF65jY526tJzoek+BzEKoBaGfCaY7O1nHKXm+
89k3rPUy0Xo4/0nHpno+N/Db09heJPbnGsCwN/l+KnR6Lz8kvWziBjZe0ijOkKI+T12y3T1VeOtY
H/aqtNlQt1mhFwrbw6ezaAiDPVbCQXnly6b4tbb8+nFsxWOGIGAfLozB

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PNsQ8uEcQYrl+GaDuBaq1tQ5br5aAdaqHnyrc0NVu/JnQUk53jaiLx8Oz5fNACvWelUUk2/C+P5I
b2rbU1bb/dC6TqC5J1N0yoMYRYw58u4Lrl8Kgqgt9Rlph5Qgzzfxp+oblXF/pO4mRyAXpZhpNkFT
0Ar9BUtPOTOtJ9/g53SRnZ6GjxzfeD+25J4fcXBNo2gCTgUkwiLSsJRwTB/cJmn+dZPwPdIOHEP9
TkfDK+OrbLYO3T+DFBTCMRNH2NB1J9sc5s+nPU8iYnjgPTo6HoGW+LIlCz6yNJMZzJzoeW708utc
0fJXkT7vLDVh7olvy3V9AAY8Do0YR1kiZlhVhQ==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
zAz8RnGHFebkJFAS+gjC+mXHW7m7We+JgSmIz15mS01u/4+9Ng0sJfkeXOClmVPTQ2Mp2Yuv6/6f
ehzUTcANilWsqLM6Q1FToCPNX/NTqodlcHirGM7b5R9yevouNT/aqH12nmbunBQmBHmehNutdCjG
r6Z7kZgeZ2ZE7MMOF0rTy1XHEPkqgMNTRoS8R/pPWPTW4/j+bn3aJj0Q/fTz4Gi3mbSUKWs2fREQ
UKiuolNJkN6DiDvhlVYHUyytXNJG44ikmBXehoQQRLapkYaxnQmMRT1ok9uY6pKoy71CtvJ3Mt2x
EQv1GU2i4qQyAOwa0mkEohWXduicU6tDz3zQwQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
TK3eE9V+v1z2P1KjG4GrjhA1n3qDOpNzLGXdtjnjhF0QBFPSuhC+nmNqTPOb3p2a9r5KD0miY3Cd
+KpjH6Ao09E2/LD2Go4aLQh6vP+9BldlSKEwCGfx2NjBQrXWVH21lQR7IRjOvyTOclpd7SgtUJLw
dvebETyLiKr9C6RfnIBeptuCA3iJlXfwkh6I0JfzD5WBizQkotioZmmrXv5105pCXQ4Ta1WThFsA
2ll9dZeSjEDHUxxhfyfjryv9m4VL89ZDU/rGITsdptwB1BC1jLqmPDymY05lyECnjA6NIR5GGfI4
K2y2f4GfikKoN5r9IOvFzw963Wm82ZZPtXOKGg==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 43824)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
