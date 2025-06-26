class `VITISNETP4_AGENT_NAME #(
) extends std_verif_pkg::agent;

    // Pointer to VitisNetP4 driver
    protected chandle _drv;

    // Pointer to Table context vector
    protected chandle _ctxPtr[$];

    //===================================
    // Methods
    //===================================
    // Constructor
    function new(input string name=`"`VITISNETP4_AGENT_NAME`", input string hier_path);
        super.new(name);
        this.__create(hier_path);
    endfunction

    // Destructor
    // [[ overrides std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        debug_msg("---------------- VitisNetP4: Destroy. -------------");
        // Destroy VitisNetP4 driver instance
        vitis_net_p4_dpi_pkg::XilVitisNetP4DpiDestroyEnv(_drv);
        super.destroy();
        debug_msg("---------------- VitisNetP4: Driver destroyed. -------------");
    endfunction

    // Create VitisNetP4 driver
    function void __create(
            input string hier_path
        );
        import vitis_net_p4_dpi_pkg::*;
        debug_msg("---------------- VitisNetP4: Create. -------------");
        if (this._drv == null) begin
            this._drv = XilVitisNetP4DpiCreateEnv(hier_path);
            debug_msg("---------------- VitisNetP4: Driver create done. -------------");
        end else begin
            debug_msg("---------------- VitisNetP4: Driver already exists. -------------");
        end
    endfunction

    // Initialize VitisNetP4 tables
    // - needs to be performed before any table accesses/programming
    task init();
        import `VITISNETP4_PKG_NAME::*;

        debug_msg("---------------- VitisNetP4: Init tables. -------------");
        initialize(this._ctxPtr, this._drv);
        debug_msg("---------------- VitisNetP4: Init tables done.. -------------");
    endtask

    // Reset VitisNetP4 tables
    // - reset VitisNetP4 IP to default state
    task reset_tables();
        import `VITISNETP4_PKG_NAME::*;

        debug_msg("---------------- VitisNetP4: Reset table state. -------------");
        reset_state(this._ctxPtr);
        debug_msg("---------------- VitisNetP4: Reset table state done.. -------------");
    endtask

    // Terminate VitisNetP4 drivers (tables, externs, etc.)
    task terminate();
        import `VITISNETP4_PKG_NAME::*;

        debug_msg("---------------- VitisNetP4: Terminate. -------------");
        if (this._drv == null) begin
            debug_msg("---------------- VitisNetP4: Terminate failed (Driver doesn't exist). -------------");
        end else begin
            terminate(this._ctxPtr);
            debug_msg("---------------- VitisNetP4: Terminate done. -------------");
        end
    endtask

    // vitisnetp4_table_init is based on the procedure described in the example_control.sv file of xilinx vitisnetp4_0 example design
    task table_init_from_file(input string filename);
        import xilinx_vitisnetp4_example_pkg::*;
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

        string __filename;
        int filename_len = filename.len;
        string filename_ext = filename.substr(filename.len-4,filename.len-1);

        // Always print this message to bracket print output from table driver
        // (no obvious way to disable driver output)
        print_msg("INFO: ", get_name(), "---------------- VitisNetP4: Initialize tables from file. -------------");

        reset_tables();

        // parse_cli_commands function adds '.txt' extension to filename input argument
        // (needs to be stripped if present
        if (filename_ext.compare(".txt"))
            __filename = filename;
        else
            __filename = filename.substr(0,filename.len-5);

        // Parse CLI command file (e.g. cli_commands.txt)
        parse_cli_commands(__filename, cli_cmds);

        for (int cmd_idx=0; cmd_idx<cli_cmds.size(); cmd_idx++) begin
           cli_cmd = cli_cmds[cmd_idx];
           case (cli_cmd.cmd_op)

               TBL_ADD: begin
                   table_format_str = `VITISNETP4_PKG_NAME::get_table_format_string(cli_cmd.table_name);
                   table_is_ternary = `VITISNETP4_PKG_NAME::table_is_ternary(cli_cmd.table_name);
                   action_id        = `VITISNETP4_PKG_NAME::get_action_id(cli_cmd.table_name, cli_cmd.action_name);
                   action_id_width  = `VITISNETP4_PKG_NAME::get_table_action_id_width(cli_cmd.table_name);
                   `VITISNETP4_PKG_NAME::get_action_arg_widths(cli_cmd.table_name, cli_cmd.action_name, action_arg_widths);
                   parse_match_fields(table_format_str, cli_cmd.match_fields, key, mask);
                   split_action_params_and_prio(table_is_ternary, cli_cmd.action_params, action_params, entry_priority);
                   parse_action_parameters(action_arg_widths, action_id, action_id_width, action_params, response);
                   if (VERBOSE) begin
                     $display("** Info: Adding entry to table %0s", cli_cmd.table_name);
                     $display("  - action:\t%0s", cli_cmd.action_name);
                     $display("  - match key:\t0x%0x", key);
                     $display("  - key mask:\t0x%0x", mask);
                     $display("  - response:\t0x%0x", response);
                     $display("  - priority:\t%0d", entry_priority);
                   end
                   `VITISNETP4_PKG_NAME::table_add(CtxPtr, cli_cmd.table_name, key, mask, response, entry_priority);
                   if (VERBOSE) $display("** Info: Entry has been added with handle %0d", cli_cmd.entry_id);
               end

               TBL_MODIFY : begin
                   action_id        = `VITISNETP4_PKG_NAME::get_action_id(cli_cmd.table_name, cli_cmd.action_name);
                   action_id_width  = `VITISNETP4_PKG_NAME::get_table_action_id_width(cli_cmd.table_name);
                   table_format_str = `VITISNETP4_PKG_NAME::get_table_format_string(cli_cmd.table_name);
                   `VITISNETP4_PKG_NAME::get_action_arg_widths(cli_cmd.table_name, cli_cmd.action_name, action_arg_widths);
                   parse_action_parameters(action_arg_widths, action_id, action_id_width, cli_cmd.action_params, response);
                   parse_match_fields(table_format_str, cli_cmd.match_fields, key, mask);
                   if (VERBOSE) begin
                     $display("** Info: Modifying entry from table %0s", cli_cmd.table_name);
                     $display("  - acion:\t%0s", cli_cmd.action_name);
                     $display("  - response:\t0x%0x", response);
                   end
                   `VITISNETP4_PKG_NAME::table_modify(CtxPtr, cli_cmd.table_name, key, mask, response);
                   if (VERBOSE) $display("** Info: Entry has been modified with handle %0d", cli_cmd.entry_id);
               end

               TBL_DELETE : begin
                   table_format_str = `VITISNETP4_PKG_NAME::get_table_format_string(cli_cmd.table_name);
                   parse_match_fields(table_format_str, cli_cmd.match_fields, key, mask);
                   if (VERBOSE) begin
                     $display("** Info: Deleting entry from table %0s", cli_cmd.table_name);
                     $display("  - match key:\t0x%0x", key);
                     $display("  - key mask:\t0x%0x", mask);
                   end
                   `VITISNETP4_PKG_NAME::table_delete(CtxPtr, cli_cmd.table_name, key, mask);
                   if (VERBOSE) $display("** Info: Entry has been deleted with handle %0d", cli_cmd.entry_id);
               end

               TBL_CLEAR : begin
                   if (VERBOSE) $display("** Info: Deleting all entries from table %0s", cli_cmd.table_name);
                   `VITISNETP4_PKG_NAME::table_clear(CtxPtr, cli_cmd.table_name);
               end

               RST_STATE : begin
                   if (VERBOSE) $display("** Info: Reseting VitisNet IP instance to default state");
                   `VITISNETP4_PKG_NAME::reset_state(CtxPtr);
               end

           endcase
       end
        print_msg("INFO: ", get_name(), "---------------- VitisNetP4: Initialize tables from file Done. -------------");
    endtask

endclass : `VITISNETP4_AGENT_NAME
