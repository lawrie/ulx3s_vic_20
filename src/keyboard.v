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



wire pressed = 1'b0;
reg key_del = 1'b0;
wire key_return = 1'b0;
reg key_left = 1'b0;
reg key_right = 1'b0;
wire key_f7 = 1'b0;
wire key_f1 = 1'b0;
wire key_f3 = 1'b0;
wire key_f5 = 1'b0;
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
reg old_state;
reg key_F1;
reg key_F3;
reg key_F5;
reg key_F7;
reg key_Return;
reg key_shiftL;

  assign pressed = ps2_key[9];
  always @(posedge clk) begin
    // reading A, scan pattern on B
    pao[0] <= pai[0] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_del) & (pbi[1] |  ~key_return) & (pbi[2] |  ~(key_left | key_right)) & (pbi[3] |  ~key_f7) & (pbi[4] |  ~key_f1) & (pbi[5] |  ~key_f3) & (pbi[6] |  ~key_f5) & (pbi[7] |  ~(key_up | key_down))));
    pao[1] <= pai[1] & (( ~backwardsReadingEnabled) | ((pbi[0] |  ~key_3) & (pbi[1] |  ~key_W) & (pbi[2] |  ~key_A) & (pbi[3] |  ~key_4) & (pbi[4] |  ~key_Z) & (pbi[5] |  ~key_S) & (pbi[6] |  ~key_E) & (pbi[7] |  ~(key_left | key_up | key_shiftL))));
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
    pbo[3] <= pbi[3] & (pai[0] |  ~key_F7) & (pai[1] |  ~key_4) & (pai[2] |  ~key_6) & (pai[3] |  ~key_8) & (pai[4] |  ~key_0) & (pai[5] |  ~key_minus) & (pai[6] |  ~key_home) & (pai[7] |  ~key_2);
    pbo[4] <= pbi[4] & (pai[0] |  ~key_F1) & (pai[1] |  ~key_Z) & (pai[2] |  ~key_C) & (pai[3] |  ~key_B) & (pai[4] |  ~key_M) & (pai[5] |  ~key_dot) & (pai[6] |  ~key_shiftr) & (pai[7] |  ~key_space);
    pbo[5] <= pbi[5] & (pai[0] |  ~key_F3) & (pai[1] |  ~key_S) & (pai[2] |  ~key_F) & (pai[3] |  ~key_H) & (pai[4] |  ~key_K) & (pai[5] |  ~key_colon) & (pai[6] |  ~key_equal) & (pai[7] |  ~key_commodore);
    pbo[6] <= pbi[6] & (pai[0] |  ~key_F5) & (pai[1] |  ~key_E) & (pai[2] |  ~key_T) & (pai[3] |  ~key_U) & (pai[4] |  ~key_O) & (pai[5] |  ~key_at) & (pai[6] |  ~key_arrowup) & (pai[7] |  ~key_Q);
    pbo[7] <= pbi[7] & (pai[0] |  ~(key_up | key_down)) & (pai[1] |  ~(key_left | key_up | key_shiftL)) & (pai[2] |  ~key_X) & (pai[3] |  ~key_V) & (pai[4] |  ~key_N) & (pai[5] |  ~key_comma) & (pai[6] |  ~key_slash) & (pai[7] |  ~key_runstop);
    old_state <= ps2_key[10];
    if(old_state != ps2_key[10]) begin
      case(ps2_key[7:0])
      8'h01 : begin
        key_pound <= pressed;
      end
      8'h03 : begin
        key_F5 <= pressed;
      end
      8'h04 : begin
        key_F3 <= pressed;
      end
      8'h05 : begin
        key_F1 <= pressed;
        //when X"06" => -- F2
      end
      8'h09 : begin
        key_plus <= pressed;
        //when X"0A" => -- F8
        //when X"0B" => -- F6
      end
      8'h0C : begin
        restore_key <= pressed;
        // F4
      end
      8'h83 : begin
        key_F7 <= pressed;
      end
      8'h0E : begin
        key_arrowleft <= pressed;
      end
      8'h11 : begin
        key_commodore <= pressed;
      end
      8'h12 : begin
        key_shiftl <= pressed;
      end
      8'h14 : begin
        key_ctrl <= pressed;
      end
      8'h15 : begin
        key_Q <= pressed;
      end
      8'h16 : begin
        key_1 <= pressed;
      end
      8'h1A : begin
        key_Z <= pressed;
      end
      8'h1B : begin
        key_S <= pressed;
      end
      8'h1C : begin
        key_A <= pressed;
      end
      8'h1D : begin
        key_W <= pressed;
      end
      8'h1E : begin
        key_2 <= pressed;
      end
      8'h21 : begin
        key_C <= pressed;
      end
      8'h22 : begin
        key_X <= pressed;
      end
      8'h23 : begin
        key_D <= pressed;
      end
      8'h24 : begin
        key_E <= pressed;
      end
      8'h25 : begin
        key_4 <= pressed;
      end
      8'h26 : begin
        key_3 <= pressed;
      end
      8'h29 : begin
        key_space <= pressed;
      end
      8'h2A : begin
        key_V <= pressed;
      end
      8'h2B : begin
        key_F <= pressed;
      end
      8'h2C : begin
        key_T <= pressed;
      end
      8'h2D : begin
        key_R <= pressed;
      end
      8'h2E : begin
        key_5 <= pressed;
      end
      8'h31 : begin
        key_N <= pressed;
      end
      8'h32 : begin
        key_B <= pressed;
      end
      8'h33 : begin
        key_H <= pressed;
      end
      8'h34 : begin
        key_G <= pressed;
      end
      8'h35 : begin
        key_Y <= pressed;
      end
      8'h36 : begin
        key_6 <= pressed;
      end
      8'h3A : begin
        key_M <= pressed;
      end
      8'h3B : begin
        key_J <= pressed;
      end
      8'h3C : begin
        key_U <= pressed;
      end
      8'h3D : begin
        key_7 <= pressed;
      end
      8'h3E : begin
        key_8 <= pressed;
      end
      8'h41 : begin
        key_comma <= pressed;
      end
      8'h42 : begin
        key_K <= pressed;
      end
      8'h43 : begin
        key_I <= pressed;
      end
      8'h44 : begin
        key_O <= pressed;
      end
      8'h45 : begin
        key_0 <= pressed;
      end
      8'h46 : begin
        key_9 <= pressed;
      end
      8'h49 : begin
        key_dot <= pressed;
      end
      8'h4A : begin
        key_slash <= pressed;
      end
      8'h4B : begin
        key_L <= pressed;
      end
      8'h4C : begin
        key_colon <= pressed;
      end
      8'h4D : begin
        key_P <= pressed;
      end
      8'h4E : begin
        key_minus <= pressed;
      end
      8'h52 : begin
        key_semicolon <= pressed;
      end
      8'h54 : begin
        key_at <= pressed;
      end
      8'h55 : begin
        key_equal <= pressed;
      end
      8'h59 : begin
        key_shiftr <= pressed;
      end
      8'h5A : begin
        key_Return <= pressed;
      end
      8'h5B : begin
        key_star <= pressed;
      end
      8'h5D : begin
        key_arrowup <= pressed;
      end
      8'h6B : begin
        key_left <= pressed;
      end
      8'h6C : begin
        key_home <= pressed;
      end
      8'h66 : begin
        key_del <= pressed;
      end
      8'h72 : begin
        key_down <= pressed;
      end
      8'h74 : begin
        key_right <= pressed;
      end
      8'h75 : begin
        key_up <= pressed;
      end
      8'h76 : begin
        key_runstop <= pressed;
      end
      8'h78 : begin
        // F11
        if(key_ctrl == 1'b1) begin
          reset_key <= pressed;
        end
      end
      default : begin
      end
      endcase
    end
  end


endmodule
