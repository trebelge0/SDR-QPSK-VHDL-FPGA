vsim work.tb

add wave tb/uut/clk
add wave tb/uut/rst

add wave tb/uut/block_a/s_axis_tready
add wave tb/uut/block_a/s_axis_tvalid
add wave tb/uut/block_a/s_axis_tlast
add wave tb/uut/block_a/s_axis_tdata

add wave tb/uut/block_b/s_axis_tready
add wave tb/uut/block_b/s_axis_tvalid
add wave tb/uut/block_b/s_axis_tlast
add wave tb/uut/block_b/s_axis_tdata

add wave tb/uut/block_c/s_axis_tready
add wave tb/uut/block_c/s_axis_tvalid
add wave tb/uut/block_c/s_axis_tlast
add wave tb/uut/block_c/s_axis_tdata

add wave tb/uut/block_di/s_axis_tready
add wave tb/uut/block_di/s_axis_tvalid
add wave tb/uut/block_di/s_axis_tlast
add wave -format analog-step -radix signed -height 100 -min -1 -max 1 tb/uut/block_di/s_axis_tdata
add wave -format analog-step -radix signed -height 100 -min -1 -max 1 tb/uut/block_dq/s_axis_tdata

add wave tb/uut/block_e/mixer/sa_axis_tvalid
add wave tb/uut/block_e/mixer/sa_axis_tready
add wave -format analog-step -radix signed -height 100 -min -2048 -max 2047 tb/uut/block_e/mixer/sa_axis_sin_tdata
add wave -format analog-step -radix signed -height 100 -min -2048 -max 2047 tb/uut/block_e/mixer/sa_axis_cos_tdata

add wave tb/uut/block_e/mixer/sb_axis_tvalid
add wave tb/uut/block_e/mixer/sb_axis_tready
add wave tb/uut/block_e/mixer/sb_axis_tlast
add wave -format analog-step -radix signed -height 100 -min -256 -max 255 tb/uut/block_e/mixer/sb_axis_i_tdata 
add wave -format analog-step -radix signed -height 100 -min -256 -max 255 tb/uut/block_e/mixer/sb_axis_q_tdata 

add wave tb/uut/block_e/m_axis_tready
add wave tb/uut/block_e/m_axis_tvalid
add wave tb/uut/block_e/m_axis_tlast
add wave -format analog-step -radix signed -height 100 -min -2048 -max 2047 tb/uut/block_e/m_axis_tdata

run 3000 ns

#view list
#add list /tb/uut/block_di/m_axis_tdata
#add list /tb/uut/block_dq/m_axis_tdata
#add list /tb/uut/block_e/m_axis_tdata
#write list validation/data.txt