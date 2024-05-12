using TCLab
using LibSerialPort

tclab=TCLabDT()
LibSerialPort.open(tclab.sp)
LibSerialPort.set_speed(tclab.sp, tclab.baud)

TCLab.send_and_receive(tclab, "VER")
TCLab.send_and_receive(tclab, "LED 100", Float64)
TCLab.send_and_receive(tclab, "LED 0", Float64)
