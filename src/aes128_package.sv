package aes128_package;
    parameter NUM_SHARES = 3;
    localparam NUM_QUARDATIC = NUM_SHARES * (NUM_SHARES - 1) / 2;
    
    function automatic int qindex;
        input int i;
        input int j;
        begin
            if (j < i) return (j * (NUM_SHARES - (j+1)/2) + i - j - 1);
            if (i < j) return (i * (NUM_SHARES - (i+1)/2) + j - i - 1);
            $error("Looking up non-existent index");
        end
    endfunction 
    
    typedef bit       bv1_t;
    typedef bit [1:0] bv2_t;
    typedef bit [3:0] bv4_t;
    typedef bit [7:0] bv8_t;

    typedef bv1_t[NUM_SHARES-1:0] sh_bv1_t;
    typedef bv2_t[NUM_SHARES-1:0] sh_bv2_t;
    typedef bv4_t[NUM_SHARES-1:0] sh_bv4_t;
    typedef bv8_t[NUM_SHARES-1:0] sh_bv8_t;


    typedef sh_bv1_t rand_l_bv1_t;
    typedef sh_bv2_t rand_l_bv2_t;
    typedef sh_bv4_t rand_l_bv4_t;
    typedef sh_bv8_t rand_l_bv8_t;
    
    typedef bv1_t[NUM_QUARDATIC-1:0] rand_q_bv1_t;
    typedef bv2_t[NUM_QUARDATIC-1:0] rand_q_bv2_t;
    typedef bv4_t[NUM_QUARDATIC-1:0] rand_q_bv4_t;
    typedef bv8_t[NUM_QUARDATIC-1:0] rand_q_bv8_t;
    
endpackage