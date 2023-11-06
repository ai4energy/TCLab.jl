using TCLab

tclab=TCLabDT()
TCLab.send_and_receive(tclab, "VER")

TCLab.send_and_receive(tclab, "LED 100", Float64)
TCLab.send_and_receive(tclab, "LED 0", Float64)
