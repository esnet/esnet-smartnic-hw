set module_name xilinx_gtm_0

create_ip -name gtwiz_versal -vendor xilinx.com -library ip -version 1.0 -module_name $module_name -dir . -force

set_property -dict [list \
  CONFIG.NO_OF_QUADS           {1} \
  CONFIG.NO_OF_INTERFACE       {1} \
  CONFIG.GT_TYPE               {GTM} \
  CONFIG.ENABLE_REG_INTERFACE  {true} \
  CONFIG.REG_CONF_INTF         {AXI_LITE} \
  CONFIG.INTF0_PRESET          {GTM-NRZ_Ethernet_25G} \
  CONFIG.INTF0_NO_OF_LANES     {4} \
  CONFIG.INTF0_GT_SETTINGS     {LR0_SETTINGS {RXPROGDIV_FREQ_VAL 644.531 RX_REFCLK_FREQUENCY 322.265625 TXPROGDIV_FREQ_VAL 644.531 TX_REFCLK_FREQUENCY 322.265625}} \
  CONFIG.QUAD0_PROT0_LANES     {4} \
  CONFIG.QUAD0_GT_GPIO_EN      {true} \
  CONFIG.QUAD0_CH0_LOOPBACK_EN {true} \
  CONFIG.QUAD0_CH1_LOOPBACK_EN {true} \
  CONFIG.QUAD0_CH2_LOOPBACK_EN {true} \
  CONFIG.QUAD0_CH3_LOOPBACK_EN {true} \
  CONFIG.INTF0_OPTIONAL_PORTS  {ch_rxcdrhold true ch_txmaincursor true ch_txpostcursor true ch_txprecursor true} \
] [get_ips $module_name]
