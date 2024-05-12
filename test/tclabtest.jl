include("../src/TCLab.jl")
using .TCLab
using LibSerialPort

tclab=TCLabDT()
TCLab.initialize!(tclab)
TCLab.close(tclab)
TCLab.connect!(tclab,19200)
LibSerialPort.set_speed(tclab.sp, tclab.baud)
LibSerialPort.isopen(tclab.sp)

TCLab.send_and_receive(tclab, "VER")
TCLab.send_and_receive(tclab, "LED 100", Float64)
TCLab.send_and_receive(tclab, "LED 0", Float64)
TCLab.send_and_receive(tclab, "Q1 200.0", Float64)
TCLab.send_and_receive(tclab, "P1 200.0", Float64)
TCLab.send_and_receive(tclab, "T1", Float64)
TCLab.send_and_receive(tclab, "P1 277.0", Float64)

TCLab.Q1(tclab, 277)
TCLab.T1(tclab)
TCLab.Q1(tclab, 0)