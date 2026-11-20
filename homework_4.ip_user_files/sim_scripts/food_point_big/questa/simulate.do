onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib food_point_big_opt

do {wave.do}

view wave
view structure
view signals

do {food_point_big.udo}

run -all

quit -force
