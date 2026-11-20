onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib food_point_small_opt

do {wave.do}

view wave
view structure
view signals

do {food_point_small.udo}

run -all

quit -force
