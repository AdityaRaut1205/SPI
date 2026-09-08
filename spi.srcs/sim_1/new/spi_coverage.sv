`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_coverage
// Description:
//   Functional Coverage Collector for SPI verification.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_coverage #(parameter int DATA_WIDTH = 8) extends uvm_subscriber #(spi_transaction #(DATA_WIDTH));
    `uvm_component_param_utils(spi_coverage #(DATA_WIDTH))

    spi_transaction #(DATA_WIDTH) cov_item;

    covergroup spi_cg;
        cp_master_tx: coverpoint cov_item.master_tx_data {
            bins zero      = {8'h00};
            bins all_ones  = {8'hFF};
            bins alt_aa    = {8'hAA};
            bins alt_55    = {8'h55};
            bins low_range = {[8'h01:8'h3F]};
            bins mid_range = {[8'h40:8'hBF]};
            bins hi_range  = {[8'hC0:8'hFE]};
        }

        cp_slave_tx: coverpoint cov_item.slave_tx_data {
            bins zero      = {8'h00};
            bins all_ones  = {8'hFF};
            bins alt_aa    = {8'hAA};
            bins alt_55    = {8'h55};
            bins low_range = {[8'h01:8'h3F]};
            bins mid_range = {[8'h40:8'hBF]};
            bins hi_range  = {[8'hC0:8'hFE]};
        }

        cp_cpol: coverpoint cov_item.cpol {
            bins idle_low  = {1'b0};
            bins idle_high = {1'b1};
        }

        cp_cpha: coverpoint cov_item.cpha {
            bins first_edge  = {1'b0};
            bins second_edge = {1'b1};
        }

        cross_modes: cross cp_cpol, cp_cpha {
            bins mode_0 = binsof(cp_cpol.idle_low)  && binsof(cp_cpha.first_edge);
            bins mode_1 = binsof(cp_cpol.idle_low)  && binsof(cp_cpha.second_edge);
            bins mode_2 = binsof(cp_cpol.idle_high) && binsof(cp_cpha.first_edge);
            bins mode_3 = binsof(cp_cpol.idle_high) && binsof(cp_cpha.second_edge);
        }

        cp_delay: coverpoint cov_item.delay {
            bins zero_delay = {0};
            bins small_delay = {[1:3]};
            bins larger_delay = {[4:10]};
        }
    endgroup

    function new(string name = "spi_coverage", uvm_component parent = null);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    virtual function void write(spi_transaction #(DATA_WIDTH) t);
        cov_item = t;
        spi_cg.sample();
    endfunction

endclass

`endif // SPI_COVERAGE_SV
