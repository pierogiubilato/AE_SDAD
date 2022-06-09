/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##             Sigma Delta Analogue to Digital didactical example             ##
##                                                                            ##
\#############################################################################*/

// INFO
// The sinegen module generates an 8-bit wide data stream representing a sine
// wave of programmable frequency.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 



// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. Asserting 'rstb' while
//                  'busy' is high will likely corrupt the communication channel.
// clk:             INPUT, master clock. Defines the timing of the transmission.
// [13:0] frq:      INPUT, Sinewave frequency, in 1 Hz steps.
// [7:0] data:      OUTPUT, the 8 bit data word representing the current sinewave 
//                  amplitude, according to the 'frq' setting.


// Tool timescale.
`timescale 1 ns / 1 ps


// Behavioural.
module sinegen # (
        parameter C_CLK_FRQ = 100_000_000  // Input clock frequency.
    ) (
        input rstb,                 // Reset, active low.
        input clk,                  // Reference input clock.
        input [15 : 0] frq,         // Frequency, units of [1 Hz].
        output reg [7 : 0] data         // Sine output.
    );
    
    
    // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Set the phase depth (by sedign).
    localparam C_PHASE_STEPS = 256;
    localparam C_PHASE_STEPS_WIDTH = 8;
    
    // Derives the clock cycles corresponding to a 1 Hz / C_PHASE_STEPS interval.
    localparam C_STEP_INTERVAL = C_CLK_FRQ /  (C_PHASE_STEPS);
    localparam C_STEP_INTERVAL_WIDTH = $clog2(C_STEP_INTERVAL);

    // =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

    
    // Create a register(s) set where to store the sine values, and fill it with
    // the pre-calculated steps found in the "sine.mem" file.
    reg	[7:0] rSine [0 : C_PHASE_STEPS - 1];
    initial $readmemh("sine.mem", rSine, 0, C_PHASE_STEPS - 1);    
    
    // Phase register, counts from 0 to the sinetable size
    reg [C_PHASE_STEPS_WIDTH - 1 : 0] rPhase;
    
    // Divider register, count the clock to match the preset frequency.
    reg [C_STEP_INTERVAL_WIDTH - 1 : 0] rAccu;
    
    // Phase step register.
    reg rPStep;
    
    
    
    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

    // Output current sine value.
    always@(posedge clk) begin
        data <= rSine[rPhase];    
    end

    // =========================================================================
    // ==                          Synchronous logic                         ==
    // =========================================================================
    
    // Accumulator.
    always@(posedge clk) begin
        if (rstb == 1'b0) begin
            rAccu <= 0;
        end else if (rAccu >= C_STEP_INTERVAL) begin
            rAccu <= 0;
        end else begin
            rAccu <= rAccu + frq;    
        end
    end 
    
    // Phase step.
    always@(posedge clk) begin
        if (rstb == 1'b0) begin
            rPhase <= 0;
        end else if (rAccu == 0) begin
            rPhase <= rPhase + 1; 
        end else begin
            rPhase <= rPhase;     
        end
    end 

endmodule