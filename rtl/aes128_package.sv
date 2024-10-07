`ifndef AES128_PACKAGE_SV
`define AES128_PACKAGE_SV

package aes128_package;
    typedef enum bit[0:0] {HPC1 = 1'b0, HPC3 = 1'b1} stage_type_t;
    typedef enum bit[0:0] {NEW_DESIGN = 1'b0, CANRIGHT_DESIGN = 1'b1} inverter_type_t;
       
    /* verilator lint_off UNUSEDPARAM */
    localparam stage_type_t DEFAULT_STAGE_TYPE = HPC1;
    localparam inverter_type_t DEFAULT_INVERTER_TYPE = NEW_DESIGN;
    /* verilator lint_on UNUSEDPARAM */
    function automatic int num_quad;
        input int i;
        return i * (i - 1) / 2;
    endfunction

    function automatic int num_zero_random;
        input int i;
        case(i)
            2: return 1;
            3: return 2;
            4: return 4;
            5: return 5;
        endcase
        $fatal("Unsupported number of shares");
    endfunction
    
    function automatic int stage_1_randoms;
        input int i;
        int q = num_quad(i);
        return 2 * (q * 4); // front_r and front_p
    endfunction

    function automatic int stage_3_randoms;
        input int i;
        int q = num_quad(i);
        return 1 * (q * 2) + // back_r
               4 * (q * 2) ; // back_ps
    endfunction

    function automatic int stage_3_lat4_randoms;
        input int i;
        int q = num_quad(i);
        int r = num_zero_random(i);
        return 1 * (r * 2) + // back_r
               4 * (q * 2) ; // back_ps
    endfunction

    function automatic int stage_2_lat4_randoms;
        input int i;
        int q = num_quad(i);
        int r = num_zero_random(i);
        int basis = 2 * (q * 2) + // theta_random
                    1 * (q * 4) + // right_p
                    1 * (q * 4) ; // left_p
        int refreshes = (r * 4);  // joint_r_raw
        return basis + refreshes;
    endfunction

    function automatic int stage_2_hpc1_randoms;
        input int i;
        int q = num_quad(i);
        int r = num_zero_random(i);
        int basis = 2 * (q * 2) + // theta_random
                    1 * (q * 4) + // right_p
                    1 * (q * 4) ; // left_p
        int num_refreshes = (i == 2) ? 1 : 2;
        int refreshes = num_refreshes * (r * 4); // right_r_raw and left_r_raw
        return basis + refreshes;
    endfunction

    function automatic int stage_2_hpc3_randoms;
        input int i;
        int q = num_quad(i);
        return 1 * (q * 4) + // joint_r
               1 * (q * 4) + // left_p
               1 * (q * 4) + // right_p
               1 * (q * 2) ; // theta_p
    endfunction

    function automatic int stage_2_randoms;
        input int i;
        input stage_type_t t;
        return (t == HPC1) ? stage_2_hpc1_randoms(i)
                           : stage_2_hpc3_randoms(i);
    endfunction


    function automatic int num_3stage_inv_random;
        input int i;
        input stage_type_t t;
        return stage_1_randoms(i) + 
               stage_2_randoms(i, t) +
               stage_3_randoms(i);               
    endfunction

    function automatic int num_4stage_inv_random;
        input int i;
        return stage_1_randoms(i) + 
               stage_2_lat4_randoms(i) +
               stage_3_lat4_randoms(i);               
    endfunction

    function automatic int stage_4_canright_hpc1_randoms;
        input int i;
        int q = num_quad(i);
        int r = num_zero_random(i);
        int c = (i == 2) ? 1 : 2;
        return c * (r * 4) + // left_r, right_r
               2 * (q * 4) ; // left_p, right_p
    endfunction

    function automatic int stage_4_canright_hpc3_randoms;
        input int i;
        int q = num_quad(i);
        return 1 * (q * 4) + // in_joint_r
               2 * (q * 4) ; // left_p, right_p
    endfunction

    function automatic int stage_4_canright_randoms;
        input int i;
        input stage_type_t t;
        return (t == HPC1) ? stage_4_canright_hpc1_randoms(i)
                           : stage_4_canright_hpc3_randoms(i);
    endfunction

    function automatic int masked_bv4_inv_randoms;
        input int i;
        int q = num_quad(i);
        int r = num_zero_random(i);
        int c = (i == 2) ? 1 : 4;
        return 2 * (q * 1) + // front_r
               2 * (q * 1) + // front_p
               c * (r * 1) + // back_r
               4 * (q * 1) ; // back_p
    endfunction

    function automatic int num_canright_inv_random;
        input int i;
        input stage_type_t t;
        return stage_1_randoms(i) + 
               masked_bv4_inv_randoms(i) +
               stage_4_canright_randoms(i, t);               
    endfunction

    function automatic int num_bv8_inv_random;
        input int i;
        input int l;
        input stage_type_t s;
        input inverter_type_t v;
        
        return (v == NEW_DESIGN) ?
            (
                (l == 3) ? 
                    (
                        num_3stage_inv_random(i, s)
                    ) :
                    (
                        num_4stage_inv_random(i)
                    )
            ) :
            (
                num_canright_inv_random(i, s)
            )
        ;               
    endfunction

    function automatic int sindex;
        input int i;
        input int n;
        begin
            if (i < 0 || i >= n) $fatal("i must be smaller than n");
            return (i + 1) % n;
        end
    endfunction

    function automatic int qindex;
        input int i;
        input int j;
        input int n;
        begin
            if (i < 0 || i >= n) $fatal("i must be smaller than n");
            if (j < 0 || j >= n) $fatal("j must be smaller than n");
            if (i == j) $fatal("i and j must be different");
            return (j < i) ? (j * (2 * n - (j+1)) / 2 + i - j - 1)
                           : (i * (2 * n - (i+1)) / 2 + j - i - 1);
        end
    endfunction

    typedef bit      bv1_t;
    typedef bit[1:0] bv2_t;
    typedef bit[3:0] bv4_t;
    typedef bit[7:0] bv8_t;

    typedef enum bit[0:0] {DFF, DFF_R} dff_type_t;     
endpackage : aes128_package
`endif // AES128_PACKAGE_SV
