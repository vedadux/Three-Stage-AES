`ifndef AES128_PACKAGE_SV
`define AES128_PACKAGE_SV

package aes128_package;
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
    
    function automatic int num_inv_random;
        input int i;
        int q = num_quad(i);
        int r = num_zero_random(i);
        return 2 * (q * 4) +
               2 * (q * 2) + 
               2 * (q * 4) + 
               1 * (r * 4) + 
               5 * (q * 2);
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
