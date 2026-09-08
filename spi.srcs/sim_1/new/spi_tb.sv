`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_tb
// Description:
//   Top-level UVM Testbench module for SPI.
//   Instantiates:
//     - 100 MHz Clock generator (10ns period)
//     - Reset generator sequence
//     - SystemVerilog interface
//     - Top-level DUT (spi_top)
//     - UVM Configuration DB registration and run_test()
//     - Waveform dump for Vivado XSim
//////////////////////////////////////////////////////////////////////////////////

import uvm_pkg::*;
`include "uvm_macros.svh"

// Include UVM class components in dependency order
`include "spi_transaction.sv"
`include "spi_sequence.sv"
`include "spi_sequencer.sv"
`include "spi_driver.sv"
`include "spi_monitor.sv"
`include "spi_coverage.sv"
`include "spi_scoreboard.sv"
`include "spi_agent.sv"
`include "spi_env.sv"
`include "spi_test.sv"

module spi_tb;

    localparam int DATA_WIDTH = 8;
    localparam int CLK_DIV    = 4;

    logic clk;
    logic rst;

    // Instantiate SystemVerilog Interface
    spi_interface #(DATA_WIDTH) vif(clk, rst);

    // Instantiate Top-level DUT
    spi_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV)
    ) dut (
        .clk(clk),
        .rst(rst),
        // Master Interface
        .start(vif.start),
        .cpol(vif.cpol),
        .cpha(vif.cpha),
        .master_tx_data(vif.master_tx_data),
        .master_rx_data(vif.master_rx_data),
        .master_busy(vif.master_busy),
        .master_done(vif.master_done),
        // Slave Interface
        .slave_tx_data(vif.slave_tx_data),
        .slave_tx_load(vif.slave_tx_load),
        .slave_rx_data(vif.slave_rx_data),
        .slave_rx_valid(vif.slave_rx_valid),
        // Physical SPI Bus Probes
        .spi_sclk_out(vif.spi_sclk),
        .spi_mosi_out(vif.spi_mosi),
        .spi_miso_out(vif.spi_miso),
        .spi_cs_n_out(vif.spi_cs_n)
    );

    // 100 MHz Clock Generator (Period = 10ns, 5ns High / 5ns Low)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Active-High Reset Sequence
    initial begin
        rst = 1'b1;
        #50;
        @(posedge clk);
        rst = 1'b0;
    end

    // UVM Test Execution
    initial begin
        uvm_config_db#(virtual spi_interface #(DATA_WIDTH))::set(null, "*", "vif", vif);
        run_test("spi_test");
    end

    // Waveform dump for Vivado XSim
    initial begin
        $dumpfile("spi_sim.vcd");
        $dumpvars(0, spi_tb);
    end

endmodule
