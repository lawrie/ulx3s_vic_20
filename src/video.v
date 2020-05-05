`default_nettype none
module video (
  input         clk,
  input         reset,
  output [3:0]  vga_r,
  output [3:0]  vga_b,
  output [3:0]  vga_g,
  output        vga_hs,
  output        vga_vs,
  output        vga_de,
  input  [7:0]  vga_data,
  output [12:0] vga_addr
);

  parameter HA = 640;
  parameter HS  = 96;
  parameter HFP = 16;
  parameter HBP = 48;
  parameter HT  = HA + HS + HFP + HBP;
  parameter HB = 144;
  parameter HB2 = HB/2-8; // NOTE pixel coarse H-adjust
  parameter HDELAY = 3;   // NOTE pixel fine H-adjust
  parameter HBattr = 4;   // NOTE attr coarse H-adjust
  parameter HBadj = 4;    // NOTE border H-adjust

  parameter VA = 480;
  parameter VS  = 2;
  parameter VFP = 11;
  parameter VBP = 31;
  parameter VT  = VA + VS + VFP + VBP;
  parameter VB = 56;
  parameter VB2 = VB/2;

  reg [9:0] hc = 0;
  reg [9:0] vc = 0;

  always @(posedge clk) begin
    if (hc == HT - 1) begin
      hc <= 0;
      if (vc == VT - 1) vc <= 0;
      else vc <= vc + 1;
    end else hc <= hc + 1;
  end

  assign vga_hs = !(hc >= HA + HFP && hc < HA + HFP + HS);
  assign vga_vs = !(vc >= VA + VFP && vc < VA + VFP + VS);
  assign vga_de = !(hc > HA || vc > VA);

  wire [7:0] x = hc[9:1] - HB2;
  wire [7:0] y = vc[9:1] - VB2;

  wire hBorder = (hc < (HB + HBadj) || hc >= (HA - HB + HBadj));
  wire vBorder = (vc < VB || vc >= VA - VB);
  wire border = hBorder || vBorder;

  wire [3:0] red = border ? 4'b0 : 4'b1111;
  wire [3:0] green = border ? 4'b1111 : 4'b1111;
  wire [3:0] blue = border ? 4'b1111 : 4'b1111;

  assign vga_r = !vga_de ? 4'b0 : red;
  assign vga_g = !vga_de ? 4'b0 : green;
  assign vga_b = !vga_de ? 4'b0 : blue;

endmodule

