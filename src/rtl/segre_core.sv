import segre_pkg::*;

module segre_core (
    // Clock and Reset
    input logic clk_i,
    input logic rsn_i,

    // Main memory signals
    input  logic mm_data_rdy_i,
    input  logic [DCACHE_LANE_SIZE-1:0] mm_rd_data_i,
    output logic [DCACHE_LANE_SIZE-1:0] mm_wr_data_o,
    output logic [ADDR_SIZE-1:0] mm_addr_o,
    output logic [ADDR_SIZE-1:0] mm_wr_addr_o,
    output logic mm_rd_o,
    output logic mm_wr_o
    //output memop_data_type_e mm_wr_data_type_o
);

core_if_t core_if;
core_id_t core_id;
core_pipeline_t core_pipeline;
rf_wdata_t rf_wdata;
decode_rf_t decode_rf;
core_mmu_t core_mmu;
core_hazards_t input_hazards;
core_hazards_t output_hazards;
core_hf_t core_hf;
core_csr_t core_csr;
logic mem_wr_done;
logic [HF_PTR-1:0] mem_wr_done_id;


assign input_hazards.ifs = output_hazards.id; 

segre_if_stage if_stage (
    // Clock and Reset
    .clk_i              (clk_i),
    .rsn_i              (rsn_i),
    // Hazard
    .hazard_i           (input_hazards.ifs),
    .hazard_o           (output_hazards.ifs),
    // Exceptions
    .hf_recovering_i    (core_hf.recovering),
    .csr_stvec_i        (core_csr.csr_stvec),
    // IF ID interface
    .instr_o            (core_id.instr),
    .pc_o               (core_id.pc),
    // WB interface
    .tkbr_i             (core_if.tkbr),
    .new_pc_i           (core_if.new_pc),
    .branch_completed_i (core_if.branch_completed),
    // MMU interface
    .mmu_data_i         (core_mmu.ic_mmu_data_rdy),
    .mmu_wr_data_i      (core_mmu.ic_data),
    .mmu_lru_index_i    (core_mmu.ic_lru_index),
    .ic_miss_o          (core_mmu.ic_miss),
    .ic_addr_o          (core_mmu.ic_addr_i),
    .ic_access_o        (core_mmu.ic_access),
    .csr_priv_i         (core_csr.csr_priv),
    .csr_satp_i         (core_csr.csr_satp)
);

segre_id_stage id_stage (
    // Clock and Reset
    .clk_i            (clk_i),
    .rsn_i            (rsn_i),
    // Hazard
    .tl_hazard_i      (output_hazards.pipeline),
    .hf_full_i        (core_hf.full),
    .hazard_o         (output_hazards.id),
    //.hf_recovering_o  (core_hf.recovering),
    // IF ID interface
    .instr_i          (core_id.instr),
    .pc_i             (core_id.pc),
    // Register file read operands
    .rf_raddr_a_o     (decode_rf.raddr_a),
    .rf_raddr_b_o     (decode_rf.raddr_b),
    .csr_raddr_o      (core_csr.raddr),
    .rf_data_a_i      (decode_rf.data_a),
    .rf_data_b_i      (decode_rf.data_b),
    .csr_data_i       (core_csr.data_o),
    // Bypass
    .bypass_data_i    (core_id.bypass_data),
    // ID EX interface
    .new_hf_entry_o   (core_hf.new_hf_entry),
    .instr_id_o       (core_pipeline.instr_id),
    .pc_o             (core_hf.instr_pc),
    // ALU
    .alu_opcode_o     (core_pipeline.alu_opcode),
    .alu_src_a_o      (core_pipeline.alu_src_a),
    .alu_src_b_o      (core_pipeline.alu_src_b),
    // Register file
    .rf_we_o          (core_pipeline.rf_we),
    .rf_waddr_o       (core_pipeline.rf_waddr),
    // Memop
    .memop_type_o     (core_pipeline.memop_type),
    .memop_rd_o       (core_pipeline.memop_rd),
    .memop_wr_o       (core_pipeline.memop_wr),
    .memop_sign_ext_o (core_pipeline.memop_sign_ext),
    .memop_rf_data_o  (core_pipeline.rf_st_data),
    // Branch | Jump
    .br_src_a_o       (core_pipeline.br_src_a),
    .br_src_b_o       (core_pipeline.br_src_b),
    // Pipeline
    .pipeline_o       (core_pipeline.pipeline),
    .is_branch_jal_o  (core_pipeline.is_branch_jal),
    // Bypass
    .bypass_a_o       (core_pipeline.bypass_a),
    .bypass_b_o       (core_pipeline.bypass_b),
    // CSR
    .csr_access_o     (core_pipeline.csr_access),
    .csr_waddr_o      (core_pipeline.csr_waddr)
);

segre_pipeline_wrapper pipeline_wrapper (
    // Clock & Reset
    .clk_i                 (clk_i),
    .rsn_i                 (rsn_i),
    // Decode information
    .core_pipeline_i       (core_pipeline),
    // Kill instructions in pipeline
    .kill_i                (core_hf.recovering),
    // Register File
    .rf_data_o             (rf_wdata),
    // CSR File
    .csr_access_o          (core_csr.we),
    .csr_waddr_o           (core_csr.waddr),
    .csr_data_o            (core_csr.data_i),
    // Instruction ID
    .ex_instr_id_o         (core_hf.ex_complete_id),
    .mem_instr_id_o        (core_hf.mem_complete_id),
    .rvm_instr_id_o        (core_hf.rvm_complete_id),
    // Store completed
    .mem_wr_done_o         (mem_wr_done),
    .mem_wr_done_id_o      (mem_wr_done_id),
    // Branch & Jump
    .branch_completed_o    (core_if.branch_completed),
    .tkbr_o                (core_if.tkbr),
    .new_pc_o              (core_if.new_pc),
    // MMU
    .mmu_data_rdy_i        (core_mmu.dc_mmu_data_rdy),
    .mmu_addr_i            (core_mmu.dc_mm_addr_o),
    .mmu_data_i            (core_mmu.dc_data_o),
    .mmu_lru_index_i       (core_mmu.dc_lru_index),
    .mmu_miss_o            (core_mmu.dc_miss),
    .mmu_addr_o            (core_mmu.dc_addr_i),
    .mmu_cache_access_o    (core_mmu.dc_access),
    .mmu_data_o            (core_mmu.dc_data_i),
    .mmu_writeback_o       (core_mmu.dc_mmu_writeback),
    // Bypass
    .bypass_data_o         (core_id.bypass_data),
    // Hazard
    .tl_hazard_o           (output_hazards.pipeline),
    //Privilege mode
    .csr_priv_i            (core_csr.csr_priv),
    //Virtual mem
    .csr_satp_i            (core_csr.csr_satp),
    // Exceptions
    .pp_exception_o        (core_hf.exc),
    .pp_exception_id_o     (core_hf.exc_id),
    .pp_addr_o             (core_csr.pp_addr)
);

segre_register_file segre_rf (
    // Clock and Reset
    .clk_i            (clk_i),
    .rsn_i            (rsn_i),

    .raddr_a_i        (decode_rf.raddr_a),
    .data_a_o         (decode_rf.data_a),
    .raddr_b_i        (decode_rf.raddr_b),
    .data_b_o         (decode_rf.data_b),
    .raddr_w_i        (core_pipeline.rf_waddr),
    .data_w_o         (core_hf.rf_data),
    .wdata_i          (rf_wdata),
    .recovering_i     (core_hf.recovering),
    .reg_recovered_i  (core_hf.dest_reg),
    .data_recovered_i (core_hf.value)
);

segre_csr_file segre_csr (
    .clk_i   (clk_i),
    .rsn_i   (rsn_i),

    .we_i    (core_csr.we),
    .raddr_i (core_csr.raddr),
    .waddr_i (core_csr.waddr),
    .data_i  (core_csr.data_i),
    .data_o  (core_csr.data_o),
    
    .pc_exc_i (core_hf.pc_fault),
    .addr_exc_i (core_csr.pp_addr),
    
    // Exceptions
    .pp_exc_i     (core_hf.exc),

    // CSR outputs
    .sie_o        (core_csr.sie),
    .csr_satp_o   (core_csr.csr_satp),
    .csr_priv_o   (core_csr.csr_priv),
    .csr_sepc_o   (core_csr.csr_sepc),
    .csr_stvec_o  (core_csr.csr_stvec)
);

segre_mmu mmu (
    .clk_i                (clk_i),
    .rsn_i                (rsn_i),
    // Exceptions
    .exc_i                (core_hf.exc),
    // Data chache
    .dc_miss_i            (core_mmu.dc_miss),
    .dc_addr_i            (core_mmu.dc_addr_i),
    .dc_writeback_i       (core_mmu.dc_mmu_writeback),
    .dc_data_i            (core_mmu.dc_data_i),
    .dc_access_i          (core_mmu.dc_access),
    .dc_mmu_data_rdy_o    (core_mmu.dc_mmu_data_rdy),
    .dc_data_o            (core_mmu.dc_data_o),
    .dc_lru_index_o       (core_mmu.dc_lru_index),
    .dc_mm_addr_o         (core_mmu.dc_mm_addr_o),
    // Instruction cache
    .ic_miss_i            (core_mmu.ic_miss),
    .ic_addr_i            (core_mmu.ic_addr_i),
    .ic_access_i          (core_mmu.ic_access),
    .ic_mmu_data_rdy_o    (core_mmu.ic_mmu_data_rdy),
    .ic_data_o            (core_mmu.ic_data),
    .ic_lru_index_o       (core_mmu.ic_lru_index),
    // Main memory
    .mm_data_rdy_i        (mm_data_rdy_i),
    .mm_data_i            (mm_rd_data_i), // If $D and $I have different LANE_SIZE we need to change this
    .mm_rd_req_o          (mm_rd_o),
    .mm_wr_req_o          (mm_wr_o),
    //.mm_wr_data_type_o    (mm_wr_data_type_o),
    .mm_addr_o            (mm_addr_o),
    .mm_wr_addr_o         (mm_wr_addr_o),
    .mm_data_o            (mm_wr_data_o)
);

assign core_hf.ex_complete  = rf_wdata.ex_we;
assign core_hf.mem_complete = rf_wdata.mem_we;
assign core_hf.rvm_complete = rf_wdata.rvm_we;

segre_history_file history_file (
    .clk_i              (clk_i),
    .rsn_i              (rsn_i),
    // Input data from id
    .sie_i              (core_csr.sie),
    .req_i              (core_hf.new_hf_entry),
    .store_i            (core_pipeline.memop_wr),
    .dest_reg_i         (core_pipeline.rf_waddr),
    .current_value_i    (core_hf.rf_data),
    .pc_i               (core_hf.instr_pc),
    .exc_i              (core_hf.exc),
    .exc_id_i           (core_hf.exc_id),
    .complete_ex_i      (core_hf.ex_complete),
    .complete_ex_id_i   (core_hf.ex_complete_id),
    .complete_mem_i     (core_hf.mem_complete),
    .complete_mem_id_i  (core_hf.mem_complete_id),
    .complete_st_i      (mem_wr_done),
    .complete_st_id_i   (mem_wr_done_id),
    .complete_rvm_i     (core_hf.rvm_complete),
    .complete_rvm_id_i  (core_hf.rvm_complete_id),
    .full_o             (core_hf.full),
    .empty_o            (core_hf.empty),
    .store_permission_o (core_pipeline.store_permission),
    .recovering_o       (core_hf.recovering),
    .dest_reg_o         (core_hf.dest_reg),
    .value_o            (core_hf.value),
    .pc_o               (core_hf.pc_fault)
);

endmodule : segre_core