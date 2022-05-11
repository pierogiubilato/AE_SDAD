/*#############################################################################\
##                                                                            ##
##       Applied Electronics - Physics Department - University of Padova      ##
##                                                                            ##
\#############################################################################*/


// Set timescale (default time unit if not otherwise specified).
`timescale 1ns / 1ps

// Top module.
module top_sim();
    
    
    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // -- MATH CONSTANTS
    // -----------------    
    parameter real C_PI = $acos(-1);            // Pi.
    
   
    // -- ANALOGUE SIGNALS
    // -------------------    
        
    // Analogue boundaries
    parameter real C_ANA_GND = 0.0;         // Analogue ground value [V].
    parameter real C_ANA_VDD = 1.5;         // Analogue digital supply [V].
    parameter C_ANA_BITS = 16;              // Analogue signal bits representation [bit].                
    localparam real C_ANA_CONV = (2**C_ANA_BITS) / (C_ANA_VDD - C_ANA_GND);    // Conversion factor. 
    
    // Input waveform properties
    parameter real C_WAV_FRQ = 5000;        // Test wave frequency [Hz].
    parameter real C_WAV_PHS = 0;           // Test wave fase [rad].       
    parameter real C_WAV_AMP = 1.0;         // Waveform amplitude (0-Max) [V].
    parameter real C_WAV_NOISE = 0.001;     // Waveform noise (sigma) [V].
        
    // RC integrator properties
    parameter real C_RC_CAP = 0.1;           // Capacitance [nF].
    parameter real C_RC_RES = 1000;         // Resistance [Ohm].       
    
    
    // HARDWARE PROPERTIES
    // -------------------    
    
    // Clock properties.
    parameter C_CLK_BRD_FRQ     = 100000000;    // Master clock (board) frequency [Hz].
    parameter C_CLK_BRD_JTR     = 50;           // Master clock (board) jitter [ps].
    parameter C_CLK_FRQ         = 10000000;     // Main clock frequency [Hz].
               
    // Derived clock properties.
    localparam real C_CLK_BRD_PERIOD = 1E9 / C_CLK_BRD_FRQ;      // Master clock period [ns].
        

    // Set user IO parameters accordingly to the board used to deploy the firmware.
    //parameter C_DATA_IN_WIDTH   = 8;           // Write bus.
    //parameter C_DATA_OUT_WIDTH  = 32;            // Read bus.
    
    
    // ==========================================================================
    // ==                               Functions                              ==
    // ==========================================================================
    
    // Analogue sine value. Here we use a function statement to generate an input 
    // signal for the testbench. Functions are "ideal", i.e. they do not take any 
    // execution time in the simulation. 
    function real waveValue(realtime t);
                
        // Returns the amplitude of a sine wave of frequency 'C_WAV_FRQ' at the 
        // time 't' assumed it starte at 't = 0', with phase 'C_WAV_PHS'. Note 
        // " / 1s " operator, which rescales the frequency with respect to the 
        // current simulation time unit.
        // The output is in the range [0 - C_WAV_AMP] 
        real val = C_ANA_GND + 
                 + C_WAV_AMP * (1 + $sin(2 * C_PI * t * C_WAV_FRQ / 1s + C_WAV_PHS)) / 2 
                 + $dist_normal(seed, 0, C_WAV_NOISE);  
    
        // Boundaries check.
        if (val < C_ANA_GND) return C_ANA_GND;
        if (val > C_WAV_AMP) return C_WAV_AMP;
        return val;
    endfunction
    
    
    // Analogue RC charge/discharge simulation. Computes the voltage present at the 
    // output of the RC network. At startup, the network is assumed discharged 
    // (empty capacitor). 'v' indicates the external voltage on the resistor node, 
    // and it is sampled each time the function is called.
    function real rcValue(realtime t, real v);
        
        // Local variables.
        static realtime lastTime = 0;   // Time of the last call.
        static real capVoltLast = 0;    // Start voltage level at the capacitor.        
        static real resVolt = 0;        // Applied voltage to the resistor. 
        real capVolt;                   // Capacitor voltage at the time of the call. 
        realtime deltaTime;             // Elapsed time since the last drive voltage switch.
        
        // Elapsed time since the driving voltage has been applied [s].
        deltaTime = (t - lastTime) / 1s;
        
        // Calculate the present the voltage at the capacitor node.
        capVolt = capVoltLast + (resVolt - capVoltLast) * (1-$exp(-deltaTime / (C_RC_RES * C_RC_CAP / 10000000000)));  
    
         // Driving voltage has changed, store the new start point in time.
        if (v != resVolt) begin
            $display("[%t] RC: new drive value %f, last interval lasted %ts", t, v, deltaTime);
            lastTime = t;
            capVoltLast= capVolt;
            resVolt = v;
        end;
        
        // Store the time of the call, the new applied voltage, and return 
        // current capacitor voltage
        return capVolt;
    endfunction
    
    
    // ==========================================================================
    // ==                              Seeding                                 ==
    // ==========================================================================
        
    // Seeding for (repeatable) random number generation. What we generally need 
    // in simulations are random sequences that, GIVEN THE SAME SEED, result to 
    // be identical. That allows REPETEABILITY, and error analysis in case the
    // simulation highlights any problem. 
    // '$urandom' is implementation dependent, but is OK for generating the 
    // starting seed.
    static int seed = $urandom + 0;




    
    // ==========================================================================
    // ==                                Signals                               ==
    // ==========================================================================
    
    // "Boards" signal, i.e. from outside the FPGA.
    reg rst_b;                                  // Board reset (active low).
    reg clkBrd;                                 // Board clock.
    
    // Simulated analogue signals.
    reg [C_ANA_BITS - 1 : 0] inputVoltage;      // Input waveform voltage.
    real inputVoltageVar;                       // Input waveform voltage.
    reg [C_ANA_BITS - 1 : 0] rcVoltage;         // RC integrator voltage.
    real rcVoltageVar;                          // RC integrator voltage.
    real rcDriveVoltageVar = C_ANA_VDD;         // RC driving (resistor) voltage [V].
    reg compOut;                                // Comparator output.
    reg [C_ANA_BITS - 1 : 0] dsError;           // DS error.
           
    // DS ADC signals.
    reg dsOut;                                  // 1-bit output of the DS.
    
    
    
    // Signals from the design.
    
    
    // Data.
    //reg [C_DATA_IN_WIDTH - 1 : 0] a;        // Input.
    //reg [C_DATA_IN_WIDTH - 1 : 0] b;        // Input.    
    //wire [C_DATA_OUT_WIDTH - 1 : 0] c;      // Output.
        

    
    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================

    // Instantiate 25 MHz READ clock generaror.
//    top #(
//        // Clocks.
//        .C_CLK_BRD_FRQ(C_CLK_BRD_FRQ),
//        .C_CLK_FRQ(C_CLK_FRQ),
        
//        // Data.
//        .C_DATA_IN_WIDTH(C_DATA_IN_WIDTH),
//        .C_DATA_OUT_WIDTH(C_DATA_OUT_WIDTH)
        
//    ) TOP (
//        .RSTB(rstb),
//        .CLK(clkBrd),
//        .A(a),
//        .B(b),
//        .C(c)
//    );
    
    
    
    // ==========================================================================
    // ==                                Stimuli                               ==
    // ==========================================================================
    
    // Initialization sequence.   
    initial begin 
        
        // Set initial values.
        clkBrd = 1'b0; 
        rst_b = 1'b1; 
        
        // Generate first reset.
        #(2 * C_CLK_BRD_PERIOD) rst_b <= 1'b0;
        #(10 * C_CLK_BRD_PERIOD) rst_b <= 1'b1;
    end
    
    // Clock generation. This process generates a clock with period equal to 
    // C_CLK_BRD_PERIOD. It also add a pseudorandom jitter, normally distributed 
    // with mean 0 and standard deviation equal to 'kClockJitter'.  
    always begin
        #(0.001 * $dist_normal(seed, 1000.0 * C_CLK_BRD_PERIOD / 2, C_CLK_BRD_JTR));
        clkBrd = ! clkBrd;
    end      
    
    // Test RC circuit.    
    //initial begin 
    //    #300us; rcDriveVoltageVar = 0;
    //    #100us; rcDriveVoltageVar = C_ANA_CEIL;
    //end    
    
    // Input waveform.
    always begin
        #1;
        //$display("A %f at %t", waveValue($realtime), $realtime);
        rcVoltageVar = rcValue($realtime, rcDriveVoltageVar);
        rcVoltage = $floor(rcVoltageVar * C_ANA_CONV);
    end
    
    // RC integrator.
    always begin
        #1;
        inputVoltageVar = waveValue($realtime);
        inputVoltage = $floor(inputVoltageVar * C_ANA_CONV);
    end   
    
    // Estimate error.
    always @(inputVoltageVar) begin
        real err = inputVoltageVar - rcVoltageVar;
        if (err < 0) err = -err;
        dsError = $floor(err * C_ANA_CONV);
    end   
    
    
    // Analogue comparator. 
    always@(rcVoltageVar, inputVoltageVar) begin
        if (inputVoltageVar >= rcVoltageVar) begin
            compOut <= 1'b1;
        end else begin
            compOut <= 1'b0;
        end
    end
     
    // DS emulator.
    always @(posedge clkBrd) begin
        if (!rst_b) begin
            dsOut <= 1'b0;
        end else begin
            dsOut <= compOut;
        end
    end
    
    // Analogue Driver.
    always @(dsOut) begin
        if (dsOut) begin
            rcDriveVoltageVar <= C_ANA_VDD;
        end else begin
            rcDriveVoltageVar <= C_ANA_GND;
        end
    end     
        
    
//    // Generate pseudorandom data at the inputs.
//    always @ (posedge clkBrd) begin
        
//        // Wait 2 clock cycles, so to slow data production by a factor 2.
//        #( 0.001 * $dist_normal(seed, 2000.0 * C_CLK_BRD_PERIOD, 1000.0 * kClockJitter) );
        
//        // Fill the data.
//        a <= $urandom_range(0, 15);
//        b <= $urandom_range(0, 15);
//    end
    
endmodule