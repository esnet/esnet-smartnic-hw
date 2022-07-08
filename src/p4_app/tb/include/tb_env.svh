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
            this._drv = XilVitisNetP4DpiGetEnv(hier_path);
            debug_msg("---------------- SDnet: Driver create done. -------------");
        end else begin
            debug_msg("---------------- SDnet: Driver already exists. -------------");
        end
    endfunction

    // Initialize SDNet tables
    // - needs to be performed before any table accesses/programming
    task sdnet_init();
        import sdnet_0_pkg::*;

        chandle env = this._drv;

        debug_msg("---------------- SDnet: Init Tables. -------------");
        //
        // Table initialization routine as captured in sdnet_0_pkg::intialize()
        //
        //   The stock sdnet_0_pkg::initialize() task also initializes the environment, with a
        //   call to XilVitisNetP4DpiGetEnv(). That function can only be called once per sim run, which
        //   makes it impossible to initialize tables more than once (useful for multiple testcases
        //   within a single run, or within a regression run).
        //
        if (env != null) begin
            for (int tbl_idx = 0; tbl_idx < XilVitisNetP4TableList.size(); tbl_idx++) begin
                case (XilVitisNetP4TableList[tbl_idx].Config.Mode)
                    XIL_VITIS_NET_P4_TABLE_MODE_BCAM : begin
                        XilVitisNetP4BcamInit(XilVitisNetP4TableList[tbl_idx].PrivateCtxPtr, env, XilVitisNetP4TableList[tbl_idx].Config.CamConfig);
                    end
                    XIL_VITIS_NET_P4_TABLE_MODE_TCAM : begin
                        XilVitisNetP4TcamInit(XilVitisNetP4TableList[tbl_idx].PrivateCtxPtr, env, XilVitisNetP4TableList[tbl_idx].Config.CamConfig);
                    end
                    XIL_VITIS_NET_P4_TABLE_MODE_STCAM : begin
                        XilVitisNetP4StcamInit(XilVitisNetP4TableList[tbl_idx].PrivateCtxPtr, env, XilVitisNetP4TableList[tbl_idx].Config.CamConfig);
                    end
                    XIL_VITIS_NET_P4_TABLE_MODE_DCAM : begin
                        XilVitisNetP4DcamInit(XilVitisNetP4TableList[tbl_idx].PrivateCtxPtr, env, XilVitisNetP4TableList[tbl_idx].Config.CamConfig);
                    end
                endcase
            end
        end
    endtask

    // Clean up SDNet tables
    // - destroys tables (created in sdnet_init)
    task sdnet_cleanup();
        import sdnet_0_pkg::*;

        debug_msg("---------------- SDnet: Destroy Tables. -------------");
        terminate();
    endtask

    // sdnet_table_init is a copy of the initial block in the example_control.sv file of xilinx sdnet_0 example design
    task sdnet_table_init_from_file(input string filename);
        import example_design_pkg::*;
        const bit VERBOSE = (this.get_debug_level() > 1);

        strArray table_entry_handles[string][$];
        strArray empty_strArray_list [$];
        strArray empty_strArray;
        strArray match_fields;
        strArray action_params;
        strArray cmd_line;
        string str_line;
        string command;
        string table_name;
        string action_name;
        int fh, delim_idx;
        int entry_priority;
        int entry_handle;
        bitArray key, mask;
        bitArray response;

        /*------------------
        traffic_start <= 0;

        // Wait for reset signal to start
        @ (posedge axi_aresetn);
        for (int d=0; d<20; d++) @ (posedge axi_aclk);

        // instantiate drivers
        sdnet_0_pkg::initialize("example_top.example_control");
        ------------------*/

        info_msg("Opening CLI command file...");

        // open CLI commands file
        fh = $fopen(filename, "r");
        if (!fh) begin
            $fatal(1, "** Error: Failed to open file './cli_commands.txt' file");
        end

        // read file lines
        while(!$feof(fh)) begin
            if($fgets(str_line, fh)) begin

                // remove '\n' at the end of line
                while (str_line[str_line.len()-1] == "\n")
                    str_line = str_line.substr(0, str_line.len()-2);

                // ignore comments and empty lines
                if (str_line[0] == "%"  ||
                    str_line[0] == "#"  ||
                    str_line[0] == "\n" ||
                    str_line.len() == 0)
                    continue;

                // split line and parse command
                cmd_line = split(str_line, " ");
                command = cmd_line[0];
                case (command)

                     // table_add <table name> <action name> <match fields> => [action parameters] [priority]
                     "table_add" : begin
                         // parse args
                         for (delim_idx = 1; delim_idx < cmd_line.size(); delim_idx++) begin
                             if (cmd_line[delim_idx] == "=>")
                                 break;
                         end
                         table_name   = cmd_line[1];
                         action_name  = cmd_line[2];
                         match_fields = cmd_line[3:delim_idx-1];
                         parse_match_fields(table_name, match_fields, key, mask);
                         split_action_params_and_prio(table_name, cmd_line[delim_idx+1:cmd_line.size()-1], action_params, entry_priority);
                         parse_action_parameters(table_name, action_name, action_params, response);
                         // execute command
                         if (VERBOSE) begin
                           $display("** Info: Adding entry to table %0s", table_name);
                           $display("  - match key:\t0x%0x", key);
                           $display("  - key mask:\t0x%0x", mask);
                           $display("  - response:\t0x%0x", response);
                           $display("  - priority:\t%0d", entry_priority);
                         end
                         sdnet_0_pkg::table_add(table_name, key, mask, response, entry_priority);
                         // create entry handle
                         if (!table_entry_handles.exists(table_name))
                             table_entry_handles[table_name] = empty_strArray_list;
                         for (int i = 0; i <= table_entry_handles[table_name].size(); i++) begin
                             if (i == table_entry_handles[table_name].size())
                                table_entry_handles[table_name][i] = empty_strArray;
                             if (table_entry_handles[table_name][i].size() == 0) begin
                                 table_entry_handles[table_name][i] = match_fields;
                                 entry_handle = i;
                                 break;
                             end
                         end
                         if (VERBOSE)
                           $display("** Info: Entry has been added with handle %0d", entry_handle);
                     end

                     // table_modify <table name> <action name> <entry handle> [action parameters]
                     "table_modify" : begin
                         // parse args
                         table_name    = cmd_line[1];
                         action_name   = cmd_line[2];
                         entry_handle  = cmd_line[3].atoi();
                         action_params = cmd_line[4:cmd_line.size()-1];
                         parse_action_parameters(table_name, action_name, action_params, response);
                         // get entry handle
                         if (!table_entry_handles.exists(table_name)) begin
                             $fatal(1, "** Error: Table entry '%0d' not found for table '%0s'", entry_handle, table_name);
                         end
                         if (table_entry_handles[table_name][entry_handle].size() == 0) begin
                             $fatal(1, "** Error: Table entry '%0d' not found for table '%0s'", entry_handle, table_name);
                         end
                         match_fields = table_entry_handles[table_name][entry_handle];
                         parse_match_fields(table_name, match_fields, key, mask);
                         // execute command
                         if (VERBOSE) begin
                           $display("** Info: Modifying entry from table %0s", table_name);
                           $display("  - response:\t0x%0x", response);
                         end
                         sdnet_0_pkg::table_modify(table_name, key, mask, response);
                         if (VERBOSE)
                           $display("** Info: Entry has been modified with handle %0d", entry_handle);
                     end

                     // table_delete <table name> <entry handle>
                     "table_delete" : begin
                         // parse args
                         table_name   = cmd_line[1];
                         entry_handle = cmd_line[2].atoi();
                         // get entry handle
                         if (!table_entry_handles.exists(table_name)) begin
                             $fatal(1, "** Error: Table entry '%0d' not found for table '%0s'", entry_handle, table_name);
                         end
                         if (table_entry_handles[table_name][entry_handle].size() == 0) begin
                             $fatal(1, "** Error: Table entry '%0d' not found for table '%0s'", entry_handle, table_name);
                         end
                         match_fields = table_entry_handles[table_name][entry_handle];
                         parse_match_fields(table_name, match_fields, key, mask);
                         // execute command
                         if (VERBOSE) begin
                           $display("** Info: Deleting entry from table %0s", table_name);
                           $display("  - match key:\t0x%0x", key);
                           $display("  - key mask:\t0x%0x", mask);
                         end
                         sdnet_0_pkg::table_delete(table_name, key, mask);
                         if (VERBOSE)
                           $display("** Info: Entry has been deleted with handle %0d", entry_handle);
                         // delete entry handle
                         table_entry_handles[table_name][entry_handle] = empty_strArray;
                     end

                     // table_clear <table name>
                     "table_clear" : begin
                         table_name = cmd_line[1];
                         for (int i = 0; i <= table_entry_handles[table_name].size(); i++) begin
                             if (table_entry_handles[table_name][entry_handle].size() > 0) begin
                                 match_fields = table_entry_handles[table_name][entry_handle];
                                 parse_match_fields(table_name, match_fields, key, mask);
                                 sdnet_0_pkg::table_delete(table_name, key, mask);
                             end
                         end
                     end

                     // reset_state
                     "reset_state" : begin
                         $display("** Info: Reseting 'sdnet_0' to default state");
                         sdnet_0_pkg::reset_state();
                     end

                     // run_traffic <file name>
                     "run_traffic" : begin
                         /*------------------
                         // wait some time for simulation to settle down before running traffic
                         for (int d=0; d<100; d++) @ (posedge axi_aclk);
                         // trigger stimulus generation
                         $display("** Info: Running traffic from file '%0s'", cmd_line[1]);
                         traffic_filename = cmd_line[1];
                         //traffic_start    <= 1;
                         @ (posedge axi_aclk);
                         //traffic_start    <= 0;
                         // wait for stimulus generator and checker to be done
                         @ (posedge (stimulus_done | checker_done));
                         @ (posedge (checker_done  | stimulus_done));
                         @ (posedge axi_aclk);
                         ------------------*/
                         break;
                     end

                     // exit
                     "exit" : begin
                         break;
                     end

                     // ignore invalid commands
                     default : begin
                         $display("** Info: Ignoring invalid command '%0s'", command);
                         continue;
                     end

                endcase
            end
        end
  endtask

endclass : tb_env
