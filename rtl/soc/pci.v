module pci (
	input			clk,
	input			rst_n,
    
	// IO slave.
	input   [15:0] io_address,
	input				io_read,
	output  [31:0] io_readdata,
	output			io_readdatavalid,
	input    [2:0] io_read_length,
	
	input				io_write,
	input   [31:0] io_writedata,
	output			io_waitrequest,
	input    [2:0] io_write_length,	

	// Avalon mem bus.
	input	  [29:0] avm_address,		// WORD address!
	input   [31:0] avm_writedata,
	input    [3:0] avm_byteenable,
	input    [3:0] avm_burstcount,
	input          avm_write,
	input          avm_read,
	 
	output  			avm_waitrequest,
	output	 		avm_readdatavalid,
	output  [31:0] avm_readdata,
	
	output			pci_io_access,
	output			pci_cs_claim,
	output			pci_wait,
	output			pci_devsel_claim,	
	
	output			pci_irq_out,
	
	inout   [31:0] PCI_AD,
	inout    [3:0] PCI_CBE,
	inout				PCI_PAR,
	
	inout				PCI_IDSEL,		// Used to select the PCI Config Regs. Only asserted/seen during the Address phase. Can toggle after that.
	
	inout				PCI_REQ_N,		// Ignored atm. Driven by the master, to request use of the bus.
	inout				PCI_GNT_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Used by the arbiter, to grant bus access.
	
	inout				PCI_SERR_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Address/data/special parity error.
	inout				PCI_PERR_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Parity error, expect Special Cycle.
	
	inout				PCI_SBO_N,		// ignored atm. Snoop Backoff (Snoop Dogg's Russian cousin).
	inout				PCI_SDONE,		// ignored atm. Snoop Done.
	inout				PCI_LOCK_N,		// ignored atm. Used to implement exclusive access on the PCI bus.
	inout				PCI_STOP_N,		// ignored atm. FROM the target (card), used to abort a transfer.
	
	inout				PCI_FRAME_N,	// Asserted by the host to denote the start and end of a PCI transaction. (or for ONE clock cycle for IDSEL).
	
	input				PCI_DEVSEL_N,	// Asserted by the device (card) when it decodes a valid address. (or when it sees IDSEL during the addr phase).
	input				PCI_TRDY_N,		// Asserted by the Target (device) when it is able to transfer data.
	
	inout				PCI_IRDY_N,		// Asserted by the Initiator (usually the host) when it is able to transfer data.
	
	output			PCI_CLK,			// 33 MHz clock to the card.
	output			PCI_RST_N,		// Reset_n to the card.
	
	input				PCI_PRSNT1_N,	// ignored atm.
	input				PCI_PRSNT2_N,	// ignored atm.
	
	input				PCI_INTA_N,		// Signal routed to pci_irq_out, but not hooked up to ao486 just yet. Will use ao486 IRQ11 for this. ElectronAsh.
	input				PCI_INTB_N,		// ignored atm.
	input				PCI_INTC_N,		// ignored atm.
	input				PCI_INTD_N		// ignored atm.
);

/*
	// IO slave.
	input       [15:0] io_address,
	input              io_read,
	output wire [31:0] io_readdata,
	output reg 		    io_readdatavalid,
	input       [2:0]  io_read_length,
	
	input              io_write,
	input       [31:0] io_writedata,
	output             io_waitrequest,
	input       [2:0]  io_write_length,	

	// Avalon mem bus.
	input       [29:0] avm_address,		// WORD address!
	input       [31:0] avm_writedata,
	input       [3:0]  avm_byteenable,
	input       [3:0]  avm_burstcount,
	input              avm_write,
	input              avm_read,
	 
	output             avm_waitrequest,
	output reg         avm_readdatavalid,
	output wire [31:0] avm_readdata,
*/

(*keep*) wire [31:0] avm_byteaddress = {avm_address, 2'b00};

// Default start address for where the Bochs BIOs maps BAR0, for the first PCI device.
(*keep*) wire pci_c0000000_cs  = (avm_byteaddress>=32'hC0000000 && avm_byteaddress<=32'hDFFFFFFF);
(*keep*) wire pci_vga_mem_cs   = (avm_byteaddress>=32'h000A0000 && avm_byteaddress<=32'h000BFFFF);	// 128K VGA Mem.
(*keep*) wire pci_bios_mem_cs  = (avm_byteaddress>=32'h0000C000 && avm_byteaddress<=32'h0000DFFF);	// 8K VGA BIOS.

(*keep*) wire pci_mem_cs = pci_c0000000_cs /*| pci_vga_mem_cs*/;

(*keep*) wire [31:0] pci_address = pci_mem_cs ? avm_byteaddress : {16'h0000,io_address};

(*keep*) wire pci_cfg_cs    = (io_address>=16'h0CF8 && io_address<=16'h0CFF);
(*keep*) wire pci_vga_io_cs = (io_address>=16'h03B0 && io_address<=16'h03DF);

(*keep*) wire pci_io_cs = pci_cfg_cs /*| pci_vga_io_cs*/;


(*keep*) wire pci_io_write  = (pci_io_cs && io_write);
(*keep*) wire pci_mem_write = (pci_mem_cs && avm_write);
(*keep*) wire [31:0] pci_writedata = pci_mem_cs ? (avm_writedata) : io_writedata;
(*keep*) wire  [3:0] pci_byteenable = pci_mem_cs ? avm_byteenable : 4'b1111;


(*keep*) wire pci_io_read  = (pci_io_cs && io_read);
assign io_readdata  = pci_readdata;
assign io_readdatavalid  = pci_readdata_valid & pci_io_access;

(*keep*) wire pci_mem_read = (pci_mem_cs && avm_read);
assign avm_readdata = pci_readdata;
assign avm_readdatavalid = pci_readdata_valid & !pci_io_access;


// NOTE: Most "cs" signals here will only be active during the same clock cycle as pci_read/pci_write.
// pci_wait should then stay High for the whole PCI request cycle.

assign pci_cs_claim = pci_mem_cs | pci_io_cs | pci_wait /*| pci_devsel_claim*/;

assign avm_waitrequest = pci_wait;
assign io_waitrequest  = pci_wait;

// pci_wait is used to inhibit the CPU read/write signals on the L2 cache block.


pci_interface pci_interface_inst
(
	.clk(clk) ,											// input  clk
	.rst_n(rst_n) ,									// input  rst_n
	
	.pci_address(pci_address) ,					// input  [31:0] pci_address
	
	.pci_io_write(pci_io_write) ,					// input  pci_io_write
	.pci_mem_write(pci_mem_write) ,				//	input  pci_mem_write
	.pci_writedata(pci_writedata) ,				// input  [31:0] pci_writedata
	.pci_byteenable(pci_byteenable) ,			// input  [3:0] pci_byteenable

	.pci_io_read(pci_io_read) ,					// input  pci_io_read
	.pci_mem_read(pci_mem_read) ,					// input  pci_mem_read	
	.pci_readdata(pci_readdata) ,					// output [31:0] pci_readdata
	.pci_readdata_valid(pci_readdata_valid) ,	// output pci_readdata_valid

	.pci_special(pci_special) ,					// input   pci_special
	
	.pci_wait(pci_wait) ,							// output  pci_wait
	.pci_io_access(pci_io_access) ,				// output  pci_io_access
	
	.pci_devsel_claim(pci_devsel_claim) ,		// output  pci_devsel_claim
	.pci_trdy_timeout(pci_trdy_timeout) ,		// output  pci_trdy_timeout
	.pci_serr(pci_serr) ,							// output  pci_serr
	.pci_perr(pci_perr) ,							// output  pci_perr
	
	.pci_irq_out(pci_irq_out) ,					// output  pci_irq_out
	.pci_irq_ack(pci_irq_ack) ,					// input  pci_irq_ack
	
	.PCI_AD(PCI_AD) ,									// inout [31:0] PCI_AD
	.PCI_CBE(PCI_CBE) ,								// inout [3:0] PCI_CBE
	.PCI_PAR(PCI_PAR) ,								// inout  PCI_PAR
	.PCI_IDSEL(PCI_IDSEL) ,							// inout  PCI_IDSEL
	.PCI_REQ_N(PCI_REQ_N) ,							// inout  PCI_REQ_N
	.PCI_GNT_N(PCI_GNT_N) ,							// inout  PCI_GNT_N
	.PCI_SERR_N(PCI_SERR_N) ,						// inout  PCI_SERR_N
	.PCI_PERR_N(PCI_PERR_N) ,						// inout  PCI_PERR_N
	.PCI_SBO_N(PCI_SBO_N) ,							// inout  PCI_SBO_N
	.PCI_SDONE(PCI_SDONE) ,							// inout  PCI_SDONE
	.PCI_LOCK_N(PCI_LOCK_N) ,						// inout  PCI_LOCK_N
	.PCI_STOP_N(PCI_STOP_N) ,						// inout  PCI_STOP_N
	.PCI_FRAME_N(PCI_FRAME_N) ,					// inout  PCI_FRAME_N
	.PCI_DEVSEL_N(PCI_DEVSEL_N) ,					// input  PCI_DEVSEL_N
	.PCI_TRDY_N(PCI_TRDY_N) ,						// input  PCI_TRDY_N
	.PCI_IRDY_N(PCI_IRDY_N) ,						// inout  PCI_IRDY_N
	.PCI_CLK(PCI_CLK) ,								// output  PCI_CLK
	.PCI_RST_N(PCI_RST_N) ,							// output  PCI_RST_N
	.PCI_PRSNT1_N(PCI_PRSNT1_N) ,					// input  PCI_PRSNT1_N
	.PCI_PRSNT2_N(PCI_PRSNT2_N) ,					// input  PCI_PRSNT2_N
	.PCI_INTA_N(PCI_INTA_N) ,						// input  PCI_INTA_N
	.PCI_INTB_N(PCI_INTB_N) ,						// input  PCI_INTB_N
	.PCI_INTC_N(PCI_INTC_N) ,						// input  PCI_INTC_N
	.PCI_INTD_N(PCI_INTD_N) 						// input  PCI_INTD_N
);


endmodule
