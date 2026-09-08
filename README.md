# Design & UVM Verification of Parameterized SPI Controller

A synthesizable full-duplex Serial Peripheral Interface (SPI) Master and Slave core designed in SystemVerilog with configurable clock prescaling, programmable data width, and full 4-mode (CPOL/CPHA) support, verified using a layered UVM 1.2 testbench in AMD Vivado.

---

## 📌 Features & Specifications

- **Protocol:** 4-Wire Synchronous Full-Duplex Serial Peripheral Interface (`SCLK`, `MOSI`, `MISO`, `CS_N`)
- **System Clock:** 100 MHz (T = 10 ns)
- **Configurable SCLK Frequency:** Parameterized integer divider `CLK_DIV` (`F_SCLK = F_CLK / (2 * CLK_DIV)`). For `CLK_DIV = 4`, `F_SCLK = 12.5 MHz` (at 100 MHz reference clock)
- **Configurable Data Width:** Parameterized `DATA_WIDTH` (8, 16, 32 bits, default: 8-bit)
- **All 4 SPI Modes Supported:**
  - **Mode 0 (`CPOL=0, CPHA=0`):** SCLK idles LOW; Data sampled on rising edge, shifted on falling edge
  - **Mode 1 (`CPOL=0, CPHA=1`):** SCLK idles LOW; Data shifted on rising edge, sampled on falling edge
  - **Mode 2 (`CPOL=1, CPHA=0`):** SCLK idles HIGH; Data sampled on falling edge, shifted on rising edge
  - **Mode 3 (`CPOL=1, CPHA=1`):** SCLK idles HIGH; Data shifted on falling edge, sampled on rising edge
- **Bus Integrity:** High-impedance tri-state buffer on `MISO` line during inactive slave selection (`CS_N = 1`)
- **Framing & Timing:** Enforces standard setup (`T_CSS`) and hold (`T_CSH`) delays before and after SCLK toggling
- **Verification Methodology:** Layered UVM 1.2 testbench featuring constrained-random stimulus, boundary corner cases, 100% cross-coverage of CPOL x CPHA, and self-checking scoreboards
- **Scoreboard:** Dual FIFO queue-based comparator (`expected_mosi_q[$]` and `expected_miso_q[$]`) validating simultaneous bi-directional full-duplex transmission
- **Simulation Result:** 49/49 transactions verified with 0 mismatches, 0 protocol errors, and 0 UVM errors

---

## 🏗️ Architecture

### RTL Top Module (`spi_top.sv`)
```
                          +------------------------------------+
                          |              spi_top               |
                          |                                    |
   clk, rst_n ───────────►|                                    |
                          |  +------------------------------+  |
   tx_data[7:0] ─────────►|  |          spi_master          |  |
   tx_valid, cpol, cpha ─►|  |                              |  |
   tx_ready ◄─────────────|  |  +------------------------+  |  |
   rx_data[7:0] ◄─────────|  |  | SCLK Divider Generator  |  |  |
   rx_valid ◄─────────────|  |  +------------------------+  |  |
                          |  +--------------+---------------+  |
                          |                 |                  |
                          |      sclk       |                  |
                          |   +-------------+--------------+   |
                          |   |  mosi                      |   |
                          |   |  cs_n                      |   |
                          |   |  miso                      |   |
                          |   v                            v   |
                          |  +------------------------------+  |
   slave_tx_data ────────►|  |          spi_slave           |  |
   slave_rx_data ◄────────|  |                              |  |
   slave_rx_valid ◄───────|  |  Tri-state MISO (Z on CS_N=1)|  |
                          |  +------------------------------+  |
                          +------------------------------------+
```

### UVM Testbench Hierarchy
```
+-----------------------------------------------------------------------------------+
|                                     spi_test                                      |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                                   spi_env                                   |  |
|  |                                                                             |  |
|  |  +-------------------------+      +------------------+      +-------------+ |  |
|  |  |        spi_agent        |      |  spi_scoreboard  |      |spi_coverage | |  |
|  |  |                         |      |                  |      |             | |  |
|  |  |  +--------------------+ |      | +--------------+ |      | Covergroups | |  |
|  |  |  |    spi_sequence    | |      | |expected_mosi_q |      | - CPOL      | |  |
|  |  |  +---------+----------+ |      | |expected_miso_q |      | - CPHA      | |  |
|  |  |            |            |      | +-------+------+ |      | - CPOLxCPHA | |  |
|  |  |            v            |      |         ^        |      | - Data Bins | |  |
|  |  |  +--------------------+ |      +---------|--------+      +------+------+ |  |
|  |  |  |    spi_sequencer   | |                |                      ^        |  |
|  |  |  +---------+----------+ |                |                      |        |  |
|  |  |            |            |                |                      |        |  |
|  |  |            v            |   item_port    |                      |        |  |
|  |  |  +--------------------+ |                |                      |        |  |
|  |  |  |     spi_driver     +-+----------------+                      |        |  |
|  |  |  +---------+----------+ |                                       |        |  |
|  |  |            |            |   mon_port                            |        |  |
|  |  |            v            |                                       |        |  |
|  |  |  +--------------------+ +---------------------------------------+        |  |
|  |  |  |    spi_monitor     +-+------------------------------------------------+  |
|  |  |  +--------------------+ |                                                |  |
|  |  +------------+------------+                                                |  |
|  +---------------|-------------------------------------------------------------+  |
+------------------|----------------------------------------------------------------+
                   |
                   v (via virtual interface vif)
          +-----------------+
          |     spi_top     |
          +-----------------+
```

---

## 📁 Repository Structure

```
SPI/
├── docs/                                # Technical Documentation & PDF Reports
│   ├── SPI_Complete_Master_Handbook.pdf # 5-page Complete Architecture, RTL & Verification Handbook
│   ├── SPI_Project_Report.pdf           # Technical Architecture & Specification Report
│   ├── SPI_Master_Interview_Report.pdf  # 20+ Protocol & Verification Interview Q&A
│   ├── SPI_Waveform_Analysis_Guide.pdf  # Timing Diagrams & Edge Sampling Analysis across Modes 0-3
│   └── 00_MASTER_INDEX.pdf              # Index of all project modules and design files
│
├── spi.srcs/
│   ├── sources_1/new/                   # Synthesizable RTL Design Sources
│   │   ├── spi_master.sv                # Parameterized Master Controller (SCLK gen, FSM, Shift Reg)
│   │   ├── spi_slave.sv                 # Synchronous SPI Slave with Tri-State MISO buffer
│   │   └── spi_top.sv                   # Top-level hardware wrapper interconnecting Master & Slave
│   │
│   └── sim_1/new/                       # UVM 1.2 Verification Testbench
│       ├── spi_interface.sv             # Interface with clocking blocks & directional modports
│       ├── spi_transaction.sv           # UVM sequence item (data, mode, delay constraints)
│       ├── spi_sequence.sv              # Directed corner-case, 4-mode sweep, & random sequences
│       ├── spi_sequencer.sv             # Arbitration sequencer for stimulus flow
│       ├── spi_driver.sv                # Pin-level driver with mode settling & clock synchronization
│       ├── spi_monitor.sv               # Passive dual-channel bus monitor capturing MOSI & MISO
│       ├── spi_coverage.sv              # Functional coverage (CPOL x CPHA cross, data ranges)
│       ├── spi_scoreboard.sv            # In-order dual FIFO comparator & verification report generator
│       ├── spi_agent.sv                 # Reusable UVM agent encapsulation
│       ├── spi_env.sv                   # Top environment integrating agent, scoreboard, coverage
│       ├── spi_test.sv                  # Test classes (spi_test regression, spi_rand_test)
│       └── spi_tb.sv                    # Simulation top (100 MHz clock generation, interface instantiation)
│
├── spi.xpr                              # AMD Vivado Project File
├── .gitignore                           # Vivado temporary & build artifact exclusions
└── README.md                            # Project documentation
```

---

## 🧪 Verification Strategy

### 1. Stimulus Generation (`spi_sequence.sv`)
- **Corner Cases:**
  - `0x00` (All zeros — ensures data bits are not confused with idle state)
  - `0xFF` (All ones — verifies high data lines under multi-cycle transmission)
  - `0xAA` & `0x55` (Alternating bit patterns — tests maximum toggling rate)
  - `0x01` & `0x80` (Walking boundary bits — checks MSB/LSB shift ordering)
- **4-Mode Sweep:**
  - Sequences systematically targeting Mode 0, Mode 1, Mode 2, and Mode 3 to verify correct polarity and phase shifting before and during transfer.
- **Constrained-Random Testing:**
  - Dynamic inter-transfer idle delays (0 to 10 clock cycles).
  - Independent random data streams on Master and Slave channels to rigorously validate bi-directional full-duplex communication.

### 2. Functional Coverage Model (`spi_coverage.sv`)
- **Mode Coverage:** 100% cross-coverage of `cpol_cp` x `cpha_cp` covering all 4 standard SPI operational modes.
- **Data Range Bins:**
  - `low`: `[8'h00 : 8'h3F]`
  - `mid`: `[8'h40 : 8'hBF]`
  - `high`: `[8'hC0 : 8'hFF]`

### 3. Dual-Channel Scoreboard (`spi_scoreboard.sv`)
- **MOSI Path:** Tracks data transmitted by Master into `expected_mosi_q[$]` and validates against bytes captured at Slave output.
- **MISO Path:** Tracks data pre-loaded into Slave into `expected_miso_q[$]` and validates against bytes sampled by Master receiver.
- **Queue Drain Assertion:** Confirms at end-of-test (`check_phase`) that both FIFO queues are completely empty (`size() == 0`), proving no dropped or duplicated packets.

---

## 📊 Simulation Results

Simulated in **AMD Vivado 2025.1 XSim** with UVM 1.2:

```text
--------------------------------------------------------
               SPI VERIFICATION REPORT                  
--------------------------------------------------------
 Total SPI Transactions : 49
 Mode 0 (0,0) Count     : 17
 Mode 1 (0,1) Count     : 12
 Mode 2 (1,0) Count     : 8
 Mode 3 (1,1) Count     : 12
--------------------------------------------------------
 MOSI Path Matches      : 49
 MOSI Path Mismatches   : 0
 MISO Path Matches      : 49
 MISO Path Mismatches   : 0
--------------------------------------------------------
  *** ALL SPI TRANSACTIONS MATCHED SUCCESSFULLY! ***   
--------------------------------------------------------

--- UVM Report Summary ---
** Report counts by severity
UVM_INFO    : 82
UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

---

## 🚀 How to Run Simulation

### Option 1: In AMD Vivado GUI
1. Launch Vivado and open the project:
   ```text
   File -> Open Project -> C:/Users/adiir/Desktop/Project_files/spi/spi.xpr
   ```
2. In the **Flow Navigator** panel, click:
   ```text
   Simulation -> Run Simulation -> Run Behavioral Simulation
   ```
3. The testbench automatically runs the comprehensive regression suite, logs all UVM reports in the Tcl Console, and renders the waveforms (`sclk`, `mosi`, `miso`, `cs_n`).
4. To run for a custom duration, execute in the Tcl Console:
   ```tcl
   run -all
   ```

### Option 2: Command Line (Batch Mode)
From PowerShell or Command Prompt, navigate to the simulation folder and launch the batch script:
```powershell
cd C:\Users\adiir\Desktop\Project_files\spi\spi.sim\sim_1\behav\xsim
.\simulate.bat
```

---

## 📖 Technical Documentation

Detailed PDF documentation, interview questions with answers, and timing analysis guides are available in the [`docs/`](docs/) directory:
- [SPI Complete Master Handbook](docs/SPI_Complete_Master_Handbook.pdf) (5-page all-in-one comprehensive guide)
- [SPI Project Report](docs/SPI_Project_Report.pdf)
- [SPI Master Interview Q&A Report](docs/SPI_Master_Interview_Report.pdf)
- [SPI Waveform Analysis Guide](docs/SPI_Waveform_Analysis_Guide.pdf)
