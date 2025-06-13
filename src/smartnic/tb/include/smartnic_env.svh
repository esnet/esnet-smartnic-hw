import smartnic_pkg::*;
import smartnic_verif_pkg::*;
import smartnic_app_reg_pkg::*;
import pcap_pkg::*;

// Environment class for 'smartnic' component verification.
class smartnic_env extends std_verif_pkg::basic_env;
    //===================================
    // Parameters
    //===================================
    localparam int  DATA_BYTE_WID = 64;
    localparam type TID_IN_T      = adpt_tx_tid_t;
    localparam type TID_OUT_T     = port_t;
    localparam type TDEST_T       = port_t;
    localparam type TUSER_IN_T    = bit;
    localparam type TUSER_OUT_T   = tuser_smartnic_meta_t;

    localparam type TRANSACTION_IN_T  = axi4s_transaction#(TID_IN_T, TDEST_T, TUSER_IN_T);
    localparam type TRANSACTION_OUT_T = axi4s_transaction#(TID_OUT_T, TDEST_T, TUSER_OUT_T);
    localparam type DRIVER_T          = axi4s_driver  #(DATA_BYTE_WID, TID_IN_T,  TDEST_T, TUSER_IN_T);
    localparam type MONITOR_T         = axi4s_monitor #(DATA_BYTE_WID, TID_OUT_T, TDEST_T, TUSER_OUT_T);
    localparam type MODEL_T           = smartnic_model;
    localparam type SCOREBOARD_T      = event_scoreboard#(TRANSACTION_OUT_T);

    local static const string __CLASS_NAME = "std_verif_pkg::smartnic_env";

    // -- AXI-L
    localparam int AXIL_APP_OFFSET = 'h100000;
    localparam int AXIL_VITISNET_OFFSET = 'h80000;

    //===================================
    // Properties
    //===================================
    DRIVER_T     driver  [4];
    MONITOR_T    monitor [4];
    MODEL_T      model   [4];
    SCOREBOARD_T scoreboard [4];

    mailbox #(TRANSACTION_IN_T)  inbox [4];

    local mailbox #(TRANSACTION_IN_T)  __drv_inbox    [4];
    local mailbox #(TRANSACTION_OUT_T) __mon_outbox   [4];
    local mailbox #(TRANSACTION_IN_T)  __model_inbox  [4];
    local mailbox #(TRANSACTION_OUT_T) __model_outbox [4];

    virtual axi4s_intf #(
        .DATA_BYTE_WID(DATA_BYTE_WID),
        .TID_T   (TID_IN_T),
        .TDEST_T (TDEST_T),
        .TUSER_T (TUSER_IN_T)
    ) axis_in_vif [4];

    virtual axi4s_intf #(
        .DATA_BYTE_WID(DATA_BYTE_WID),
        .TID_T   (TID_OUT_T),
        .TDEST_T (TDEST_T),
        .TUSER_T (TUSER_OUT_T)
    ) axis_out_vif [4];

    virtual axi4l_intf axil_vif;

    axi4l_verif_pkg::axi4l_reg_agent                        #() reg_agent;

    smartnic_reg_verif_pkg::smartnic_reg_blk_agent          #() smartnic_reg_blk_agent;
    smartnic_reg_verif_pkg::smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_0_reg_blk_agent;
    smartnic_reg_verif_pkg::smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_1_reg_blk_agent;
    reg_endian_check_reg_blk_agent                          #() reg_endian_check_reg_blk_agent;
    smartnic_app_reg_verif_pkg::smartnic_app_reg_blk_agent  #() smartnic_app_reg_blk_agent;

    //===================================
    // Methods
    //===================================
    // Constructor
    function new(input string name="smartnic_env", bit bigendian=1);
        super.new(name);
        for (int i=0; i < 4; i++) inbox[i] = new();
        for (int i=0; i < 4; i++) __drv_inbox[i]    = new();
        for (int i=0; i < 4; i++) __mon_outbox[i]   = new();
        for (int i=0; i < 4; i++) __model_inbox[i]  = new();
        for (int i=0; i < 4; i++) __model_outbox[i] = new();
        for (int i=0; i < 4; i++) driver[i]  = new(.name($sformatf("axi4s_driver[%0d]",i)),  .BIGENDIAN(bigendian));
        for (int i=0; i < 4; i++) monitor[i] = new(.name($sformatf("axi4s_monitor[%0d]",i)), .BIGENDIAN(bigendian));

        model[0] = new(.name("model[0]"), .dest_if(0)); // PHY0
        model[1] = new(.name("model[1]"), .dest_if(1)); // PHY1
        model[2] = new(.name("model[2]"), .dest_if(2)); // PF0
        model[3] = new(.name("model[3]"), .dest_if(3)); // PF1

        for (int i=0; i < 4; i++) scoreboard[i] = new(.name($sformatf("scoreboard[%0d]",i)));

    endfunction

    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        for (int i=0; i < 4; i++) driver[i]  = null;
        for (int i=0; i < 4; i++) monitor[i] = null;
        for (int i=0; i < 4; i++) model[i]   = null;

        for (int i=0; i < 4; i++) inbox[i] = null;
        for (int i=0; i < 4; i++) __drv_inbox[i]    = null;
        for (int i=0; i < 4; i++) __mon_outbox[i]   = null;
        for (int i=0; i < 4; i++) __model_inbox[i]  = null;
        for (int i=0; i < 4; i++) __model_outbox[i] = null;

        for (int i=0; i < 4; i++) scoreboard[i] = null;

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
        for (int i=0; i < 4; i++) driver[i].inbox   = __drv_inbox[i];
        for (int i=0; i < 4; i++) model[i].inbox    = __model_inbox[i];
        for (int i=0; i < 4; i++) model[i].outbox   = __model_outbox[i];
        for (int i=0; i < 4; i++) monitor[i].outbox = __mon_outbox[i];

        for (int i=0; i < 4; i++) scoreboard[i].got_inbox = __mon_outbox[i];

        for (int i=0; i < 4; i++) scoreboard[i].exp_inbox = __model_outbox[i];

        for (int i=0; i < 4; i++) this.driver[i].axis_vif  = axis_in_vif[i];
        for (int i=0; i < 4; i++) this.monitor[i].axis_vif = axis_out_vif[i];
        for (int i=0; i < 4; i++) register_subcomponent(driver[i]);
        for (int i=0; i < 4; i++) register_subcomponent(monitor[i]);
        for (int i=0; i < 4; i++) register_subcomponent(model[i]);
        for (int i=0; i < 4; i++) register_subcomponent(scoreboard[i]);

        reg_agent = new("axi4l_reg_agent");
        reg_agent.axil_vif = axil_vif;
        register_subcomponent(reg_agent);

        smartnic_reg_blk_agent            = new("smartnic_reg_blk_agent");
        smartnic_hash2qid_0_reg_blk_agent = new("smartnic_hash2qid_0_reg_blk_agent", 'h12000);
        smartnic_hash2qid_1_reg_blk_agent = new("smartnic_hash2qid_1_reg_blk_agent", 'h13000);
        reg_endian_check_reg_blk_agent    = new("reg_endian_check_reg_blk_agent",    'h00400);
        smartnic_app_reg_blk_agent        = new("smartnic_app_reg_blk_agent",        'he4000);

        smartnic_reg_blk_agent.reg_agent            = reg_agent;
        smartnic_hash2qid_0_reg_blk_agent.reg_agent = reg_agent;
        smartnic_hash2qid_1_reg_blk_agent.reg_agent = reg_agent;
        reg_endian_check_reg_blk_agent.reg_agent    = reg_agent;
        smartnic_app_reg_blk_agent.reg_agent        = reg_agent;

        trace_msg("_build() Done.");
    endfunction

    // Start environment execution (run loop)
    // [[ implements std_verif_pkg::component._run() ]]
    protected task _run();
        trace_msg("_run()");
        super._run();
        trace_msg("Running...");

        fork
            begin
                for (int i = 0; i < 4; i++) begin
                    fork
                        automatic int j = i;
                        begin
                            forever begin
                                TRANSACTION_IN_T transaction;
                                int dest_if;
                                inbox[j].get(transaction);
                                __drv_inbox[j].put(transaction);
                                case (transaction.get_tdest().encoded.typ)
                                    PHY:    dest_if = (transaction.get_tdest().encoded.num == P0) ? 0 : 1;
                                    default dest_if = (transaction.get_tdest().encoded.num == P0) ? 2 : 3;
                                endcase
                                __model_inbox[dest_if].put(transaction);
                            end
                        end
                    join_none
                end
                wait fork;
            end
        join
        trace_msg("_run() Done.");
    endtask


    task automatic pcap_to_driver (
        input string      filename,
        input TID_IN_T    tid=0,
        input TDEST_T     tdest=0,
        input TUSER_IN_T  tuser=0,
        input DRIVER_T    driver  );

        // signals
        pcap_pkg::pcap_t pcap;
        int num_pkts;

        // read pcap file
        pcap = pcap_pkg::read_pcap(filename);
        num_pkts = pcap.records.size();

        // put packets one at a time
        for (int i = 0; i < num_pkts; i++) begin
            axi4s_transaction#(TID_IN_T, TDEST_T, TUSER_IN_T) transaction =
                axi4s_transaction#(TID_IN_T, TDEST_T, TUSER_IN_T)::create_from_bytes(
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
        input TID_OUT_T    tid=0,
        input TDEST_T      tdest=0,
        input TUSER_OUT_T  tuser=0,
        //input SCOREBOARD_T scoreboard );
        input port_t       out_port );

        // signals
        pcap_pkg::pcap_t pcap;
        int num_pkts;

        // read pcap file
        pcap = pcap_pkg::read_pcap(filename);
        num_pkts = pcap.records.size();

        // put packets one at a time
        for (int i = 0; i < num_pkts; i++) begin
            axi4s_transaction#(TID_OUT_T, TDEST_T, TUSER_OUT_T) transaction =
                axi4s_transaction#(TID_OUT_T, TDEST_T, TUSER_OUT_T)::create_from_bytes(
                    $sformatf("Packet %0d", i),
                    pcap.records[i].pkt_data,
                    tid,
                    tdest,
                    tuser
                );
            //scoreboard.exp_inbox.put(transaction);
            __model_outbox[out_port].put(transaction);
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

endclass : smartnic_env

