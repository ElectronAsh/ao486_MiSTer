
module system
(
	input         clk_sys,
	input         reset,

	input  [27:0] clock_rate,
	
	input         l1_disable,
	input         l2_disable,

	output [1:0]  fdd_request,
	output [2:0]  hdd0_request,
	output [2:0]  hdd1_request,

	input  [13:0] joystick_dig_1,
	input  [13:0] joystick_dig_2,
	input  [15:0] joystick_ana_1,
	input  [15:0] joystick_ana_2,
	input  [1:0]  joystick_mode,
	input         joystick_clk_grav,

	input  [15:0] mgmt_address,
	input         mgmt_read,
	output [15:0] mgmt_readdata,
	input         mgmt_write,
	input  [15:0] mgmt_writedata,
	input         mgmt_active,

	input         ps2_kbclk_in,
	input         ps2_kbdat_in,
	output        ps2_kbclk_out,
	output        ps2_kbdat_out,
	input         ps2_mouseclk_in,
	input         ps2_mousedat_in,
	output        ps2_mouseclk_out,
	output        ps2_mousedat_out,
	output        ps2_reset_n,

	input         memcfg,
	output  [7:0] syscfg,

	input         clk_uart,
	input         serial_rx,
	output        serial_tx,
	input         serial_cts_n,
	input         serial_dcd_n,
	input         serial_dsr_n,
	output        serial_rts_n,
	output        serial_dtr_n,
	input         serial_midi_rate,

	input         clk_opl,
	output [15:0] sound_sample_l,
	output [15:0] sound_sample_r,
	input         sound_fm_mode,
	input         sound_cms_en,

	output        speaker_out,

	input         clk_vga,
	input  [27:0] clock_rate_vga,

	output        video_ce,
	output        video_blank_n,
	output        video_hsync,
	output        video_vsync,
	output [7:0]  video_r,
	output [7:0]  video_g,
	output [7:0]  video_b,
	input         video_f60,
	output [7:0]  video_pal_a,
	output [17:0] video_pal_d,
	output        video_pal_we,
	output [19:0] video_start_addr,
	output [8:0]  video_width,
	output [10:0] video_height,
	output [3:0]  video_flags,
	output [8:0]  video_stride,
	output        video_off,
	input         video_fb_en,
	input         video_lores,

	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [24:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	
	inout [31:0] PCI_AD,
	inout [3:0] PCI_CBE,
	inout PCI_PAR,
	inout PCI_IDSEL,
	inout PCI_GNT_N,
	inout PCI_SERR_N,
	inout PCI_SBO_N,
	inout PCI_SDONE,
	inout PCI_PERR_N,
	inout PCI_LOCK_N,
	inout PCI_STOP_N,
	inout PCI_DEVSEL_N,
	inout PCI_TRDY_N,
	inout PCI_IRDY_N,
	inout PCI_FRAME_N,
	inout PCI_REQ_N,
	
	output PCI_CLK,
	output PCI_RST_N,
	
	input PCI_PRSNT1_N,
	input PCI_PRSNT2_N,
	input PCI_INTA_N,
	input PCI_INTB_N,
	input PCI_INTC_N,
	input PCI_INTD_N
);

wire        a20_enable;
wire  [7:0] dma_floppy_readdata;
wire        dma_floppy_tc;
wire  [7:0] dma_floppy_writedata;
wire        dma_floppy_req;
wire        dma_floppy_ack;
wire        dma_sb_req_8;
wire        dma_sb_req_16;
wire        dma_sb_ack_8;
wire        dma_sb_ack_16;
wire  [7:0] dma_sb_readdata_8;
wire [15:0] dma_sb_readdata_16;
wire [15:0] dma_sb_writedata;
wire [15:0] dma_readdata;
wire        dma_waitrequest;
wire [23:0] dma_address;
wire        dma_read;
wire        dma_readdatavalid;
wire        dma_write;
wire [15:0] dma_writedata;
wire        dma_16bit;

wire [31:0] mgmt_fdd_readdata;
wire [31:0] mgmt_hdd0_readdata;
wire [31:0] mgmt_hdd1_readdata;
wire [31:0] mgmt_ctl_writedata;
wire  [7:0] mgmt_ctl_address;
wire        mgmt_ctl_read;
wire        mgmt_ctl_write;
reg         mgmt_hdd0_cs;
reg         mgmt_hdd1_cs;
reg         mgmt_fdd_cs;
reg         mgmt_rtc_cs;

wire        interrupt_done;
wire        interrupt_do;
wire  [7:0] interrupt_vector;
reg  [15:0] interrupt;
wire        irq_0, irq_1, irq_2, irq_4, irq_5, irq_6, irq_7, irq_8, irq_9, irq_10, irq_11, irq_12, irq_14, irq_15;

wire        cpu_io_read_do;
wire [15:0] cpu_io_read_address;
wire [2:0]  cpu_io_read_length;
wire [31:0] cpu_io_read_data;
wire        cpu_io_read_done;
wire        cpu_io_write_do;
wire [15:0] cpu_io_write_address;
wire [2:0]  cpu_io_write_length;
wire [31:0] cpu_io_write_data;
wire        cpu_io_write_done;
wire [15:0] iobus_address;
wire        iobus_write;
wire        iobus_read;
wire  [2:0] iobus_datasize;
wire [31:0] iobus_writedata;

reg         hdd0_cs;
reg         hdd1_cs;
reg         floppy0_cs;
reg         dma_master_cs;
reg         dma_page_cs;
reg         dma_slave_cs;
reg         pic_master_cs;
reg         pic_slave_cs;
reg         pit_cs;
reg         ps2_io_cs;
reg         ps2_ctl_cs;
reg         joy_cs;
reg         rtc_cs;
reg         fm_cs;
reg         sb_cs;
reg         uart_cs;
reg         mpu_cs;
reg         vga_b_cs;
reg         vga_c_cs;
reg         vga_d_cs;
reg         sysctl_cs;
reg         pci_io_cs;

wire  [7:0] sound_readdata;
wire  [7:0] floppy0_readdata;
wire [31:0] hdd0_readdata;
wire [31:0] hdd1_readdata;
wire  [7:0] joystick_readdata;
wire  [7:0] pit_readdata;
wire  [7:0] ps2_readdata;
wire  [7:0] rtc_readdata;
wire  [7:0] uart_readdata;
wire  [7:0] dma_io_readdata;
wire  [7:0] pic_readdata;
wire  [7:0] vga_io_readdata;

wire [29:0] mem_address;
wire [31:0] mem_writedata;
wire [31:0] mem_readdata;
wire  [3:0] mem_byteenable;
wire  [3:0] mem_burstcount;
wire        mem_write;
wire        mem_read;
wire        mem_waitrequest;
wire        mem_readdatavalid;

wire [16:0] vga_address;
wire  [7:0] vga_readdata;
wire  [7:0] vga_writedata;
wire        vga_read;
wire        vga_write;
wire  [2:0] vga_memmode;
wire  [5:0] video_wr_seg;
wire  [5:0] video_rd_seg;

assign      DDRAM_CLK = clk_sys;

l2_cache cache
(
	.CLK               (clk_sys),
	.RESET             (reset),

	.DISABLE           (l2_disable),

	.CPU_ADDR          (mem_address),
	.CPU_DIN           (mem_writedata),
	.CPU_DOUT          (mem_readdata),
	.CPU_DOUT_READY    (mem_readdatavalid),
	.CPU_BE            (mem_byteenable),
	.CPU_BURSTCNT      (mem_burstcount),
	.CPU_BUSY          (mem_waitrequest),
	.CPU_RD            (mem_read),
	.CPU_WE            (mem_write),

	.DDRAM_ADDR        (DDRAM_ADDR),
	.DDRAM_DIN         (DDRAM_DIN),
	.DDRAM_DOUT        (DDRAM_DOUT),
	.DDRAM_DOUT_READY  (DDRAM_DOUT_READY),
	.DDRAM_BE          (DDRAM_BE),
	.DDRAM_BURSTCNT    (DDRAM_BURSTCNT),
	.DDRAM_BUSY        (DDRAM_BUSY),
	.DDRAM_RD          (DDRAM_RD),
	.DDRAM_WE          (DDRAM_WE),

	.VGA_ADDR          (vga_address),
	.VGA_DIN           (vga_readdata),
	.VGA_DOUT          (vga_writedata),
	.VGA_RD            (vga_read),
	.VGA_WE            (vga_write),
	.VGA_MODE          (vga_memmode),

	.VGA_WR_SEG        (video_wr_seg),
	.VGA_RD_SEG        (video_rd_seg),
	.VGA_FB_EN         (video_fb_en)
);

ao486 ao486
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.cache_disable     (l1_disable),

	.avm_address       (mem_address),
	.avm_writedata     (mem_writedata),
	.avm_byteenable    (mem_byteenable),
	.avm_burstcount    (mem_burstcount),
	.avm_write         (mem_write),
	.avm_read          (mem_read),
	.avm_waitrequest   (mem_waitrequest),
	.avm_readdatavalid (mem_readdatavalid),
	.avm_readdata      (mem_readdata),

	.interrupt_do      (interrupt_do),
	.interrupt_vector  (interrupt_vector),
	.interrupt_done    (interrupt_done),

	.io_read_do        (cpu_io_read_do),
	.io_read_address   (cpu_io_read_address),
	.io_read_length    (cpu_io_read_length),
	.io_read_data      (cpu_io_read_data),
	.io_read_done      (cpu_io_read_done),
	.io_write_do       (cpu_io_write_do),
	.io_write_address  (cpu_io_write_address),
	.io_write_length   (cpu_io_write_length),
	.io_write_data     (cpu_io_write_data),
	.io_write_done     (cpu_io_write_done),

	.a20_enable        (a20_enable),

	.dma_address       (dma_address),
	.dma_16bit         (dma_16bit),
	.dma_read          (dma_read),
	.dma_readdata      (dma_readdata),
	.dma_readdatavalid (dma_readdatavalid),
	.dma_waitrequest   (dma_waitrequest),
	.dma_write         (dma_write),
	.dma_writedata     (dma_writedata)
);

always @(posedge clk_sys) begin
	hdd0_cs       <= ({iobus_address[15:3], 3'd0} == 16'h01F0) || (iobus_address == 16'h03F6);
	hdd1_cs       <= ({iobus_address[15:3], 3'd0} == 16'h0170) || (iobus_address == 16'h0376);
	joy_cs        <= ({iobus_address[15:0]      } == 16'h0201);
	floppy0_cs    <= ({iobus_address[15:3], 3'd0} == 16'h03F0);
	dma_master_cs <= ({iobus_address[15:5], 5'd0} == 16'h00C0);
	dma_page_cs   <= ({iobus_address[15:4], 4'd0} == 16'h0080);
	dma_slave_cs  <= ({iobus_address[15:4], 4'd0} == 16'h0000);
	pic_master_cs <= ({iobus_address[15:1], 1'd0} == 16'h0020);
	pic_slave_cs  <= ({iobus_address[15:1], 1'd0} == 16'h00A0);
	pit_cs        <= ({iobus_address[15:2], 2'd0} == 16'h0040) || (iobus_address == 16'h0061);
	ps2_io_cs     <= ({iobus_address[15:3], 3'd0} == 16'h0060);
	ps2_ctl_cs    <= ({iobus_address[15:4], 4'd0} == 16'h0090);
	rtc_cs        <= ({iobus_address[15:1], 1'd0} == 16'h0070);
	fm_cs         <= ({iobus_address[15:2], 2'd0} == 16'h0388);
	sb_cs         <= ({iobus_address[15:4], 4'd0} == 16'h0220);
	uart_cs       <= ({iobus_address[15:3], 3'd0} == 16'h03F8);
	mpu_cs        <= ({iobus_address[15:1], 1'd0} == 16'h0330);
	vga_b_cs      <= ({iobus_address[15:4], 4'd0} == 16'h03B0);
	vga_c_cs      <= ({iobus_address[15:4], 4'd0} == 16'h03C0);
	vga_d_cs      <= ({iobus_address[15:4], 4'd0} == 16'h03D0);
	pci_io_cs	  <= ({iobus_address[15:0]      } == 16'h0CF8) || (iobus_address == 16'h0CFC);
	sysctl_cs     <= ({iobus_address[15:0]      } == 16'h8888);
end

reg [7:0] ctlport = 0;
always @(posedge clk_sys) begin
	reg in_reset = 1;
	if(reset) begin
		ctlport <= 8'hA2;
		in_reset <= 1;
	end
	else if((hdd0_cs|hdd1_cs|floppy0_cs) && in_reset) begin
		ctlport <= 0;
		in_reset <= 0;
	end
	else if(iobus_write && sysctl_cs && iobus_datasize == 2 && iobus_writedata[15:8] == 8'hA1) begin
		ctlport <= iobus_writedata[7:0];
		in_reset <= 0;
	end
end

assign syscfg = ctlport;

wire [7:0] iobus_readdata8 =
	( floppy0_cs                             ) ? floppy0_readdata  :
	( dma_master_cs|dma_slave_cs|dma_page_cs ) ? dma_io_readdata   :
	( pic_master_cs|pic_slave_cs             ) ? pic_readdata      :
	( pit_cs                                 ) ? pit_readdata      :
	( ps2_io_cs|ps2_ctl_cs                   ) ? ps2_readdata      :
	( rtc_cs                                 ) ? rtc_readdata      :
	( sb_cs|fm_cs                            ) ? sound_readdata    :
	( uart_cs|mpu_cs                         ) ? uart_readdata     :
	( vga_b_cs|vga_c_cs|vga_d_cs             ) ? vga_io_readdata   :
	( joy_cs                                 ) ? joystick_readdata :
	                                             8'hFF;

iobus iobus
(
	.clk               (clk_sys),
	.reset             (reset),

	.cpu_read_do       (cpu_io_read_do),
	.cpu_read_address  (cpu_io_read_address),
	.cpu_read_length   (cpu_io_read_length),
	.cpu_read_data     (cpu_io_read_data),
	.cpu_read_done     (cpu_io_read_done),
	.cpu_write_do      (cpu_io_write_do),
	.cpu_write_address (cpu_io_write_address),
	.cpu_write_length  (cpu_io_write_length),
	.cpu_write_data    (cpu_io_write_data),
	.cpu_write_done    (cpu_io_write_done),

	.bus_address       (iobus_address),
	.bus_write         (iobus_write),
	.bus_read          (iobus_read),
	.bus_io32          (((hdd0_cs | hdd1_cs) & ~iobus_address[9]) | sysctl_cs),
	.bus_datasize      (iobus_datasize),
	.bus_writedata     (iobus_writedata),
	.bus_readdata      (hdd0_cs ? hdd0_readdata : hdd1_cs ? hdd1_readdata : pci_io_cs ? pci_io_readdata : iobus_readdata8)
);

dma dma
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.mem_address       (dma_address),
	.mem_16bit         (dma_16bit),
	.mem_waitrequest   (dma_waitrequest),
	.mem_read          (dma_read),
	.mem_readdatavalid (dma_readdatavalid),
	.mem_readdata      (dma_readdata),
	.mem_write         (dma_write),
	.mem_writedata     (dma_writedata),

	.io_address        (iobus_address[4:0]),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read),
	.io_write          (iobus_write),
	.io_readdata       (dma_io_readdata),
	.io_master_cs      (dma_master_cs),
	.io_slave_cs       (dma_slave_cs),
	.io_page_cs        (dma_page_cs),
	
	.dma_2_req         (dma_floppy_req),
	.dma_2_ack         (dma_floppy_ack),
	.dma_2_tc          (dma_floppy_tc),
	.dma_2_readdata    (dma_floppy_readdata),
	.dma_2_writedata   (dma_floppy_writedata),

	.dma_1_req         (dma_sb_req_8),
	.dma_1_ack         (dma_sb_ack_8),
	.dma_1_readdata    (dma_sb_readdata_8),
	.dma_1_writedata   (dma_sb_writedata[7:0]),

	.dma_5_req         (dma_sb_req_16),
	.dma_5_ack         (dma_sb_ack_16),
	.dma_5_readdata    (dma_sb_readdata_16),
	.dma_5_writedata   (dma_sb_writedata)
);

floppy floppy
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.clock_rate        (clock_rate),

	.io_address        (iobus_address[2:0]),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read & floppy0_cs),
	.io_write          (iobus_write & floppy0_cs),
	.io_readdata       (floppy0_readdata),

	.dma_req           (dma_floppy_req),
	.dma_ack           (dma_floppy_ack),
	.dma_tc            (dma_floppy_tc),
	.dma_readdata      (dma_floppy_readdata),
	.dma_writedata     (dma_floppy_writedata),

	.mgmt_address      (mgmt_ctl_address[3:0]),
	.mgmt_fddn         (mgmt_address[7]),
	.mgmt_write        (mgmt_ctl_write & mgmt_fdd_cs),
	.mgmt_writedata    (mgmt_ctl_writedata),
	.mgmt_read         (mgmt_ctl_read & mgmt_fdd_cs),
	.mgmt_readdata     (mgmt_fdd_readdata),

	.request           (fdd_request),
	.irq               (irq_6)
);

hdd hdd0
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.io_address        ({iobus_address[9],iobus_address[2:0]}),
	.io_writedata      (iobus_writedata),
	.io_data_size      (iobus_datasize),
	.io_read           (iobus_read & hdd0_cs),
	.io_write          (iobus_write & hdd0_cs),
	.io_readdata       (hdd0_readdata),

	.mgmt_address      (mgmt_ctl_address[3:0]),
	.mgmt_write        (mgmt_ctl_write & mgmt_hdd0_cs),
	.mgmt_writedata    (mgmt_ctl_writedata),
	.mgmt_read         (mgmt_ctl_read & mgmt_hdd0_cs),
	.mgmt_readdata     (mgmt_hdd0_readdata),

	.request           (hdd0_request),
	.irq               (irq_14)
);

hdd hdd1
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.io_address        ({iobus_address[9],iobus_address[2:0]}),
	.io_writedata      (iobus_writedata),
	.io_data_size      (iobus_datasize),
	.io_read           (iobus_read & hdd1_cs),
	.io_write          (iobus_write & hdd1_cs),
	.io_readdata       (hdd1_readdata),

	.mgmt_address      (mgmt_ctl_address[3:0]),
	.mgmt_write        (mgmt_ctl_write & mgmt_hdd1_cs),
	.mgmt_writedata    (mgmt_ctl_writedata),
	.mgmt_read         (mgmt_ctl_read & mgmt_hdd1_cs),
	.mgmt_readdata     (mgmt_hdd1_readdata),

	.request           (hdd1_request),
	.irq               (irq_15)
);

joystick joystick
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.clk_grav          (joystick_clk_grav),

	.write             (iobus_write & joy_cs),
	.readdata          (joystick_readdata),

	.dig_1             (joystick_dig_1),
	.dig_2             (joystick_dig_2),
	.ana_1             (joystick_ana_1),
	.ana_2             (joystick_ana_2),
	.mode              (joystick_mode)
);

pit pit
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.clock_rate        (clock_rate),

	.io_address        ({iobus_address[5],iobus_address[1:0]}),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read & pit_cs),
	.io_write          (iobus_write & pit_cs),
	.io_readdata       (pit_readdata),

	.speaker_out       (speaker_out),
	.irq               (irq_0)
);

ps2 ps2
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.io_address        (iobus_address[3:0]),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read),
	.io_write          (iobus_write),
	.io_readdata       (ps2_readdata),
	.io_cs             (ps2_io_cs),
	.ctl_cs            (ps2_ctl_cs),

	.ps2_kbclk         (ps2_kbclk_in),
	.ps2_kbdat         (ps2_kbdat_in),
	.ps2_kbclk_out     (ps2_kbclk_out),
	.ps2_kbdat_out     (ps2_kbdat_out),

	.ps2_mouseclk      (ps2_mouseclk_in),
	.ps2_mousedat      (ps2_mousedat_in),
	.ps2_mouseclk_out  (ps2_mouseclk_out),
	.ps2_mousedat_out  (ps2_mousedat_out),

	.output_a20_enable (),
	.output_reset_n    (ps2_reset_n),
	.a20_enable        (a20_enable),

	.irq_keyb          (irq_1),
	.irq_mouse         (irq_12)
);

rtc rtc
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.clock_rate        (clock_rate),

	.io_address        (iobus_address[0]),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read & rtc_cs),
	.io_write          (iobus_write & rtc_cs),
	.io_readdata       (rtc_readdata),

	.mgmt_address      (mgmt_ctl_address),
	.mgmt_write        (mgmt_ctl_write & mgmt_rtc_cs),
	.mgmt_writedata    (mgmt_ctl_writedata[7:0]),

	.rtc_memcfg        (memcfg),

	.irq               (irq_8)
);

sound sound
(
	.clk               (clk_sys),
	.clk_opl           (clk_opl),
	.rst_n             (~reset),

	.clock_rate        (clock_rate),

	.address           (iobus_address[3:0]),
	.writedata         (iobus_writedata[7:0]),
	.read              (iobus_read),
	.write             (iobus_write),
	.readdata          (sound_readdata),
	.sb_cs             (sb_cs),
	.fm_cs             (fm_cs),

	.dma_req8          (dma_sb_req_8),
	.dma_req16         (dma_sb_req_16),
	.dma_ack           (dma_sb_ack_16 | dma_sb_ack_8),
	.dma_readdata      (dma_sb_req_16 ? dma_sb_readdata_16 : dma_sb_readdata_8),
	.dma_writedata     (dma_sb_writedata),

	.sample_l          (sound_sample_l),
	.sample_r          (sound_sample_r),

	.fm_mode           (sound_fm_mode),
	.cms_en            (sound_cms_en),

	.irq_5             (irq_5),
	.irq_7             (irq_7),
	.irq_10            (irq_10)
);

uart uart
(
	.clk               (clk_sys),
	.br_clk            (clk_uart),
	.reset             (reset),

	.address           (iobus_address[2:0]),
	.writedata         (iobus_writedata[7:0]),
	.read              (iobus_read),
	.write             (iobus_write),
	.readdata          (uart_readdata),
	.uart_cs           (uart_cs),
	.mpu_cs            (mpu_cs),

	.rx                (serial_rx),
	.tx                (serial_tx),
	.cts_n             (serial_cts_n),
	.dcd_n             (serial_dcd_n),
	.dsr_n             (serial_dsr_n),
	.rts_n             (serial_rts_n),
	.dtr_n             (serial_dtr_n),
	.br_out            (),
	.ri_n              (1),

	.midi_rate         (serial_midi_rate),

	.irq_uart          (irq_4),
	.irq_mpu           (irq_9)
);

vga vga
(
	.clk_sys           (clk_sys),
	.rst_n             (~reset),

	.clk_vga           (clk_vga),
	.clock_rate_vga    (clock_rate_vga),

	.io_address        (iobus_address[3:0]),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read),
	.io_write          (iobus_write),
	.io_readdata       (vga_io_readdata),
	.io_b_cs           (vga_b_cs),
	.io_c_cs           (vga_c_cs),
	.io_d_cs           (vga_d_cs),

	.mem_address       (vga_address),
	.mem_read          (vga_read),
	.mem_readdata      (vga_readdata),
	.mem_write         (vga_write),
	.mem_writedata     (vga_writedata),

	.vga_ce            (video_ce),
	.vga_blank_n       (video_blank_n),
	.vga_horiz_sync    (video_hsync),
	.vga_vert_sync     (video_vsync),
	.vga_r             (video_r),
	.vga_g             (video_g),
	.vga_b             (video_b),
	.vga_f60           (video_f60),
	.vga_memmode       (vga_memmode),
	.vga_pal_a         (video_pal_a),
	.vga_pal_d         (video_pal_d),
	.vga_pal_we        (video_pal_we),
	.vga_start_addr    (video_start_addr),
	.vga_wr_seg        (video_wr_seg),
	.vga_rd_seg        (video_rd_seg),
	.vga_width         (video_width),
	.vga_height        (video_height),
	.vga_flags         (video_flags),
	.vga_stride        (video_stride),
	.vga_off           (video_off),
	.vga_lores         (video_lores),

	.irq               (irq_2)
);

pic pic
(
	.clk               (clk_sys),
	.rst_n             (~reset),

	.io_address        (iobus_address[0]),
	.io_writedata      (iobus_writedata[7:0]),
	.io_read           (iobus_read),
	.io_write          (iobus_write),
	.io_readdata       (pic_readdata),
	.io_master_cs      (pic_master_cs),
	.io_slave_cs       (pic_slave_cs),

	.interrupt_vector  (interrupt_vector),
	.interrupt_done    (interrupt_done),
	.interrupt_do      (interrupt_do),
	.interrupt_input   (interrupt)
);


wire pci_io_waitrequest;
wire pci_io_readdatavalid;
wire [31:0] pci_io_readdata;

wire pci_mem_waitrequest;
wire pci_mem_readdatavalid;
wire [31:0] pci_mem_readdata;

wire pci_irq_out;
//assign irq_11 = pci_irq_out;

wire pci_mem_cs = 1'b0;	// todo !

pci pci_inst
(
	.clk(clk_sys) ,										// input  clk
	.rst_n(~reset) ,										// input  rst_n
	
	.io_address(iobus_address[2]) ,					// input  io_address
	.io_read(pci_io_cs & iobus_read) ,				// input  io_read
	.io_readdata(pci_io_readdata) ,					// output [31:0] io_readdata
	.io_write(pci_io_cs & iobus_write) ,			// input  io_write
	.io_writedata(iobus_writedata) ,					// input [31:0] io_writedata
	.io_waitrequest(pci_io_waitrequest) ,			// output  io_waitrequest
	.io_readdatavalid(pci_io_readdatavalid) ,		// output  io_readdatavalid
	
	.avm_address(mem_address) ,						// input [21:0] avm_address
	.avm_writedata(mem_writedata) ,					// input [31:0] avm_writedata
	.avm_byteenable(mem_byteenable) ,				// input [3:0] avm_byteenable
	.avm_burstcount(mem_burstcount) ,				// input [2:0] avm_burstcount
	.avm_write(pci_mem_cs & mem_write) ,			// input  avm_write
	.avm_read(pci_mem_cs & mem_read) ,				// input  avm_read
	.avm_waitrequest(pci_mem_waitrequest) ,		// output  avm_waitrequest
	.avm_readdatavalid(pci_mem_readdatavalid) ,	// output  avm_readdatavalid
	.avm_readdata(pci_mem_readdata) ,				// output [31:0] avm_readdata
	
	.pci_irq_out(pci_irq_out) ,						// output  pci_irq_out
	
	.PCI_AD(PCI_AD) ,					// inout [31:0] PCI_AD
	.PCI_CBE(PCI_CBE) ,				// inout [3:0] PCI_CBE
	.PCI_PAR(PCI_PAR) ,				// inout  PCI_PAR
	.PCI_IDSEL(PCI_IDSEL) ,			// inout  PCI_IDSEL
	.PCI_GNT_N(PCI_GNT_N) ,			// inout  PCI_GNT_N
	.PCI_SERR_N(PCI_SERR_N) ,		// inout  PCI_SERR_N
	.PCI_SBO_N(PCI_SBO_N) ,			// inout  PCI_SBO_N
	.PCI_SDONE(PCI_SDONE) ,			// inout  PCI_SDONE
	.PCI_PERR_N(PCI_PERR_N) ,		// inout  PCI_PERR_N
	.PCI_LOCK_N(PCI_LOCK_N) ,		// inout  PCI_LOCK_N
	.PCI_STOP_N(PCI_STOP_N) ,		// inout  PCI_STOP_N
	.PCI_DEVSEL_N(PCI_DEVSEL_N) ,	// inout  PCI_DEVSEL_N
	.PCI_TRDY_N(PCI_TRDY_N) ,		// inout  PCI_TRDY_N
	.PCI_IRDY_N(PCI_IRDY_N) ,		// inout  PCI_IRDY_N
	.PCI_FRAME_N(PCI_FRAME_N) ,	// inout  PCI_FRAME_N
	.PCI_REQ_N(PCI_REQ_N) ,			// inout  PCI_REQ_N
	.PCI_CLK(PCI_CLK) ,				// inout  PCI_CLK
	.PCI_RST_N(PCI_RST_N) ,			// inout  PCI_RST_N
	.PCI_PRSNT1_N(PCI_PRSNT1_N) ,	// input  PCI_PRSNT1_N
	.PCI_PRSNT2_N(PCI_PRSNT2_N) ,	// input  PCI_PRSNT2_N
	.PCI_INTA_N(PCI_INTA_N) ,		// input  PCI_INTA_N
	.PCI_INTB_N(PCI_INTB_N) ,		// input  PCI_INTB_N
	.PCI_INTC_N(PCI_INTC_N) ,		// input  PCI_INTC_N
	.PCI_INTD_N(PCI_INTD_N)			// input  PCI_INTD_N
);


always @* begin
	interrupt = 0;

	interrupt[0]  = irq_0;
	interrupt[1]  = irq_1;
	interrupt[4]  = irq_4;
	interrupt[5]  = irq_5;
	interrupt[6]  = irq_6;
	interrupt[7]  = irq_7;
	interrupt[8]  = irq_8;
	interrupt[9]  = irq_9 | irq_2;
	interrupt[10] = irq_10;
	interrupt[11] = irq_11;
	interrupt[12] = irq_12;
	interrupt[14] = irq_14;
	interrupt[15] = irq_15;
end

always @(posedge clk_sys) begin
	mgmt_hdd0_cs <= (mgmt_address[15:8] == 8'hF0);
	mgmt_hdd1_cs <= (mgmt_address[15:8] == 8'hF1);
	mgmt_fdd_cs  <= (mgmt_address[15:8] == 8'hF2);
	mgmt_rtc_cs  <= (mgmt_address[15:8] == 8'hF4);
end

mgmt mgmt
(
	.clk               (clk_sys),

	.in_address        (mgmt_address),
	.in_read           (mgmt_read),
	.in_readdata       (mgmt_readdata),
	.in_write          (mgmt_write),
	.in_writedata      (mgmt_writedata),
	.in_active         (mgmt_active),

	.out_address       (mgmt_ctl_address),
	.out_read          (mgmt_ctl_read),
	.out_write         (mgmt_ctl_write),
	.out_writedata     (mgmt_ctl_writedata),
	.out_readdata      (mgmt_hdd0_cs ? mgmt_hdd0_readdata : mgmt_hdd1_cs ? mgmt_hdd1_readdata : mgmt_fdd_readdata)
);

endmodule
