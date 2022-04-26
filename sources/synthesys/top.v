`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2022 10:45:15 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top (
        input sysclk_p,
        input sysclk_n,
        output [0:0] led
    );
    
    // Clock buffering
    IBUFGDS clk_inst (
        .O(clk),
        .I(sysclk_p),
        .IB(sysclk_n)
    );
    
    // Static
    reg [24:0] rCount = 0;
    wire wClk;
    assign led[0] = rCount[24];
 
    // Simple process
    always @ (posedge(clk)) begin
        rCount <= count + 1;
    end
    


endmodule
