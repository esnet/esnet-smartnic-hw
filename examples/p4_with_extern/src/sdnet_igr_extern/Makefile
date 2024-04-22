# ----------------------------------------------------
# Path setup
# ----------------------------------------------------
APP_DIR = $(abspath ..)

VITISNETP4_IP_NAME ?= sdnet_igr

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: add_extern_to_xpr  add_extern_to_dut_wrapper  add_so_to_p4bm_cmd

add_extern_to_xpr: add_extern_to_xpr.tcl
	vivado -mode batch -notrace -nojournal -nolog -source add_extern_to_xpr.tcl
	rm -f add_extern_to_xpr.tcl

add_extern_to_xpr.tcl:
	echo "open_project ../../example/$(VITISNETP4_IP_NAME)_ex/$(VITISNETP4_IP_NAME)_ex.xpr" >> add_extern_to_xpr.tcl; \
	echo "import_files ./rtl/src"                                                           >> add_extern_to_xpr.tcl; \
	echo "close_project"                                                                    >> add_extern_to_xpr.tcl;

add_extern_to_dut_wrapper:
	sed -i 's:Instantiate User Externs:Instantiate User Externs\
   import $(VITISNETP4_IP_NAME)_pkg\:\:*\;\
   \
   USER_EXTERN_OUT_T    user_extern_out\;\
   USER_EXTERN_VALID_T  user_extern_out_valid\;\
   USER_EXTERN_IN_T     user_extern_in\;\
   USER_EXTERN_VALID_T  user_extern_in_valid\;\
   \
   sdnet_igr_extern sdnet_igr_extern_inst (\
            .clk                     ( s_axis_aclk ),\
            .rstn                    ( s_axis_aresetn ),\
            .extern_from_sdnet       ( user_extern_out ),\
            .extern_from_sdnet_valid ( user_extern_out_valid ),\
            .extern_to_sdnet         ( user_extern_in ),\
            .extern_to_sdnet_valid   ( user_extern_in_valid )\
         )\;\
   :g' $(APP_DIR)/example/$(VITISNETP4_IP_NAME)_ex/imports/example_dut_wrapper.sv


add_so_to_p4bm_cmd:
	sed -i 's:-j \$$json_file:-j \$$json_file -m ./$(VITISNETP4_IP_NAME)_extern.so:g' $(APP_DIR)/example/$(VITISNETP4_IP_NAME)_ex/imports/compile_pre_script.tcl
