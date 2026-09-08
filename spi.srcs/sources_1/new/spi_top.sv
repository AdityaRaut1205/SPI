`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_top
// Module Name: spi_top
// Project Name: spi
// Description:
//   Top-level integration connecting Parameterized SPI Master and SPI Slave.
//   Provides parallel interfaces for Master and Slave along with direct access
//   to the physical SPI bus wires (SCLK, MOSI, MISO, CS_N).
//   Enables simultaneous full-duplex communication verification.
//////////////////////////////////////////////////////////////////////////////////

module spi_top #(
    parameter int DATA_WIDTH   = 8,
    parameter int CLK_DIV      = 4,
    parameter bit DEFAULT_CPOL = 1'b0,
    parameter bit DEFAULT_CPHA = 1'b0
)(
    input  logic                  clk,
    input  logic                  rst,
    // Master Parallel Interface
    input  logic                  start,
    input  logic                  cpol,
    input  logic                  cpha,
    input  logic [DATA_WIDTH-1:0] master_tx_data,
    output logic [DATA_WIDTH-1:0] master_rx_data,
    output logic                  master_busy,
    output logic                  master_done,
    // Slave Parallel Interface
    input  logic [DATA_WIDTH-1:0] slave_tx_data,
    input  logic                  slave_tx_load,
    output logic [DATA_WIDTH-1:0] slave_rx_data,
    output logic                  slave_rx_valid,
    // Physical SPI Bus Probes
    output logic                  spi_sclk_out,
    output logic                  spi_mosi_out,
    output logic                  spi_miso_out,
    output logic                  spi_cs_n_out
);

    wire spi_sclk;
    wire spi_mosi;
    wire spi_miso;
    wire spi_cs_n;

    // Pull-up on MISO line (when slave tri-states, MISO pulls up to 1)
    tri1 spi_miso_bus;
    assign spi_miso_bus = spi_miso;

    assign spi_sclk_out = spi_sclk;
    assign spi_mosi_out = spi_mosi;
    assign spi_miso_out = spi_miso_bus;
    assign spi_cs_n_out = spi_cs_n;

    // Instantiate SPI Master
    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV),
        .DEFAULT_CPOL(DEFAULT_CPOL),
        .DEFAULT_CPHA(DEFAULT_CPHA)
    ) u_master (
        .clk(clk),
        .rst(rst),
        .start(start),
        .cpol(cpol),
        .cpha(cpha),
        .tx_data(master_tx_data),
        .rx_data(master_rx_data),
        .busy(master_busy),
        .done(master_done),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_cs_n(spi_cs_n),
        .spi_miso(spi_miso_bus)
    );

    // Instantiate SPI Slave
    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEFAULT_CPOL(DEFAULT_CPOL),
        .DEFAULT_CPHA(DEFAULT_CPHA)
    ) u_slave (
        .clk(clk),
        .rst(rst),
        .cpol(cpol),
        .cpha(cpha),
        .slave_tx_data(slave_tx_data),
        .slave_tx_load(slave_tx_load),
        .slave_rx_data(slave_rx_data),
        .slave_rx_valid(slave_rx_valid),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
    );

endmodule
