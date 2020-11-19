package segre_pkg;

/*****************
*    OPCODES     *
*****************/
typedef enum logic [6:0] {
  OPCODE_LOAD     = 7'h03,
  OPCODE_MISC_MEM = 7'h0f,
  OPCODE_OP_IMM   = 7'h13,
  OPCODE_AUIPC    = 7'h17,
  OPCODE_STORE    = 7'h23,
  OPCODE_OP       = 7'h33,
  OPCODE_LUI      = 7'h37,
  OPCODE_BRANCH   = 7'h63,
  OPCODE_JALR     = 7'h67,
  OPCODE_JAL      = 7'h6f,
  OPCODE_SYSTEM   = 7'h73
} opcode_e;

typedef enum logic [5:0] {
    ALU_ADD,
    ALU_SUB,
    ALU_SLL,
    ALU_SLT,
    ALU_SLTU,
    ALU_XOR,
    ALU_SRL,
    ALU_SRA,
    ALU_OR,
    ALU_AND,
    ALU_JAL,
    ALU_JALR,
    ALU_BEQ,
    ALU_BNE,
    ALU_BLT,
    ALU_BGE,
    ALU_BLTU,
    ALU_BGEU,
    ALU_AUIPC,
    ALU_MUL,
    ALU_MULH,
    ALU_MULHU,
    ALU_MULHSU,
    ALU_DIV,
    ALU_DIVU,
    ALU_REM,
    ALU_REMU
} alu_opcode_e;

/*****************
* ALU PARAMETERS *
*****************/
typedef enum logic[1:0] {
    ALU_A_REG,
    ALU_A_IMM,
    ALU_A_PC
} alu_src_a_e;

typedef enum logic[1:0] {
    ALU_B_REG,
    ALU_B_IMM
} alu_src_b_e;

typedef enum logic {
    BR_A_REG,
    BR_A_PC
} br_src_a_e;

typedef enum logic {
    BR_B_REG
} br_src_b_e;

typedef enum logic[2:0] {
    IMM_B_I,
    IMM_B_U,
    IMM_B_J,
    IMM_B_B,
    IMM_B_S
} alu_imm_b_e;

typedef enum logic {
    IMM_A_ZERO
} alu_imm_a_e;

typedef enum logic [2:0] {
    IF_STATE = 0,
    ID_STATE,
    EX_STATE,
    MEM_STATE,
    WB_STATE
} fsm_state_e;

typedef enum logic [1:0] {
    BYTE,
    HALF,
    WORD
} memop_data_type_e;

typedef enum logic [2:0] {
    DCACHE_REQ,
    DCACHE_WAIT,
    ICACHE_REQ,
    ICACHE_WAIT,
    IDLE
} mmu_fsm_state_e;

/********************
* SEGRE  DATATYPES  *
********************/
typedef struct packed {
    logic req;
    logic mmu_data;
    logic [WORD_SIZE-1:0] addr;
    logic [DCACHE_INDEX_SIZE-1:0] lru_index;
    logic invalidate;
    logic hit;
    logic miss;
} dcache_tag_t;

typedef struct packed {
    logic rd_data;
    logic wr_data;
    logic mmu_wr_data;
    logic [WORD_SIZE-1:0] addr;
    memop_data_type_e memop_data_type;
    logic [WORD_SIZE-1:0] data;
    logic [DCACHE_LANE_SIZE-1:0] mmu_data;
    logic [WORD_SIZE-1:0] data;
} dcache_data_t;

typedef struct packed {
    logic req_store;
    logic req_load;
    logic flush_chance;
    logic [ADDR_SIZE-1:0] addr;
    logic [WORD_SIZE-1:0] data;
    memop_data_type_e memop_data_type;
    logic hit;
    logic miss;
    logic full;
    logic data_valid;
    logic [WORD_SIZE-1:0] data;
    logic [ADDR_SIZE-1:0] addr;
} store_buffer_t;

typedef struct packed {
    logic [WORD_SIZE-1:0] addr;
    logic mem_rd;
    logic [WORD_SIZE-1:0] new_pc;
    logic tkbr;
} core_if_t

typedef struct packed {
    logic [WORD_SIZE-1:0] instr;
} core_id_t

typedef struct packed {
    memop_data_type_e memop_type;
    logic [WORD_SIZE-1:0] alu_src_a;
    logic [WORD_SIZE-1:0] alu_src_b;
    logic [WORD_SIZE-1:0] rf_st_data;
    logic rf_we;
    logic [REG_SIZE-1:0] rf_waddr;
    alu_opcode_e alu_opcode;
    logic memop_rd;
    logic memop_wr;
    logic memop_sign_ext;
    logic [WORD_SIZE-1:0] br_src_a;
    logic [WORD_SIZE-1:0] br_src_b;
} core_ex_t

typedef struct packed {
} core_tl_t

typedef struct packed {
    memop_data_type_e memop_type;
    memop_data_type_e data_type;
    logic [WORD_SIZE-1:0] alu_res;
    logic [WORD_SIZE-1:0] addr;
    logic [WORD_SIZE-1:0] wr_data;
    logic [WORD_SIZE-1:0] rf_st_data;
    logic [REG_SIZE-1:0]  rf_waddr;
    logic memop_rd;
    logic memop_wr;
    logic memop_sign_ext;
    logic rf_we;
    logic rd;
    logic wr;
    logic tkbr;
    logic [WORD_SIZE-1:0] new_pc;
} core_mem_t

typedef struct packed {
    logic [REG_SIZE-1:0] raddr_a;
    logic [REG_SIZE-1:0] raddr_b;
    logic [REG_SIZE-1:0] waddr_w;
    logic [WORD_SIZE-1:0] data_a;
    logic [WORD_SIZE-1:0] data_b;
    logic [WORD_SIZE-1:0] data_w;
    logic we;
} core_rf_t

typedef struct packed {
    logic dc_miss;
    logic [ADDR_SIZE-1:0] dc_addr_i;
    logic dc_store;
    logic [DCACHE_LANE_SIZE-1:0] dc_data_i;
    logic dc_access;
    logic dc_mmu_data_rdy;
    logic [DCACHE_LANE_SIZE-1:0] dc_data_o;
    logic [ADDR_SIZE-1:0] dc_addr_o;
    logic ic_miss;
    logic [ADDR_SIZE-1:0] ic_addr_i;
    logic ic_access;
    logic ic_mmu_data_rdy;
    logic [ICACHE_LANE_SIZE-1:0] ic_data;
    logic [ADDR_SIZE-1:0] ic_addr_o;
} core_mmu_t

/********************
* RISC-V PARAMETERS *
********************/

parameter WORD_SIZE = 32;
parameter ADDR_SIZE = 32;
parameter REG_SIZE  = 5;

/********************
* SEGRE  PARAMETERS *
********************/
/** DATA CACHE **/
parameter DCACHE_NUM_LANES = 4;
parameter DCACHE_BYTES_PER_LANE = 16;
parameter DCACHE_LANE_SIZE = DCACHE_BYTES_PER_LANE * 8;
parameter DCACHE_BYTE_SIZE = $clog2(DCACHE_BYTES_PER_LANE);
parameter DCACHE_INDEX_SIZE = $clog2(DCACHE_NUM_LANES);
parameter DCACHE_TAG_SIZE = ADDR_SIZE - DCACHE_BYTE_SIZE - DCACHE_INDEX_SIZE;

/** INSTRUCTIONS CACHE **/
parameter ICACHE_NUM_LANES = 4;
parameter ICACHE_BYTES_PER_LANE = 16;
parameter ICACHE_LANE_SIZE = ICACHE_BYTES_PER_LANE * 8;
parameter ICACHE_BYTE_SIZE = $clog2(ICACHE_BYTES_PER_LANE);
parameter ICACHE_INDEX_SIZE = $clog2(ICACHE_NUM_LANES);
parameter ICACHE_TAG_SIZE = ADDR_SIZE - ICACHE_BYTE_SIZE - ICACHE_INDEX_SIZE;

/** STORE BUFFER **/
parameter STORE_BUFFER_NUM_ELEMS = 2;

endpackage : segre_pkg
