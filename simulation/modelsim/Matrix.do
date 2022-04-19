transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/tonix/Documents/QuartusCinves/MatrixMul {/home/tonix/Documents/QuartusCinves/MatrixMul/FSM.v}
vlog -vlog01compat -work work +incdir+/home/tonix/Documents/QuartusCinves/MatrixMul {/home/tonix/Documents/QuartusCinves/MatrixMul/config.v}
vlog -vlog01compat -work work +incdir+/home/tonix/Documents/QuartusCinves/MatrixMul {/home/tonix/Documents/QuartusCinves/MatrixMul/Matrix_Mul.v}
vlog -vlog01compat -work work +incdir+/home/tonix/Documents/QuartusCinves/MatrixMul {/home/tonix/Documents/QuartusCinves/MatrixMul/FXP.v}
vlog -vlog01compat -work work +incdir+/home/tonix/Documents/QuartusCinves/MatrixMul {/home/tonix/Documents/QuartusCinves/MatrixMul/RAM.v}

vlog -vlog01compat -work work +incdir+/home/tonix/Documents/QuartusCinves/MatrixMul/test {/home/tonix/Documents/QuartusCinves/MatrixMul/test/MatrixFIxed_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  MatrixFIxed_tb

radix define States {
	5'b000001 "IDLE"     -color cyan,
	5'b000010 "WRITEMEM" -color yellow,
	5'b000100 "READ_B"   -color "spring green",
	5'b001000 "READ_A",  -color white,
	5'b010000 "FXP_CHECK" -color magenta,
	5'b100000 "EXPORT_ROWS" -color plum,
	-default hex
	-defaultcolor red
}


add wave -position insertpoint sim:/MatrixFIxed_tb/src_clk

#******* MEMORY *******
#add wave -position insertpoint sim:/MatrixFIxed_tb/we
#add wave -radix hex -position insertpoint sim:/MatrixFIxed_tb/data_wr
#add wave -radix unsigned -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/addr
#add wave -radix unsigned -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/mem/addr
#add wave -radix unsigned -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/mem/addr_reg
#add wave -radix hex -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/mem/q
#add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/mem/ram

#******* STATES *******
add wave -radix States -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/status

#***** A and B *****
add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/A
add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/B
add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/AB

#******MEM REGISTERS HELPERS*****
#add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/addr_rd
#add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/hold
#add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/addr_set
#add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/rd_ack

#******** FXP ********
add wave -radix hex -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/fxp_stage
add wave -radix hex -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/C
add wave -radix hex -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/TEMP
add wave -radix hex -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/row_cnt

add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/Sum
add wave -position insertpoint sim:/MatrixFIxed_tb/Matrix_Mul_dut/QI_out sim:/MatrixFIxed_tb/Matrix_Mul_dut/QF_out




view structure
view signals
run -all
