const __version__ = "0.1.0"

function get_port_metadata(port::LibSerialPort.Port; show_config::Bool=true)
    port_info = Dict{String,Any}()
    port_info["Port name"] = LibSerialPort.sp_get_port_name(port)
    println("\nPort name:\t", port_info["Port name"])
    transport = LibSerialPort.Lib.sp_get_port_transport(port)
    if transport == LibSerialPort.SP_TRANSPORT_NATIVE
        port_info["Port transport"] = "native serial port"
        print("\nPort transport:\t")
        println("native serial port")
    elseif transport == LibSerialPort.SP_TRANSPORT_USB
        port_info["Port transport"] = "USB"
        print("\nPort transport:\t")
        println("USB")
        port_info["Manufacturer"] = LibSerialPort.sp_get_port_usb_manufacturer(port)
        port_info["Product"] = LibSerialPort.sp_get_port_usb_product(port)
        port_info["USB serial number"] = LibSerialPort.sp_get_port_usb_serial(port)
        bus, addr = LibSerialPort.sp_get_port_usb_bus_address(port)
        port_info["USB bus number"] = bus
        port_info["Address on bus"] = addr
        vid, pid = LibSerialPort.sp_get_port_usb_vid_pid(port)
        port_info["Vendor ID"] = vid
        port_info["Product ID"] = pid
        port_info["Description"] = LibSerialPort.sp_get_port_description(port)
        println("Manufacturer:\t", port_info["Manufacturer"])
        println("Product:\t", port_info["Product"])
        println("USB serial number:\t", port_info["USB serial number"])
        println("USB bus #:\t", bus)
        println("Address on bus:\t", addr)
        println("Vendor ID:\t", vid)
        println("Product ID:\t", pid)
        println("Description:\t", port_info["Description"])
    elseif transport == LibSerialPort.SP_TRANSPORT_BLUETOOTH
        port_info["Port transport"] = "Bluetooth"
        print("\nPort transport:\t")
        println("Bluetooth")
        port_info["Bluetooth address"] = LibSerialPort.Lib.sp_get_port_bluetooth_address(port)
        println("Bluetooth address:\t", port_info["Bluetooth address"])
    end
    if show_config
        port_info["Configuration"] = LibSerialPort.get_port_settings(port)
        LibSerialPort.print_port_settings(port)
    end
    return port_info
end

function get_port_metadata(port::SerialPort; show_config::Bool=true)
    realport = port.ref
    return get_port_metadata(realport, show_config=show_config)
end

function get_port_metadata(port_name::String; show_config::Bool=true, baudrate::Int=19200)
    port = LibSerialPort.open(port_name, baudrate)
    port_info = get_port_metadata(port, show_config=show_config)
    LibSerialPort.close(port)
    return port_info
end

const sep = ' ' # command/value separator in TCLab firmware

const arduinos = [
    ((9025, 67), "Arduino Uno"),
]

const sketchurl = "https://github.com/jckantor/TCLab-sketch"
_connected = false

"""Limit value to be between lower and upper limits"""
function clip(val; lower=0, upper=100)
    return max(lower, min(val, upper))
end

function command(name::String, argument::Number; lower=0, upper=100)
    # 生成字符串指令
    return name * sep * string(clip(argument; lower=lower, upper=upper))
end

struct AlreadyConnectedError <: Exception
    msg::String
    AlreadyConnectedError(msg="Already connected!") = new(msg)
end

function find_arduino()
    ports = LibSerialPort.get_port_list()
    for port in ports
        println("Checking port: ", port)
        sp = nothing
        try
            sp = LibSerialPort.open(port, 19200)
            realsp = sp.ref
            vid_pid = LibSerialPort.sp_get_port_usb_vid_pid(realsp)
            if !isnothing(vid_pid)
                vid, pid = vid_pid
                for (identifier, arduino) in arduinos
                    if (vid, pid) == identifier
                        println("Found Arduino: ", arduino, " on port ", port)
                        return port, arduino
                    end
                end
            end
        finally
            if !isnothing(sp)
                LibSerialPort.close(sp)  # 确保在退出前关闭端口
            end
        end
    end
    println("--- Serial Ports ---")
    for port in ports
        println("Port name: ", LibSerialPort.sp_get_port_name(port))
        # 额外的端口信息打印，如果需要的话
    end
    return nothing, nothing
end