module top
  import typedefs::*;
#(
  // Selects the TBEC-RSC encoder/decoder implementation (passed to control):
  //   0 = 2D2P4X, 1 = 4D4X, any other value = current (default) implementation.
  parameter int TBEC_RSC_ALGORITHM = 0
)
(
  input sel_t       sel,
  input logic       read_en,
  input logic       write_en,
  inout wire  [7:0] cpu_data,
  inout wire  [7:0] ram_up_data,
  inout wire  [7:0] ram_down_data
);
  logic cpu_oe, ram_up_oe, ram_down_oe;
  logic [7:0] cpu_data_out, ram_up_data_out, ram_down_data_out;

  control #(.TBEC_RSC_ALGORITHM(TBEC_RSC_ALGORITHM)) control0 (
    .sel(sel),
    .read_en(read_en),
    .write_en(write_en),
    .cpu_data_in(cpu_data),
    .cpu_data_out(cpu_data_out),
    .ram_up_data_in(ram_up_data),
    .ram_up_data_out(ram_up_data_out),
    .ram_down_data_in(ram_down_data),
    .ram_down_data_out(ram_down_data_out),
    .cpu_oe(cpu_oe),
    .ram_up_oe(ram_up_oe),
    .ram_down_oe(ram_down_oe)
  );

  assign cpu_data      = cpu_oe ? cpu_data_out : 8'hZZ;
  assign ram_up_data   = ram_up_oe ? ram_up_data_out : 8'hZZ;
  assign ram_down_data = ram_down_oe ? ram_down_data_out : 8'hZZ;
endmodule
