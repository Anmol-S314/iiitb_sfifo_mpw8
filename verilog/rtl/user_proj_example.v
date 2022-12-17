
// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire CLK;
    wire RSTn;
    wire [7:0] iData;
    wire [7:0] oData;
    wire write;
    wire read;
    wire full;
    wire empty;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

   

    // IO
    assign CLK = wb_clk_i;
    assign RSTn = wb_rst_i;
    assign iData = io_in[37:30];
    assign write = io_in[29];
    assign read = io_in[28];
    assign oData = io_out[37:30];
    assign full = io_out[29];
    assign empty = io_out[28];
    assign io_oeb = 0;

    // IRQ
    assign irq = 3'b000;	// Unused

	iiitb_sfifo instance (CLK,RSTn,write,read,iData,oData,full,empty);
    

endmodule
module iiitb_sfifo(input CLK, input RSTn, input write, input read, input[7:0] iData, output[7:0] oData, output full, output empty);

reg [4:0] wp;          //write point should add 1 bit(N+1) 
reg [4:0] rp;          //read point
reg [7:0] RAM [15:0];  //deep16,8 bit RAM
reg [7:0] oData_reg;   //regsiter of oData

always @ ( posedge CLK or negedge RSTn )
begin                  //write to RAM
	if (!RSTn)
	begin
		wp <= 5'b0;
	end
	else if ( write )
	begin
		RAM[wp[3:0]] <= iData;
		wp <= wp + 1'b1;
	end
end

always @ ( posedge CLK or negedge RSTn )
begin                  // read from RAM
	if (!RSTn)
	begin
		rp <= 5'b0;
		oData_reg <= 8'b0;
	end
	else if ( read  )
	begin
		oData_reg <= RAM[rp[3:0]];
		rp <= rp + 1'b1;
	end
end


assign full = ( wp[4] ^ rp[4] & wp[3:0] == rp[3:0] );
assign empty = ( wp == rp );
assign oData = oData_reg;


endmodule

