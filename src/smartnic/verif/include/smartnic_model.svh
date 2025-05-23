import smartnic_pkg::*;
import axi4s_verif_pkg::*;

// Reference model for smartnic module.  Models egress axi4s signaling, including qid selection.
class smartnic_model
    extends std_verif_pkg::model#(axi4s_transaction#(adpt_tx_tid_t, port_t, bit),
                                  axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t));
    port_t dest_if;

    function new(string name="smartnic_model", port_t dest_if=0);
        super.new(name);
        this.dest_if = dest_if;
    endfunction

    protected task _process(input axi4s_transaction#(adpt_tx_tid_t, port_t, bit) transaction);
        axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t) transaction_out;
        port_t  tid_out;
        port_t  tdest_out;
        tuser_smartnic_meta_t  tuser_out;

        tid_out   = 'x; // egr tid is disconnected.
        tdest_out = 'x; // egr tdest is disconnected.

        if (dest_if.encoded.typ == PHY) begin
            tuser_out = 1'b0; // m_axis_adpt_rx_322mhz_tuser_err=0 for egr CMAC ifs.
        end else begin
            tuser_out = 'x;
            tuser_out.rss_enable = 1'b1;
            // set entropy=qid based on egr queue (hash2qid) config.
            case (transaction.get_tdest().encoded.typ)
                PF:  if (transaction.get_tdest().encoded.num == P0) tuser_out.rss_entropy = 12'd2048;
                     else                                           tuser_out.rss_entropy = 12'd0;
                VF0: if (transaction.get_tdest().encoded.num == P0) tuser_out.rss_entropy = 12'd2560;
                     else                                           tuser_out.rss_entropy = 12'd512;
                VF1: if (transaction.get_tdest().encoded.num == P0) tuser_out.rss_entropy = 12'd3072;
                     else                                           tuser_out.rss_entropy = 12'd1024;
                VF2: if (transaction.get_tdest().encoded.num == P0) tuser_out.rss_entropy = 12'd3584;
                     else                                           tuser_out.rss_entropy = 12'd1536;
                default  tuser_out.rss_entropy = 12'd0;
            endcase
        end

        transaction_out = new ($sformatf("trans_%0d_out", num_output_transactions()), transaction.payload().size(),
                               tid_out, tdest_out, tuser_out);
        transaction_out.from_bytes(transaction.payload());
        _enqueue(transaction_out);
    endtask

endclass
