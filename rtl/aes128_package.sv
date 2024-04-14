`ifndef AES128_PACKAGE_SV
`define AES128_PACKAGE_SV

package aes128_package;
    typedef enum bit[0:0] {HPC1, HPC3} stage_type_t;     
    localparam stage_type_t DEFAULT_STAGE_TYPE = HPC3;
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
        $error("Unsupported number of shares");
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


    function automatic int num_inv_random;
        input int i;
        input stage_type_t t;
        return stage_1_randoms(i) + 
               stage_2_randoms(i, t) +
               stage_3_randoms(i);               
    endfunction

    function automatic int qindex;
        input int i;
        input int j;
        input int n;
        begin
            if (i < 0 || i >= n) $error("i must be smaller than n");
            if (j < 0 || j >= n) $error("j must be smaller than n");
            if (i == j) $error("i and j must be different");
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
