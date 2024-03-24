package aes128_package;
    function automatic int num_quad;
        input int i;
        return i * (i - 1) / 2;
    endfunction
    
    function automatic int qindex;
        input int i;
        input int j;
        input int n;
        begin
            if (j < i) return (j * (n - (j+1)/2) + i - j - 1);
            if (i < j) return (i * (n - (i+1)/2) + j - i - 1);
            $error("Looking up non-existent index");
        end
    endfunction

    typedef bit      bv1_t;
    typedef bit[1:0] bv2_t;
    typedef bit[3:0] bv4_t;
    typedef bit[7:0] bv8_t;

endpackage