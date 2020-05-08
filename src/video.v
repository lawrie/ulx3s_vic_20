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
  output reg [15:0] vga_addr,
  input [15:0]  screen_addr,
  input [15:0]  char_rom_addr,
  input [15:0]  color_ram_addr,
  input [2:0]   border_color,
  input [3:0]   back_color,
  input         inverted,
  input [3:0]   aux_color
);

  parameter HA = 640;
  parameter HS  = 96;
  parameter HFP = 16;
  parameter HBP = 48;
  parameter HT  = HA + HS + HFP + HBP;
  parameter HB = 144;
  parameter HB2 = HB/2 - 8; // NOTE pixel coarse H-adjust
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

  wire [11:0] color_to_rgb [0:15];
  assign color_to_rgb[0]  = 12'b000000000000;
  assign color_to_rgb[1]  = 12'b111111111111;
  assign color_to_rgb[2]  = 12'b111100000000;
  assign color_to_rgb[3]  = 12'b000011111111;
  assign color_to_rgb[4]  = 12'b111100001111;
  assign color_to_rgb[5]  = 12'b000011110000;
  assign color_to_rgb[6]  = 12'b000000001111;
  assign color_to_rgb[7]  = 12'b111111110000;
  assign color_to_rgb[8]  = 12'b111101110000;
  assign color_to_rgb[9]  = 12'b111100110000;
  assign color_to_rgb[10] = 12'b111101110111;
  assign color_to_rgb[11] = 12'b011111111111;
  assign color_to_rgb[12] = 12'b111101111111;
  assign color_to_rgb[13] = 12'b011111110111;
  assign color_to_rgb[14] = 12'b011111111111;
  assign color_to_rgb[15] = 12'b1111111110111;

  reg [2:0] fore_color = 3'b110;

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

  // Pixel co-ordinates
  wire [7:0] x = hc[9:1] - HB2;
  wire [7:0] y = vc[9:1] - VB2;

  wire hBorder = (hc < (HB + HBadj) || hc >= (HA - HB + HBadj));
  wire vBorder = (vc < VB || vc >= VA - VB);
  wire border = hBorder || vBorder;

  wire [15:0] char_addr = screen_addr + (y[7:3] * 22) + x[7:3];
  reg [7:0] current_char;

  wire [15:0] attr_addr = color_ram_addr + (y[7:3] * 22) + x[7:3];
  reg [7:0] attr;
  wire [2:0] color = attr[2:0];

  wire [15:0] char_row_addr = char_rom_addr + {5'b0, current_char, y[2:0]};
  reg [7:0] R_pixel_data;

  wire pixel = inverted ? R_pixel_data[7] : ~R_pixel_data[7];

  always @(posedge clk) begin
    if (hc[0]) begin
      vga_addr <= char_row_addr;
      if (hc[3:1])
        R_pixel_data <= {R_pixel_data[6:0],1'b0};
      else
        R_pixel_data <= vga_data;
    end else begin
      vga_addr <= char_addr;
      current_char <= vga_data;
    end
  end

  wire [3:0] border_r = color_to_rgb[border_color][11:8];
  wire [3:0] border_g = color_to_rgb[border_color][7:4];
  wire [3:0] border_b = color_to_rgb[border_color][3:0];

  wire [4:0] back_r = color_to_rgb[back_color][11:8];
  wire [4:0] back_g = color_to_rgb[back_color][7:4];
  wire [4:0] back_b = color_to_rgb[back_color][3:0];

  wire [4:0] fore_r = color_to_rgb[fore_color][11:8];
  wire [4:0] fore_g = color_to_rgb[fore_color][7:4];
  wire [4:0] fore_b = color_to_rgb[fore_color][3:0];

  wire [3:0] red = border ? border_r : (pixel ? fore_r : back_r);
  wire [3:0] green = border ? border_g : (pixel ? fore_g : back_g);
  wire [3:0] blue = border ? border_b : (pixel ? fore_b : back_b);

  assign vga_r = !vga_de ? 4'b0 : red;
  assign vga_g = !vga_de ? 4'b0 : green;
  assign vga_b = !vga_de ? 4'b0 : blue;

endmodule

