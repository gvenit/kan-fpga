`timescale 1ns / 1ps

module BramIntrfTranslator #(
        parameter IN_WIDTH = 32,    // width of input data
        parameter OUT_WIDTH = 16,   // width of output data

        parameter BANKS = 4,                            // number of BRAM banks
        parameter IN_WORD_DATA = IN_WIDTH / OUT_WIDTH,  // number of data packed in an input word

        parameter IN_DEPTH = 1024,  // number of total input data
        parameter IN_ADDR = 12,     // number of input address bits
        parameter IN_WE = 4,        // number of input write-enable bits
        
        parameter OUT_DEPTH = IN_DEPTH / BANKS, // the depth of each BRAM bank
        parameter OUT_ADDR = $clog2(OUT_DEPTH), // number of output address bits
        parameter OUT_WE = OUT_WIDTH / 8        // number of output write-enable bits
    );

    /********************************
     Internal signals / Local params
    ********************************/

    localparam INJ_BITS = $clog2(IN_WORD_DATA);
    localparam ITRL_ADDR = IN_ADDR + INJ_BITS;

    // uut direct connection signals

    logic                en_i = 1'b0;
    logic [IN_WE-1:0]    we_i;
    logic [IN_ADDR-1:0]  addr_i = 0;
    logic [IN_WIDTH-1:0] wrdata_i;
    logic [IN_WIDTH-1:0] rddata_i;

    logic [BANKS-1:0]             en_o;
    logic [(BANKS*OUT_WE)-1:0]    we_o;
    logic [(BANKS*OUT_ADDR)-1:0]  addr_o;
    logic [(BANKS*OUT_WIDTH)-1:0] wrdata_o;
    logic [(BANKS*OUT_WIDTH)-1:0] rddata_o;

    // testbench evalutation signals

    logic [IN_WORD_DATA-1:0][OUT_WE-1:0]    we_input = 0;
    logic [IN_WORD_DATA-1:0][OUT_WIDTH-1:0] wrdata_input = 0;
    logic [IN_WORD_DATA-1:0][OUT_WIDTH-1:0] rddata_input;

    logic [BANKS-1:0]                   en_output;
    logic [BANKS-1:0][OUT_WE-1:0]       we_output;
    logic [BANKS-1:0][OUT_ADDR-1:0]     addr_output;
    logic [BANKS-1:0][OUT_WIDTH-1:0]    wrdata_output;
    logic [BANKS-1:0][OUT_WIDTH-1:0]    rddata_output;

    logic [IN_WORD_DATA-1:0][ITRL_ADDR-1:0] addr_itrl;
    logic [OUT_WE-1:0]       we_itrl [IN_WORD_DATA-1:0];
    logic [OUT_WIDTH-1:0]    wrdata_itrl [IN_WORD_DATA-1:0];
    logic [OUT_WIDTH-1:0]    rddata_itrl [IN_WORD_DATA-1:0];

    logic [BANKS-1:0] en_itrl [IN_WORD_DATA-1:0];
    logic [BANKS-1:0] en_reduct;

    /********************************
     Clocking
    ********************************/

    `define PERIOD 10

    logic clk = 1'b1;

    always
        #(`PERIOD/2) clk = ~clk;

    /********************************
     Unit Under Test
    ********************************/

    BramIntrfTranslator #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .BANKS(BANKS),
        .IN_WORD_DATA(IN_WORD_DATA),
        .IN_DEPTH(IN_DEPTH),
        .IN_ADDR(IN_ADDR),
        .IN_WE(IN_WE)
    ) bram_interface_translator_uut (
        .en_i       (en_i),
        .we_i       (we_i),
        .addr_i     (addr_i),
        .wrdata_i   (wrdata_i),
        .rddata_i   (rddata_i),
        .en_o       (en_o),
        .we_o       (we_o),
        .addr_o     (addr_o),
        .wrdata_o   (wrdata_o),
        .rddata_o   (rddata_o)
    );

    /********************************
     Testbench initalizations
    ********************************/

    genvar n;
    generate
        for (n = 0; n < IN_WORD_DATA; n = n + 1) begin
            assign we_i[n*OUT_WE +: OUT_WE] = we_input[n];
            assign wrdata_i[n*OUT_WIDTH +: OUT_WIDTH] = wrdata_input[n];
            assign rddata_input[n] = rddata_i[n*OUT_WIDTH +: OUT_WIDTH];
        end
    endgenerate

    genvar k;
    generate
        for (k = 0; k < BANKS; k = k + 1) begin
            assign en_output[k] = en_o[k];
            assign we_output[k] = we_o[k*OUT_WE +: OUT_WE];
            assign addr_output[k] = addr_o[k*OUT_ADDR +: OUT_ADDR];
            assign wrdata_output[k] = wrdata_o[k*OUT_WIDTH +: OUT_WIDTH];
            assign rddata_o[k*OUT_WIDTH +: OUT_WIDTH] = rddata_output[k];
        end
    endgenerate

    genvar m;
    generate
        for (m = 0; m < BANKS; m = m + 1) begin
            assign addr_itrl[m] = bram_interface_translator_uut.addr_itrl[m];
            assign we_itrl[m] = bram_interface_translator_uut.we_itrl[m];
            assign wrdata_itrl[m] = bram_interface_translator_uut.wrdata_itrl[m];
            assign rddata_itrl[m] = bram_interface_translator_uut.rddata_itrl[m];
            
            assign en_itrl[m] = bram_interface_translator_uut.en_itrl[m];
        end
    endgenerate

    assign en_reduct = bram_interface_translator_uut.en_reduct;

    /********************************
     Initial Begin / Tests
    ********************************/

    initial begin
        $display ("TESTBENCH START");

        $display ("ADDRESS TESTING");

        en_i = 1'b1;

        /*-------------------------------
         The following test
         updates each data within a word
         at every clock cycle
        -------------------------------*/

        for (int i = 0; i < (BANKS * OUT_DEPTH); i = i + 1) begin
            addr_i = i;
            for (int j = 0; j < IN_WORD_DATA; j = j + 1) begin
                we_input = '0;
                we_input[j] = '1;
                wrdata_input[j] = 2*i + j;
                #(`PERIOD);
            end
        end
        #(`PERIOD * 10);

        /*-------------------------------
         The following test
         updates an entire input word
         at every clock cycle
        -------------------------------*/

        for (int i = 0; i < (BANKS * OUT_DEPTH); i = i + 1) begin
            addr_i = i;
            we_input = '1;
            for (int j = 0; j < IN_WORD_DATA; j = j + 1)
                wrdata_input[j] = 2*i + j;
            #(`PERIOD);
        end
        #(`PERIOD * 10);

        $display ("READ TESTING");

        en_i = 1'b1;

        /*-------------------------------
         The following test
         initializes rddata
         with two simple vectors
         and sees if the read behavior
         is correct
        -------------------------------*/

        for (int i = 0; i < BANKS; i = i + 1) begin
            rddata_output[i] = i;
        end
        #(`PERIOD * 4);
        for (int i = 0; i < BANKS; i = i + 1) begin
            addr_i = i;
            #(`PERIOD);
        end

        for (int i = 0; i < (BANKS * OUT_DEPTH); i = i + 1) begin
            rddata_output[i] = i + BANKS;
        end
        #(`PERIOD * 4);
        for (int i = 0; i < (BANKS * OUT_DEPTH); i = i + 1) begin
            addr_i = i;
            #(`PERIOD);
        end

        $finish;
    end

endmodule
