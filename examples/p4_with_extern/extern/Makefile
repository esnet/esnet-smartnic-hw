# ----------------------------------------------------
# Path setup
# ----------------------------------------------------
APP_DIR = $(abspath ..)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: add_extern_to_xpr  add_extern_to_dut_wrapper  add_so_to_p4bm_cmd

add_extern_to_xpr: add_extern_to_xpr.tcl
	vivado -mode batch -notrace -nojournal -nolog -source add_extern_to_xpr.tcl
	rm -f add_extern_to_xpr.tcl

add_extern_to_xpr.tcl:
	echo "open_project ../example/sdnet_0_ex/sdnet_0_ex.xpr" >> add_extern_to_xpr.tcl; \
	echo "import_files ./rtl"                                >> add_extern_to_xpr.tcl; \
	echo "close_project"                                     >> add_extern_to_xpr.tcl;


add_extern_to_dut_wrapper:
	sed -i 's:Instantiate User Extern:Instantiate User Extern\
   import sdnet_0_pkg\:\:*\;\
   \
   USER_EXTERN_OUT_T    user_extern_out\;\
   USER_EXTERN_VALID_T  user_extern_out_valid\;\
   USER_EXTERN_IN_T     user_extern_in\;\
   USER_EXTERN_VALID_T  user_extern_in_valid\;\
   \
   smartnic_extern smartnic_extern_0 (\
            .clk                     ( s_axis_aclk ),\
            .rstn                    ( s_axis_aresetn ),\
            .extern_from_sdnet       ( user_extern_out ),\
            .extern_from_sdnet_valid ( user_extern_out_valid ),\
            .extern_to_sdnet         ( user_extern_in ),\
            .extern_to_sdnet_valid   ( user_extern_in_valid )\
         )\;\
   :g' $(APP_DIR)/example/sdnet_0_ex/imports/example_dut_wrapper.sv


add_so_to_p4bm_cmd:
	sed -i 's:json_file\}:json_file -m ./smartnic_extern.so\}:g' $(APP_DIR)/example/sdnet_0_ex/imports/run-p4bm-vitisnet.tcl
