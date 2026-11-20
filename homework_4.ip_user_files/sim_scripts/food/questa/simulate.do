onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib food_opt

do {wave.do}

view wave
view structure
view signals

do {food.udo}

run -all

quit -force
