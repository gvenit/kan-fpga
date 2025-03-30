`include "utils.vh"

module MultiWidthDualPortBram #(

        /*-----------------------------------------
            PORT B interface

            - read only
            - used internally in the architecture
            - specifies the depth
        -----------------------------------------*/

        parameter PORT_B_WIDTH = 8,
        parameter PORT_B_DEPTH = 256,
        parameter PORT_B_ADDR = `LOG2(PORT_B_DEPTH),

        /*-----------------------------------------
            PORT B interface

            - read and write
            - controlled by the PS
            - assumed larger width than port A
            - depth specified by internal depth
        -----------------------------------------*/


        parameter PORT_A_WIDTH = 32,
        parameter IN_WORD_DATA = PORT_A_WIDTH / PORT_B_WIDTH,
        parameter PORT_A_DEPTH = PORT_B_DEPTH / IN_WORD_DATA,
        parameter PORT_A_ADDR = `LOG2(PORT_A_DEPTH),
        parameter PORT_A_WE = PORT_A_WIDTH / 8

    ) (
        input wire clk,

        input wire                      ena,
        input wire [PORT_A_WE-1:0]      wea,
        input wire [PORT_A_ADDR-1:0]    addra,
        input wire [PORT_A_WIDTH-1:0]   dina,
        output wire [PORT_A_WIDTH-1:0]  douta,

        input wire                      enb,
        input wire [PORT_B_ADDR-1:0]    addrb,
        output wire [PORT_B_WIDTH-1:0]  doutb,
        output wire                     validb
    );

    /********************************
     Local parameters
    ********************************/

    localparam ADDRB_EXTRA_BITS = `LOG2(IN_WORD_DATA);

    /********************************
     Internal Signals
    ********************************/

    wire [PORT_A_ADDR-1:0] addrb_itrl;
    reg [ADDRB_EXTRA_BITS-1:0] addrb_lsb;

    wire [PORT_A_WIDTH-1:0] doutb_itrl;

    /********************************
     Always blocks
    ********************************/

    assign addrb_itrl = addrb[PORT_B_ADDR-1:ADDRB_EXTRA_BITS];

    always @ (posedge clk) begin
        if (enb) begin
            addrb_lsb <= addrb[ADDRB_EXTRA_BITS-1:0];
        end
    end

    /********************************
     Direct assignments
    ********************************/

    assign doutb = doutb_itrl[PORT_B_WIDTH*addrb_lsb +: PORT_B_WIDTH];

    /********************************
     Module instantiations
    ********************************/

    Bram #(
        .WIDTH(PORT_A_WIDTH),
        .DEPTH(PORT_A_DEPTH)
    ) bram_inst (
        .clk(clk),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .enb(enb),
        .addrb(addrb_itrl),
        .doutb(doutb_itrl),
        .validb(validb)
    );

endmodule