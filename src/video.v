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
  output [7:0]  raster_line,
  input [15:0]  screen_addr,
  input [15:0]  char_rom_addr,
  input [15:0]  color_ram_addr,
  input [2:0]   border_color,
  input [3:0]   back_color,
  input         inverted,
  input         chars8x16,
  input [3:0]   aux_color,
  input [6:0]   xorigin,
  input [7:0]   yorigin,
  input [6:0]   rows,
  input [6:0]   cols
);

  parameter HA = 640;
  parameter HS  = 96;
  parameter HFP = 16;
  parameter HBP = 48;
  parameter HT  = HA + HS + HFP + HBP;
  parameter HDELAY = 3;     // NOTE pixel fine H-adjust
  parameter HBattr = 0;     // NOTE attr coarse H-adjust
  parameter HBadj  = 100+3; // NOTE border H-adjust
  parameter HB2adj = 100-16;

  parameter VA = 480;
  parameter VS  = 2;
  parameter VFP = 11;
  parameter VBP = 31;
  parameter VT  = VA + VS + VFP + VBP;
  parameter VBadj = 0;    // NOTE border V-adjust

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
  assign color_to_rgb[15] = 12'b111111110111;

  reg [9:0] hc;
  reg [9:0] vc;

  reg R_vga_hs, R_vga_vs, R_vga_hde, R_vga_vde;
  always @(posedge clk) begin
    if (hc == HT - 1) begin
      hc <= 0;
      if (vc == VT - 1) vc <= 0;
      else vc <= vc + 1;
    end else hc <= hc + 1;
    case(hc)
      0           : R_vga_hde <= 1;
      HA          : R_vga_hde <= 0;
      HA+HFP      : R_vga_hs  <= 1;
      HA+HFP+HS-1 : R_vga_hs  <= 0;
    endcase
    case(vc)
      0           : R_vga_vde <= 1;
      VA          : R_vga_vde <= 0;
      VA+VFP      : R_vga_vs  <= 1;
      VA+VFP+VS-1 : R_vga_vs  <= 0;
    endcase
  end

  assign vga_hs = !R_vga_hs;
  assign vga_vs = !R_vga_vs;
  assign vga_de = R_vga_hde && R_vga_vde;

  reg [9:0] hBorder_left, hBorder_right, hBorder_left2;
  reg [9:0] vBorder_top,  vBorder_bottom;
  reg R_hBorder, R_vBorder;
  always @(posedge clk)
  begin
    hBorder_left     <= {xorigin,3'b0}+HBadj;
    hBorder_left2    <= {xorigin,3'b0}+HB2adj;
    hBorder_right    <= hBorder_left + {cols,4'b0};
    vBorder_top      <= {yorigin,1'b0}+VBadj;
    if(chars8x16)
      vBorder_bottom <= vBorder_top + {rows,4'd0} - 17;
    else
      vBorder_bottom <= vBorder_top + {rows,3'b0} - 1;
    if(hc == hBorder_left)
      R_hBorder <= 0;
    else
      if(hc == hBorder_right)
        R_hBorder <= 1;
    if(vc == vBorder_top)
      R_vBorder <= 0;
    else
      if(vc == vBorder_bottom)
        R_vBorder <= 1;
  end
  wire border = R_hBorder || R_vBorder;

  assign raster_line = vc[9:2];

  // Pixel co-ordinates
  wire [9:0] x = hc - hBorder_left2;
  wire [9:0] y = vc - vBorder_top;

  wire [15:0] char8x8_addr  = screen_addr + (y[8:4] * cols) + x[8:4];
  wire [15:0] char8x16_addr = screen_addr + (y[8:5] * cols) + x[8:4];
  reg   [7:0] current_char;

  wire  [7:3] xattr_early   = x[8:4] - HBattr;
  wire [15:0] attr8x8_addr  = color_ram_addr + (y[8:4] * cols) + xattr_early[7:3];
  wire [15:0] attr8x16_addr = color_ram_addr + (y[8:5] * cols) + xattr_early[7:3];
  reg   [2:0] fore_color;
  
  wire [13:0] cha8x8  = {char_rom_addr[15],char_rom_addr[12:0]} + {3'b0,current_char,y[3:1]};
  wire [13:0] cha8x16 = {char_rom_addr[15],char_rom_addr[12:0]} + {2'b0,current_char,y[4:1]};
  wire [15:0] char8x8_row_addr  = { cha8x8[13],2'b0, cha8x8[12:0]};
  wire [15:0] char8x16_row_addr = {cha8x16[13],2'b0,cha8x16[12:0]};

  reg   [7:0] R_pixel_data;
  wire pixel = inverted ? R_pixel_data[7] : ~R_pixel_data[7];

  reg R_pixel;
  reg [3:0] R_attr;
  reg [3:0] R_attr_delay;
  reg       multi_color;

  always @(posedge clk) begin
    if (x[0]) begin
      R_attr_delay <= R_attr;
      fore_color <= R_attr_delay[2:0];
      multi_color <= R_attr_delay[3];
      
      if (chars8x16)
        vga_addr <= char8x16_row_addr;
      else
        vga_addr <= char8x8_row_addr;
      
      if (x[3:1]) begin
        R_pixel_data <= {R_pixel_data[6:0],1'b0};
        if (x[3:1] == 6)
        begin
          if(chars8x16)
            vga_addr <= attr8x16_addr;
          else
            vga_addr <= attr8x8_addr;
        end
        if (x[3:1] == 7)
          R_attr <= vga_data[3:0];
      end else begin
        R_pixel_data <= vga_data;
      end
      
      R_pixel <= pixel;
    end else begin
      if (chars8x16)
        vga_addr <= char8x16_addr;
      else
        vga_addr <= char8x8_addr;
      current_char <= vga_data;
    end
  end

  wire [3:0] border_r = color_to_rgb[border_color][11:8];
  wire [3:0] border_g = color_to_rgb[border_color][7:4];
  wire [3:0] border_b = color_to_rgb[border_color][3:0];

  wire [4:0] back_r = color_to_rgb[back_color][11:8];
  wire [4:0] back_g = color_to_rgb[back_color][7:4];
  wire [4:0] back_b = color_to_rgb[back_color][3:0];

  reg [3:0] color_2bit;
  reg [3:0] R_color_2bit;

  always @(posedge clk) begin
    if (x[0]) R_color_2bit <= color_2bit;
  end

  always @(*) begin
    if (!x[1]) begin
      case ({R_pixel, pixel})
        2'b00: color_2bit = back_color;
	2'b01: color_2bit = {1'b0, border_color};
	2'b10: color_2bit = {1'b0, fore_color};
	2'b11: color_2bit = aux_color;
      endcase
    end else begin
      color_2bit = R_color_2bit;
    end
  end

  wire [3:0] char_color = multi_color ? color_2bit : fore_color;

  wire [4:0] fore_r = color_to_rgb[char_color][11:8];
  wire [3:0] fore_g = color_to_rgb[char_color][7:4];
  wire [3:0] fore_b = color_to_rgb[char_color][3:0];

  wire [3:0] red = border ? border_r : (R_pixel || multi_color ? fore_r : back_r);
  wire [3:0] green = border ? border_g : (R_pixel || multi_color ? fore_g : back_g);
  wire [3:0] blue = border ? border_b : (R_pixel || multi_color ? fore_b : back_b);

  assign vga_r = !vga_de ? 4'b0 : red;
  assign vga_g = !vga_de ? 4'b0 : green;
  assign vga_b = !vga_de ? 4'b0 : blue;

endmodule

