package smartnic_250mhz_pkg;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef struct packed {
        logic [15:0] size;
        logic [15:0] src;
        logic [15:0] dst;
    } tuser_h2c_t;
 
    typedef struct packed {
        logic [15:0] size;
        logic [15:0] src;
        logic [15:0] dst;
        logic        rss_hash_valid;
        logic [11:0] rss_hash;
    } tuser_c2h_t;


    // --------------------------------------------------------------
    // Derived parameters
    // --------------------------------------------------------------
    localparam int TUSER_H2C_WID = $bits(tuser_h2c_t);
    localparam int TUSER_C2H_WID = $bits(tuser_c2h_t);

endpackage : smartnic_250mhz_pkg
