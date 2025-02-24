import smartnic_pkg::*;
import axi4s_reg_verif_pkg::*;
import smartnic_app_reg_verif_pkg::*;

class tb_env extends std_verif_pkg::base;

    // Parameters
    // -- Datapath
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    localparam int HOST_NUM_IFS = 3;   // Number of HOST interfaces.
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
    virtual axi4l_intf app_axil_vif;

    // SDnet AXI-L management interface
    virtual axi4l_intf axil_vif;

    // AXI-S interfaces
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_in_vif  [NUM_PORTS];
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_h2c_vif [HOST_NUM_IFS][NUM_PORTS];
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_out_vif [NUM_PORTS];
    virtual axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_c2h_vif [HOST_NUM_IFS][NUM_PORTS];

    // Drivers/Monitors
    axi4s_driver #(      .TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_in_driver   [NUM_PORTS];
    axi4s_driver #(      .TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_h2c_driver  [HOST_NUM_IFS][NUM_PORTS];
    axi4s_monitor #(     .TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_out_monitor [NUM_PORTS];
    axi4s_monitor #(     .TUSER_T(tuser_smartnic_meta_t),
                         .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t)) axis_c2h_monitor [HOST_NUM_IFS][NUM_PORTS];

    // AXI-L agent
    axi4l_reg_agent #() app_reg_agent;

    // SDnet AXI-L agent
    axi4l_reg_agent #() reg_agent;

    // Register agents
    smartnic_app_reg_agent smartnic_app_reg_agent;

    axi4s_probe_reg_blk_agent #() probe_from_pf0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_pf1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_pf0_vf0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_pf1_vf0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_pf0_vf1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_from_pf1_vf1_reg_blk_agent;

    axi4s_probe_reg_blk_agent #() probe_to_pf0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_pf1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_pf0_vf0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_pf1_vf0_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_pf0_vf1_reg_blk_agent;
    axi4s_probe_reg_blk_agent #() probe_to_pf1_vf1_reg_blk_agent;

    // Timestamp
    virtual timestamp_if #() timestamp_vif;

    timestamp_agent #() ts_agent;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(string name , bit bigendian = 1);
        super.new(name);
        axis_in_driver[0]      = new(.BIGENDIAN(bigendian));
        axis_in_driver[1]      = new(.BIGENDIAN(bigendian));
        axis_h2c_driver[0][0]  = new(.BIGENDIAN(bigendian));
        axis_h2c_driver[1][0]  = new(.BIGENDIAN(bigendian));
        axis_h2c_driver[2][0]  = new(.BIGENDIAN(bigendian));
        axis_h2c_driver[0][1]  = new(.BIGENDIAN(bigendian));
        axis_h2c_driver[1][1]  = new(.BIGENDIAN(bigendian));
        axis_h2c_driver[2][1]  = new(.BIGENDIAN(bigendian));

        axis_out_monitor[0]    = new(.BIGENDIAN(bigendian));
        axis_out_monitor[1]    = new(.BIGENDIAN(bigendian));
        axis_c2h_monitor[0][0] = new(.BIGENDIAN(bigendian));
        axis_c2h_monitor[1][0] = new(.BIGENDIAN(bigendian));
        axis_c2h_monitor[2][0] = new(.BIGENDIAN(bigendian));
        axis_c2h_monitor[0][1] = new(.BIGENDIAN(bigendian));
        axis_c2h_monitor[1][1] = new(.BIGENDIAN(bigendian));
        axis_c2h_monitor[2][1] = new(.BIGENDIAN(bigendian));

        app_reg_agent          = new("axi4l_reg_agent");
        reg_agent              = new("axi4l_reg_agent");
        smartnic_app_reg_agent = new("smartnic_app_reg_agent", reg_agent, 'h63000);
        ts_agent               = new;

        probe_from_pf0_reg_blk_agent     = new("probe_from_pf0_reg_blk",     'h64000);
        probe_from_pf1_reg_blk_agent     = new("probe_from_pf1_reg_blk",     'h64100);
        probe_from_pf0_vf0_reg_blk_agent = new("probe_from_pf0_vf0_reg_blk", 'h64200);
        probe_from_pf1_vf0_reg_blk_agent = new("probe_from_pf1_vf0_reg_blk", 'h64300);
        probe_from_pf0_vf1_reg_blk_agent = new("probe_from_pf0_vf1_reg_blk", 'h64400);
        probe_from_pf1_vf1_reg_blk_agent = new("probe_from_pf1_vf1_reg_blk", 'h64500);

        probe_to_pf0_reg_blk_agent     = new("probe_to_pf0_reg_blk",     'h64600);
        probe_to_pf1_reg_blk_agent     = new("probe_to_pf1_reg_blk",     'h64700);
        probe_to_pf0_vf0_reg_blk_agent = new("probe_to_pf0_vf0_reg_blk", 'h64800);
        probe_to_pf1_vf0_reg_blk_agent = new("probe_to_pf1_vf0_reg_blk", 'h64900);
        probe_to_pf0_vf1_reg_blk_agent = new("probe_to_pf0_vf1_reg_blk", 'h64a00);
        probe_to_pf1_vf1_reg_blk_agent = new("probe_to_pf1_vf1_reg_blk", 'h64b00);

    endfunction

    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        // TODO
    endfunction

    function void connect();
        axis_in_driver[0].axis_vif        = axis_in_vif[0];
        axis_in_driver[1].axis_vif        = axis_in_vif[1];
        axis_h2c_driver[PF][0].axis_vif   = axis_h2c_vif[PF][0];
        axis_h2c_driver[PF][1].axis_vif   = axis_h2c_vif[PF][1];
        axis_h2c_driver[VF0][0].axis_vif  = axis_h2c_vif[VF0][0];
        axis_h2c_driver[VF0][1].axis_vif  = axis_h2c_vif[VF0][1];
        axis_h2c_driver[VF1][0].axis_vif  = axis_h2c_vif[VF1][0];
        axis_h2c_driver[VF1][1].axis_vif  = axis_h2c_vif[VF1][1];

        axis_out_monitor[0].axis_vif      = axis_out_vif[0];
        axis_out_monitor[1].axis_vif      = axis_out_vif[1];
        axis_c2h_monitor[PF][0].axis_vif  = axis_c2h_vif[PF][0];
        axis_c2h_monitor[PF][1].axis_vif  = axis_c2h_vif[PF][1];
        axis_c2h_monitor[VF0][0].axis_vif = axis_c2h_vif[VF0][0];
        axis_c2h_monitor[VF0][1].axis_vif = axis_c2h_vif[VF0][1];
        axis_c2h_monitor[VF1][0].axis_vif = axis_c2h_vif[VF1][0];
        axis_c2h_monitor[VF1][1].axis_vif = axis_c2h_vif[VF1][1];

        ts_agent.timestamp_vif            = timestamp_vif;
        app_reg_agent.axil_vif            = app_axil_vif;
        reg_agent.axil_vif                = axil_vif;

        probe_from_pf0_reg_blk_agent.reg_agent     = reg_agent;
        probe_from_pf1_reg_blk_agent.reg_agent     = reg_agent;
        probe_from_pf0_vf0_reg_blk_agent.reg_agent = reg_agent;
        probe_from_pf1_vf0_reg_blk_agent.reg_agent = reg_agent;
        probe_from_pf0_vf1_reg_blk_agent.reg_agent = reg_agent;
        probe_from_pf1_vf1_reg_blk_agent.reg_agent = reg_agent;

        probe_to_pf0_reg_blk_agent.reg_agent     = reg_agent;
        probe_to_pf1_reg_blk_agent.reg_agent     = reg_agent;
        probe_to_pf0_vf0_reg_blk_agent.reg_agent = reg_agent;
        probe_to_pf1_vf0_reg_blk_agent.reg_agent = reg_agent;
        probe_to_pf0_vf1_reg_blk_agent.reg_agent = reg_agent;
        probe_to_pf1_vf1_reg_blk_agent.reg_agent = reg_agent;

    endfunction

    task reset();
        app_reg_agent.idle();
        reg_agent.idle();

        axis_in_driver[0].idle();
        axis_in_driver[1].idle();
        axis_h2c_driver[PF][0].idle();
        axis_h2c_driver[PF][1].idle();
        axis_h2c_driver[VF0][0].idle();
        axis_h2c_driver[VF0][1].idle();
        axis_h2c_driver[VF1][0].idle();
        axis_h2c_driver[VF1][1].idle();

        axis_out_monitor[0].idle();
        axis_out_monitor[1].idle();
        axis_c2h_monitor[PF][0].idle();
        axis_c2h_monitor[PF][1].idle();
        axis_c2h_monitor[VF0][0].idle();
        axis_c2h_monitor[VF0][1].idle();
        axis_c2h_monitor[VF1][0].idle();
        axis_c2h_monitor[VF1][1].idle();

        reset_vif.pulse(8);
        mgmt_reset_vif.pulse(8);
        #100ns;
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
        app_axil_vif.read(addr, data, error, timeout, TIMEOUT);
    endtask

    task write(
            input  bit [31:0] addr,
            input  bit [31:0] data,
            output bit error,
            output bit timeout,
            input  int TIMEOUT=32
        );
        app_axil_vif.write(addr, data, error, timeout, TIMEOUT);
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
        reg_agent.set_rd_timeout(128);
        reg_agent.read_reg(addr, data);
    endtask

    task vitisnetp4_write(
            input  bit [31:0] addr,
            input  bit [31:0] data
        );
        reg_agent.set_wr_timeout(128);
        reg_agent.write_reg(addr, data);
    endtask

endclass : tb_env
