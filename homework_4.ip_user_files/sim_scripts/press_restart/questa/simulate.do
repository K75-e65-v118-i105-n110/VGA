onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib press_restart_opt

do {wave.do}

view wave
view structure
view signals

do {press_restart.udo}

run -all

quit -force
