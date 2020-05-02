`default_nettype none
module vic20
   (
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
	     // Leds
	     output [7:0]  leds,
	     output reg [15:0] diag
             );

   // PS/2 pull-ups
   assign usb_fpga_pu_dp = 1;
   assign usb_fpga_pu_dn = 1;

   // Diagnostics
   assign leds = {led8, led7, led6, led5, led4, led3, led2, led1};
   
   // ===============================================================
   // Parameters
   // ===============================================================

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

   always @(posedge clk25) diag <= address;

   // ===============================================================
   // Wires/Reg definitions
   // TODO: reorganize so all defined here
   // ===============================================================

   reg         hard_reset_n;
   reg [15:0]  address;
   reg [7:0]   cpu_dout;
   reg [7:0]   vid_dout;
   reg         cpu_clken;
   reg         cpu_clken1;
   reg         rnw;
   wire        via1_cs;
   wire        via2_cs;
   reg         via1_clken;
   reg         via4_clken;
   wire [1:0]  turbo;

   // ===============================================================
   // VGA Clock generation (25MHz/12.5MHz)
   // ===============================================================

   wire vga_blank;
   wire clk_vga = clk25;

   // ===============================================================
   // Clock Enable Generation
   // ===============================================================
   reg [4:0] clkdiv = 5'b00000;  // divider, from 25MHz down to 1, 2, 4 or 8MHz

   always @(posedge clk25) begin
      if (clkdiv == 24)
        clkdiv <= 0;
      else
        clkdiv <= clkdiv + 1;
      case (turbo)
        2'b00: // 1MHz
          begin
             cpu_clken  <= (clkdiv[3:0] == 0) & (clkdiv[4] == 0);
             via1_clken <= (clkdiv[3:0] == 0) & (clkdiv[4] == 0);
             via4_clken <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0);
          end
        2'b01: // 2MHz
          begin
             cpu_clken  <= (clkdiv[2:0] == 0) & (clkdiv[4] == 0);
             via1_clken <= (clkdiv[2:0] == 0) & (clkdiv[4] == 0);
             via4_clken <= (clkdiv[0]   == 0) & (clkdiv[4] == 0);
          end
        default: // 4MHz
          begin
             cpu_clken  <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0);
             via1_clken <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0);
             via4_clken <=                      (clkdiv[4] == 0);
          end
      endcase
      cpu_clken1 <= cpu_clken;
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

   wire reset = !hard_reset_n | !btn[0];

   // ===============================================================
   // Keyboard
   // ===============================================================

   wire [4:0]  key_data;
   wire [11:1] Fn;
   wire [2:0]  mod;
   wire [10:0] ps2_key;

   // Get PS/2 keyboard events
   ps2 ps2_kbd (
      .clk(clk25),
      .ps2_clk(ps2_clk),
      .ps2_data(ps2_data),
      .ps2_key(ps2_key)
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
        led1 <= 0;  // red     - indicates alt colour set active
        led2 <= 0;        // yellow  - indicates SD card activity
        led3 <= 0;       // green   - indicates rept key pressed
        led4 <= reset;      // blue    - indicates reset active
	led5 <= 0;
	led6 <= 0;
	led7 <= 0;
	led8 <= 0;
     end

   assign audio_l = 0;
   assign audio_r = 0;

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
      .NMI(1'b0),
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
   // Address decoding logic and data in multiplexor
   // ===============================================================

   wire [7:0] ram_dout;

   dpram #(
     .MEM_INIT_FILE("../roms/vic20.mem")
   )ram64(
     .clk_a(clk25),
     .we_a(!rnw),
     .addr_a(address),
     .din_a(cpu_dout),
     .dout_a(ram_dout)
   );

   assign cpu_din = ram_dout;

   // ===============================================================
   // 6522 VIAs
   // ===============================================================

   wire [7:0] via1_dout;
   wire via1_irq_n;
   wire [7:0] via2_dout;
   wire via2_irq_n;

   m6522 VIA1
     (
      .I_RS(address[3:0]),
      .I_DATA(cpu_dout),
      .O_DATA(via1_dout),
      .O_DATA_OE_L(),
      .I_RW_L(rnw),
      .I_CS1(via1_cs),
      .I_CS2_L(1'b0),
      .O_IRQ_L(via1_irq_n),
      .I_CA1(1'b0),
      .I_CA2(1'b0),
      .O_CA2(),
      .O_CA2_OE_L(),
      .I_PA(8'b0),
      .O_PA(),
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
      .I_DATA(cpu_dout),
      .O_DATA(via2_dout),
      .O_DATA_OE_L(),
      .I_RW_L(rnw),
      .I_CS1(via2_cs),
      .I_CS2_L(1'b0),
      .O_IRQ_L(via2_irq_n),
      .I_CA1(1'b0),
      .I_CA2(1'b0),
      .O_CA2(),
      .O_CA2_OE_L(),
      .I_PA(8'b0),
      .O_PA(),
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

   // Convert VGA to HDMI
   HDMI_out vga2dvid (
     .pixclk(clk_vga),
     .pixclk_x5(clk_dvi),
     .red({red, 4'b0}),
     .green({green, 4'b0}),
     .blue({blue, 4'b0}),
     .vde(!vga_blank),
     .hSync(hsync),
     .vSync(vsync),
     .gpdi_dp(gpdi_dp),
     .gpdi_dn(gpdi_dn)
   );
endmodule