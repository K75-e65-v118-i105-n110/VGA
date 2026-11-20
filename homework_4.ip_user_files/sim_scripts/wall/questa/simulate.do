onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib wall_opt

do {wave.do}

view wave
view structure
view signals

do {wall.udo}

run -all

quit -force
