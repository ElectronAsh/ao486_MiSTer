module pci (
	input			clk,
	input			rst_n,
    
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
	
	output pci_irq_out,
	
	inout [31:0] PCI_AD,
	inout [3:0] PCI_CBE,
	inout			PCI_PAR,
	
	inout			PCI_IDSEL,		// Used to select the PCI Config Regs. Only asserted/seen during the Address phase. Can toggle after that.
	
	inout			PCI_REQ_N,		// Ignored atm. Driven by the master, to request use of the bus.
	inout			PCI_GNT_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Used by the arbiter, to grant bus access.
	
	inout			PCI_SERR_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Address/data/special parity error.
	inout			PCI_PERR_N,		// Pulled high atm. Todo - add a pull-up to the adapter. Parity error, expect Special Cycle.
	
	inout			PCI_SBO_N,		// ignored atm. Snoop Backoff (Snoop Dogg's Russian cousin).
	inout			PCI_SDONE,		// ignored atm. Snoop Done.
	inout			PCI_LOCK_N,		// ignored atm. Used to implement exclusive access on the PCI bus.
	inout			PCI_STOP_N,		// ignored atm. FROM the target (card), used to abort a transfer.
	
	inout			PCI_FRAME_N,	// Asserted by the host to denote the start and end of a PCI transaction. (or for ONE clock cycle for IDSEL).
	
	input			PCI_DEVSEL_N,	// Asserted by the device (card) when it decodes a valid address. (or when it sees IDSEL during the addr phase).
	input			PCI_TRDY_N,		// Asserted by the Target (device) when it is able to transfer data.
	
	inout			PCI_IRDY_N,		// Asserted by the Initiator (usually the host) when it is able to transfer data.
	
	output		PCI_CLK,			// 33 MHz clock to the card.
	output		PCI_RST_N,		// Reset_n to the card.
	
	input			PCI_PRSNT1_N,	// ignored atm.
	input			PCI_PRSNT2_N,	// ignored atm.
	
	input			PCI_INTA_N,		// Signal routed to pci_irq_out, but not hooked up to ao486 just yet. Will use ao486 IRQ11 for this. ElectronAsh.
	input			PCI_INTB_N,		// ignored atm.
	input			PCI_INTC_N,		// ignored atm.
	input			PCI_INTD_N		// ignored atm.
);

assign io_readdata = readdata;
assign avm_readdata = readdata;


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

assign io_waitrequest  = io_access && PCI_STATE>0;
assign avm_waitrequest = !io_access && PCI_STATE>0;


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


(*noprune*) reg [31:0] pci_config_addr;		// 0xCF8 (to 0xCFB).
(*keep*) wire [7:0] bus 	= pci_config_addr[23:16];
(*keep*) wire [4:0] device	= pci_config_addr[15:11];
(*keep*) wire [2:0] func	= pci_config_addr[10:8];
(*keep*) wire [5:0] pcireg	= pci_config_addr[7:2];

(*noprune*) reg [15:0] io_addr_latch;

(*noprune*) reg FRAME_N_OUT;
(*noprune*) reg IDSEL_OUT;

(*noprune*) reg [31:0] AD_OUT;
(*noprune*) reg [3:0] CBE_OUT;

(*noprune*) reg PAR_OUT;

(*noprune*) reg CONT_OE;
(*noprune*) reg AD_OE;

(*noprune*) reg [7:0] PCI_STATE;

(*noprune*) reg io_access;

(*noprune*) reg [31:0] readdata;
(*noprune*) reg [31:0] writedata;

(*noprune*) reg [5:0] timeout;

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
	
	io_readdatavalid <= 1'b0;
	avm_readdatavalid <= 1'b0;
	
	io_access <= 1'b0;
end
else begin
	// Parity output is apparently delayed by one clock cycle, and includes PCI_AD + CBE.
	PAR_OUT <= AD_OUT[31] ^ AD_OUT[30] ^ AD_OUT[29] ^ AD_OUT[28] ^ AD_OUT[27] ^ AD_OUT[26] ^ AD_OUT[25] ^ AD_OUT[24] ^ 
				  AD_OUT[23] ^ AD_OUT[22] ^ AD_OUT[21] ^ AD_OUT[20] ^ AD_OUT[19] ^ AD_OUT[18] ^ AD_OUT[17] ^ AD_OUT[16] ^ 
				  AD_OUT[15] ^ AD_OUT[14] ^ AD_OUT[13] ^ AD_OUT[12] ^ AD_OUT[11] ^ AD_OUT[10] ^ AD_OUT[9] ^ AD_OUT[8] ^ 
				  AD_OUT[7] ^ AD_OUT[6] ^ AD_OUT[5] ^ AD_OUT[4] ^ AD_OUT[3] ^ AD_OUT[2] ^ AD_OUT[1] ^ AD_OUT[0] ^ 
				  CBE_OUT[3] ^ CBE_OUT[2] ^ CBE_OUT[1] ^ CBE_OUT[0];

	
	io_readdatavalid <= 1'b0;
	avm_readdatavalid <= 1'b0;
				  
	case (PCI_STATE)
		0: begin
			AD_OE <= 1'b0;
			CONT_OE <= 1'b0;
			PCI_IRDY_N_REG <= 1'b1;
			
			timeout <= 6'd63;
		
			if (avm_read) begin				// MEMIO READ.
				io_access <= 1'b0;
				IDSEL_OUT <= 1'b0;
				CBE_OUT <= CMD_MEMR;
				AD_OUT <= {avm_address, 2'b00};	// Target avm_address. avm_address is the WORD address!
				FRAME_N_OUT	<= 1'b0;					// Assert FRAME_N.
				CONT_OE <= 1'b1;						// Assert PAR and CBE onto the bus.
				AD_OE <= 1'b1;							// Allow AD_OUT assert on bus.
				PCI_STATE <= 1;
			end
			else if (io_read) begin				// IO (PCI Config Space) READ.
				io_access <= 1'b1;
				if (1 /*bus==8'd0 && device==5'd2*/) begin	// Allow DATA reads from bus=0, device=2 only.
					if (io_address>=16'h0CFC && io_address<=16'h0CFF) begin
						IDSEL_OUT <= 1'b1;
						CBE_OUT <= CMD_CFGR;			// PCI Config DATA read.
						AD_OUT <= pci_config_addr;	// Target pci_config_addr.
						io_addr_latch <= pci_config_addr;
						FRAME_N_OUT	<= 1'b0;			// Assert FRAME_N.
						CONT_OE <= 1'b1;				// Assert PAR and CBE onto the bus.
						AD_OE <= 1'b1;					// Allow AD_OUT assert on bus.
						PCI_STATE <= 1;
					end
					/*else begin
						IDSEL_OUT <= 1'b0;
						CBE_OUT <= CMD_IOR;		// Normal IO range read.
						AD_OUT <= io_address;	// Target io_address.
						io_addr_latch <= io_address;
						FRAME_N_OUT	<= 1'b0;			// Assert FRAME_N.
						CONT_OE <= 1'b1;				// Assert PAR and CBE onto the bus.
						AD_OE <= 1'b1;					// Allow AD_OUT assert on bus.
						PCI_STATE <= 1;
					end*/
				end
			end
			
			if (avm_write) begin				// MEMIO WRITE.
				io_access <= 1'b0;
				writedata <= avm_writedata;		// Grab the writedata.
				IDSEL_OUT <= 1'b0;
				CBE_OUT <= CMD_MEMW;
				AD_OUT <=  {avm_address, 2'b00};	// Target avm_address. avm_address is the WORD address!
				AD_OE <= 1'b1;							// Allow AD_OUT assert on bus.
				CONT_OE <= 1'b1;						// Assert PAR and CBE onto the bus.
				FRAME_N_OUT	<= 1'b0;					// Assert FRAME_N.
				PCI_STATE <= 3;
			end
			else if (io_write) begin		// IO (PCI Config Space) WRITE.
				io_access <= 1'b1;
				// Not sure whether to ignore the MSB (enable) bit io_writedata for PCI Config addr,
				// or put it onto the PCI bus during the address phase? ElectronAsh.
				if (io_address>=16'h0CF8 && io_address<=16'h0CFB) begin	// Handle writes to pci_config_addr at 0xCF8-0xCFB.
					case (io_address[1:0])
						2'd0: pci_config_addr[31:00] <= io_writedata[31:00];	// 0xCF8. 32-bit aligned. TODO - double check this, for all instructions!
						2'd1: pci_config_addr[15:08] <= io_writedata[07:00];	// 0xCF9.
						2'd2: pci_config_addr[23:16] <= io_writedata[07:00];	// 0xCFA.
						2'd3: pci_config_addr[31:24] <= io_writedata[07:00];	// 0xCFB.
					endcase
				end
				else if (bus==8'd0 && device==5'd2) begin		// bus=0, device=2 only.
					if (io_address>=16'h0CFC && io_address<=16'h0CFF) begin	// Allow CONFIG writes.
						IDSEL_OUT <= 1'b1;
						CBE_OUT <= CMD_CFGW;			// PCI config DATA write.
						AD_OUT <= pci_config_addr;	// Target pci_config_addr.
						io_addr_latch <= io_address;
						writedata <= io_writedata;
						FRAME_N_OUT	<= 1'b0;		// Assert FRAME_N.
						CONT_OE <= 1'b1;			// Assert PAR and CBE onto the bus.
						AD_OE <= 1'b1;				// Allow AD_OUT assert on bus.
						PCI_STATE <= 3;
					end
					else if (io_address>=16'h03B0 && io_address<=16'h03DF) begin	// Allow normal IO writes. (TESTING VGA REGS!)
						IDSEL_OUT <= 1'b0;
						CBE_OUT <= CMD_IOW;		// Normal IO range write.
						AD_OUT <= io_address;	// Target io_address.
						io_addr_latch <= io_address;
						writedata <= io_writedata;
						FRAME_N_OUT	<= 1'b0;		// Assert FRAME_N.
						CONT_OE <= 1'b1;			// Assert PAR and CBE onto the bus.
						AD_OE <= 1'b1;				// Allow AD_OUT assert on bus.
						PCI_STATE <= 3;
					end
				end
			end
		end
		
		
		// READ...
		1: begin
			AD_OE <= 1'b0;						// Allow READ from target.
			IDSEL_OUT <= 1'b0;				// De-assert IDSEL after the io_addressess phase (if set in state 0).
			CBE_OUT <= 4'b0000;				// Byte-Enable bits are Active-LOW! (assuming this is needed for reads?)
			FRAME_N_OUT <= 1'b1;				// De-assert FRAME_N (last/only data word).
			PCI_IRDY_N_REG <= 1'b0;			// Ready to accept data.
			PCI_STATE <= PCI_STATE + 1;
		end

		2: begin
			if (!PCI_TRDY_N && bus==8'd0 && device==5'd2) begin	// Target has data ready!
				if (io_access) begin
					case (io_addr_latch[1:0])
						2'd0: readdata[31:00] <= PCI_AD[31:00];	// 32-bit aligned. TODO - double check this, for all instructions!
						2'd1: readdata[07:00] <= PCI_AD[15:08];	// 
						2'd2: readdata[07:00] <= PCI_AD[23:16];	// 
						2'd3: readdata[07:00] <= PCI_AD[31:24];	// 
					endcase
					io_readdatavalid <= 1'b1;
				end
				else begin							// Handle mem-mapped READ.
					readdata <= PCI_AD;
					avm_readdatavalid <= 1'b1;
				end
				
				PCI_IRDY_N_REG <= 1'b1;			// De-assert IRDY_N.
				//io_waitrequest <= 1'b0;		// To handle cases where io_read is held HIGH before state 0.
				//avm_waitrequest <= 1'b0;		// To handle cases where avm_read is held HIGH before state 0.
				PCI_STATE <= 0;
			end
			else if (timeout==6'd0) begin
				readdata <= 32'hFFFFFFFF;		// Null readdata, for both IO and Mem reads.
				if (io_access) io_readdatavalid <= 1'b1;
				else avm_readdatavalid <= 1'b1;
				PCI_STATE <= 0;
			end
			else timeout <= timeout - 6'd1;
		end

		
		// WRITE...
		3: begin
			IDSEL_OUT <= 1'b0;					// De-assert IDSEL after the address phase.
			FRAME_N_OUT <= 1'b1;					// De-assert FRAME_N (last/only data word).
			PCI_IRDY_N_REG <= 1'b0;				// We are ready to transfer data to the card...
			
			if (io_access) begin
				case (io_addr_latch[1:0])
					2'd0: begin AD_OUT[31:00] <= writedata[31:00]; CBE_OUT <= 4'b0000; end	// 32-bit aligned. TODO - double check this, for all instructions!
					2'd1: begin AD_OUT[15:08] <= writedata[07:00]; CBE_OUT <= 4'b1101; end	// 
					2'd2: begin AD_OUT[23:16] <= writedata[07:00]; CBE_OUT <= 4'b1011; end	//
					2'd3: begin AD_OUT[31:24] <= writedata[07:00]; CBE_OUT <= 4'b0111; end	//
				endcase
			end
			else begin								// AVM / mem access. Always 32-bit? TODO - Check all write combinations!
				AD_OUT <= writedata;				// Output the data onto the bus (before TRDY_N has chance to go low!)
				CBE_OUT <= 4'b0000;
				/*
				if (io_access) CBE_OUT <= 4'b0000;	// Byte-Enable bits are Active-LOW!
				//else CBE_OUT <= ~avm_byteenable;	// Byte-Enable bits are Active-LOW!
				*/
			end			
			
			if (!PCI_TRDY_N || timeout==6'd0) begin	// TRDY_N goes Low when the card has accepted the data.
				PCI_IRDY_N_REG <= 1'b1;			// De-assert IRDY_N.
				PCI_STATE <= 0;					// State 0 will deassert AD_OE and CONT_OE.
			end
			else timeout <= timeout - 6'd1;
		end

		//4: begin
			//io_waitrequest <= 1'b0;			// To handle cases where io_write is held HIGH before state 0.
			//avm_waitrequest <= 1'b0;			// To handle cases where avm_write is held HIGH before state 0.
			//PCI_STATE <= 0;
		//end

		default:;
	endcase

end



endmodule
