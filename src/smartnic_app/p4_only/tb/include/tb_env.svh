import smartnic_pkg::*;

class tb_env extends std_verif_pkg::base;

    // Parameters
    // -- Datapath
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    localparam int HOST_NUM_IFS = 2;   // Number of HOST interfaces.
    localparam int NUM_PORTS = 2;      // Number of processor ports (per vitisnetp4 processor).

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
    virtual axi4l_intf axil_vitisnetp4_vif;

    // AXI-S interfaces
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_in_vif  [NUM_PORTS];
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_out_vif [NUM_PORTS];
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_c2h_vif [NUM_PORTS * HOST_NUM_IFS];
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_h2c_vif [NUM_PORTS * HOST_NUM_IFS];

    // AXI3 interfaces to HBM
    virtual axi3_intf #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm_vif [16];

    // Drivers/Monitors
    axi4s_driver #(
        .TUSER_T(tuser_smartnic_meta_t), .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T (port_t), .TDEST_T (port_t)
    ) axis_driver  [NUM_PORTS * (HOST_NUM_IFS + 1)];

    axi4s_monitor #(
        .TUSER_T(tuser_smartnic_meta_t), .DATA_BYTE_WID (AXIS_DATA_BYTE_WID), .TID_T (port_t), .TDEST_T (port_t)
    ) axis_monitor [NUM_PORTS * (HOST_NUM_IFS + 1)];

    // AXI-L agent
    axi4l_reg_agent #() reg_agent;

    // SDnet AXI-L agent
    axi4l_reg_agent #() vitisnetp4_reg_agent;

    // Register agents
    p4_only_reg_agent p4_only_reg_agent;

    // Timestamp
    virtual timestamp_if #() timestamp_vif;

    timestamp_agent #() ts_agent;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(string name , bit bigendian = 1);
        super.new(name);
        axis_driver  [0]     = new(.BIGENDIAN(bigendian));
        axis_driver  [1]     = new(.BIGENDIAN(bigendian));
        axis_driver  [2]     = new(.BIGENDIAN(bigendian));
        axis_driver  [3]     = new(.BIGENDIAN(bigendian));
        axis_driver  [4]     = new(.BIGENDIAN(bigendian));
        axis_driver  [5]     = new(.BIGENDIAN(bigendian));
        axis_monitor [0]     = new(.BIGENDIAN(bigendian));
        axis_monitor [1]     = new(.BIGENDIAN(bigendian));
        axis_monitor [2]     = new(.BIGENDIAN(bigendian));
        axis_monitor [3]     = new(.BIGENDIAN(bigendian));
        axis_monitor [4]     = new(.BIGENDIAN(bigendian));
        axis_monitor [5]     = new(.BIGENDIAN(bigendian));
        reg_agent            = new("axi4l_reg_agent");
        vitisnetp4_reg_agent = new("axi4l_reg_agent");
        p4_only_reg_agent    = new("p4_only_reg_agent", reg_agent, 'h0000);
        ts_agent             = new;
    endfunction

    function void connect();
        axis_driver[0].axis_vif       = axis_in_vif[0];
        axis_driver[1].axis_vif       = axis_in_vif[1];
        axis_driver[2].axis_vif       = axis_h2c_vif[0];
        axis_driver[3].axis_vif       = axis_h2c_vif[1];
        axis_driver[4].axis_vif       = axis_h2c_vif[2];
        axis_driver[5].axis_vif       = axis_h2c_vif[3];
        axis_monitor[0].axis_vif      = axis_out_vif[0];
        axis_monitor[1].axis_vif      = axis_out_vif[1];
        axis_monitor[2].axis_vif      = axis_c2h_vif[0];
        axis_monitor[3].axis_vif      = axis_c2h_vif[1];
        axis_monitor[4].axis_vif      = axis_c2h_vif[2];
        axis_monitor[5].axis_vif      = axis_c2h_vif[3];
        ts_agent.timestamp_vif        = timestamp_vif;
        reg_agent.axil_vif            = axil_vif;
        vitisnetp4_reg_agent.axil_vif = axil_vitisnetp4_vif;
    endfunction

    task reset();
        reg_agent.idle();
        vitisnetp4_reg_agent.idle();
        axis_driver[0].idle();
        axis_driver[1].idle();
        axis_driver[2].idle();
        axis_driver[3].idle();
        axis_driver[4].idle();
        axis_driver[5].idle();
        axis_monitor[0].idle();
        axis_monitor[1].idle();
        axis_monitor[2].idle();
        axis_monitor[3].idle();
        axis_monitor[4].idle();
        axis_monitor[5].idle();
        reset_vif.pulse(8);
        mgmt_reset_vif.pulse(8);
        vitisnetp4_reg_agent._wait(32);
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
    task vitisnetp4_read(
            input  bit [31:0] addr,
            output bit [31:0] data
        );
        vitisnetp4_reg_agent.set_rd_timeout(128);
        vitisnetp4_reg_agent.read_reg(addr, data);
    endtask

    task vitisnetp4_write(
            input  bit [31:0] addr,
            input  bit [31:0] data
        );
        vitisnetp4_reg_agent.set_wr_timeout(128);
        vitisnetp4_reg_agent.write_reg(addr, data);
    endtask

endclass : tb_env
