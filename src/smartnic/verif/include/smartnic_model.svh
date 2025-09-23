// Reference model for smartnic module.  Models egress axi4s signaling, including qid selection.
class smartnic_model
    extends std_verif_pkg::model#(axi4s_transaction#(adpt_tx_tid_t, port_t, bit),
                                  axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t));
    port_t dest_port;

    function new(string name="smartnic_model", port_t dest_port=0);
        super.new(name);
        this.dest_port = dest_port;
    endfunction

    protected task _process(input axi4s_transaction#(adpt_tx_tid_t, port_t, bit) transaction);
        axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t) transaction_out;
        port_t  tdest_in;
        port_t  tid_out;
        port_t  tdest_out;
        tuser_smartnic_meta_t  tuser_out;

        tdest_in = transaction.get_tdest();

        tid_out   = '0; // egr tid is disconnected (not used).
        tdest_out = '0; // egr tdest is disconnected (not used).

        if (dest_port.encoded.typ == PHY) begin
            tuser_out = '0; // m_axis_adpt_rx_322mhz_tuser_err=0 for egr CMAC ifs.

        end else if (dest_port.encoded.typ == PF) begin
            tuser_out.rss_enable = 1'b1;
            // set entropy=qid based on egr queue (hash2qid) config.
            case (tdest_in.encoded.typ)
                PF:  if (tdest_in.encoded.num == P0) tuser_out.rss_entropy = 12'd2048;
                     else                                           tuser_out.rss_entropy = 12'd0;
                VF0: if (tdest_in.encoded.num == P0) tuser_out.rss_entropy = 12'd2560;
                     else                                           tuser_out.rss_entropy = 12'd512;
                VF1: if (tdest_in.encoded.num == P0) tuser_out.rss_entropy = 12'd3072;
                     else                                           tuser_out.rss_entropy = 12'd1024;
                VF2: if (tdest_in.encoded.num == P0) tuser_out.rss_entropy = 12'd3584;
                     else                                           tuser_out.rss_entropy = 12'd1536;
                default  tuser_out.rss_entropy = 12'd0;
            endcase

        end else begin  // packets are directed to 'smartnic_pkt_capture' block by default.
            // 'smartnic_mux' sets tdest to PHY, and 'smartnic_pkt_capture' tests run 'smartnic_app' in passthru mode.
	    tdest_out.encoded.num = tdest_in.encoded.num;
            tdest_out.encoded.typ = PHY;

            tid_out.encoded.num = tdest_out.encoded.num;
            tid_out.encoded.typ = PHY;  // 'smartnic_pkt_capture' tests use PHY ports for input.

            tuser_out = '0;
            tuser_out.rss_enable = 1'b1;
            tuser_out.rss_entropy = (tdest_out.encoded.num == P0) ? 12'd2048 : 12'd0;  // hash2qid config.

        end

        transaction_out = new($sformatf("trans_%0d_out", num_output_transactions()), transaction.size(),
                               tid_out, tdest_out, tuser_out);
        transaction_out.from_bytes(transaction.payload());
        _enqueue(transaction_out);
    endtask

endclass
