package smartnic_250mhz_pkg;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef struct packed {
        bit [15:0] size;
        bit [15:0] src;
        bit [15:0] dst;
    } tuser_h2c_t;
 
    typedef struct packed {
        bit [15:0] size;
        bit [15:0] src;
        bit [15:0] dst;
        bit        rss_hash_valid;
        bit [11:0] rss_hash;
    } tuser_c2h_t;

endpackage : smartnic_250mhz_pkg
