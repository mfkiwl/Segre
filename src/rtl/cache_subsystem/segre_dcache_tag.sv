import segre_pkg::*;

module segre_dcache_tag
    ( input logic clk_i,
      input logic rsn_i,
      input logic req_i,
      input logic mmu_data_i,
      input logic [WORD_SIZE-1:0] addr_i,
      input logic invalidate_i,
      output logic [DCACHE_INDEX_SIZE-1:0] addr_index_o,
      output logic hit_o,
      output logic miss_o
    );

localparam ADDR_BYTE_SIZE  = DCACHE_BYTE_SIZE;
localparam ADDR_INDEX_SIZE = DCACHE_INDEX_SIZE;
localparam LANE_SIZE       = DCACHE_LANE_SIZE;
localparam TAG_SIZE        = DCACHE_TAG_SIZE;
localparam NUM_LANES       = DCACHE_NUM_LANES;
localparam INDEX_SIZE = DCACHE_INDEX_SIZE;

typedef struct packed {
    logic valid;
    logic [TAG_SIZE-1:0] tag;
} tags_t;

tags_t [NUM_LANES-1:0] cache_tags;
logic  [TAG_SIZE-1:0] addr_tag;
logic  [ADDR_INDEX_SIZE-1:0] addr_index;
logic  [NUM_LANES-1:0] hit_vector;
logic  tag_hit;

// Help Functions
function logic[INDEX_SIZE-1:0] one_hot_to_binary(logic [NUM_LANES-1:0] one_hot);
    static logic [INDEX_SIZE-1:0] ret = 0;
    foreach(one_hot[index]) begin
        if (one_hot[index] == 1'b1) begin
            ret |= index;
        end
    end
    return ret;
endfunction

assign addr_tag   = addr_i[WORD_SIZE-1:ADDR_INDEX_SIZE+ADDR_BYTE_SIZE];
assign addr_index = addr_i[ADDR_INDEX_SIZE+ADDR_BYTE_SIZE-1:ADDR_BYTE_SIZE];

always_ff @(posedge clk_i) begin : tag_reset
    if (!rsn_i) begin
        for (int i = 0; i < NUM_LANES; i++) begin
            cache_tags[i].valid <= 0;
            cache_tags[i].tag   <= 0;
        end
    end 
end

always_ff @(posedge clk_i) begin : invalidate_tags
    if (invalidate_i) begin
        for (int i = 0; i < NUM_LANES; i++) begin
            cache_tags[i].valid <= 0;
        end
    end 
end

always_ff @(posedge clk_i) begin : update_tag
    if (mmu_data_i) begin
        cache_tags[addr_index].valid <= 1;
        cache_tags[addr_index].tag <= addr_tag;
    end
end

always_comb begin : tag_rd
    for(int i=0; i<NUM_LANES; i++) begin
        hit_vector[i] = (cache_tags[i].tag == addr_tag) & cache_tags[i].valid;
    end
    tag_hit = |hit_vector;
end

assign addr_index_o = one_hot_to_binary(hit_vector);
assign hit_o = tag_hit & req_i;
assign miss_o = ~tag_hit & req_i;

endmodule : segre_dcache_tag