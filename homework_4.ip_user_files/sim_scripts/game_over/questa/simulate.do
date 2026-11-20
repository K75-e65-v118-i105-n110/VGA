onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib game_over_opt

do {wave.do}

view wave
view structure
view signals

do {game_over.udo}

run -all

quit -force
