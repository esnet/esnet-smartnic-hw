import smartnic_pkg::*;
import pcap_pkg::*;

// Environment class for 'smartnic_app' component verification.
class tb_env extends std_verif_pkg::basic_env;
    //===================================
    // Parameters
    //===================================
    localparam int  DATA_BYTE_WID = 64;
    localparam type TID_T         = port_t;
    localparam type TDEST_T       = port_t;
    localparam type TUSER_T       = tuser_smartnic_meta_t;

    localparam type TRANSACTION_T = axi4s_transaction#(TID_T, TDEST_T, TUSER_T);
    localparam type DRIVER_T      = axi4s_driver  #(DATA_BYTE_WID, TID_T, TDEST_T, TUSER_T);
    localparam type MONITOR_T     = axi4s_monitor #(DATA_BYTE_WID, TID_T, TDEST_T, TUSER_T);
    localparam type MODEL_T       = smartnic_app_model;
    localparam type SCOREBOARD_T  = event_scoreboard#(TRANSACTION_T);

    local static const string __CLASS_NAME = "tb_pkg::tb_env";


    localparam int AXIL_APP_OFFSET = 'h100000;
    localparam int AXIL_VITISNET_OFFSET = 'h80000;

    localparam int NUM_HOST_IFS = 3;       // Number of HOST interfaces.
    localparam int NUM_PROC_PORTS = 2;     // Number of processor ports (per vitisnetp4 processor).
    localparam int N = NUM_PROC_PORTS*(NUM_HOST_IFS+1);

    //===================================
    // Properties
    //===================================
    DRIVER_T     driver  [N];
    MONITOR_T    monitor [N];
    MODEL_T      model   [N];
    SCOREBOARD_T scoreboard [N];

    mailbox #(TRANSACTION_T)  inbox [N];

    local mailbox #(TRANSACTION_T) __drv_inbox    [N];
    local mailbox #(TRANSACTION_T) __mon_outbox   [N];
    local mailbox #(TRANSACTION_T) __model_inbox  [N];
    local mailbox #(TRANSACTION_T) __model_outbox [N];

    // AXI-S interfaces
    virtual axi4s_intf #(.TUSER_T(TUSER_T), .DATA_BYTE_WID(DATA_BYTE_WID),
                         .TID_T(TID_T), .TDEST_T(TDEST_T)) axis_in_vif  [NUM_PROC_PORTS];
    virtual axi4s_intf #(.TUSER_T(TUSER_T), .DATA_BYTE_WID(DATA_BYTE_WID),
                         .TID_T(TID_T), .TDEST_T(TDEST_T)) axis_h2c_vif [NUM_HOST_IFS][NUM_PROC_PORTS];
    virtual axi4s_intf #(.TUSER_T(TUSER_T), .DATA_BYTE_WID(DATA_BYTE_WID),
                         .TID_T(TID_T), .TDEST_T(TDEST_T)) axis_out_vif [NUM_PROC_PORTS];
    virtual axi4s_intf #(.TUSER_T(TUSER_T), .DATA_BYTE_WID(DATA_BYTE_WID),
                         .TID_T(TID_T), .TDEST_T(TDEST_T)) axis_c2h_vif [NUM_HOST_IFS][NUM_PROC_PORTS];

    // AXI-L interfaces
    virtual axi4l_intf axil_vif;
    virtual axi4l_intf app_axil_vif;

    // AXI-L reg agents
    axi4l_reg_agent #() reg_agent;
    axi4l_reg_agent #() app_reg_agent;

    // Register agents
    smartnic_app_reg_agent smartnic_app_reg_agent;

    // Timestamp
    virtual timestamp_intf #() timestamp_vif;

    timestamp_agent #() ts_agent;


    //===================================
    // Methods
    //===================================
    // Constructor
    function new(input string name="tb_env");
        super.new(name);
        for (int i=0; i < N; i++) begin
            inbox[i]      = new();
            driver[i]     = new(.name($sformatf("axi4s_driver[%0d]",i)));
            monitor[i]    = new(.name($sformatf("axi4s_monitor[%0d]",i)));
            model[i]      = new(.name($sformatf("model[%0d]",i)));
            scoreboard[i] = new(.name($sformatf("scoreboard[%0d]",i)));

            __drv_inbox[i]    = new();
            __mon_outbox[i]   = new();
            __model_inbox[i]  = new();
            __model_outbox[i] = new();
        end

    endfunction


    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        for (int i=0; i < N; i++) begin
            inbox[i]      = null;
            driver[i]     = null;
            monitor[i]    = null;
            model[i]      = null;
            scoreboard[i] = null;

            __drv_inbox[i]    = null;
            __mon_outbox[i]   = null;
            __model_inbox[i]  = null;
            __model_outbox[i] = null;
        end
        super.destroy();
    endfunction


    // Configure trace output
    // [[ overrides std_verif_pkg::base.trace_msg() ]]
    function automatic void trace_msg(input string msg);
        _trace_msg(msg, __CLASS_NAME);
    endfunction


    // Build environment
    // [[ implements std_verif_pkg::env._build() ]]
    virtual protected function automatic void _build();
        trace_msg("_build()");
        for (int i=0; i < N; i++) begin
            driver[i].inbox   = __drv_inbox[i];
            model[i].inbox    = __model_inbox[i];
            model[i].outbox   = __model_outbox[i];
            monitor[i].outbox = __mon_outbox[i];
        end

        for (int i=0; i < N; i++) scoreboard[i].got_inbox = __mon_outbox[i];
        for (int i=0; i < N; i++) scoreboard[i].exp_inbox = __model_outbox[i];

        this.driver[0].axis_vif  = axis_in_vif[0];
        this.driver[1].axis_vif  = axis_in_vif[1];
        this.driver[2].axis_vif  = axis_h2c_vif[0][0];
        this.driver[3].axis_vif  = axis_h2c_vif[0][1];
        this.driver[4].axis_vif  = axis_h2c_vif[1][0];
        this.driver[5].axis_vif  = axis_h2c_vif[1][1];
        this.driver[6].axis_vif  = axis_h2c_vif[2][0];
        this.driver[7].axis_vif  = axis_h2c_vif[2][1];

        this.monitor[0].axis_vif  = axis_out_vif[0];
        this.monitor[1].axis_vif  = axis_out_vif[1];
        this.monitor[2].axis_vif  = axis_c2h_vif[0][0];
        this.monitor[3].axis_vif  = axis_c2h_vif[0][1];
        this.monitor[4].axis_vif  = axis_c2h_vif[1][0];
        this.monitor[5].axis_vif  = axis_c2h_vif[1][1];
        this.monitor[6].axis_vif  = axis_c2h_vif[2][0];
        this.monitor[7].axis_vif  = axis_c2h_vif[2][1];

        for (int i=0; i < N; i++) begin
            register_subcomponent(driver[i]);
            register_subcomponent(monitor[i]);
            register_subcomponent(model[i]);
            register_subcomponent(scoreboard[i]);
        end

        reg_agent              = new("axi4l_reg_agent");
        app_reg_agent          = new("axi4l_app_reg_agent");
        ts_agent               = new;

        reg_agent.axil_vif     = axil_vif;
        app_reg_agent.axil_vif = app_axil_vif;

        register_subcomponent(reg_agent);
        register_subcomponent(app_reg_agent);

        ts_agent.timestamp_vif = timestamp_vif;

        smartnic_app_reg_agent = new("smartnic_app_reg_agent", reg_agent, 'h64000);

        trace_msg("_build() Done.");
    endfunction


    // Start environment execution (run loop)
    // [[ implements std_verif_pkg::component._run() ]]
    protected task _run();
        trace_msg("_run()");
        super._run();
        trace_msg("Running...");

        trace_msg("_run() Done.");
    endtask


    task automatic pcap_to_driver (
        input string      filename,
        input TID_T       tid=0,
        input TDEST_T     tdest=0,
        input TUSER_T     tuser=0,
        input DRIVER_T    driver  );

        // signals
        pcap_pkg::pcap_t pcap;
        int num_pkts;

        // read pcap file
        pcap = pcap_pkg::read_pcap(filename);
        num_pkts = pcap.records.size();

        // put packets one at a time
        for (int i = 0; i < num_pkts; i++) begin
            axi4s_transaction#(TID_T, TDEST_T, TUSER_T) transaction =
                axi4s_transaction#(TID_T, TDEST_T, TUSER_T)::create_from_bytes(
                    $sformatf("Packet %0d", i),
                    pcap.records[i].pkt_data,
                    tid,
                    tdest,
                    tuser
                );
            driver.inbox.put(transaction);
        end
    endtask


    task automatic pcap_to_scoreboard (
        input string       filename,
        input TID_T        tid=0,
        input TDEST_T      tdest=0,
        input TUSER_T      tuser=0,
        input SCOREBOARD_T scoreboard );

        // signals
        pcap_pkg::pcap_t pcap;
        int num_pkts;

        // read pcap file
        pcap = pcap_pkg::read_pcap(filename);
        num_pkts = pcap.records.size();

        // put packets one at a time
        for (int i = 0; i < num_pkts; i++) begin
            axi4s_transaction#(TID_T, TDEST_T, TUSER_T) transaction =
                axi4s_transaction#(TID_T, TDEST_T, TUSER_T)::create_from_bytes(
                    $sformatf("Packet %0d", i),
                    pcap.records[i].pkt_data,
                    tid,
                    tdest,
                    tuser
                );
            scoreboard.exp_inbox.put(transaction);
        end
    endtask


    task init_timestamp();
        ts_agent.reset();
    endtask


    // vitisnetp4 tasks
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


// Environment class for 'smartnic_app' component verification.  placeholder for future code (tbd).
class smartnic_app_model
    extends std_verif_pkg::model#(axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t),
                                  axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t));

    function new(string name="smartnic_app_model");
        super.new(name);
    endfunction

    protected task _process(input axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t) transaction);
        _enqueue(transaction);
    endtask

endclass
