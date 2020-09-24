module pci_interface (
	input			clk,
	input			rst_n,
   
	input  [31:0] pci_address,			// BYTE address! So will need {avm_address,2'b00} for mem accesses.

	input			  pci_io_write,		// Single pulse input.
	input			  pci_mem_write,		// Single pulse input.
	input  [31:0] pci_writedata,
	input   [3:0] pci_byteenable,		// Only used for WRITE requests. Active-HIGH!

	input			  pci_io_read,			// Single pulse input.
	input			  pci_mem_read,		// Single pulse input.
	output [31:0] pci_readdata,		// A PCI access timeout will always return 0xFFFFFFFF on pci_readdata.
	output		  pci_readdata_valid,
	
	input			  pci_mem_sel,			// Select Mem access when High, IO port access when Low.
												// If pci_mem_sel is Low, and the IO Port address is 0xCF8-0xCFF,
												// then a PCI Config access will be generated.
	
	input			  pci_special,			// Select Special cycle access.

	output		  pci_wait,				// Stays high after a pci_read or pci_write pulse, until the transfer has finished, or timeout has occurred.
	output		  pci_io_access,

	output reg	  pci_devsel_claim,	// A PCI device claimed the CFG/IO/Mem request by driving PCI_DEVSEL_N low. Stays HIGH to include readata_valid!
	output reg	  pci_trdy_timeout,	// A PCI device didn't respond with TRDY within the expected number of clock cycles. (single-pulse output).

	output		  pci_serr,				// A PCI device generated an Address/Special-cycle error.
	output		  pci_perr,				// A PCI device generated a Parity error.

	output		  pci_irq_out,			// Only routing !PCI_INTA_N directly to this atm.
	input			  pci_irq_ack,			// TODO. Handle the PCI Interrupt Acknowledge cycle.

	inout  [31:0] PCI_AD,
	inout   [3:0] PCI_CBE,
	inout			  PCI_PAR,
	
	inout			  PCI_IDSEL,		// Used to select the PCI Config Regs. Only asserted/seen during the Address phase. Can toggle after that.
	
	inout			  PCI_REQ_N,		// Ignored atm. Driven by the master, to request use of the bus.
	inout			  PCI_GNT_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Used by the arbiter, to grant bus access.
	
	inout			  PCI_SERR_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Address/data/special parity error.
	inout			  PCI_PERR_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Parity error, expect Special Cycle.
	
	inout			  PCI_SBO_N,		// ignored atm. Snoop Backoff (Snoop Dogg's Russian cousin).
	inout			  PCI_SDONE,		// ignored atm. Snoop Done.
	inout			  PCI_LOCK_N,		// ignored atm. Used to implement exclusive access on the PCI bus.
	inout			  PCI_STOP_N,		// ignored atm. FROM the target (card), used to abort a transfer.
	
	inout			  PCI_FRAME_N,		// Asserted by the host to denote the start and end of a PCI transaction. (or for ONE clock cycle for IDSEL).
	
	input			  PCI_DEVSEL_N,	// Asserted by the device (card) when it decodes a valid address. (or when it sees IDSEL during the addr phase).
	input			  PCI_TRDY_N,		// Asserted by the Target (device) when it is able to transfer data.
	
	inout			  PCI_IRDY_N,		// Asserted by the Initiator (usually the host) when it is able to transfer data.
	
	output		  PCI_CLK,			// 33 MHz clock to the card.
	output		  PCI_RST_N,		// Reset_n to the card.
	
	input			  PCI_PRSNT1_N,	// ignored atm.
	input			  PCI_PRSNT2_N,	// ignored atm.
	
	input			  PCI_INTA_N,		// Signal routed to pci_irq_out, but not hooked up to ao486 just yet. Will use ao486 IRQ11 for this. ElectronAsh.
	input			  PCI_INTB_N,		// ignored atm.
	input			  PCI_INTC_N,		// ignored atm.
	input			  PCI_INTD_N		// ignored atm.
);

assign pci_readdata = readdata;
assign pci_readdata_valid = readdata_valid;

assign pci_io_access = io_access;

assign PCI_CLK = !clk;	// Invert the clock to the PCI card, as it samples our signals on the RISING edge. Works best for the Voodoo 1.
//assign PCI_CLK = clk;		// TESTING posedge clock (seems to work fine for the Adaptec SCSI card, for CFG reg access.)

assign PCI_RST_N = rst_n;

assign PCI_FRAME_N = FRAME_N_OUT;
assign PCI_IDSEL   = IDSEL_OUT;

assign PCI_AD      = (AD_OE)  ? AD_OUT  : 32'hzzzzzzzz;
assign PCI_CBE     = (CONT_OE) ? CBE_OUT : 4'bzzzz;
assign PCI_PAR     = (CONT_OE) ? PAR_OUT : 1'bz;

reg PCI_IRDY_N_REG;
assign PCI_IRDY_N  = PCI_IRDY_N_REG;

assign PCI_PERR_N  = 1'b1;
assign PCI_SERR_N  = 1'b1;
assign PCI_REQ_N   = 1'b1;
assign PCI_GNT_N   = 1'b1;

assign pci_irq_out = !PCI_INTA_N;

assign pci_wait  = PCI_STATE>0;


localparam CMD_IACK  = 4'b0000;
localparam CMD_SPEC  = 4'b0001;
localparam CMD_IOR   = 4'b0010;
localparam CMD_IOW   = 4'b0011;
//localparam CMD_RESV1 = 4'b0100;
//localparam CMD_RESV2 = 4'b0101;
localparam CMD_MEMR  = 4'b0110;
localparam CMD_MEMW  = 4'b0111;
//localparam CMD_RESV3 = 4'b1000;
//localparam CMD_RESV4 = 4'b1001;
localparam CMD_CFGR  = 4'b1010;
localparam CMD_CFGW  = 4'b1011;
localparam CMD_MEMRM = 4'b1100;
localparam CMD_DUAL  = 4'b1101;
localparam CMD_MEMRL = 4'b1110;
localparam CMD_MEMWI = 4'b1111;

wire vga_io_regs_cs = (pci_address>=16'h0CB0 && pci_address<=16'h0CDF);
wire cfg_addr_cs 	  = (pci_address>=16'h0CF8 && pci_address<=16'h0CFB);
wire cfg_data_cs 	  = (pci_address>=16'h0CFC && pci_address<=16'h0CFF);


(*noprune*) reg [31:0] pci_config_addr;		// 0xCF8 (to 0xCFB).
(*keep*) wire [7:0] bus 	= pci_config_addr[23:16];
(*keep*) wire [4:0] device	= pci_config_addr[15:11];
(*keep*) wire [2:0] func	= pci_config_addr[10:8];
(*keep*) wire [5:0] pcireg	= pci_config_addr[7:2];

(*keep*) wire device_selected = (bus==8'd0 && device==5'd2);

(*noprune*) reg [15:0] addr_latch;

(*noprune*) reg FRAME_N_OUT;
(*noprune*) reg IDSEL_OUT;

(*noprune*) reg [31:0] AD_OUT;
(*noprune*) reg [3:0] CBE_OUT;

(*noprune*) reg PAR_OUT;

(*noprune*) reg CONT_OE;
(*noprune*) reg AD_OE;

(*noprune*) reg [7:0] PCI_STATE;

(*noprune*) reg io_access;

(*noprune*) reg [31:0] writedata;
(*noprune*) reg [3:0] byteenable;

(*noprune*) reg [31:0] readdata;
(*noprune*) reg readdata_valid;

(*noprune*) reg [4:0] timeout;

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	CONT_OE <= 1'b0;
	AD_OE <= 1'b0;
	
	AD_OUT <= 32'h00000000;
	CBE_OUT <= 4'b0000;
	
	FRAME_N_OUT <= 1'b1;
	IDSEL_OUT <= 1'b0;
	
	PCI_IRDY_N_REG <= 1'b1;
	
	PCI_STATE <= 8'd0;
	
	io_access <= 1'b0;
	
	readdata_valid <= 1'b0;
	pci_devsel_claim <= 1'b0;
	
	pci_trdy_timeout <= 1'b0;
end
else begin
	// Parity output is apparently delayed by one clock cycle, and includes PCI_AD + CBE.
	PAR_OUT <= AD_OUT[31] ^ AD_OUT[30] ^ AD_OUT[29] ^ AD_OUT[28] ^ AD_OUT[27] ^ AD_OUT[26] ^ AD_OUT[25] ^ AD_OUT[24] ^ 
				  AD_OUT[23] ^ AD_OUT[22] ^ AD_OUT[21] ^ AD_OUT[20] ^ AD_OUT[19] ^ AD_OUT[18] ^ AD_OUT[17] ^ AD_OUT[16] ^ 
				  AD_OUT[15] ^ AD_OUT[14] ^ AD_OUT[13] ^ AD_OUT[12] ^ AD_OUT[11] ^ AD_OUT[10] ^ AD_OUT[9] ^ AD_OUT[8] ^ 
				  AD_OUT[7] ^ AD_OUT[6] ^ AD_OUT[5] ^ AD_OUT[4] ^ AD_OUT[3] ^ AD_OUT[2] ^ AD_OUT[1] ^ AD_OUT[0] ^ 
				  CBE_OUT[3] ^ CBE_OUT[2] ^ CBE_OUT[1] ^ CBE_OUT[0];

	readdata_valid <= 1'b0;
				  
	case (PCI_STATE)
		0: begin
			AD_OE <= 1'b0;
			CONT_OE <= 1'b0;
			FRAME_N_OUT <= 1'b1;
			PCI_IRDY_N_REG <= 1'b1;
			
			IDSEL_OUT <= 1'b0;
			
			timeout <= 5'd31;
			pci_trdy_timeout <= 1'b0;

			pci_devsel_claim <= 1'b0;
			
			io_access <= pci_io_read | pci_io_write;
			
			if (cfg_data_cs) addr_latch <= pci_config_addr;
			else addr_latch <= pci_address;
			
			if (pci_mem_read) begin				// MEMIO READ.
				CBE_OUT <= CMD_MEMR;
				FRAME_N_OUT	<= 1'b0;					// Assert FRAME_N.
				AD_OUT <= pci_address;				// BYTE address!
				AD_OE <= 1'b1;							// Allow AD_OUT assert on bus.
				CONT_OE <= 1'b1;						// Assert PAR and CBE onto the bus.
				PCI_STATE <= 1;
			end
			else if (pci_io_read) begin		// IO READ.
				if (cfg_data_cs) begin				// Do a CONFIG Data read.
					if (device_selected) IDSEL_OUT <= 1'b1;	// We only have one PCI slot.
					CBE_OUT <= CMD_CFGR;					// PCI Config DATA read.
					FRAME_N_OUT	<= 1'b0;					// Assert FRAME_N.
					AD_OUT <= pci_config_addr;			// Target pci_config_addr.
					AD_OE <= 1'b1;							// Allow AD_OUT assert on bus.
					CONT_OE <= 1'b1;						// Assert PAR and CBE onto the bus.
					PCI_STATE <= 1;
				end
				/*else begin
					CBE_OUT <= CMD_IOR;					// Normal IO range read.
					FRAME_N_OUT	<= 1'b0;					// Assert FRAME_N.
					AD_OUT <= pci_address;				// Target io_address.
					AD_OE <= 1'b1;							// Allow AD_OUT assert on bus.
					CONT_OE <= 1'b1;						// Assert PAR and CBE onto the bus.
					PCI_STATE <= 1;
				end*/
			end
			
			writedata <= pci_writedata;			// Grab the writedata.

			if (pci_mem_write) begin				// MEMIO WRITE.
				CBE_OUT <= CMD_MEMW;
				byteenable <= pci_byteenable;
				AD_OUT <=  pci_address;				// BYTE address!
				AD_OE <= 1'b1;				// Allow AD_OUT assert on bus.
				CONT_OE <= 1'b1;			// Assert PAR and CBE onto the bus.
				PCI_STATE <= 3;
			end
			else if (pci_io_write) begin		// IO WRITE.
				if (cfg_addr_cs) begin
					PCI_STATE <= 4;				// Handle (ANY) writes to pci_config_addr at 0xCF8-0xCFB.
				end
				else begin
					if (cfg_data_cs) begin				// Do a CONFIG DATA write.
						if (device_selected) IDSEL_OUT <= 1'b1;	// We only have one PCI slot.
						// Do the write request anyway, but it will get ignored if IDSEL_OUT is Low...
						CBE_OUT <= CMD_CFGW;				// PCI config DATA write.
						AD_OUT <= pci_config_addr;		// Target pci_config_addr.
						AD_OE <= 1'b1;						// Allow AD_OUT assert on bus.
						CONT_OE <= 1'b1;					// Assert PAR and CBE onto the bus.
						PCI_STATE <= 3;
					end
					else if (vga_io_regs_cs) begin	// Allow normal IO writes. (TESTING VGA REGS!)
						CBE_OUT <= CMD_IOW;				// Normal IO range write.
						FRAME_N_OUT	<= 1'b0;				// Assert FRAME_N.
						AD_OUT <= pci_address;
						AD_OE <= 1'b1;						// Allow AD_OUT assert on bus.
						CONT_OE <= 1'b1;					// Assert PAR and CBE onto the bus.
						PCI_STATE <= 3;
					end
				end
			end
		end
		
		// Handle PCI Config ADDRESS Write...
		4: begin
			case (addr_latch[1:0])
				2'd0: pci_config_addr[31:00] <= writedata[31:00];	// 0xCF8. 32-bit aligned. TODO - double check this, for all instructions!
				2'd1: pci_config_addr[15:08] <= writedata[07:00];	// 0xCF9.
				2'd2: pci_config_addr[23:16] <= writedata[07:00];	// 0xCFA.
				2'd3: pci_config_addr[31:24] <= writedata[07:00];	// 0xCFB.
			endcase
			PCI_STATE <= 0;
		end
		
		
		// READ...
		1: begin
			AD_OE <= 1'b0;						// Allow READ from target.
			CBE_OUT <= 4'b0000;				// Byte-Enable bits are Active-LOW! (assuming this is needed for reads?)
			PCI_IRDY_N_REG <= 1'b0;			// Ready to accept data.
			PCI_STATE <= PCI_STATE + 1;
		end

		2: begin
			if (!PCI_DEVSEL_N) pci_devsel_claim <= 1'b1;
		
			if (!PCI_TRDY_N) begin	// Target has data ready!
				if (io_access) begin
					case (addr_latch[1:0])
						2'd0: readdata[31:00] <= PCI_AD[31:00];	// 32-bit aligned. TODO - double check this, for all instructions!
						2'd1: readdata[07:00] <= PCI_AD[15:08];	// 
						2'd2: readdata[07:00] <= PCI_AD[23:16];	// 
						2'd3: readdata[07:00] <= PCI_AD[31:24];	// 
					endcase
					readdata_valid <= 1'b1;
				end
				else begin							// Handle mem-mapped READ.
					readdata <= PCI_AD;
					readdata_valid <= 1'b1;
				end
				
				PCI_IRDY_N_REG <= 1'b1;			// De-assert IRDY_N.
				//io_waitrequest <= 1'b0;		// To handle cases where io_read is held HIGH before state 0.
				//avm_waitrequest <= 1'b0;		// To handle cases where avm_read is held HIGH before state 0.
				PCI_STATE <= 0;
			end
			else if (timeout==5'd0 /*|| !device_selected*/) begin
				pci_trdy_timeout <= 1'b1;
				readdata <= 32'hFFFFFFFF;		// Null readdata, for both IO and Mem reads.
				readdata_valid <= 1'b1;
				PCI_STATE <= 0;
			end
			else timeout <= timeout - 5'd1;
		end

		
		// WRITE...
		3: begin
			if (!PCI_DEVSEL_N) pci_devsel_claim <= 1'b1;
			
			PCI_IRDY_N_REG <= 1'b0;				// We are ready to transfer data to the card...
			
			if (io_access) begin
				/*
				case (addr_latch[1:0])
					2'd0: begin AD_OUT[31:00] <= writedata[31:00]; CBE_OUT <= 4'b0000; end	// 32-bit aligned. TODO - double check this, for all instructions!
					2'd1: begin AD_OUT[15:08] <= writedata[07:00]; CBE_OUT <= 4'b1101; end	// 
					2'd2: begin AD_OUT[23:16] <= writedata[07:00]; CBE_OUT <= 4'b1011; end	//
					2'd3: begin AD_OUT[31:24] <= writedata[07:00]; CBE_OUT <= 4'b0111; end	//
				endcase
				*/
				AD_OUT <= writedata;		// TESTING !!
				CBE_OUT <= 4'b0000;
			end
			else begin								// AVM / mem access. Always 32-bit? TODO - Check all write combinations!
				AD_OUT <= writedata;				// Output the data onto the bus (before TRDY_N has chance to go low!)
				CBE_OUT <= 4'b0000;
				/*
				if (io_access) CBE_OUT <= 4'b0000;	// Byte-Enable bits are Active-LOW!
				//else CBE_OUT <= ~byteenable;		// Byte-Enable bits are Active-LOW!
				*/
			end			
			
			if (!PCI_TRDY_N || timeout==5'd0) begin	// TRDY_N goes Low when the card has accepted the data.
				pci_trdy_timeout <= 1'b1;
				PCI_IRDY_N_REG <= 1'b1;			// De-assert IRDY_N.
				PCI_STATE <= 0;					// State 0 will deassert AD_OE and CONT_OE.
			end
			else timeout <= timeout - 5'd1;
		end

		default:;
	endcase

end



endmodule
