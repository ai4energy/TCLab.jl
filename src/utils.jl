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
    # 使用下面的函数组合，判断哪个是目标端口，返回port和arduino信息
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

function tclab_print_port_metadata(port::LibSerialPort.Port; show_config::Bool=true)
    println("\nPort name:\t",       LibSerialPort.Lib.sp_get_port_name(port))
    transport = LibSerialPort.Lib.sp_get_port_transport(port)
    print("\nPort transport:\t");
    if transport == LibSerialPort.SP_TRANSPORT_NATIVE
        println("native serial port")
    elseif transport == LibSerialPort.SP_TRANSPORT_USB
        println("USB")
        println("Manufacturer:\t",      LibSerialPort.Lib.sp_get_port_usb_manufacturer(port))
        println("Product:\t",           LibSerialPort.Lib.sp_get_port_usb_product(port))
        println("USB serial number:\t", LibSerialPort.Lib.sp_get_port_usb_serial(port))
        bus, addr = LibSerialPort.Lib.sp_get_port_usb_bus_address(port)
        println("USB bus #:\t", bus)
        println("Address on bus:\t", addr)
        vid, pid = LibSerialPort.Lib.sp_get_port_usb_vid_pid(port)
        println("Vendor ID:\t", vid)
        println("Product ID:\t", pid)
    elseif transport == LibSerialPort.SP_TRANSPORT_BLUETOOTH
        println("Bluetooth")
        println("Bluetooth address:\t", LibSerialPort.Lib.sp_get_port_bluetooth_address(port))
    end

    if show_config
        LibSerialPort.print_port_settings(port)
    end
    return nothing
end



