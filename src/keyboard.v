// File fpga64_keyboard.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2017 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

// -----------------------------------------------------------------------
//
//                                 FPGA 64
//
//     A fully functional commodore 64 implementation in a single FPGA
//
// -----------------------------------------------------------------------
// Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
// http://www.syntiac.com/fpga64.html
// -----------------------------------------------------------------------
// 'Joystick emulation on keypad' additions by
// Mark McDougall (msmcdoug@iinet.net.au)
// -----------------------------------------------------------------------
//
// VIC20/C64 Keyboard matrix
//
// Hardware huh?
//	In original machine if a key is pressed a contact is made.
//	Bidirectional reading is possible on real hardware, which is difficult
//	to emulate. (set backwardsReadingEnabled to '1' if you want this enabled).
//	Then we have the joysticks, one of which is normally connected
//	to a OUTPUT pin.
//
// Emulation:
//	All pins are high except when one is driven low and there is a
//	connection. This is consistent with joysticks that force a line
//	low too. CIA will put '1's when set to input to help this emulation.
//
// -----------------------------------------------------------------------
// no timescale needed

module keyboard(
  input wire clk,
  input wire [10:0] ps2_key,
  input wire [7:0] pai,
  input wire [7:0] pbi,
  output reg [7:0] pao,
  output reg [7:0] pbo,
  output reg reset_key,
  output reg restore_key,
  input wire backwardsReadingEnabled
);

// Config
// backwardsReadingEnabled = 1 allows reversal of PIA registers to still work.
// not needed for kernel/normal operation only for some specific programs.
// set to 0 to save some hardware.

wire pressed;

reg key_del = 1'b0;
reg key_return = 1'b0;
reg key_left = 1'b0;
reg key_right = 1'b0;
reg key_f7 = 1'b0;
reg key_f1 = 1'b0;
reg key_f3 = 1'b0;
reg key_f5 = 1'b0;
reg key_up = 1'b0;
reg key_down = 1'b0;
reg key_3 = 1'b0;
reg key_W = 1'b0;
reg key_A = 1'b0;
reg key_4 = 1'b0;
reg key_Z = 1'b0;
reg key_S = 1'b0;
reg key_E = 1'b0;
reg key_shiftl = 1'b0;
reg key_5 = 1'b0;
reg key_R = 1'b0;
reg key_D = 1'b0;
reg key_6 = 1'b0;
reg key_C = 1'b0;
reg key_F = 1'b0;
reg key_T = 1'b0;
reg key_X = 1'b0;
reg key_7 = 1'b0;
reg key_Y = 1'b0;
reg key_G = 1'b0;
reg key_8 = 1'b0;
reg key_B = 1'b0;
reg key_H = 1'b0;
reg key_U = 1'b0;
reg key_V = 1'b0;
reg key_9 = 1'b0;
reg key_I = 1'b0;
reg key_J = 1'b0;
reg key_0 = 1'b0;
reg key_M = 1'b0;
reg key_K = 1'b0;
reg key_O = 1'b0;
reg key_N = 1'b0;
reg key_plus = 1'b0;
reg key_P = 1'b0;
reg key_L = 1'b0;
reg key_minus = 1'b0;
reg key_dot = 1'b0;
reg key_colon = 1'b0;
reg key_at = 1'b0;
reg key_comma = 1'b0;
reg key_pound = 1'b0;
reg key_star = 1'b0;
reg key_semicolon = 1'b0;
reg key_home = 1'b0;
reg key_shiftr = 1'b0;
reg key_equal = 1'b0;
reg key_arrowup = 1'b0;
reg key_slash = 1'b0;
reg key_1 = 1'b0;
reg key_arrowleft = 1'b0;
reg key_ctrl = 1'b0;
reg key_2 = 1'b0;
reg key_space = 1'b0;
reg key_commodore = 1'b0;
reg key_Q = 1'b0;
reg key_runstop = 1'b0;  // for joystick emulation on PS2

  assign pressed = ~ps2_key[9];

  always @(posedge clk) begin
    // reading A, scan pattern on B
    pao[0] <= pai[0] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_del) & (pbi[1] |  ~key_return) & (pbi[2] |  ~(key_left | key_right)) & (pbi[3] |  ~key_f7) & (pbi[4] |  ~key_f1) & (pbi[5] |  ~key_f3) & (pbi[6] |  ~key_f5) & (pbi[7] |  ~(key_up | key_down))));

    pao[1] <= pai[1] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_3) & (pbi[1] |  ~key_W) & (pbi[2] |  ~key_A) & (pbi[3] |  ~key_4) & (pbi[4] |  ~key_Z) & (pbi[5] |  ~key_S) & (pbi[6] |  ~key_E) & (pbi[7] |  ~(key_left | key_up | key_shiftl))));

    pao[2] <= pai[2] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_5) & (pbi[1] |  ~key_R) & (pbi[2] |  ~key_D) & (pbi[3] |  ~key_6) & (pbi[4] |  ~key_C) & (pbi[5] |  ~key_F) & (pbi[6] |  ~key_T) & (pbi[7] |  ~key_X)));

    pao[3] <= pai[3] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_7) & (pbi[1] |  ~key_Y) & (pbi[2] |  ~key_G) & (pbi[3] |  ~key_8) & (pbi[4] |  ~key_B) & (pbi[5] |  ~key_H) & (pbi[6] |  ~key_U) & (pbi[7] |  ~key_V)));

    pao[4] <= pai[4] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_9) & (pbi[1] |  ~key_I) & (pbi[2] |  ~key_J) & (pbi[3] |  ~key_0) & (pbi[4] |  ~key_M) & (pbi[5] |  ~key_K) & (pbi[6] |  ~key_O) & (pbi[7] |  ~key_N)));

    pao[5] <= pai[5] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_plus) & (pbi[1] |  ~key_P) & (pbi[2] |  ~key_L) & (pbi[3] |  ~key_minus) & (pbi[4] |  ~key_dot) & (pbi[5] |  ~key_colon) & (pbi[6] |  ~key_at) & (pbi[7] |  ~key_comma)));

    pao[6] <= pai[6] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_pound) & (pbi[1] |  ~key_star) & (pbi[2] |  ~key_semicolon) & (pbi[3] |  ~key_home) & (pbi[4] |  ~key_shiftr) & (pbi[5] |  ~key_equal) & (pbi[6] |  ~key_arrowup) & (pbi[7] |  ~key_slash)));

    pao[7] <= pai[7] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_1) & (pbi[1] |  ~key_arrowleft) & (pbi[2] |  ~key_ctrl) & (pbi[3] |  ~key_2) & (pbi[4] |  ~key_space) & (pbi[5] |  ~key_commodore) & (pbi[6] |  ~key_Q) & (pbi[7] |  ~key_runstop)));

    // reading B, scan pattern on A
    pbo[0] <= pbi[0] & (pai[0] |  ~key_del) & (pai[1] |  ~key_3) & (pai[2] |  ~key_5) & (pai[3] |  ~key_7) & (pai[4] |  ~key_9) & (pai[5] |  ~key_plus) & (pai[6] |  ~key_pound) & (pai[7] |  ~key_1);

    pbo[1] <= pbi[1] & (pai[0] |  ~key_return) & (pai[1] |  ~key_W) & (pai[2] |  ~key_R) & (pai[3] |  ~key_Y) & (pai[4] |  ~key_I) & (pai[5] |  ~key_P) & (pai[6] |  ~key_star) & (pai[7] |  ~key_arrowleft);

    pbo[2] <= pbi[2] & (pai[0] |  ~(key_left | key_right)) & (pai[1] |  ~key_A) & (pai[2] |  ~key_D) & (pai[3] |  ~key_G) & (pai[4] |  ~key_J) & (pai[5] |  ~key_L) & (pai[6] |  ~key_semicolon) & (pai[7] |  ~key_ctrl);

    pbo[3] <= pbi[3] & (pai[0] |  ~key_f7) & (pai[1] |  ~key_4) & (pai[2] |  ~key_6) & (pai[3] |  ~key_8) & (pai[4] |  ~key_0) & (pai[5] |  ~key_minus) & (pai[6] |  ~key_home) & (pai[7] |  ~key_2);

    pbo[4] <= pbi[4] & (pai[0] |  ~key_f1) & (pai[1] |  ~key_Z) & (pai[2] |  ~key_C) & (pai[3] |  ~key_B) & (pai[4] |  ~key_M) & (pai[5] |  ~key_dot) & (pai[6] |  ~key_shiftr) & (pai[7] |  ~key_space);

    pbo[5] <= pbi[5] & (pai[0] |  ~key_f3) & (pai[1] |  ~key_S) & (pai[2] |  ~key_F) & (pai[3] |  ~key_H) & (pai[4] |  ~key_K) & (pai[5] |  ~key_colon) & (pai[6] |  ~key_equal) & (pai[7] |  ~key_commodore);

    pbo[6] <= pbi[6] & (pai[0] |  ~key_f5) & (pai[1] |  ~key_E) & (pai[2] |  ~key_T) & (pai[3] |  ~key_U) & (pai[4] |  ~key_O) & (pai[5] |  ~key_at) & (pai[6] |  ~key_arrowup) & (pai[7] |  ~key_Q);

    pbo[7] <= pbi[7] & (pai[0] |  ~(key_up | key_down)) & (pai[1] |  ~(key_left | key_up | key_shiftl)) & (pai[2] |  ~key_X) & (pai[3] |  ~key_V) & (pai[4] |  ~key_N) & (pai[5] |  ~key_comma) & (pai[6] |  ~key_slash) & (pai[7] |  ~key_runstop);

    if(ps2_key[10]) begin
      case(ps2_key[7:0])
        8'h01 : key_pound <= pressed;
        8'h03 : key_f5 <= pressed;
        8'h04 : key_f3 <= pressed;
        8'h05 : key_f1 <= pressed; //when X"06" => -- F2
        8'h09 : key_plus <= pressed;
        8'h0C : restore_key <= pressed; // F4
        8'h83 : key_f7 <= pressed;
        8'h0E : key_arrowleft <= pressed;
        8'h11 : key_commodore <= pressed;
        8'h12 : key_shiftl <= pressed; 
        8'h14 : key_ctrl <= pressed; 
        8'h15 : key_Q <= pressed;
        8'h16 : key_1 <= pressed;
        8'h1A : key_Z <= pressed;
        8'h1B : key_S <= pressed;
        8'h1C : key_A <= pressed;
        8'h1D : key_W <= pressed;
        8'h1E : key_2 <= pressed;
        8'h21 : key_C <= pressed;
        8'h22 : key_X <= pressed;
        8'h23 : key_D <= pressed;
        8'h24 : key_E <= pressed;
        8'h25 : key_4 <= pressed;
        8'h26 : key_3 <= pressed;
        8'h29 : key_space <= pressed;
        8'h2A : key_V <= pressed;
        8'h2B : key_F <= pressed;
        8'h2C : key_T <= pressed;
        8'h2D : key_R <= pressed;
        8'h2E : key_5 <= pressed;
        8'h31 : key_N <= pressed;
        8'h32 : key_B <= pressed;
        8'h33 : key_H <= pressed;
        8'h34 : key_G <= pressed;
        8'h35 : key_Y <= pressed;
        8'h36 : key_6 <= pressed;
        8'h3A : key_M <= pressed;
        8'h3B : key_J <= pressed;
        8'h3C : key_U <= pressed;
        8'h3D : key_7 <= pressed;
        8'h3E : key_8 <= pressed;
        8'h41 : key_comma <= pressed;
        8'h42 : key_K <= pressed;
        8'h43 : key_I <= pressed;
        8'h44 : key_O <= pressed;
        8'h45 : key_0 <= pressed;
        8'h46 : key_9 <= pressed;
        8'h49 : key_dot <= pressed;
        8'h4A : key_slash <= pressed;
        8'h4B : key_L <= pressed;
        8'h4C : key_colon <= pressed;
        8'h4D : key_P <= pressed;
        8'h4E : key_minus <= pressed;
        8'h52 : key_semicolon <= pressed;
        8'h54 : key_at <= pressed;
        8'h55 : key_equal <= pressed;
        8'h59 : key_shiftr <= pressed;
        8'h5A : key_return <= pressed;
        8'h5B : key_star <= pressed;
        8'h5D : key_arrowup <= pressed;
        8'h6B : key_left <= pressed;
        8'h6C : key_home <= pressed;
        8'h66 : key_del <= pressed;
        8'h72 : key_down <= pressed;
        8'h74 : key_right <= pressed;
        8'h75 : key_up <= pressed;
        8'h76 : key_runstop <= pressed;
        8'h78 : begin // F11
                  if(key_ctrl == 1'b1) begin
                    reset_key <= pressed;
                  end
                end
      endcase
    end
  end

endmodule
