// Environment class for 'smartnic' component verification.
class smartnic_env extends std_verif_pkg::basic_env;
    //===================================
    // Parameters
    //===================================
    localparam int  DATA_BYTE_WID = 64;
    localparam type TID_IN_T      = adpt_tx_tid_t;
    localparam type TDEST_IN_T    = port_t;
    localparam type TUSER_IN_T    = bit; // error
    localparam type TID_OUT_T     = port_t;
    localparam type TDEST_OUT_T   = port_t;
    localparam type TUSER_OUT_T   = tuser_smartnic_meta_t;

    localparam type TRANSACTION_IN_T  = axi4s_transaction#(TID_IN_T, TDEST_IN_T, TUSER_IN_T);
    localparam type TRANSACTION_OUT_T = axi4s_transaction#(TDEST_OUT_T, TDEST_OUT_T, TUSER_OUT_T);
    localparam type DRIVER_T          = axi4s_driver  #(DATA_BYTE_WID, TID_IN_T,  TDEST_IN_T,  TUSER_IN_T);
    localparam type MONITOR_T         = axi4s_monitor #(DATA_BYTE_WID, TID_OUT_T, TDEST_OUT_T, TUSER_OUT_T);
    localparam type MODEL_T           = smartnic_model;
    localparam type SCOREBOARD_T      = event_scoreboard#(TRANSACTION_OUT_T);

    local static const string __CLASS_NAME = "tb_pkg::smartnic_env";

    // -- AXI-L
    localparam int AXIL_APP_OFFSET = 'h100000;
    localparam int AXIL_VITISNET_OFFSET = 'h80000;

    //===================================
    // Properties
    //===================================
    DRIVER_T     driver     [4];
    MONITOR_T    monitor    [4];
    MODEL_T      model      [5];
    SCOREBOARD_T scoreboard [5]; // 0:PHY0, 1:PHY1, 2:PF0, 3:PF1, 4:PKT_CAPTURE

    axi4s_playback_driver#(DATA_BYTE_WID, port_t,    TDEST_IN_T,  TUSER_IN_T)  pkt_playback_driver;
    axi4s_capture_monitor#(DATA_BYTE_WID, TID_OUT_T, TDEST_OUT_T, TUSER_OUT_T) pkt_capture_monitor;

    mailbox #(TRANSACTION_IN_T)  inbox [4];
    mailbox #(TRANSACTION_IN_T)  pkt_playback_inbox;

    local mailbox #(TRANSACTION_IN_T)  __drv_inbox    [4];
    local mailbox #(TRANSACTION_OUT_T) __mon_outbox   [5];
    local mailbox #(TRANSACTION_IN_T)  __model_inbox  [5];
    local mailbox #(TRANSACTION_OUT_T) __model_outbox [5];

    virtual axi4s_intf #(
        .DATA_BYTE_WID(DATA_BYTE_WID),
        .TID_WID   ($bits(TID_IN_T)),
        .TDEST_WID ($bits(TDEST_IN_T)),
        .TUSER_WID ($bits(TUSER_IN_T))
    ) axis_in_vif [4];

    virtual axi4s_intf #(
        .DATA_BYTE_WID(DATA_BYTE_WID),
        .TID_WID   ($bits(TID_OUT_T)),
        .TDEST_WID ($bits(TDEST_OUT_T)),
        .TUSER_WID ($bits(TUSER_OUT_T))
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
    function new(input string name="smartnic_env");
        super.new(name);
        for (int i=0; i < 4; i++) begin
            inbox[i]      = new();
            driver[i]     = new(.name($sformatf("axi4s_driver[%0d]",i)));
            monitor[i]    = new(.name($sformatf("axi4s_monitor[%0d]",i)));

            __drv_inbox[i] = new();
        end

        for (int i=0; i < 5; i++) begin
            model[i]      = new(.name($sformatf("model[%0d]",i)), .dest_port(i));
            scoreboard[i] = new(.name($sformatf("scoreboard[%0d]",i)));

            __model_inbox[i]  = new();
            __model_outbox[i] = new();
            __mon_outbox[i]   = new();
        end

        reg_agent = new("axi4l_reg_agent");

        pkt_playback_inbox  = new();
        pkt_playback_driver = new("axi4s_playback_driver", 16384, reg_agent, 'h5000);
        pkt_capture_monitor = new("axi4s_capture_monitor", 16384, reg_agent, 'h6000);

    endfunction

    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        for (int i=0; i < 4; i++) begin
            inbox[i]      = null;
            driver[i]     = null;
            monitor[i]    = null;

            __drv_inbox[i] = null;
        end

        for (int i=0; i < 5; i++) begin
            model[i]      = null;
            scoreboard[i] = null;

            __model_inbox[i]  = null;
            __model_outbox[i] = null;
            __mon_outbox[i]   = null;
        end

        pkt_playback_inbox  = null;
        pkt_playback_driver = null;
        pkt_capture_monitor = null;

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
            monitor[i].outbox = __mon_outbox[i];

            this.driver[i].axis_vif  = axis_in_vif[i];
            this.monitor[i].axis_vif = axis_out_vif[i];

            register_subcomponent(driver[i]);
            register_subcomponent(monitor[i]);
        end

        for (int i=0; i < 5; i++) begin
            model[i].inbox    = __model_inbox[i];
            model[i].outbox   = __model_outbox[i];

            scoreboard[i].got_inbox = __mon_outbox[i];
            scoreboard[i].exp_inbox = __model_outbox[i];

            register_subcomponent(model[i]);
            register_subcomponent(scoreboard[i]);
        end

        pkt_playback_driver.inbox = new();
        register_subcomponent(pkt_playback_driver);

        pkt_capture_monitor.outbox = __mon_outbox[4];
        register_subcomponent(pkt_capture_monitor);

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
            for (int i = 0; i < 4; i++) begin
                fork
                    automatic int j = i;
                    begin
                        forever begin
                            TRANSACTION_IN_T transaction;
                            port_t tdest_in;
                            int dest_port;
                            inbox[j].get(transaction);
                            driver[j].inbox.put(transaction);
                            tdest_in = transaction.get_tdest();
                            case (tdest_in.encoded.typ)
                                PHY:     dest_port = (tdest_in.encoded.num == P0) ? 0 : 1;
                                PF:      dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                                VF0:     dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                                VF1:     dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                                VF2:     dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                                default: dest_port = 4; // 'pkt_capture' block
                            endcase
                            model[dest_port].inbox.put(transaction);
                        end
                    end
                join_none
            end
            forever begin
                TRANSACTION_IN_T transaction_in;
                axi4s_transaction#(port_t, TDEST_IN_T, TUSER_IN_T) transaction;
                port_t tdest_in;
                int  dest_port;
                adpt_tx_tid_t tid_in;
                port_t tid;

                pkt_playback_inbox.get(transaction_in);
                tid_in = transaction_in.get_tid();
                tdest_in = transaction_in.get_tdest();
                tid = tid_in[$bits(port_t)-1:0];
                transaction = axi4s_transaction#(port_t, TDEST_IN_T, TUSER_IN_T)::create_from_bytes(
                    transaction_in.get_name(),
                    transaction_in.to_bytes(),
                    tid,
                    transaction_in.get_tdest(),
                    transaction_in.get_tuser()
                );
                pkt_playback_driver.inbox.put(transaction);

                case (tdest_in.encoded.typ)
                    PHY:     dest_port = (tdest_in.encoded.num == P0) ? 0 : 1;
                    PF:      dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                    VF0:     dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                    VF1:     dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                    VF2:     dest_port = (tdest_in.encoded.num == P0) ? 2 : 3;
                    default: dest_port = 4; // 'pkt_capture' block
                endcase
                model[dest_port].inbox.put(transaction_in);
            end
        join_any
        wait fork;
        trace_msg("_run() Done.");
    endtask


    task automatic pkt_to_playback (int id=0, len=$urandom_range(64, 512), port_t tid='0, tdest='0, bit tuser='0);
        TRANSACTION_IN_T transaction;

        transaction = new($sformatf("pkt_%0d", id), len);
        transaction.randomize();
        transaction.set_tid(tid);
        transaction.set_tdest(tdest);
        transaction.set_tuser(tuser);

        pkt_playback_inbox.put(transaction);
    endtask


    task automatic pcap_to_driver (
        input string      filename,
        input TID_IN_T    tid=0,
        input TDEST_IN_T  tdest=0,
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
            TRANSACTION_IN_T transaction =
                TRANSACTION_IN_T::create_from_bytes(
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
        input TDEST_OUT_T  tdest=0,
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
            TRANSACTION_OUT_T transaction =
                TRANSACTION_OUT_T::create_from_bytes(
                    $sformatf("Packet %0d", i),
                    pcap.records[i].pkt_data,
                    tid,
                    tdest,
                    tuser
                );
            scoreboard.exp_inbox.put(transaction);
        end
    endtask

    task automatic send_packet(input string name, input port_t inport, input byte data[], input adpt_tx_tid_t tid=0, input port_t dest=0, input bit err=0);
        TRANSACTION_IN_T transaction_in =
            TRANSACTION_IN_T::create_from_bytes(
                name,
                data,
                tid,
                dest,
                err
            );
        case (inport.encoded.typ)
            PHY: if (inport.encoded.num == P0) this.inbox[0].put(transaction_in);
                 else                          this.inbox[1].put(transaction_in);
            PF:  if (inport.encoded.num == P0) this.inbox[2].put(transaction_in);
                 else                          this.inbox[3].put(transaction_in);
        endcase
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
