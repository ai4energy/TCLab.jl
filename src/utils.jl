using LibSerialPort

function clip(val, lower=0, upper=100)
    # Limit value to be between lower and upper limits
    return max(lower, min(val, upper))
end

function command(name, argument, lower=0, upper=100)
    # Construct command to TCLab-sketch
    return string(name, " ", clip(argument, lower, upper))
end

"""Locates Arduino and returns port and device."""
function find_arduino()


## 使用下面的函数组合，判断哪个是目标端口，返回port和arduino信息
    # LibSerialPort.close(sp)
    # spp = LibSerialPort.sp_get_port_by_name("COM7")
    # LibSerialPort.sp_get_port_name(spp)
    # LibSerialPort.sp_get_port_description(sp.ref)
    # LibSerialPort.sp_get_port_usb_vid_pid(spp)
    # LibSerialPort.sp_get_port_transport(sp.ref)
    # LibSerialPort.sp_get_port_usb_manufacturer(sp.ref)
    # LibSerialPort.sp_get_port_usb_serial(sp.ref)
    # LibSerialPort.sp_get_port_usb_bus_address(sp.ref)
    # LibSerialPort.get_port_settings(sp.ref)
    # LibSerialPort.print_port_settings(sp.ref)
    # LibSerialPort.get_port_list()
    return "COM7", "Arduino Uno (COM7)"
end

find_arduino()
list_ports()
sp = LibSerialPort.open("COM7", 9600)
write(sp, "VER\n")
sleep(0.1)
println(readline(sp))
LibSerialPort.close(sp)






