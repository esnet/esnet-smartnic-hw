// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Jonathan Sewter hereinafter the Contractor, under Contract No.
//  DE-AC02-05CH11231 with the Department of Energy (DOE). All rights in the
//  computer software are reserved by DOE on behalf of the United States
//  Government and the Contractor as provided in the Contract. You are
//  authorized to use this computer software for Governmental purposes but it
//  is not to be released or distributed to the public.
//
//  NEITHER THE GOVERNMENT NOR THE CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR
//  IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
//
//  This notice including this sentence must appear on any copies of this
//  computer software.
// =============================================================================
import smartnic_322mhz_pkg::*;

class tb_env extends std_verif_pkg::base;

    // Parameters
    // -- Datapath
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;
    // -- Timeouts
    localparam int RESET_TIMEOUT = 1024;     // In clk cycles
    localparam int MGMT_RESET_TIMEOUT = 256; // In aclk cycles

    //===================================
    // Properties
    //===================================

    // Reset interfaces
    virtual std_reset_intf #(.ACTIVE_LOW(1)) reset_vif;
    virtual std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_vif;

    // AXI-L management interface
    virtual axi4l_intf axil_vif;

    // SDnet AXI-L management interface
    virtual axi4l_intf axil_sdnet_vif;

    // AXI-S input interface
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_in_vif;
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_out_vif;
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_to_adpt_vif;
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_from_adpt_vif;

    // AXI3 interfaces to HBM
    virtual axi3_intf #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm_vif [16];

    // Drivers/Monitors
    axi4s_driver #(
        .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T (port_t), .TDEST_T (port_t)
    ) axis_driver;

    axi4s_monitor #(
        .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T (port_t), .TDEST_T (port_t)
    ) axis_monitor;

    axi4s_monitor #(
        .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T (port_t), .TDEST_T (port_t)
    ) axis_to_adpt_monitor;

    // AXI-L agent
    axi4l_reg_agent #() reg_agent;

    // SDnet AXI-L agent
    axi4l_reg_agent #() sdnet_reg_agent;

    // Register agents
    p4_app_reg_agent p4_app_reg_agent;

    // Pointer to SDNet driver
    protected chandle _drv;

    // Pointer to Table context vector
    protected chandle _ctxPtr[$];

    // Timestamp
    virtual timestamp_if #() timestamp_vif;

    timestamp_agent #() ts_agent;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(string name , bit bigendian = 1);
        super.new(name);
        axis_driver          = new(.BIGENDIAN(bigendian));
        axis_monitor         = new(.BIGENDIAN(bigendian));
        axis_to_adpt_monitor = new(.BIGENDIAN(bigendian));
        reg_agent            = new("axi4l_reg_agent");
        sdnet_reg_agent      = new("axi4l_reg_agent");
        p4_app_reg_agent     = new("p4_app_reg_agent", reg_agent, 'h0000);
        ts_agent             = new;
    endfunction

    function void connect();
        axis_driver.axis_vif          = axis_in_vif;
        axis_monitor.axis_vif         = axis_out_vif;
        axis_to_adpt_monitor.axis_vif = axis_to_adpt_vif;
        ts_agent.timestamp_vif        = timestamp_vif;
        reg_agent.axil_vif            = axil_vif;
        sdnet_reg_agent.axil_vif      = axil_sdnet_vif;
    endfunction

    task reset();
        reg_agent.idle();
        sdnet_reg_agent.idle();
        axis_driver.idle();
        axis_monitor.idle();
        axis_to_adpt_monitor.idle();
        reset_vif.pulse(8);
        mgmt_reset_vif.pulse(8);
        sdnet_reg_agent._wait(32);
    endtask

    task init_timestamp();
        ts_agent.reset();
    endtask

    task read(
            input  bit [31:0] addr,
            output bit [31:0] data,
            output bit error,
            output bit timeout,
            input  int TIMEOUT=128
        );
        axil_vif.read(addr, data, error, timeout, TIMEOUT);
    endtask

    task write(
            input  bit [31:0] addr,
            input  bit [31:0] data,
            output bit error,
            output bit timeout,
            input  int TIMEOUT=32
        );
        axil_vif.write(addr, data, error, timeout, TIMEOUT);
    endtask

    task wait_reset_done(
            output bit done,
            output string msg
        );
        bit reset_done;
        bit mgmt_reset_done;
        bit reset_timeout;
        bit mgmt_reset_timeout;
        fork
            begin
                reset_vif.wait_ready(
                    reset_timeout, RESET_TIMEOUT);
            end
            begin
                mgmt_reset_vif.wait_ready(
                    mgmt_reset_timeout, MGMT_RESET_TIMEOUT);
            end
        join
        reset_done = !reset_timeout;
        mgmt_reset_done = !mgmt_reset_timeout;
        done = reset_done & mgmt_reset_done;
        if (reset_done) begin
            if (mgmt_reset_done) begin
                msg = "Return from datapath and management resets completed.";
            end else begin
                msg =
                    $sformatf(
                        "Return from management reset timed out after %d mgmt_clk cycles.",
                        MGMT_RESET_TIMEOUT
                    );
            end
        end else begin
            if (mgmt_reset_done) begin
                msg =
                    $sformatf(
                        "Return from datapath reset timed out after %d clk cycles.",
                        RESET_TIMEOUT
                    );
            end else begin
                msg = "Return from datapath/management resets timed out.";
            end
        end
    endtask

    // SDnet Tasks
    task sdnet_read(
            input  bit [31:0] addr,
            output bit [31:0] data
        );
        sdnet_reg_agent.set_rd_timeout(128);
        sdnet_reg_agent.read_reg(addr, data);
    endtask

    task sdnet_write(
            input  bit [31:0] addr,
            input  bit [31:0] data
        );
        sdnet_reg_agent.set_wr_timeout(128);
        sdnet_reg_agent.write_reg(addr, data);
    endtask

    // Create SDNet driver
    function void sdnet_create(
            input string hier_path
        );
        import sdnet_0_pkg::*;
        debug_msg("---------------- SDnet: Create. -------------");
        if (this._drv == null) begin
            this._drv = XilVitisNetP4DpiCreateEnv(hier_path);
            debug_msg("---------------- SDnet: Driver create done. -------------");
        end else begin
            debug_msg("---------------- SDnet: Driver already exists. -------------");
        end
    endfunction

    // Initialize SDNet tables
    // - needs to be performed before any table accesses/programming
    task sdnet_init();
        import sdnet_0_pkg::*;

        debug_msg("---------------- SDnet: Init tables. -------------");
        initialize(this._ctxPtr, this._drv);
        debug_msg("---------------- SDnet: Init tables done.. -------------");
    endtask

    // Clean up SDNet tables
    // - destroys tables (created in sdnet_init)
    task sdnet_cleanup();
        import sdnet_0_pkg::*;

        debug_msg("---------------- SDnet: Destroy Tables. -------------");
        terminate(this._ctxPtr);
    endtask

    // sdnet_table_init is based on the procedure described in the example_control.sv file of xilinx sdnet_0 example design
    task sdnet_table_init_from_file(input string filename);
        import example_design_pkg::*;
        const bit VERBOSE = (this.get_debug_level() > 1);

        CliCmdStruct cli_cmds[$];
        CliCmdStruct cli_cmd;

        string table_format_str;
        strArray action_params;
        bitArray key, mask;
        bitArray response;
        int table_is_ternary;
        int action_id;
        int action_id_width;
        int entry_priority;
        int action_arg_widths[$];

        chandle CtxPtr[$] = this._ctxPtr;

        sdnet_init();

        // Parse CLI command file (e.g. config.txt)
        parse_cli_commands(filename, cli_cmds);

        for (int cmd_idx=0; cmd_idx<cli_cmds.size(); cmd_idx++) begin
           cli_cmd = cli_cmds[cmd_idx];
           case (cli_cmd.cmd_op)

               TBL_ADD: begin
                   table_format_str = sdnet_0_pkg::get_table_format_string(cli_cmd.table_name);
                   table_is_ternary = sdnet_0_pkg::table_is_ternary(cli_cmd.table_name);
                   action_id        = sdnet_0_pkg::get_action_id(cli_cmd.table_name, cli_cmd.action_name);
                   action_id_width  = sdnet_0_pkg::get_table_action_id_width(cli_cmd.table_name);
                   sdnet_0_pkg::get_action_arg_widths(cli_cmd.table_name, cli_cmd.action_name, action_arg_widths);
                   parse_match_fields(table_format_str, cli_cmd.match_fields, key, mask);
                   split_action_params_and_prio(table_is_ternary, cli_cmd.action_params, action_params, entry_priority);
                   parse_action_parameters(action_arg_widths, action_id, action_id_width, action_params, response);
                   if (VERBOSE) begin
                     $display("** Info: Adding entry to table %0s", cli_cmd.table_name);
                     $display("  - acion:\t%0s", cli_cmd.action_name);
                     $display("  - match key:\t0x%0x", key);
                     $display("  - key mask:\t0x%0x", mask);
                     $display("  - response:\t0x%0x", response);
                     $display("  - priority:\t%0d", entry_priority);
                   end
                   sdnet_0_pkg::table_add(CtxPtr, cli_cmd.table_name, key, mask, response, entry_priority);
                   if (VERBOSE) $display("** Info: Entry has been added with handle %0d", cli_cmd.entry_id);
               end

               TBL_MODIFY : begin
                   action_id        = sdnet_0_pkg::get_action_id(cli_cmd.table_name, cli_cmd.action_name);
                   action_id_width  = sdnet_0_pkg::get_table_action_id_width(cli_cmd.table_name);
                   table_format_str = sdnet_0_pkg::get_table_format_string(cli_cmd.table_name);
                   sdnet_0_pkg::get_action_arg_widths(cli_cmd.table_name, cli_cmd.action_name, action_arg_widths);
                   parse_action_parameters(action_arg_widths, action_id, action_id_width, cli_cmd.action_params, response);
                   parse_match_fields(table_format_str, cli_cmd.match_fields, key, mask);
                   if (VERBOSE) begin
                     $display("** Info: Modifying entry from table %0s", cli_cmd.table_name);
                     $display("  - acion:\t%0s", cli_cmd.action_name);
                     $display("  - response:\t0x%0x", response);
                   end
                   sdnet_0_pkg::table_modify(CtxPtr, cli_cmd.table_name, key, mask, response);
                   if (VERBOSE) $display("** Info: Entry has been modified with handle %0d", cli_cmd.entry_id);
               end

               TBL_DELETE : begin
                   table_format_str = sdnet_0_pkg::get_table_format_string(cli_cmd.table_name);
                   parse_match_fields(table_format_str, cli_cmd.match_fields, key, mask);
                   if (VERBOSE) begin
                     $display("** Info: Deleting entry from table %0s", cli_cmd.table_name);
                     $display("  - match key:\t0x%0x", key);
                     $display("  - key mask:\t0x%0x", mask);
                   end
                   sdnet_0_pkg::table_delete(CtxPtr, cli_cmd.table_name, key, mask);
                   if (VERBOSE) $display("** Info: Entry has been deleted with handle %0d", cli_cmd.entry_id);
               end

               TBL_CLEAR : begin
                   if (VERBOSE) $display("** Info: Deleting all entries from table %0s", cli_cmd.table_name);
                   sdnet_0_pkg::table_clear(CtxPtr, cli_cmd.table_name);
               end

               RST_STATE : begin
                   if (VERBOSE) $display("** Info: Reseting VitisNet IP instance to default state");
                   sdnet_0_pkg::reset_state(CtxPtr);
               end

           endcase
       end


  endtask

endclass : tb_env
