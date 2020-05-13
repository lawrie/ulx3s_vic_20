`default_nettype none
module vic20 (
  // Main clock, 25MHz
  input         clk25_mhz,
  // Buttons
  input [6:0]   btn,
  // Keyboard
  output        usb_fpga_pu_dp,
  output        usb_fpga_pu_dn,
  input         ps2_clk,
  input         ps2_data,
  // Video
  output [3:0]  red,
  output [3:0]  green,
  output [3:0]  blue,
  output        hsync,
  output        vsync,
  // HDMI
  output [3:0]  gpdi_dp, 
  output [3:0]  gpdi_dn,
  // Audio
  output  [3:0] audio_l, 
  output  [3:0] audio_r,
  // ESP32 passthru
  input         ftdi_txd,
  output        ftdi_rxd,
  input         wifi_txd,
  output        wifi_rxd,  // SPI from ESP32
  // SPI control
  input         wifi_gpio16,
  input         wifi_gpio5,
  output        wifi_gpio0,
  inout         sd_clk, sd_cmd,
  inout   [3:0] sd_d,
  // Leds
  output [7:0]  leds,
  output reg [15:0] diag
);

   // passthru to ESP32 micropython serial console
   assign wifi_rxd = ftdi_txd;
   assign ftdi_rxd = wifi_txd;

   // PS/2 pull-ups
   assign usb_fpga_pu_dp = 1;
   assign usb_fpga_pu_dn = 1;

   // ===============================================================
   // System Clock generation (25MHz)
   // ===============================================================
   wire clk25, clk_dvi, locked;

   pll pll_i (
     .clkin(clk25_mhz),
     .clkout0(clk_dvi),
     .clkout1(clk25),
     .locked(locked)
   );

   // ===============================================================
   // Wires/Reg definitions
   // TODO: reorganize so all defined here
   // ===============================================================

   reg         hard_reset_n;
   reg [15:0]  address;
   reg [7:0]   cpu_dout;
   reg [7:0]   vid_dout;
   reg         cpu_clken;
   reg         rnw;
   reg         via1_clken;
   reg         via4_clken;
   wire [1:0]  turbo = 0;
   wire        p2_h;
   wire [7:0]  v_data = cpu_dout;
   wire [7:0]  ram_dout;
   wire        via_cs = (address[15:8] == 8'h91);
   wire        clk_vga = clk25;

   always @(posedge clk25) diag <= 0;
       
   // ===============================================================
   // Joystick for OSD control and games
   // ===============================================================

   wire [6:0] R_btn_joy;
   always @(posedge clk25)
     R_btn_joy <= btn;
     //R_btn_joy <= btn | { usb_buttons[7],usb_buttons[6],usb_buttons[5],usb_buttons[4],usb_buttons[0],usb_buttons[1],1'b0};

   // ===============================================================
   // SPI Slave for RAM and CPU control
   // ===============================================================
  
   wire        spi_ram_wr, spi_ram_rd;
   wire [31:0] spi_ram_addr;
   wire  [7:0] spi_ram_di;
   wire  [7:0] spi_ram_do = ram_dout;

   assign sd_d[3] = 1'bz; // FPGA pin pullup sets SD card inactive at SPI bus

   wire irq;
   spi_ram_btn
   #(
     .c_sclk_capable_pin(1'b0),
     .c_addr_bits(32)
   )
   spi_ram_btn_inst
   (
     .clk(clk25),
     .csn(~wifi_gpio5),
     .sclk(wifi_gpio16),
     .mosi(sd_d[1]), // wifi_gpio4
     .miso(sd_d[2]), // wifi_gpio12
     .btn(R_btn_joy),
     .irq(irq),
     .wr(spi_ram_wr),
     .rd(spi_ram_rd),
     .addr(spi_ram_addr),
     .data_in(spi_ram_do),
     .data_out(spi_ram_di)
   );
   assign wifi_gpio0 = ~irq;

   reg [7:0] R_cpu_control;
   always @(posedge clk25) begin
     if (spi_ram_wr && spi_ram_addr[31:24] == 8'hFF) begin
       R_cpu_control <= spi_ram_di;
     end
   end

   // ===============================================================
   // Clock Enable Generation
   // ===============================================================

   reg [4:0] clkdiv = 5'b00000;  // divider, from 25MHz down to 1, 2, 4MHz

   always @(posedge clk25) begin
      if (clkdiv == 24)
        clkdiv <= 0;
      else
        clkdiv <= clkdiv + 1;
      case (turbo)
        2'b00: // 1MHz
          begin
             cpu_clken  <= (clkdiv[3:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
             via1_clken <= (clkdiv[3:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
             via4_clken <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
          end
        2'b01: // 2MHz
          begin
             cpu_clken  <= (clkdiv[2:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
             via1_clken <= (clkdiv[2:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
             via4_clken <= (clkdiv[0]   == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
          end
        default: // 4MHz
          begin
             cpu_clken  <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
             via1_clken <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0) & ~R_cpu_control[1];
             via4_clken <=                      (clkdiv[4] == 0) & ~R_cpu_control[1];
          end
      endcase
   end

   // ===============================================================
   // Reset generation
   // ===============================================================

   reg [15:0] pwr_up_reset_counter = 0; // hold reset low for ~1ms
   wire       pwr_up_reset_n = &pwr_up_reset_counter;

   always @(posedge clk25)
     begin
        if (cpu_clken)
          begin
             if (!pwr_up_reset_n)
               pwr_up_reset_counter <= pwr_up_reset_counter + 1;
             hard_reset_n <= pwr_up_reset_n;
          end
     end

   wire reset = reset_key | !hard_reset_n | !btn[0] | R_cpu_control[0];

   // ===============================================================
   // Keyboard
   // ===============================================================

   wire [10:0] ps2_key;
   wire [7:0]  kbd_col_out;
   wire [7:0]  kbd_col_out_oe_n;
   wire [7:0]  kbd_col_out_s = kbd_col_out | kbd_col_out_oe_n;
   wire [7:0]  kbd_col_in;
   wire [7:0]  kbd_row_out;
   wire [7:0]  kbd_row_out_oe_n;
   wire [7:0]  kbd_row_in;
   wire [7:0]  kbd_row_out_s = kbd_row_out | kbd_row_out_oe_n;
   wire        reset_key;
   wire        kbd_restore;

   // Get PS/2 keyboard events
   ps2 ps2_kbd (
      .clk(clk25),
      .ps2_clk(ps2_clk),
      .ps2_data(ps2_data),
      .ps2_key(ps2_key)
   );

   keyboard kbd (
     .clk(clk25),
     .ps2_key(ps2_key),
     .pbi({kbd_col_out_s[3], kbd_col_out_s[6:4], kbd_col_out_s[7], kbd_col_out_s[2:0]}),
     .pbo(kbd_col_in),
     .pai({kbd_row_out_s[0], kbd_row_out_s[6:1], kbd_row_out_s[7]}),
     .pao(kbd_row_in),
     .reset_key(reset_key),
     .restore_key(kbd_restore),
    . backwardsReadingEnabled(1'b1)
   );

   // ===============================================================
   // 6502 CPU
   // ===============================================================

   wire [7:0]  cpu_din;
   wire [7:0]  cpu_dout_c;
   wire [15:0] address_c;
   wire        rnw_c;

   // Arlet's 6502 core is one of the smallest available
   cpu CPU
     (
      .clk(clk25),
      .reset(reset),
      .AB(address_c),
      .DI(cpu_din),
      .DO(cpu_dout_c),
      .WE(rnw_c),
      .IRQ(!via2_irq_n),
      .NMI(!via1_nmi_n),
      .RDY(cpu_clken)
      );

   // The outputs of Arlets's 6502 core need registing
   always @(posedge clk25)
     begin
        if (cpu_clken)
          begin
             address  <= address_c;
             cpu_dout <= cpu_dout_c;
             rnw      <= !rnw_c;
          end
     end

   // ===============================================================
   // RAM
   // ===============================================================

   wire [15:0] vga_addr;
   wire [7:0] vid_out;
   
   wire address_rom = address[15:12]==4'h8 
                   || address[15:12]==4'hC
                   || address[15:12]==4'hD
                   || address[15:12]==4'hE
                   || address[15:12]==4'hF;

   dpram #(
     .MEM_INIT_FILE("../roms/vic20.mem")
   )ram64(
     .clk_a(clk25),
     .we_a(R_cpu_control[1] ? spi_ram_wr && spi_ram_addr[31:24] == 8'h00 : !rnw && address_rom == 1'b0),
     .addr_a(R_cpu_control[1] ? spi_ram_addr[15:0] : address),
     .din_a(R_cpu_control[1] ? spi_ram_di : cpu_dout),
     .dout_a(ram_dout),
     .clk_b(clk_vga),
     .addr_b(vga_addr),
     .dout_b(vid_out)
   );

   wire [7:0] raster_line;

   /* VIC20 Keyboard Matrix
   9
   1  Write to Port B($9120)column
   2  Read from Port A($9121)row
   1
      7   6   5   4   3   2   1   0
     -------------------------------- 9120
   7| F7  F5  F3  F1  CDN CRT RET DEL    CRT=Cursor-Right, CDN=Cursor-Down
   6| HOM UA  =   RSH /   ;   *   BP     BP=British Pound, RSH=Should be Right-SHIFT,
   5| -   @   :   .   ,   L   P   +
   4| 0   O   K   M   N   J   I   9
   3| 8   U   H   B   V   G   Y   7
   2| 6   T   F   C   X   D   R   5      LSH=Should be Left-SHIFT
   1| 4   E   S   Z   LSH A   W   3      LA=Left Arrow, CTL=Should be CTRL, STP=RUN/STOP
   0| 2   Q   CBM SPC STP CTL LA  1      CBM=Commodore key
   */
   reg [7:0] last_ddr2b_out; // B2
   always @(posedge clk25) if (via_cs && address[5] && address[3:0] == 4'h2 && !rnw) last_ddr2b_out <= cpu_dout; 

   assign cpu_din = address == 16'h9004  ? raster_line :
                    via_cs && address[4] && (address[3:0] == 4'h1 || address[3:0] == 4'hF)  ? {2'b11, ~btn[1], ~btn[5:4], ~btn[3], 2'b11} :
                    via_cs && address[4] ? via1_dout :
                    via_cs && address[5] && (address[3:0] == 4'h1 || address[3:0] == 4'hF)  ? {kbd_row_in[0], kbd_row_in[6:1], kbd_row_in[7]} :
                    via_cs && address[5] &&  address[3:0] == 4'h0 && last_ddr2b_out[7] == 0 ? {~btn[6] /*& kbd_col_in[3]*/, kbd_col_in[6:4], kbd_col_in[7], kbd_col_in[2:0]} :
                    via_cs && address[5] ? via2_dout :
                                           ram_dout;

   // ===============================================================
   // 6522 VIAs
   // ===============================================================

   wire [7:0] via1_dout;
   wire via1_nmi_n;
   wire [7:0] via2_dout;
   wire via2_irq_n;
   wire [7:0] via1_pa_in = {2'b11, ~btn[1],~btn[5],~btn[4],~btn[3], 2'b11};
   wire [7:0] via1_pa_out;

   m6522 VIA1
     (
      .I_RS(address[3:0]),
      .I_DATA(v_data),
      .O_DATA(via1_dout),
      .O_DATA_OE_L(),
      .I_RW_L(rnw),
      .I_CS1(address[4]),
      .I_CS2_L(!via_cs),
      .O_IRQ_L(via1_nmi_n),
      .I_CA1(kbd_restore),
      .I_CA2(1'b0),
      .O_CA2(),
      .O_CA2_OE_L(),
      .I_PA(via1_pa_in),
      .O_PA(via1_pa_out),
      .O_PA_OE_L(),
      .I_CB1(1'b0),
      .O_CB1(),
      .O_CB1_OE_L(),
      .I_CB2(1'b0),
      .O_CB2(),
      .O_CB2_OE_L(),
      .I_PB(8'b0),
      .O_PB(),
      .O_PB_OE_L(),
      .I_P2_H(via1_clken),
      .RESET_L(!reset),
      .ENA_4(via4_clken),
      .CLK(clk25)
   );

   m6522 VIA2
     (
      .I_RS(address[3:0]),
      .I_DATA(v_data),
      .O_DATA(via2_dout),
      .O_DATA_OE_L(),
      .I_RW_L(rnw),
      .I_CS1(address[5]),
      .I_CS2_L(!via_cs),
      .O_IRQ_L(via2_irq_n),
      .I_CA1(1'b0),
      .I_CA2(1'b0),
      .O_CA2(),
      .O_CA2_OE_L(),
      .I_PA({kbd_row_in[0], kbd_row_in[6:1], kbd_row_in[7]}),
      .O_PA(kbd_row_out),
      .O_PA_OE_L(kbd_row_out_oe_n),
      .I_CB1(1'b0),
      .O_CB1(),
      .O_CB1_OE_L(),
      .I_CB2(1'b0),
      .O_CB2(),
      .O_CB2_OE_L(),
      .I_PB({kbd_col_in[3], kbd_col_in[6:4], kbd_col_in[7], kbd_col_in[2:0]}),
      .O_PB(kbd_col_out),
      .O_PB_OE_L(kbd_col_out_oe_n),
      .I_P2_H(via1_clken),
      .RESET_L(!reset),
      .ENA_4(via4_clken),
      .CLK(clk25)
   );

   // ===============================================================
   // Audio
   // ===============================================================
   
   reg [7:0] r_base_sound;
   reg [7:0] r_alto_sound;
   reg [7:0] r_soprano_sound;
   reg [7:0] r_noise_sound;
   reg [3:0] r_amplitude;
   wire [5:0] audio_out;

   always @(posedge clk25) begin
     if (!rnw && address[15:8] == 8'h90) begin
       case (address[3:0]) 
         4'ha: r_base_sound <= cpu_dout;
	 4'hb: r_alto_sound <= cpu_dout;
	 4'hc: r_soprano_sound <= cpu_dout;
	 4'hd: r_noise_sound <= cpu_dout;
         4'he: r_amplitude <= cpu_dout[3:0];
       endcase
     end
   end

   audio audio_i (
     .i_clk(clk25),
     .i_ena4(via4_clken),
     .i_base_sound(r_base_sound),
     .i_alto_sound(r_alto_sound),
     .i_soprano_sound(r_soprano_sound),
     .i_noise_sound(r_noise_sound),
     .i_amplitude(r_amplitude),
     .o_audio(audio_out)
   );

   assign audio_l = audio_out[5:2];
   assign audio_r = audio_out[5:2];

   // ===============================================================
   // VGA
   // ===============================================================
   wire vga_de;
   reg [15:0] r_screen_addr = 16'h1e00;
   reg [15:0] r_char_rom_addr = 16'h8000;
   reg [15:0] r_color_ram_addr = 16'h9400;
   reg [2:0]  r_border_color;
   reg [3:0]  r_back_color;
   reg [3:0]  r_aux_color;
   reg        r_inverted;
   reg        r_chars8x16;
   reg [6:0]  r_xorigin = 12;
   reg [7:0]  r_yorigin = 38;
   reg [6:0]  r_cols = 22;
   reg [6:0]  r_rows = 23;

   // Set start addresses for screen and character rom
   always @(posedge clk25) begin
     if (!rnw && address[15:4] == 12'h900) begin

       if (address[3:0] == 4'h0) begin
	 r_xorigin <= cpu_dout[6:0];
       end

       if (address[3:0] == 4'h1) begin
	 r_yorigin <= cpu_dout;
       end

       // Columns and extra bit for screen and color ram address
       if (address[3:0] == 4'h2) begin
         r_screen_addr[9] <= cpu_dout[7];
         r_color_ram_addr[9] <= cpu_dout[7];
	 r_cols <= cpu_dout[6:0];
       end

       // Rows and 8x16 characters
       if (address[3:0] == 4'h3) begin
         r_chars8x16 <= cpu_dout[0];
         r_rows <= cpu_dout[6:0];
       end

       // Screen and character rom address
       if (address[3:0] == 4'h5) begin
         r_char_rom_addr[15] <= ~cpu_dout[3];
         r_char_rom_addr[12:10] <= cpu_dout[2:0];
         r_screen_addr[15] <= ~cpu_dout[7];
         r_screen_addr[12:10] <= cpu_dout[6:4];
       end

       // Set auxilliary color info
       if (address[3:0] == 4'he) begin
         r_aux_color <= cpu_dout[7:4];
       end

       // Set border and background colors
       if (address[3:0] == 4'hf) begin
         r_border_color <= cpu_dout[2:0];
         r_inverted <= cpu_dout[3];
         r_back_color <= cpu_dout[7:4];
       end
     end
   end

   video vga (
     .clk(clk_vga),
     .vga_r(red),
     .vga_g(green),
     .vga_b(blue),
     .vga_de(vga_de),
     .vga_hs(hsync),
     .vga_vs(vsync),
     .vga_addr(vga_addr),
     .vga_data(vid_out),
     .raster_line(raster_line),
     .screen_addr(r_screen_addr),
     .char_rom_addr(r_char_rom_addr),
     .color_ram_addr(r_color_ram_addr),
     .border_color(r_border_color),
     .back_color(r_back_color),
     .inverted(r_inverted),
     .chars8x16(r_chars8x16),
     .aux_color(r_aux_color),
     .xorigin(r_xorigin),
     .yorigin(r_yorigin),
     .cols(r_cols),
     .rows(r_rows)
   );

   // ===============================================================
   // SPI Slave for OSD display
   // ===============================================================

   wire [7:0] osd_vga_r, osd_vga_g, osd_vga_b;
   wire osd_vga_hsync, osd_vga_vsync, osd_vga_blank;
   spi_osd
   #(
     .c_start_x(62), .c_start_y(80),
     .c_chars_x(64), .c_chars_y(20),
     .c_init_on(0),
     .c_char_file("osd.mem"),
     .c_font_file("font_bizcat8x16.mem")
   )
   spi_osd_inst
   (
     .clk_pixel(clk_vga), .clk_pixel_ena(1),
     .i_r({red,   {4{red[0]}}   }),
     .i_g({green, {4{green[0]}} }),
     .i_b({blue,  {4{blue[0]}}  }),
     .i_hsync(~hsync), .i_vsync(~vsync), .i_blank(~vga_de),
     .i_csn(~wifi_gpio5), .i_sclk(wifi_gpio16), .i_mosi(sd_d[1]), // .o_miso(),
     .o_r(osd_vga_r), .o_g(osd_vga_g), .o_b(osd_vga_b),
     .o_hsync(osd_vga_hsync), .o_vsync(osd_vga_vsync), .o_blank(osd_vga_blank)
   );


   // Convert VGA to HDMI
   HDMI_out vga2dvid (
     .pixclk(clk_vga),
     .pixclk_x5(clk_dvi),
     .red(osd_vga_r),
     .green(osd_vga_g),
     .blue(osd_vga_b),
     .vde(~osd_vga_blank),
     .hSync(~osd_vga_hsync),
     .vSync(~osd_vga_vsync),
     .gpdi_dp(gpdi_dp),
     .gpdi_dn(gpdi_dn)
   );

   // ===============================================================
   // LEDs
   // ===============================================================

   reg        led1;
   reg        led2;
   reg        led3;
   reg        led4;
   reg        led5;
   reg        led6;
   reg        led7;
   reg        led8;

   always @(posedge clk25)
     begin
        led1 <= !via2_irq_n;  // red
        led2 <= !via1_nmi_n;  // yellow
        led3 <= reset_key;    // green
        led4 <= reset;        // blue
	led5 <= kbd_restore;  // red
	led6 <= ~r_inverted;  // yellow
	led7 <= 0;            // green
	led8 <= 0;            // blue
     end

   // Diagnostics
   assign leds = {led8, led7, led6, led5, led4, led3, led2, led1};

endmodule
