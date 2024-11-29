import smartnic_250mhz_pkg::*;

class tb_env #(parameter int NUM_INTF = 2) extends std_verif_pkg::basic_env;
    // Parameters
    // -- Datapath
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;
    // -- Timeouts
    localparam int RESET_TIMEOUT = 1024; // In clk cycles

    //===================================
    // Typedefs
    //===================================
    parameter type H2C_AXI4S_TRANSACTION_T = axi4s_transaction#(bit,bit,tuser_h2c_t);
    parameter type C2H_AXI4S_TRANSACTION_T = axi4s_transaction#(bit,bit,tuser_c2h_t);

    //===================================
    // Properties
    //===================================

    // AXI-L management interface
    virtual axi4l_intf axil_vif;

    // AXI-S input interface
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_h2c_t)) axis_h2c_in_vif [NUM_INTF];
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_h2c_t)) axis_h2c_out_vif [NUM_INTF];
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_c2h_t)) axis_c2h_in_vif [NUM_INTF];
    virtual axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_c2h_t)) axis_c2h_out_vif [NUM_INTF];

    axi4s_component_env #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_h2c_t)) env_h2c [NUM_INTF];
    axi4s_component_env #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TUSER_T(tuser_c2h_t)) env_c2h [NUM_INTF];

    // Models
    wire_model#(H2C_AXI4S_TRANSACTION_T) h2c_model [NUM_INTF];
    wire_model#(C2H_AXI4S_TRANSACTION_T) c2h_model [NUM_INTF];

    // Scoreboards
    event_scoreboard#(H2C_AXI4S_TRANSACTION_T) h2c_scoreboard [NUM_INTF];
    event_scoreboard#(C2H_AXI4S_TRANSACTION_T) c2h_scoreboard [NUM_INTF];

    // AXI-L agent
    axi4l_reg_agent #() reg_agent;

    // Register block agents
    smartnic_250mhz_reg_blk_agent #() smartnic_250mhz_reg_blk_agent;

    // Name
    protected string name;

    //===================================
    // Methods
    //===================================

    // Constructor
    function new(string name , bit bigendian = 1);
        this.name = name;
        for (int i=0; i < NUM_INTF; i++) begin
            h2c_model[i] = new($sformatf("h2c_model[%0d]",i));
            c2h_model[i] = new($sformatf("c2h_model[%0d]",i));
            h2c_scoreboard[i] = new($sformatf("h2c_scoreboard[%0d]",i));
            c2h_scoreboard[i] = new($sformatf("c2h_scoreboard[%0d]",i));
            env_h2c[i] = new("env_h2c", h2c_model[i], h2c_scoreboard[i], bigendian);
            env_c2h[i] = new("env_c2h", c2h_model[i], c2h_scoreboard[i], bigendian);
        end
        reg_agent = new("axi4l_reg_agent");
        smartnic_250mhz_reg_blk_agent = new("smartnic_250mhz_reg_blk", 'h0000);
    endfunction

    function automatic void set_debug_level(input int DEBUG_LEVEL);
        super.set_debug_level(DEBUG_LEVEL);
        for (int i=0; i < NUM_INTF; i++) begin
            env_h2c[i].set_debug_level(DEBUG_LEVEL);
            env_c2h[i].set_debug_level(DEBUG_LEVEL);
        end
    endfunction

    function void connect();
        super.build();
        for (int i=0; i < NUM_INTF; i++) begin
            env_h2c[i].axis_in_vif = axis_h2c_in_vif[i];
            env_h2c[i].axis_out_vif = axis_h2c_out_vif[i];
            env_c2h[i].axis_in_vif = axis_c2h_in_vif[i];
            env_c2h[i].axis_out_vif = axis_c2h_out_vif[i];
            env_h2c[i].build();
            env_c2h[i].build();
        end
        reg_agent.axil_vif = axil_vif;
        smartnic_250mhz_reg_blk_agent.reg_agent = reg_agent;
    endfunction

    function automatic void reset();
        super.reset();
        for (int i=0; i < NUM_INTF; i++) begin
            env_h2c[i].reset();
            env_c2h[i].reset();
        end
    endfunction

    task idle();
        axil_vif.idle_controller();
        for (int i=0; i < NUM_INTF; i++) begin
            env_h2c[i].idle();
            env_c2h[i].idle();
        end
    endtask

    task start();
        for (int i=0; i < NUM_INTF; i++) begin
            env_h2c[i].start();
            env_c2h[i].start();
        end
    endtask

    task stop();
        for (int i=0; i < NUM_INTF; i++) begin
            env_h2c[i].stop();
            env_c2h[i].stop();
        end
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
        bit timeout;
        reset_vif.wait_ready(timeout, RESET_TIMEOUT);
        done = !timeout;
        if (done) msg = "Reset complete.";
        else      msg = $sformatf(
                      "Reset timed out after %0d clk cycles.",
                      RESET_TIMEOUT
                  );
    endtask

endclass : tb_env
