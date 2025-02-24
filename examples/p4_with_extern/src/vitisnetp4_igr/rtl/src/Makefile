# ----------------------------------------------------
# Path setup
# ----------------------------------------------------
APP_DIR = $(abspath ../../../..)

include $(APP_DIR)/config.mk

# ----------------------------------------------------
# Variablle and source setup
# ----------------------------------------------------
VITISNETP4_IP_NAME ?= vitisnetp4_igr

SRC_DIRS = . \
           $(SMARTNIC_ROOT)/src/smartnic/pkg/src \
           $(SMARTNIC_ROOT)/esnet-fpga-library/src/axi4s/rtl/src \
           $(SMARTNIC_ROOT)/esnet-fpga-library/src/axi4l/rtl/src

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: add_extern_to_xpr  add_extern_to_dut_wrapper  add_so_to_p4bm_cmd

add_extern_to_xpr: add_extern_to_xpr.tcl
	vivado -mode batch -notrace -nojournal -nolog -source add_extern_to_xpr.tcl
	rm -f add_extern_to_xpr.tcl

add_extern_to_xpr.tcl:
	echo "open_project $(APP_DIR)/example/$(VITISNETP4_IP_NAME)_ex/$(VITISNETP4_IP_NAME)_ex.xpr" >> add_extern_to_xpr.tcl; \
	echo "import_files $(SRC_DIRS)"                                                              >> add_extern_to_xpr.tcl; \
	echo "close_project"                                                                         >> add_extern_to_xpr.tcl;

add_extern_to_dut_wrapper:
	sed -i 's:Instantiate User Externs:Instantiate User Externs\
   import $(VITISNETP4_IP_NAME)_pkg\:\:*\;\
   import smartnic_pkg\:\:*;\
   \
   USER_EXTERN_OUT_T    user_extern_out\;\
   USER_EXTERN_VALID_T  user_extern_out_valid\;\
   USER_EXTERN_IN_T     user_extern_in\;\
   USER_EXTERN_VALID_T  user_extern_in_valid\;\
   \
   axi4l_intf           axil_to_extern ()\;\
   axi4s_intf           axis_to_extern ()\;\
   axi4s_intf           axis_from_extern ()\;\
   \
   vitisnetp4_igr_extern vitisnetp4_igr_extern_inst (\
            .clk                     ( s_axis_aclk ),\
            .rstn                    ( s_axis_aresetn ),\
            .extern_from_vitisnetp4       ( user_extern_out ),\
            .extern_from_vitisnetp4_valid ( user_extern_out_valid ),\
            .extern_to_vitisnetp4         ( user_extern_in ),\
            .extern_to_vitisnetp4_valid   ( user_extern_in_valid ),\
            .timestamp                    ( 0 ),\
            .egr_flow_ctl                 ( 0 ),\
            .axil_to_extern               ( axil_to_extern ),\
            .axis_to_extern               ( axis_to_extern ),\
            .axis_from_extern             ( axis_from_extern )\
         )\;\
   \
   axi4l_intf_controller_term   axil_term       ( .axi4l_if(axil_to_extern) )\;\
   axi4s_intf_tx_term   axis_to_extern_term     ( .aclk(s_axis_aclk), .aresetn(s_axis_aresetn), .axi4s_if(axis_to_extern) )\;\
   axi4s_intf_rx_sink   axis_from_extern_sink   ( .axi4s_if(axis_from_extern) )\;\
   :g' $(APP_DIR)/example/$(VITISNETP4_IP_NAME)_ex/imports/example_dut_wrapper.sv

add_so_to_p4bm_cmd:
	sed -i 's:-j \$$json_file:-j \$$json_file -m ./$(VITISNETP4_IP_NAME)_extern.so:g' $(APP_DIR)/example/$(VITISNETP4_IP_NAME)_ex/imports/compile_pre_script.tcl
