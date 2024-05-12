#using TCLab
using LibSerialPort
LibSerialPort.list_ports()

#---------------------------------------
# 下面这一行手动修改，打开串口
#---------------------------------------
sp = LibSerialPort.open("COM3", 19200)

#---------------------------------------
# 以下调用LibSerialPort库来看各种信息
#---------------------------------------

LibSerialPort.Lib.sp_get_age_lib_version()
LibSerialPort.Lib.sp_get_port_description(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_bus_address(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_vid_pid(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_manufacturer(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_product(sp.ref)
LibSerialPort.Lib.sp_get_port_usb_serial(sp.ref)
LibSerialPort.Lib.sp_get_lib_version_string()
LibSerialPort.Lib.sp_get_current_lib_version()
LibSerialPort.Lib.sp_get_package_version_string()
LibSerialPort.Lib.sp_get_major_package_version()
LibSerialPort.Lib.sp_get_micro_package_version()
LibSerialPort.Lib.sp_get_minor_package_version()
LibSerialPort.Lib.sp_get_port_name(sp.ref)
LibSerialPort.Lib.sp_get_port_by_name("COM3")
LibSerialPort.Lib.sp_get_port_transport(sp.ref)
LibSerialPort.Lib.sp_get_port_bluetooth_address(sp.ref)
LibSerialPort.get_port_list()
LibSerialPort.Lib.sp_get_config(sp.ref)
LibSerialPort.get_port_settings(sp.ref)
LibSerialPort.print_port_settings(sp.ref)
config = LibSerialPort.sp_get_config(sp.ref)
LibSerialPort.sp_get_config_baudrate(config)

#---------------------------------------
# 以下自己写一个函数来汇总所需的信息
#---------------------------------------
function tclab_print_port_metadata(port::LibSerialPort.Port; show_config::Bool=true)
        println("\nPort name:\t", LibSerialPort.Lib.sp_get_port_name(port))
        transport = LibSerialPort.Lib.sp_get_port_transport(port)
        print("\nPort transport:\t")
        if transport == LibSerialPort.SP_TRANSPORT_NATIVE
                println("native serial port")
        elseif transport == LibSerialPort.SP_TRANSPORT_USB
                println("USB")
                println("Manufacturer:\t", LibSerialPort.Lib.sp_get_port_usb_manufacturer(port))
                println("Product:\t", LibSerialPort.Lib.sp_get_port_usb_product(port))
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

#---------------------------------------
# 以下调用自己写的函数
#---------------------------------------
tclab_print_port_metadata(sp.ref)