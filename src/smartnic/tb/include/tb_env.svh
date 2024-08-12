import smartnic_pkg::*;

class tb_env #(parameter int NUM_CMAC = 2) extends std_verif_pkg::base;
    // Parameters
    // -- Datapath
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;
    // -- Timeouts
    localparam int RESET_TIMEOUT = 1024; // In clk cycles
    localparam int MGMT_RESET_TIMEOUT = 256; // In aclk cycles

    // -- AXI-L
    localparam int AXIL_APP_OFFSET = 'h80000;
    localparam int AXIL_VITISNET_OFFSET = 'hC0000;

    //===================================
    // Properties
    //===================================

    // Reset interfaces
    virtual std_reset_intf reset_vif;
    virtual std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_vif;

    // AXI-L management interface
    virtual axi4l_intf axil_vif;

    // AXI-S input interface
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t)) axis_in_vif [2*NUM_CMAC];
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_out_vif [2*NUM_CMAC];
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(igr_tdest_t)) axis_sample_vif;

    // Drivers/Monitors
    axi4s_driver #(
        .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t)
    ) axis_driver [2*NUM_CMAC];

    axi4s_monitor #(
        .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)
    ) axis_monitor [2*NUM_CMAC];

    axi4s_sample #(
        .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(igr_tdest_t)
    ) axis_sample;

    // AXI-L agent
    axi4l_reg_agent #() reg_agent;

    // Register block agents
    smartnic_reg_blk_agent #() smartnic_reg_blk_agent;
    smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_0_reg_blk_agent;
    smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_1_reg_blk_agent;
    reg_endian_check_reg_blk_agent #() reg_endian_check_reg_blk_agent;

    axi4s_probe_reg_blk_agent #() probe_from_cmac_0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_cmac_1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_host_0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_host_1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_app0_to_core_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_app1_to_core_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_core_to_app0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_core_to_app1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_cmac_0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_cmac_1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_host_0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_host_1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_bypass_0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_bypass_1_reg_blk_agent;

    // Timestamp
    virtual timestamp_if #() timestamp_vif;

    timestamp_agent #() ts_agent;

    // Name
    protected string name;

    // Verbosity
    protected bit DEBUG = 1'b0;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(string name , bit bigendian = 1);
        this.name = name;
        for (int i=0; i < 2*NUM_CMAC; i++)  axis_driver[i] = new(.BIGENDIAN(bigendian));
        for (int i=0; i < 2*NUM_CMAC; i++) axis_monitor[i] = new(.BIGENDIAN(bigendian));
        axis_sample = new(.BIGENDIAN(bigendian));
        reg_agent = new("axi4l_reg_agent");
        ts_agent = new;
        smartnic_reg_blk_agent = new("smartnic_reg_blk", 'h0000);
        smartnic_hash2qid_0_reg_blk_agent = new("smartnic_hash2qid_0_reg_blk", 'h12000);
        smartnic_hash2qid_1_reg_blk_agent = new("smartnic_hash2qid_1_reg_blk", 'h13000);
        reg_endian_check_reg_blk_agent = new("reg_endian_check_reg_blk", 'h0400);

        probe_from_cmac_0_reg_blk_agent  = new("probe_from_cmac_0_reg_blk",    'h2000);
        probe_from_cmac_1_reg_blk_agent  = new("probe_from_cmac_1_reg_blk",    'h2300);
        probe_to_cmac_0_reg_blk_agent    = new("probe_core_to_cmac_0_reg_blk", 'h2600);
        probe_to_cmac_1_reg_blk_agent    = new("probe_core_to_cmac_1_reg_blk", 'h2800);

        probe_from_host_0_reg_blk_agent  = new("probe_from_host_0_reg_blk",    'h3000);
        probe_from_host_1_reg_blk_agent  = new("probe_from_host_1_reg_blk",    'h3100);
        probe_to_host_0_reg_blk_agent    = new("probe_core_to_host_0_reg_blk", 'h3200);
        probe_to_host_1_reg_blk_agent    = new("probe_core_to_host_1_reg_blk", 'h3400);

        probe_to_bypass_0_reg_blk_agent  = new("probe_to_bypass_0_reg_blk",    'h4000);
        probe_to_bypass_1_reg_blk_agent  = new("probe_to_bypass_1_reg_blk",    'h4300);

        probe_core_to_app0_reg_blk_agent = new("probe_core_to_app0_reg_blk",   'h0c00);
        probe_core_to_app1_reg_blk_agent = new("probe_core_to_app1_reg_blk",   'h0d00);
        probe_app0_to_core_reg_blk_agent = new("probe_app0_to_core_reg_blk",   'h0e00);
        probe_app1_to_core_reg_blk_agent = new("probe_app1_to_core_reg_blk",   'h0f00);

    endfunction

    function void set_debug(input bit debug);
        this.DEBUG = debug;
    endfunction

    function void debug(input string msg);
        if (DEBUG)
            $display($sformatf("DEBUG: [%0t][%0s]: %s", $time, name, msg));
    endfunction

    function void connect();
        for (int i=0; i < 2*NUM_CMAC; i++)  axis_driver[i].axis_vif = axis_in_vif[i];
        for (int i=0; i < 2*NUM_CMAC; i++) axis_monitor[i].axis_vif = axis_out_vif[i];
        axis_sample.axis_vif = axis_sample_vif;
        ts_agent.timestamp_vif = timestamp_vif;
        reg_agent.axil_vif = axil_vif;
        smartnic_reg_blk_agent.reg_agent = reg_agent;
        smartnic_hash2qid_0_reg_blk_agent.reg_agent = reg_agent;
        smartnic_hash2qid_1_reg_blk_agent.reg_agent = reg_agent;
        reg_endian_check_reg_blk_agent.reg_agent = reg_agent;

        probe_from_cmac_0_reg_blk_agent.reg_agent  = reg_agent;
        probe_from_cmac_1_reg_blk_agent.reg_agent  = reg_agent;
        probe_from_host_0_reg_blk_agent.reg_agent  = reg_agent;
        probe_from_host_1_reg_blk_agent.reg_agent  = reg_agent;
        probe_core_to_app0_reg_blk_agent.reg_agent = reg_agent;
        probe_core_to_app1_reg_blk_agent.reg_agent = reg_agent;
        probe_app0_to_core_reg_blk_agent.reg_agent = reg_agent;
        probe_app1_to_core_reg_blk_agent.reg_agent = reg_agent;
        probe_to_cmac_0_reg_blk_agent.reg_agent    = reg_agent;
        probe_to_cmac_1_reg_blk_agent.reg_agent    = reg_agent;
        probe_to_host_0_reg_blk_agent.reg_agent    = reg_agent;
        probe_to_host_1_reg_blk_agent.reg_agent    = reg_agent;
        probe_to_bypass_0_reg_blk_agent.reg_agent  = reg_agent;
        probe_to_bypass_1_reg_blk_agent.reg_agent  = reg_agent;
    endfunction

    task reset();
        reset_vif.pulse(8);
        mgmt_reset_vif.pulse(8);
        axil_vif.idle_controller();
        for (int i=0; i < 2*NUM_CMAC; i++)  axis_driver[i].idle();
        for (int i=0; i < 2*NUM_CMAC; i++) axis_monitor[i].idle();
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

    task vitisnetp4_read(
            input  bit [31:0] addr,
            output bit [31:0] data
        );
        int _addr = AXIL_VITISNET_OFFSET + addr;
        reg_agent.set_rd_timeout(128);
        reg_agent.read_reg(_addr, data);
    endtask

    task vitisnetp4_write(
            input  bit [31:0] addr,
            input  bit [31:0] data
        );
        int _addr = AXIL_VITISNET_OFFSET + addr;
        reg_agent.set_wr_timeout(128);
        reg_agent.write_reg(_addr, data);
    endtask

endclass : tb_env
