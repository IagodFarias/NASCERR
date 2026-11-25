`include "macros.svh"

// 4D4X TBEC-RSC decoder (V2 engineering adaptation, optimized solution).
// Ported from TBEC_RSC_8_4D4X_Verilog/tbec8_decoder.v (module tbec8_v2_decoder).
// Combinational; corrects DATA only (does not repair stored redundancy).
// The reference uses two helper functions (upper_check, fits_burst3); both are
// inlined here (no functions). The diagnostic outputs of the reference
// (syndrome, error mask, region, status) are kept as internal signals so the
// module keeps its data_in/data_out port list.
module tbec_rsc_4d4x_decoder (
  input  logic [15:0] data_in,
  output logic [ 7:0] data_out
);
  // region: 0=NONE, 1=R1, 2=R2, 3=R3, 4=REDUNDANCY, 5=UNKNOWN.
  // status: 0=NO_SYNDROME, 1=DATA_CORRECTED, 2=REDUNDANCY_ONLY, 3=UNCLASSIFIED.
  localparam logic [2:0] REGION_NONE    = 3'd0,
                         REGION_R1       = 3'd1,
                         REGION_R2       = 3'd2,
                         REGION_R3       = 3'd3,
                         REGION_RED      = 3'd4,
                         REGION_UNKNOWN  = 3'd5;
  localparam logic [1:0] STATUS_NONE      = 2'd0,
                         STATUS_CORRECTED = 2'd1,
                         STATUS_RED       = 2'd2,
                         STATUS_UNKNOWN   = 2'd3;

  logic [7:0]  data_rx;
  logic [7:0]  check_rx;
  logic [7:0]  expected_check;
  logic [7:0]  syndrome;
  logic [3:0]  sx;

  logic [7:0]  mask_r1, mask_r2, mask_r3;

  logic [3:0]  upper_check_r1, upper_check_r2, upper_check_r3;
  logic [3:0]  residual1, residual2, residual3;
  logic [15:0] hypothesis1, hypothesis2, hypothesis3;

  logic [15:0] em_red;
  logic [15:0] lowest_one_red, lowest_one_1, lowest_one_2, lowest_one_3;
  logic [15:0] window3_red,    window3_1,    window3_2,    window3_3;

  logic        redundancy_only;
  logic        valid_r1, valid_r2, valid_r3;

  logic [7:0]  selected_data_mask;
  logic [2:0]  selected_region;
  logic [1:0]  selected_status;

  assign data_rx  = data_in[15:8];
  assign check_rx = data_in[7:0];

  assign expected_check[7] = data_rx[7] ^ data_rx[4] ^ data_rx[3];
  assign expected_check[6] = data_rx[5] ^ data_rx[6] ^ data_rx[1];
  assign expected_check[5] = data_rx[3] ^ data_rx[0] ^ data_rx[6];
  assign expected_check[4] = data_rx[1] ^ data_rx[2] ^ data_rx[4];
  assign expected_check[3] = data_rx[7] ^ data_rx[3];
  assign expected_check[2] = data_rx[5] ^ data_rx[1];
  assign expected_check[1] = data_rx[6] ^ data_rx[2];
  assign expected_check[0] = data_rx[4] ^ data_rx[0];

  assign syndrome = check_rx ^ expected_check;
  assign sx       = syndrome[3:0];

  // The position of the X syndrome components determines candidate data masks.
  assign mask_r1 = {sx[3], sx[1], sx[2], sx[0], 4'b0000};
  assign mask_r2 = {4'b0000, sx[3], sx[1], sx[2], sx[0]};
  assign mask_r3 = {2'b00, sx[2], sx[0], sx[3], sx[1], 2'b00};

  // Inlined upper_check(data_mask): 4 MSBs of f(data_mask), per region.
  assign upper_check_r1[3] = mask_r1[7] ^ mask_r1[4] ^ mask_r1[3];
  assign upper_check_r1[2] = mask_r1[5] ^ mask_r1[6] ^ mask_r1[1];
  assign upper_check_r1[1] = mask_r1[3] ^ mask_r1[0] ^ mask_r1[6];
  assign upper_check_r1[0] = mask_r1[1] ^ mask_r1[2] ^ mask_r1[4];

  assign upper_check_r2[3] = mask_r2[7] ^ mask_r2[4] ^ mask_r2[3];
  assign upper_check_r2[2] = mask_r2[5] ^ mask_r2[6] ^ mask_r2[1];
  assign upper_check_r2[1] = mask_r2[3] ^ mask_r2[0] ^ mask_r2[6];
  assign upper_check_r2[0] = mask_r2[1] ^ mask_r2[2] ^ mask_r2[4];

  assign upper_check_r3[3] = mask_r3[7] ^ mask_r3[4] ^ mask_r3[3];
  assign upper_check_r3[2] = mask_r3[5] ^ mask_r3[6] ^ mask_r3[1];
  assign upper_check_r3[1] = mask_r3[3] ^ mask_r3[0] ^ mask_r3[6];
  assign upper_check_r3[0] = mask_r3[1] ^ mask_r3[2] ^ mask_r3[4];

  assign residual1 = syndrome[7:4] ^ upper_check_r1;
  assign residual2 = syndrome[7:4] ^ upper_check_r2;
  assign residual3 = syndrome[7:4] ^ upper_check_r3;

  assign hypothesis1 = {mask_r1, residual1, 4'b0000};
  assign hypothesis2 = {mask_r2, residual2, 4'b0000};
  assign hypothesis3 = {mask_r3, residual3, 4'b0000};

  // Inlined fits_burst3(error_mask): nonzero error mask confined to a 3-position
  // physical window starting at its lowest set bit.
  //   lowest_one = error_mask & (~error_mask + 1)
  //   window3    = lowest_one | (lowest_one<<1) | (lowest_one<<2)
  //   fits       = (error_mask != 0) && ((error_mask & ~window3) == 0)

  // H=[Q|I]: if only redundancy is corrupted, the syndrome IS its error mask.
  assign em_red         = {8'h00, syndrome};
  assign lowest_one_red = em_red & (~em_red + 16'h0001);
  assign window3_red    = lowest_one_red | (lowest_one_red << 1) | (lowest_one_red << 2);
  assign redundancy_only = (em_red != 16'h0000) &&
                           ((em_red & ~window3_red) == 16'h0000);

  assign lowest_one_1 = hypothesis1 & (~hypothesis1 + 16'h0001);
  assign window3_1    = lowest_one_1 | (lowest_one_1 << 1) | (lowest_one_1 << 2);
  assign valid_r1     = (mask_r1 != 8'h00) && (hypothesis1 != 16'h0000) &&
                        ((hypothesis1 & ~window3_1) == 16'h0000);

  assign lowest_one_2 = hypothesis2 & (~hypothesis2 + 16'h0001);
  assign window3_2    = lowest_one_2 | (lowest_one_2 << 1) | (lowest_one_2 << 2);
  assign valid_r2     = (mask_r2 != 8'h00) && (hypothesis2 != 16'h0000) &&
                        ((hypothesis2 & ~window3_2) == 16'h0000);

  assign lowest_one_3 = hypothesis3 & (~hypothesis3 + 16'h0001);
  assign window3_3    = lowest_one_3 | (lowest_one_3 << 1) | (lowest_one_3 << 2);
  assign valid_r3     = (mask_r3 != 8'h00) && (hypothesis3 != 16'h0000) &&
                        ((hypothesis3 & ~window3_3) == 16'h0000);

  // Priority: zero > redundancy > R1 > R2 > R3 > unknown.
  always_comb begin
    selected_data_mask = 8'h00;
    selected_region    = REGION_UNKNOWN;
    selected_status    = STATUS_UNKNOWN;
    if (syndrome == 8'h00) begin
      selected_region = REGION_NONE;
      selected_status = STATUS_NONE;
    end else if (redundancy_only) begin
      selected_region = REGION_RED;
      selected_status = STATUS_RED;
    end else if (valid_r1) begin
      selected_data_mask = mask_r1;
      selected_region    = REGION_R1;
      selected_status    = STATUS_CORRECTED;
    end else if (valid_r2) begin
      selected_data_mask = mask_r2;
      selected_region    = REGION_R2;
      selected_status    = STATUS_CORRECTED;
    end else if (valid_r3) begin
      selected_data_mask = mask_r3;
      selected_region    = REGION_R3;
      selected_status    = STATUS_CORRECTED;
    end
  end

  assign data_out = data_rx ^ selected_data_mask;
endmodule
