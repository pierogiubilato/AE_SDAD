/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##             Sigma Delta Analogue to Digital didactical example             ##
##                                                                            ##
\#############################################################################*/

// The top module is the topmost wrapper of the whole project, and contains
// all the I/O ports used by the FPGA.







module top () #
    (
        
        // Timing.
        input sysClk_p,                 // System clock, positive.
        input sysClk_n,                 // System clock, negative.
        
        // External switches and buttons inputs.
        input [3:0] switch,
        input [3:0] button,
        
        // Standard LEDs output, it is an array of single bits.
        output reg rLed [0 : 3],   

        // RGB LEDs output, it is an array of 4 vectors of 3 bit each.
        output reg [2:0] rLedRGB [0 : 3],   

        // Pseudo-analogue input.


        // Pseudo USB connection (reference direction is controller toward FPGA).
        input TXD,              // Data from the controller toward the FPGA.
        output RXD,             // Data from the FPGA toward the controller.
                
        
        // Debug.
        output [0:0] led
    );
    

    //--------------------------------------------------------------------------
    // I/O buffering
    //--------------------------------------------------------------------------


    // System clock buffers. The IBUFGDS primitive ensures a clock network is 
    // connected to the buffer output.
    IBUFGDS clk_inst (
        .O(wClk),
        .I(sysClk_p),
        .IB(sysClk_n)
    );
    
    // Static
    reg [24:0] rCount = 0;
    wire wClk;
    assign led[0] = rCount[24];
 
    // Simple process
    always @ (posedge(wClk)) begin
        rCount <= count + 1;
    end

endmodule
