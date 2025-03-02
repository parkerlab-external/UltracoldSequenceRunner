function out_i32 = U32toI32(in_u32)

out_i32 = int32(bitshift(bitshift(int64(uint32(in_u32)),32),-32));