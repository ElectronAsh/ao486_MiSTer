module pci (
	input			clk,
	input			rst_n,
    
	//io slave CF8h-CFCh
	input              io_address,
	input              io_read,
	output wire [31:0] io_readdata,
	input              io_write,
	input      [31:0]  io_writedata,
	output             io_waitrequest,
	output reg 		    io_readdatavalid,

	// Avalon mem bus.
	input      [29:0]  avm_address,		// WORD address!
	input      [31:0]  avm_writedata,
	input      [3:0]   avm_byteenable,
	input      [3:0]   avm_burstcount,
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


assign PCI_CLK = !clk;	// Invert the clock to the PCI card, as it samples our signals on the RISING edge.
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

/*
localparam vendor_id 	= 16'h121A;	// 3Dfx Interactive, Inc.
localparam device_id 	= 16'h0001;	// Voodoo card.
localparam revision_id 	= 8'h01;	// rev 1.
localparam class_code	= 24'h038000;	// "Display Controller. non-VGA compatible)"?

(*noprune*) reg [15:0] command_reg;
(*noprune*) reg [15:0] status_reg;
(*noprune*) reg [7:0] cache_line_size;
(*noprune*) reg [7:0] latency_timer;
(*noprune*) reg [7:0] header_type;
(*noprune*) reg [7:0] bist;
//(*noprune*) reg [31:0] membase_addr;
(*noprune*) reg [7:0] interrupt_line;
(*noprune*) reg [7:0] interrupt_pin;
(*noprune*) reg [7:0] min_gnt;
(*noprune*) reg [7:0] max_lat;

(*noprune*) reg [31:0] init_enable;
(*noprune*) reg [31:0] bussnoop0;
(*noprune*) reg [31:0] bussnoop1;
(*noprune*) reg [31:0] cfgstatus;
(*noprune*) reg [31:0] cfgscratch;
(*noprune*) reg [31:0] siprocess;


(*noprune*) reg [7:0] bar0_upper_byte;
(*noprune*) reg bar0_set;
*/

(*noprune*) reg [31:0] pci_config_addr;		// 0xCF8.
//(*noprune*) reg [31:0] pci_config_writedata;	// 0xCFC.

(*keep*) wire [7:0] bus 	= pci_config_addr[23:16];
(*keep*) wire [4:0] device	= pci_config_addr[15:11];
(*keep*) wire [2:0] func	= pci_config_addr[10:8];
(*keep*) wire [5:0] pcireg	= pci_config_addr[7:2];

/*
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	command_reg <= 32'h00000000;
	status_reg <= 32'h00000000;
	cache_line_size <= 8'h00;
	latency_timer <= 8'h00;
	header_type <= 8'h00;		// Header Type - 00h Standard Header - 01h PCI-to-PCI Bridge - 02h CardBus Bridge
	bist <= 8'h00;
	interrupt_line <= 8'h00;
	interrupt_pin <= 8'h01;
	min_gnt <= 8'h00;
	max_lat <= 8'h00;
	
	//membase_addr <= 32'hff000000;	// default for Voodoo. (fb_addr_b[1]=0).
	
	init_enable <= 32'h00000000;
	bussnoop0 <= 32'h00000000;
	bussnoop1 <= 32'h00000000;
	cfgstatus <= 32'h00000000;
	cfgscratch <= 32'h00000000;
	siprocess <= 32'h00000000;	// Not implemented yet.
	
	bar0_set <= 1'b0;
end

else begin
	if (io_write) begin
		// Handle writes to the pci_config_addr reg at 0xCF8.
		if (!io_address) pci_config_addr <= io_writedata;

		// Handle (data) writes to the PCI config registers via 0xCFC.
		// Only really command_reg, membase_addr, and a few others that are writeable on the Voodoo 2.
		if (pci_config_addr[31] && io_address && bus==8'd0 && device==5'd1) begin	// 0xCFC. Writes, to bus=0 / device=1 only...
			case (pcireg)
				//6'h0: // device_id / vendor_id. (read-only).
				6'h1: command_reg <= io_writedata[15:0];	// status reg is read-only, from bits [31:16].
				//6'h2: // class_code / revision_id (read_only).
				//6'h3: // bist / header_type / latency_timer / cache_line_size (read-only).
				
				6'h4: begin
					bar0_upper_byte <= io_writedata[31:24];
					bar0_set <= 1'b1;
				end

				//6'hf: max_lat / min_gnt / interrupt_pin / interrupt_line (read-only).
				default:;
			endcase
		end
	end
end

// Handle config reads...
always @* begin
	if (pci_config_addr[31] && io_address && bus==8'd0 && device==5'd1) begin	// 0xCFC. Spoof reads, for bus=0 / device=1 only...
		case (pcireg)
			6'h0: io_readdata = {device_id, vendor_id};			// Word offset 0x00.
			6'h1: io_readdata = {status_reg, command_reg};		// Word offset 0x04.
			6'h2: io_readdata = {class_code, revision_id};		// Word offset 0x08.
			6'h3: io_readdata = {bist, header_type, latency_timer, cache_line_size};	// Word offset 0x0C.
			
			6'h4: io_readdata = {bar0_upper_byte, 24'h000000};	// Word offset 0x10. (BAR0).

			// Other Base Address registers not used on the Voodoo. I think?

			// Last WORD of the PCI config regs...
			6'hf: io_readdata = {max_lat, min_gnt, interrupt_pin, interrupt_line}; // Word offset 0x3C.
			default: io_readdata = 32'hFFFFFFFF;
		endcase
	end
	else begin
		io_readdata = 32'hFFFFFFFF;	// Send back this value (-1) for all other busses/devices).
	end
end
*/


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
			else if (io_read) begin			// IO (PCI Config Space) READ.
				io_access <= 1'b1;
				if (bus==8'd0 && device==5'd1) begin		// Allow reads from 0xCFC (config data read). bus=0, device=1 only.
					IDSEL_OUT <= 1'b1;
					CBE_OUT <= CMD_CFGR;
					AD_OUT <= pci_config_addr;	// Target pci_config_addr.
					FRAME_N_OUT	<= 1'b0;			// Assert FRAME_N.
					CONT_OE <= 1'b1;				// Assert PAR and CBE onto the bus.
					AD_OE <= 1'b1;					// Allow AD_OUT assert on bus.
					PCI_STATE <= 1;
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
				if (!io_address) pci_config_addr <= io_writedata;	// Handle writes to the pci_config_addr reg at 0xCF8.
				else if (bus==8'd0 && device==5'd1) begin				// Write to 0xCFC (config data write). bus=0, device=1 only.
					io_access <= 1'b1;
					writedata <= io_writedata;
					IDSEL_OUT <= 1'b1;
					CBE_OUT <= CMD_CFGW;
					AD_OUT <= pci_config_addr;	// Target pci_config_addr.
					FRAME_N_OUT	<= 1'b0;		// Assert FRAME_N.
					CONT_OE <= 1'b1;			// Assert PAR and CBE onto the bus.
					AD_OE <= 1'b1;				// Allow AD_OUT assert on bus.
					PCI_STATE <= 3;
				end
			end
		end
		
		
		// READ...
		1: begin
			AD_OE <= 1'b0;						// Allow READ from target.
			IDSEL_OUT <= 1'b0;				// De-assert IDSEL after the io_addressess phase (if set in state 0).
			CBE_OUT <= 4'b0000;				// Byte-Enable bits are Active-LOW!
			FRAME_N_OUT <= 1'b1;				// De-assert FRAME_N (last/only data word).
			PCI_IRDY_N_REG <= 1'b0;			// Ready to accept data.
			PCI_STATE <= PCI_STATE + 1;
		end

		2: begin
			if (!PCI_TRDY_N || timeout==6'd0) begin			// Target has data ready!
				readdata <= PCI_AD;
				if (io_access) io_readdatavalid <= 1'b1;
				else avm_readdatavalid <= 1'b1;
				PCI_IRDY_N_REG <= 1'b1;		// De-assert IRDY_N.
				//io_waitrequest <= 1'b0;		// To handle cases where io_read is held HIGH before state 0.
				//avm_waitrequest <= 1'b0;	// To handle cases where avm_read is held HIGH before state 0.
				PCI_STATE <= 0;
			end
			else timeout <= timeout - 6'd1;
		end

		
		// WRITE...
		3: begin
			IDSEL_OUT <= 1'b0;					// De-assert IDSEL after the address phase.
			FRAME_N_OUT <= 1'b1;					// De-assert FRAME_N (last/only data word).
			AD_OUT <= writedata;					// Output the data onto the bus (before TRDY_N has chance to go low!)
			PCI_IRDY_N_REG <= 1'b0;				// We are ready to transfer data to the card...
			
			/*if (io_access)*/ CBE_OUT <= 4'b0000;	// Byte-Enable bits are Active-LOW!
			//else CBE_OUT <= ~avm_byteenable;		// Byte-Enable bits are Active-LOW!
			
			if (!PCI_TRDY_N || timeout==6'd0) begin	// TRDY_N goes Low when the card has accepted the data.
				PCI_IRDY_N_REG <= 1'b1;			// De-assert IRDY_N.
				//AD_OE <= 1'b0;					// TESTING !!
				//CONT_OE <= 1'b0;				// TESTING !! Allowing state 0 to deassert these, to hold the data for longer.
				PCI_STATE <= 0;
			end
			else timeout <= timeout - 6'd1;
		end

		//4: begin
			//io_waitrequest <= 1'b0;			// To handle cases where io_write is held HIGH before state 0.
			//avm_waitrequest <= 1'b0;		// To handle cases where avm_write is held HIGH before state 0.
			//PCI_STATE <= 0;
		//end

		default:;
	endcase

end



endmodule
