using LibSerialPort
function clip(val, lower=0, upper=100)
    # Limit value to be between lower and upper limits
    return max(lower, min(val, upper))
end

function command(name, argument, lower=0, upper=100)
    # Construct command to TCLab-sketch
    return string(name, " ", clip(argument, lower, upper))
end

function find_arduino()    
end

list_ports()

sp=LibSerialPort.open("COM5", 115200)

write(sp, "VER\n")
sleep(0.1)
println(readline(sp))

LibSerialPort.close(sp)