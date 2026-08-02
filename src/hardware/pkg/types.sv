package rv32i_types;
  typedef enum logic [6:0] {
    op_lui       = 7'b0110111, // load upper imemediate (U type)
    op_auipc     = 7'b0010111, // add upper imemediate PC (U type)
    op_jal       = 7'b1101111, // jump and link (J type)
    op_jalr      = 7'b1100111, // jump and link register (I type)
    op_br        = 7'b1100011, // branch (B type)
    op_load      = 7'b0000011, // load (I type)
    op_store     = 7'b0100011, // store (S type)
    op_imm       = 7'b0010011, // arith ops with register/imemediate operands (I type)
    op_reg       = 7'b0110011, // arith ops with register operands (R type)
    op_system    = 7'b1110011  // system instructions (I type)
  } rv32i_opcode;

  typedef enum logic [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
  } branch_funct3_t;

  typedef enum logic [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
  } load_funct3_t;

  typedef enum logic [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
  } store_funct3_t;

  typedef enum logic [2:0] {
    add  = 3'b000, //check logic 30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check logic 30 for logical/arithmetic
    aor  = 3'b110,
    aand  = 3'b111
  } arith_funct3_t;

  typedef enum logic [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
  } alu_ops;

  typedef struct packed {
    logic valid;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] inst;
  } if_id_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] inst;
    logic [4:0] rd_s;
    logic [4:0] rs1_s;
    logic [4:0] rs2_s;
    logic [31:0] rs1_v;
    logic [31:0] rs2_v;
    // standard CSR fields
    logic csr_we;
    logic [4:0]  csr_rd_s;
    logic [31:0] csr_rdata;
    // trap CSR fields
    logic trap;
    logic [31:0] trap_cause;
  } id_ex_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] inst;
    logic [4:0] rd_s;
    logic [31:0] rd_v;
    logic [4:0] rs1_s;
    logic [4:0] rs2_s;
    logic [31:0] rs1_v;
    logic [31:0] rs2_v;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_rmask;
    logic [3:0]  mem_wmask;
    logic sign;
    // standard CSR fields
    logic csr_we;
    logic [4:0]  csr_rd_s;
    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
    // trap CSR fields
    logic trap;
    logic [31:0] trap_cause;
  } ex_mem_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] inst;
    logic [4:0] rd_s;
    logic [31:0] rd_v;
    logic [4:0] rs1_s;
    logic [4:0] rs2_s;
    logic [31:0] rs1_v;
    logic [31:0] rs2_v;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_rmask;
    logic [3:0]  mem_wmask;
    logic [31:0] mem_rdata;
    // standard CSR fields
    logic csr_we;
    logic [4:0]  csr_rd_s;
    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
    // trap CSR fields
    logic trap;
    logic [31:0] trap_cause;
  } mem_wb_t;

  typedef struct packed {
    logic [4:0]  rd_s;
    logic [31:0] rd_v;
    logic        trap;
    logic [4:0]  csr_rd_s;
    logic [31:0] csr_rd_v;
    logic [31:0] trap_pc;
    logic [31:0] trap_cause;
  } fwd_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] inst;
    logic [4:0] rd_s;
    logic [31:0] rd_v;
    logic [4:0] rs1_s;
    logic [31:0] rs1_v;
    logic [4:0] rs2_s;
    logic [31:0] rs2_v;
    logic [3:0]  mem_wmask;
    logic [3:0]  mem_rmask;
    logic [31:0] mem_addr;
    logic [31:0] mem_rdata;
    logic [31:0] mem_wdata;
    logic [31:0] order;
    logic csr_we;
    logic [4:0]  csr_rd_s;
    logic [31:0] csr_rdata;
    logic [31:0] csr_wdata;
  } commit_intf_t;

  localparam NUM_CSR_REGS = 32;

  typedef enum logic [11:0] {
    csr_sstatus     = 12'h100,
    csr_sie         = 12'h104,
    csr_stvec       = 12'h105,
    csr_sscratch    = 12'h140,
    csr_sepc        = 12'h141,
    csr_scause      = 12'h142,
    csr_stval       = 12'h143,
    csr_sip         = 12'h144,
    csr_mstatus     = 12'h300,
    csr_mie         = 12'h304,
    csr_mtvec       = 12'h305,
    csr_mstatush    = 12'h310,
    csr_mscratch    = 12'h340,
    csr_mepc        = 12'h341,
    csr_mcause      = 12'h342,
    csr_mtval       = 12'h343,
    csr_mip         = 12'h344,
    csr_mnscratch   = 12'h740,
    csr_mnepc       = 12'h741,
    csr_mncause     = 12'h742,
    csr_mnstatus    = 12'h744
  } csr_t;
  
  typedef enum logic [4:0] {
    csr_invalid_reg     = 5'b00000,
    csr_sstatus_reg     = 5'b00001,
    csr_sie_reg         = 5'b00010,
    csr_stvec_reg       = 5'b00011,
    csr_sscratch_reg    = 5'b00100,
    csr_sepc_reg        = 5'b00101,
    csr_scause_reg      = 5'b00110,
    csr_stval_reg       = 5'b00111,
    csr_sip_reg         = 5'b01000,
    csr_mstatus_reg     = 5'b01001,
    csr_mie_reg         = 5'b01010,
    csr_mtvec_reg       = 5'b01011,
    csr_mstatush_reg    = 5'b01100,
    csr_mscratch_reg    = 5'b01101,
    csr_mepc_reg        = 5'b01110,
    csr_mcause_reg      = 5'b01111,
    csr_mtval_reg       = 5'b10000,
    csr_mip_reg         = 5'b10001,
    csr_mnscratch_reg   = 5'b10010,
    csr_mnepc_reg       = 5'b10011,
    csr_mncause_reg     = 5'b10100,
    csr_mnstatus_reg    = 5'b10101
  } csr_regfile_t;
  
  typedef enum logic [3:0] {
    umode_trap = 4'h8,
    smode_trap = 4'h9,
    mmode_trap = 4'hB,
    breakpoint = 4'h3
  } mcause_t;

  typedef enum logic [1:0] {
    umode = 2'b00,
    smode = 2'b01,
    mmode = 2'b11
  } priv_t;

  typedef struct packed {
      logic        sd;     // bit 31
      logic [5:0]  wpri2;  // bit 30:25
      logic        sdt;    // bit 24
      logic        spelp;  // bit 23
      logic        tsr;    // bit 22
      logic        tw;     // bit 21
      logic        tvm;    // bit 20
      logic        mxr;    // bit 19
      logic        sum;    // bit 18
      logic        mprv;   // bit 17
      logic [1:0]  xs;     // bit 16:15
      logic [1:0]  fs;     // bit 14:13
      logic [1:0]  mpp;    // bit 12:11
      logic [1:0]  vs;     // bit 10:9
      logic        spp;    // bit 8
      logic        mpie;   // bit 7
      logic        ube;    // bit 6
      logic        spie;   // bit 5
      logic        wpri1;  // bit 4
      logic        mie;    // bit 3
      logic        wpri0;  // bit 2
      logic        sie;    // bit 1
      logic        wpri3;  // bit 0
  } mstatus_t;

  
  typedef union packed {
    logic [31:0] val;
    mstatus_t f;
  } mstatus_union_t;

  localparam mstatus_union_t MSTATUS_WMASK = '{
    val: 32'h806279AA // Spike's enabled mstatus bits
  };

  localparam logic[31:0] MTVEC_WMASK = 32'hFFFFFFFD; // MODE 2'b11 and 2'b10 are invalid, so disable bit 1


endpackage