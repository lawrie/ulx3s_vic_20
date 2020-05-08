`default_nettype none
module audio (
  input        i_clk,
  input        i_ena4,
  input [3:0]  i_amplitude,
  input [7:0]  i_base_sound,
  input [7:0]  i_alto_sound,
  input [7:0]  i_soprano_sound,
  input [7:0]  i_noise_sound,
  output [5:0] o_audio
);

  reg [9:0] audio_div = 0;
  reg [9:0] audio_div_t1 = 0;
  reg audio_div_256;
  reg audio_div_128;
  reg audio_div_64;
  reg audio_div_16;

  reg base_sg;
  reg [6:0] base_sg_freq;
  reg [6:0] base_sg_cnt = 0;

  reg alto_sg;
  reg [6:0] alto_sg_freq;
  reg [6:0] alto_sg_cnt;

  reg soprano_sg;
  reg [6:0] soprano_sg_freq;
  reg [6:0] soprano_sg_cnt;

  reg  noise_sg;
  reg [6:0] noise_sg_freq;
  reg [6:0] noise_sg_cnt = 0;
  reg [18:0]  noise_gen = 0;

  reg [3:0] audio_wav;
  reg [7:0] audio_mul_out;

  wire noise_zero = (noise_gen == 0);
  
  always @(posedge i_clk) begin
    // bass       freq f=Phi2/256/(128-(($900a+1)&127))
    // alto       freq f=Phi2/128/(128-(($900b+1)&127))
    // soprano    freq f=Phi2/64/(128-(($900c+1) &127))
    // noise      freq f=Phi2/32/(128-(($900d+1) &127)) -- not true about the divider !
    if (i_ena4) begin
      audio_div <= audio_div + 1;
      audio_div_t1 <= audio_div;
      //  /256 /4 (phi = clk4 /4) *2 as toggling output
      audio_div_256 <= audio_div[8] & !audio_div_t1[8];
      audio_div_128 <= audio_div[7] & !audio_div_t1[7];
      audio_div_64  <= audio_div[6] & !audio_div_t1[6];
      audio_div_16  <= audio_div[4] & !audio_div_t1[4];
    end 
  end

  always @(posedge i_clk) begin
    if (i_ena4) begin
      base_sg_freq    <= 7'b1111111 - i_base_sound[6:0];
      alto_sg_freq    <= 7'b1111111 - i_alto_sound[6:0];
      soprano_sg_freq <= 7'b1111111 - i_soprano_sound[6:0];
      noise_sg_freq   <= 7'b1111111 - i_noise_sound[6:0];

      if (audio_div_256) begin
        if (base_sg_cnt == 0) begin
          base_sg_cnt <= base_sg_freq[6:0] - 1; // note wrap around for 0 case
          base_sg <= !base_sg;
        end else begin
          base_sg_cnt <= base_sg_cnt - 1;
        end
      end

      if (audio_div_128) begin
        if (alto_sg_cnt == 0) begin
          alto_sg_cnt <= alto_sg_freq[6:0] - 1;
          alto_sg <= !alto_sg;
        end else begin
          alto_sg_cnt <= alto_sg_cnt - 1;
        end
      end

      if (audio_div_64) begin
        if (soprano_sg_cnt == 0) begin
          soprano_sg_cnt <= soprano_sg_freq[6:0] - 1;
          soprano_sg <= !soprano_sg;
        end else begin
          soprano_sg_cnt <= soprano_sg_cnt - 1;
        end
      end

      if (audio_div_16) begin
        if (noise_sg_cnt == 0) begin
          noise_sg_cnt <= noise_sg_freq[6:0] - 1;
          noise_gen[10:2] <= noise_gen[17:1];
          noise_gen[1] <= noise_gen[0] ^ noise_zero;
          noise_gen[0] <= noise_gen[0] ^ noise_gen[1] ^ noise_gen[4] ^ noise_gen[18];
          noise_sg <= noise_gen[9];
        end else begin
          noise_sg_cnt <= noise_sg_cnt - 1;
        end
      end
    end
  end

  // Mixer
  assign o_audio = (i_base_sound[7] & base_sg ? {2'b0, i_amplitude} : 6'b0) +
	           (i_alto_sound[7] & alto_sg ? {2'b0, i_amplitude} : 6'b0) +
	    	   (i_soprano_sound[7] & soprano_sg ? {2'b0, i_amplitude} : 6'b0) +
                   (i_noise_sound[7] & noise_sg ? {2'b0, i_amplitude} : 6'b0);
endmodule

