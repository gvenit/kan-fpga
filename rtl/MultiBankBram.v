// `include "utils.vh"

module MultiBankBram #(
        parameter BANKS = 4,
        parameter WIDTH = 16,
        parameter DEPTH = 256,
        parameter ADDR = $clog2(DEPTH),
        parameter WE = WIDTH / 8
    ) (
        input clk,

        input [BANKS-1:0] ena,    
        input [(BANKS*WE)-1:0] wea,    
        input [(BANKS*ADDR)-1:0] addra,  
        input [(BANKS*WIDTH)-1:0] dina,  
        output [(BANKS*WIDTH)-1:0] douta,

        input [BANKS-1:0] enb,    
        input [(BANKS*ADDR)-1:0] addrb,  
        output [(BANKS*WIDTH)-1:0] doutb,  
        output [BANKS-1:0] validb
    );

    genvar i;

    generate
        for (i = 0; i < BANKS; i = i + 1) begin
            Bram #(
                .WIDTH(WIDTH),
                .DEPTH(DEPTH),
                .ADDR(ADDR)
            ) bram_inst (
                .clk(clk),
                .ena(ena[i]),
                .wea(wea[(i+1)*WE-1 : i*WE]),
                .addra(addra[(i+1)*ADDR-1 : i*ADDR]),
                .dina(dina[(i+1)*WIDTH-1 : i*WIDTH]),
                .douta(douta[(i+1)*WIDTH-1 : i*WIDTH]),
                .enb(enb[i]),
                .addrb(addrb[(i+1)*ADDR-1 : i*ADDR]),
                .doutb(doutb[(i+1)*WIDTH-1 : i*WIDTH]),
                .validb(validb[i])
            );
        end
    endgenerate

endmodule