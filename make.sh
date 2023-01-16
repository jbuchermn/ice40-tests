yosys -p 'synth_ice40 -top main -json main.json' main.v &&
nextpnr-ice40 --hx8k --json main.json --pcf alchitry_cu.pcf --package cb132 --asc main.asc &&
icepack main.asc main.bin &&
sudo iceprog main.bin
