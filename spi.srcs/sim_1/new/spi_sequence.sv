`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_sequence
// Description:
//   UVM Sequences for SPI verification.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_SEQUENCE_SV
`define SPI_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// 1. All 4 SPI Modes Sequence (Mode 0, 1, 2, 3)
class spi_modes_sequence #(parameter int DATA_WIDTH = 8) extends uvm_sequence #(spi_transaction #(DATA_WIDTH));
    `uvm_object_param_utils(spi_modes_sequence #(DATA_WIDTH))

    function new(string name = "spi_modes_sequence");
        super.new(name);
    endfunction

    task body();
        spi_transaction #(DATA_WIDTH) tr;
        `uvm_info("SEQ_MODES", "=== Starting 4-Modes SPI Directed Sequence ===", UVM_LOW)

        // Mode 0: CPOL=0, CPHA=0
        `uvm_info("SEQ_MODES", "Testing Mode 0 (CPOL=0, CPHA=0)...", UVM_LOW)
        repeat (4) begin
            tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { cpol == 1'b0; cpha == 1'b0; });
            finish_item(tr);
        end

        // Mode 1: CPOL=0, CPHA=1
        `uvm_info("SEQ_MODES", "Testing Mode 1 (CPOL=0, CPHA=1)...", UVM_LOW)
        repeat (4) begin
            tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { cpol == 1'b0; cpha == 1'b1; });
            finish_item(tr);
        end

        // Mode 2: CPOL=1, CPHA=0
        `uvm_info("SEQ_MODES", "Testing Mode 2 (CPOL=1, CPHA=0)...", UVM_LOW)
        repeat (4) begin
            tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { cpol == 1'b1; cpha == 1'b0; });
            finish_item(tr);
        end

        // Mode 3: CPOL=1, CPHA=1
        `uvm_info("SEQ_MODES", "Testing Mode 3 (CPOL=1, CPHA=1)...", UVM_LOW)
        repeat (4) begin
            tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { cpol == 1'b1; cpha == 1'b1; });
            finish_item(tr);
        end
    endtask
endclass

// 2. Corner Case Sequence
class spi_corner_sequence #(parameter int DATA_WIDTH = 8) extends uvm_sequence #(spi_transaction #(DATA_WIDTH));
    `uvm_object_param_utils(spi_corner_sequence #(DATA_WIDTH))

    bit [DATA_WIDTH-1:0] corner_cases[$] = '{
        8'h00, 8'hFF, 8'hAA, 8'h55, 8'hA5, 8'h5A, 8'h01, 8'h80
    };

    function new(string name = "spi_corner_sequence");
        super.new(name);
    endfunction

    task body();
        spi_transaction #(DATA_WIDTH) tr;
        `uvm_info("SEQ_CORNER", "=== Starting Corner Cases Sequence ===", UVM_LOW)

        foreach (corner_cases[i]) begin
            tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with {
                master_tx_data == corner_cases[i];
                slave_tx_data  == ~corner_cases[i];
                cpol == 1'b0;
                cpha == 1'b0;
            });
            finish_item(tr);
        end
    endtask
endclass

// 3. Random Stimulus Sequence
class spi_random_sequence #(parameter int DATA_WIDTH = 8) extends uvm_sequence #(spi_transaction #(DATA_WIDTH));
    `uvm_object_param_utils(spi_random_sequence #(DATA_WIDTH))

    int unsigned num_transactions = 25;

    function new(string name = "spi_random_sequence");
        super.new(name);
    endfunction

    task body();
        spi_transaction #(DATA_WIDTH) tr;
        `uvm_info("SEQ_RAND", $sformatf("=== Starting Random Sequence (%0d items) ===", num_transactions), UVM_LOW)

        repeat (num_transactions) begin
            tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize()) begin
                `uvm_error("SEQ_RAND", "Randomization failed!")
            end
            finish_item(tr);
        end
    endtask
endclass

// 4. Combined Master Regression Sequence
class spi_regression_sequence #(parameter int DATA_WIDTH = 8) extends uvm_sequence #(spi_transaction #(DATA_WIDTH));
    `uvm_object_param_utils(spi_regression_sequence #(DATA_WIDTH))

    spi_corner_sequence #(DATA_WIDTH) corner_seq;
    spi_modes_sequence  #(DATA_WIDTH) modes_seq;
    spi_random_sequence #(DATA_WIDTH) rand_seq;

    function new(string name = "spi_regression_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ_REGRESS", "==================================================", UVM_LOW)
        `uvm_info("SEQ_REGRESS", "    STARTING COMPREHENSIVE SPI REGRESSION SUITE   ", UVM_LOW)
        `uvm_info("SEQ_REGRESS", "==================================================", UVM_LOW)

        `uvm_do(corner_seq)
        `uvm_do(modes_seq)
        `uvm_do(rand_seq)

        `uvm_info("SEQ_REGRESS", "=== SPI Regression Suite Completed Successfully ===", UVM_LOW)
    endtask
endclass

`endif // SPI_SEQUENCE_SV
