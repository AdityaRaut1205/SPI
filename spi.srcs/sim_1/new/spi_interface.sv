`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_interface
// Description:
//   SystemVerilog Interface for SPI verification environment.
//   Bundles Master control, Slave control, and physical SPI bus signals.
//////////////////////////////////////////////////////////////////////////////////

interface spi_interface #(parameter int DATA_WIDTH = 8) (
    input logic clk,
    input logic rst
);

    // Master signals
    logic                  start;
    logic                  cpol;
    logic                  cpha;
    logic [DATA_WIDTH-1:0] master_tx_data;
    logic [DATA_WIDTH-1:0] master_rx_data;
    logic                  master_busy;
    logic                  master_done;

    // Slave signals
    logic [DATA_WIDTH-1:0] slave_tx_data;
    logic                  slave_tx_load;
    logic [DATA_WIDTH-1:0] slave_rx_data;
    logic                  slave_rx_valid;

    // Physical bus probes
    logic                  spi_sclk;
    logic                  spi_mosi;
    logic                  spi_miso;
    logic                  spi_cs_n;

    // Clocking block for driver
    clocking cb_drv @(posedge clk);
        default input #1ns output #1ns;
        output start, cpol, cpha, master_tx_data, slave_tx_data, slave_tx_load;
        input  master_busy, master_done, master_rx_data, slave_rx_data, slave_rx_valid;
    endclocking

    // Clocking block for monitor
    clocking cb_mon @(posedge clk);
        default input #1ns output #1ns;
        input start, cpol, cpha, master_tx_data, master_rx_data, master_busy, master_done;
        input slave_tx_data, slave_tx_load, slave_rx_data, slave_rx_valid;
        input spi_sclk, spi_mosi, spi_miso, spi_cs_n;
    endclocking

    modport DRIVER  (clocking cb_drv, input clk, rst);
    modport MONITOR (clocking cb_mon, input clk, rst);

endinterface
