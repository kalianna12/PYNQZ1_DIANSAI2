// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Mon Mar 10 22:13:39 2025
// Host        : AYJT running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               f:/Xilix/7020/CDelc/LTC2208_MAX5885/TAFU/ltc2208_max5885.gen/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0_sim_netlist.v
// Design      : blk_mem_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z020clg484-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_0,blk_mem_gen_v8_4_7,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_7,Vivado 2023.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_0
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
  blk_mem_gen_0_blk_mem_gen_v8_4_7 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 43680)
`pragma protect data_block
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
kIxOs2thscUlgU/YqWgb80ZK
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
