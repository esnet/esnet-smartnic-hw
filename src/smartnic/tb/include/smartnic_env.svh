import smartnic_pkg::*;
import smartnic_verif_pkg::*;
import smartnic_app_reg_pkg::*;
import packet_verif_pkg::*;
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

    localparam type PKT_PLAYBACK_META_T   = struct packed {port_t tid; port_t tdest; bit tuser;};
    localparam type PKT_PLAYBACK_T        = packet#(PKT_PLAYBACK_META_T);
    localparam type PKT_PLAYBACK_DRIVER_T = packet_playback_driver#(PKT_PLAYBACK_META_T);

    local static const string __CLASS_NAME = "tb_pkg::smartnic_env";

    // -- AXI-L
    localparam int AXIL_APP_OFFSET = 'h100000;
    localparam int AXIL_VITISNET_OFFSET = 'h80000;

    //===================================
    // Properties
    //===================================
    local bit __BIGENDIAN;

    DRIVER_T     driver  [4];
    MONITOR_T    monitor [4];
    MODEL_T      model   [4];
    SCOREBOARD_T scoreboard [4];

    PKT_PLAYBACK_DRIVER_T pkt_playback_driver;

    mailbox #(TRANSACTION_IN_T)  inbox [4];
    mailbox #(PKT_PLAYBACK_T)    pkt_playback_inbox;

    local mailbox #(TRANSACTION_IN_T)  __drv_inbox    [4];
    local mailbox #(TRANSACTION_OUT_T) __mon_outbox   [4];
    local mailbox #(TRANSACTION_IN_T)  __model_inbox  [4];
    local mailbox #(TRANSACTION_OUT_T) __model_outbox [4];

    local mailbox #(PKT_PLAYBACK_T)    __pkt_playback_drv_inbox;

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
        this.__BIGENDIAN = bigendian;
        for (int i=0; i < 4; i++) begin
            inbox[i]      = new();
            driver[i]     = new(.name($sformatf("axi4s_driver[%0d]",i)), .BIGENDIAN(bigendian));
            monitor[i]    = new(.name($sformatf("axi4s_monitor[%0d]",i)), .BIGENDIAN(bigendian));
            model[i]      = new(.name($sformatf("model[%0d]",i)), .dest_if(i));
            scoreboard[i] = new(.name($sformatf("scoreboard[%0d]",i)));

            __drv_inbox[i]    = new();
            __mon_outbox[i]   = new();
            __model_inbox[i]  = new();
            __model_outbox[i] = new();
        end

        reg_agent = new("axi4l_reg_agent");

        pkt_playback_inbox  = new();
        pkt_playback_driver = new("packet_playback_driver", 16384, 512, reg_agent, 'h5000);

        __pkt_playback_drv_inbox = new();

    endfunction

    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        for (int i=0; i < 4; i++) begin
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

        pkt_playback_inbox  = null;
        pkt_playback_driver = null;

        __pkt_playback_drv_inbox = null;

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
        for (int i=0; i < 4; i++) begin
            driver[i].inbox   = __drv_inbox[i];
            model[i].inbox    = __model_inbox[i];
            model[i].outbox   = __model_outbox[i];
            monitor[i].outbox = __mon_outbox[i];

            scoreboard[i].got_inbox = __mon_outbox[i];
            scoreboard[i].exp_inbox = __model_outbox[i];

            this.driver[i].axis_vif  = axis_in_vif[i];
            this.monitor[i].axis_vif = axis_out_vif[i];

            register_subcomponent(driver[i]);
            register_subcomponent(monitor[i]);
            register_subcomponent(model[i]);
            register_subcomponent(scoreboard[i]);
        end

        pkt_playback_driver.inbox = __pkt_playback_drv_inbox;
        register_subcomponent(pkt_playback_driver);

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

                fork
                    begin
                        forever begin
                            PKT_PLAYBACK_T       packet;
                            PKT_PLAYBACK_META_T  meta;
                            TRANSACTION_IN_T     transaction;

                            int  dest_if;

                            pkt_playback_inbox.get(packet);
                            __pkt_playback_drv_inbox.put(packet);

                            meta = packet.get_meta();
                            case (meta.tdest.encoded.typ)
                                PHY:    dest_if = (meta.tdest.encoded.num == P0) ? 0 : 1;
                                default dest_if = (meta.tdest.encoded.num == P0) ? 2 : 3;
                            endcase

                            transaction = axi4s_transaction#(adpt_tx_tid_t, port_t, bit)::create_from_bytes(
                                .data (packet.to_bytes()),
                                .tid  (meta.tid),
                                .tdest(meta.tdest),
                                .tuser(meta.tuser)
                            );
                            __model_inbox[dest_if].put(transaction);
                        end
                    end
                join_none

                wait fork;
            end
        join
        trace_msg("_run() Done.");
    endtask


    task automatic pkt_to_playback (int id=0, len=$urandom_range(64, 1500), port_t tid='0, tdest='0, bit tuser='0);
        automatic packet_raw#(PKT_PLAYBACK_META_T) packet;

        automatic PKT_PLAYBACK_META_T meta;

        packet = new($sformatf("pkt_%0d", id), len);
        packet.randomize();

        meta.tid   = tid;
        meta.tdest = tdest;
        meta.tuser = tuser;
        packet.set_meta(meta);

        pkt_playback_inbox.put(packet);
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
        input SCOREBOARD_T scoreboard );

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
            scoreboard.exp_inbox.put(transaction);
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

