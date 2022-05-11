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


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// Timing
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_DBC_INTERVAL:  debouncing interval on external "mech" inputs [ms].
//
// UART interface
// C_UART_RATE:     transmission bit frequency [BAUD] {1000000}.
// C_UART_DATA_WIDTH: transmission word width [bit] {8}.
// C_UART_PARITY:   transmission parity bit [bit] {0, 1}.
// C_UART_STOP:     transmission stop bit(s) [bit] {0, 1, 2}.



// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// sysRstb:         INPUT, synchronous reset, ACTIVE LOW.
// sysClk:          INPUT, master clock. Defines the timing of the transmission.
//
// [3:0] sw:        INPUT, connected to the board switches.
// [3:0] btn:       INPUT, connected to the board push buttons.
// [3:0] led:       OUTPUT, connected to the board LEDs.
// [11:0] ledRGB:   INPUT, connected to the board RGB LEDs, grouped by 3 for
//                  each LED: [11:9] = R,G,B for led 3, [8:6] = R,G,B for led 2,
//                  [5:3] = R,G,B for led 1, [2:0] = R,G,B for led 0,
//
// UART_Rx:         INPUT, the bit-line carrying the UART communication.
// UART_Tx:         OUTPUT, the bit-line sourcing the UART communication.


// -----------------------------------------------------------------------------
// --                                Libraries                                --
// -----------------------------------------------------------------------------

/*============================================================================*\
||                                                                            ||
||                            WARNING: PROTOTYPE!                             ||
||                                                                            ||
/*============================================================================*/


// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module top # (
        
        // Timing.
        parameter C_SYSCLK_FRQ = 100_000_000,   // SYstem clock frequency.
        parameter C_DBC_INTERVAL = 10,          // Debouncing interval [ms].              
        
        // UART properties.
        parameter C_UART_RATE = 1_000_000,      // UART word width.
        parameter C_UART_DATA_WIDTH = 8,        // UART word width.
        parameter C_UART_PARITY = 1,            // UART parity bits.
        parameter C_UART_STOP = 1,              // UART stop bits.

        // Debug registers.
        parameter C_REG_WIDTH = 4               // Registry data width.
    ) (
        
        // Timing.
        input sysRstb,                  // System reset, active low.
        input sysClk,                   // System clock, SE input.
                
        // External switches and buttons inputs.
        input [3:0] sw,                 // Switches.
        input [3:0] btn,                // Push buttons.
        
        // Standard LEDs outputs.
        output [3:0] led,   
        output [11:0] ledRGB,
        
        // UART iterface (reference direction is controller toward FPGA).
        input UART_Rx,              // Data from the controller toward the FPGA.
        output UART_Tx              // Data from the FPGA toward the controller.
    );
    

    // =========================================================================
    // ==                                Wires                                ==
    // =========================================================================
    
    // Timing.
    wire wSysRstb;      // System reset (from the board push-button).
    wire wSysClk;       // System clock (from the board oscillator).
        
    // Wires from the debouncer(s) toward the fabric.
    wire [3:0] wSw;     // Switches.
    wire [3:0] wBtn;    // Push buttons.
        
    
    // =========================================================================
    // ==                            I/O buffering                            ==
    // =========================================================================
    
    // System clock buffer. The IBUFG primitive ensures a clock network is 
    // connected to the buffer output.
    IBUFG clk_inst (
        .O(wSysClk),
        .I(sysClk)
    );
    
    // Input debouncer(s).
    // -------------------------------------------------------------------------
    genvar i;
    
    // Reset button.
    //debounce #(
    //    .C_CLK_FRQ(C_SYSCLK_FRQ),
    //    .C_INTERVAL(C_DBC_INTERVAL)
    //) DBC_BTN (
    //    .rstb(1'b1),    // Note that the reset debouncer never reset!
    //    .clk(wSysClk),
    //    .in(sysRstb),
    //    .out(wSysRst)
    //);
    assign wSysRstb = 1'b1; // sysRstb;
 
    
    // Buttons.
    generate 
        for (i = 0; i < 4; i=i+1) begin
            debounce #(
                .C_CLK_FRQ(C_SYSCLK_FRQ),
                .C_INTERVAL(C_DBC_INTERVAL)
            ) DBC_BTN (
                .rstb(wSysRstb),
                .clk(wSysClk),
                .in(btn[i]),
                .out(wBtn[i])
            );
        end
    endgenerate
    
    // Switches.
    generate 
        for (i = 0; i < 4; i=i+1) begin
            debounce #(
                .C_CLK_FRQ(C_SYSCLK_FRQ),
                .C_INTERVAL(C_DBC_INTERVAL)
            ) DBC_SW (
                .rstb(wSysRstb),
                .clk(wSysClk),
                .in(sw[i]),
                .out(wSw[i])
            );
        end
    endgenerate
    
    
    // =========================================================================
    // ==                          UART interface                             ==
    // =========================================================================
    
    // UART Rx.
    UART_Rx #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP)
    ) URx (
        .rstb(wSysRstb),
        .clk(sysClk),
        .ack(),
        .data(),
        .valid(),
        .error(),
        .rx(UART_Rx)
    );    

    // UART Tx.
    UART_Tx #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP)
    ) UTx (
        .rstb(wSysRstb),
        .clk(sysClk),
        .send(),
        .data(),
        .error(),
        .tx(UART_Tx)
    );    

    
    // =========================================================================
    // ==                          DEBUG Registry                             ==
    // =========================================================================
    
    registry #(
            .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
            .C_REG_WIDTH(C_REG_WIDTH)
        ) DUT_Tx (
            .rstb(rRstb),
            .clk(rClk),
            .data(),
            .valid(),
            .ack(),
            .register()
    );
    

    // =========================================================================
    // ==                              Routing                                ==
    // =========================================================================
    
    assign led[1] = wBtn[1];
    assign led[2] = wBtn[2];
    assign led[3] = wBtn[3];
    
    assign ledRGB[0] = wSw[0];
    assign ledRGB[1] = wSw[1];
    assign ledRGB[2] = wSw[2];
    
    // Static
    reg [23:0] rCount = 0;
    
    assign led[0] = rCount[23];
    
    // Simple process
    always @ (posedge(wSysClk)) begin
        rCount <= rCount + 1;
    end

endmodule
