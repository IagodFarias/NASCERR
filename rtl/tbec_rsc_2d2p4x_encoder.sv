// 2D2P4X TBEC-RSC encoder (V3 engineering adaptation).
// Ported from TBEC_RSC_8_2D2P4X_VERILOG/tbec8_encoder.v.
// Codeword layout: {data_in, checks}. The 8 redundancy ("checks") bits are
// D1 D2 P1 P2 XA13 XA24 XB13 XB24 (checks[7] .. checks[0]).
module tbec_rsc_2d2p4x_encoder (
  input  logic [ 7:0] data_in,
  output logic [15:0] data_out
);
  logic [7:0] checks;

  assign checks[7] = data_in[5] ^ data_in[3] ^ data_in[0];
  assign checks[6] = data_in[7] ^ data_in[5] ^ data_in[4] ^ data_in[1];
  assign checks[5] = data_in[7] ^ data_in[6] ^ data_in[5] ^ data_in[4];
  assign checks[4] = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];
  assign checks[3] = data_in[7] ^ data_in[3];
  assign checks[2] = data_in[5] ^ data_in[1];
  assign checks[1] = data_in[6] ^ data_in[2];
  assign checks[0] = data_in[4] ^ data_in[0];

  assign data_out = {data_in, checks};
endmodule
