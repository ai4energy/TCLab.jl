module TCLab
using LibSerialPort

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

"""Locates Arduino and returns port and device."""
function find_arduino()
    ports = LibSerialPort.get_port_list()
    for port in ports
        sp=LibSerialPort.open(port,19200)
        realsp=sp.ref
        vid_pid = LibSerialPort.sp_get_port_usb_vid_pid(realsp)
        if !isnothing(vid_pid)
            vid, pid = vid_pid
            for (identifier, arduino) in arduinos
                if (vid, pid) == identifier
                    return port, arduino
                end
            end
        end
        LibSerialPort.destroy!(sp)
    end
    println("--- Serial Ports ---")
    for port in ports
        println("Port name: ", LibSerialPort.sp_get_port_name(port))
#        println("Description: ", LibSerialPort.sp_get_port_description(port))
#        println("Hardware ID: ", LibSerialPort.sp_get_port_usb_vid_pid(port))
    end    
    return nothing, nothing
end

struct AlreadyConnectedError <: Exception
    msg::String
    AlreadyConnectedError(msg="Already connected!") = new(msg)
end

"""
TCLab Digital Twin
"""
mutable struct TCLabDT
    debug::Bool
    port::String
    arduino::String
    baud::Int
    _P1::Float64
    _P2::Float64
    sp::SerialPort
end
baud=19200
port, arduino = find_arduino()
sp = LibSerialPort.open(port, baud)

sp = LibSerialPort.open("COM3", baud)
LibSerialPort.close(sp)
LibSerialPort.isopen(sp)
LibSerialPort.destroy!(sp)
function TCLabDT(; debug::Bool=false)
    baud=19200
    port, arduino = find_arduino()
    sp = LibSerialPort.open(port, baud)
    LibSerialPort.close(sp)
    _P1=0.0
    _P2=0.0
    return TCLabDT(debug, port, arduino, baud, _P1, _P2, sp)
end

"""
用于模拟从Arduino接收数据和发送命令的方法
"""
function send_and_receive(tclab::TCLabDT, command::String)
    write(tclab.sp, command * "\n")
    return readline(tclab.sp)
end



#= 
function TCLab(port::String = "", debug::Bool = false)
    _connected = false
    print("TCLab version ", __version__)
    port, arduino = find_arduino(port)
    if port == nothing
        throw(RuntimeError("No Arduino device found."))
    end  

    try
        connect(TCLab, arduino, 115200)
    catch e
        if isa(e, AlreadyConnectedError)
            throw(e)
        else
            try
                global _connected = false
                sp.close()
                connect(TCLab, arduino, 9600)
                println("Could not connect at high speed, but succeeded at low speed.")
                println("This may be due to an old TCLab firmware.")
                println("New Arduino TCLab firmware available at:")
                println(_sketchurl)
            catch
                throw(RuntimeError("Failed to Connect."))
            end
        end
    end

    readline(sp)
    version = send_and_receive(TCLab, "VER")
    if isopen(sp)
        println(arduino, " connected on port ", port, " at ", baud, " baud.")
        println(version, ".")
    end

    labtime.set_rate(1)
    labtime.start()
    _P1 = 200.0
    _P2 = 100.0
    Q2(TCLab, 0)
    sources = [("T1", scan),
               ("T2", nothing),
               ("Q1", nothing),
               ("Q2", nothing),
              ]

    return new(debug, port, arduino, baud, _P1, _P2, sp)
end =#

function close(tclab::TCLabDT)
    Q1(tclab, 0)
    Q2(tclab, 0)
    send_and_receive(tclab, "X")
    close(tclab.sp)
    global _connected = false
    println("TCLab disconnected successfully.")
end

function send(tclab::TCLabDT, msg::String)
    write(tclab.sp, msg * "\r\n")
    if tclab.debug
        println("Sent: \"$msg\"")
    end
    flush(tclab.sp)
end

function receive(tclab::TCLabDT)
    msg = readline(tclab.sp)
    if tclab.debug
        println("Return: \"$msg\"")
    end
    return msg
end

function send_and_receive(tclab::TCLabDT, msg::AbstractString, convert::Type{T}=Float64) where {T}
    send(tclab, msg)
    response = receive(tclab)
    return parse(T, response)
end

function send_and_receive(tclab::TCLabDT, msg::AbstractString)
    send(tclab, msg)
    response = receive(tclab)
    return response
end

function LED(tclab::TCLabDT, val=100)
    return send_and_receive(tclab, command("LED", val), Float64)
end

# Properties
function T1(tclab::TCLabDT)
    return send_and_receive(tclab, "T1", Float64)
end

function T2(tclab::TCLabDT)
    return send_and_receive(tclab, "T2", Float64)
end


# Define P1 and P2 as properties
function P1(tclab::TCLabDT)
    return tclab._P1
end

function P1(tclab::TCLabDT, val::Float64)
    tclab._P1 = send_and_receive(tclab, command("P1", val, 0, 255), Float64)
end


function P2(tclab::TCLabDT)
    return tclab._P2
end

function P2(tclab::TCLabDT, val::Float64)
    tclab._P2 = send_and_receive(tclab, command("P2", val, 0, 255), Float64)
end


# Functions for Q1 and Q2
function Q1(tclab::TCLabDT, val::Union{Float64,Nothing,Int64}=nothing)
    if isnothing(val)
        msg = "R1"
    else
        msg = "Q1$sep$(clip(val))"
    end
    return send_and_receive(tclab, msg, Float64)
end

function Q2(tclab::TCLabDT, val::Union{Float64,Nothing,Int64}=nothing)
    if isnothing(val)
        msg = "R2"
    else
        msg = "Q2$sep$(clip(val))"
    end
    return send_and_receive(tclab, msg, Float64)
end

# Define scan function
function scan(tclab::TCLabDT)
    T1_val = T1(tclab)
    T2_val = T2(tclab)
    Q1_val = Q1(tclab)
    Q2_val = Q2(tclab)
    return (T1_val, T2_val, Q1_val, Q2_val)
end

# Define properties for U1 and U2
U1(tclab::TCLabDT) = Q1(tclab)
U1(tclab::TCLabDT, val::Float64) = Q1(tclab, val)

U2(tclab::TCLabDT) = Q2(tclab)
U2(tclab::TCLabDT, val::Float64) = Q2(tclab, val)

"""
Establish a connection to the Arduino.

baud: baud rate
"""
# function connect(tclab::TCLab,port::String,baud::Int64)

#     global _connected

#     if _connected
#         print("You already have an open connection")
#     end

#     _connected = true
#     tclab.sp = LibSerialPort.open(port,baud)
#     sleep(2)

# # find_arduino()
# # list_ports()
# # sp = LibSerialPort.open("COM7", 9600)
# # write(sp, "VER\n")
# # sleep(3)
# # println(readline(sp))
# # LibSerialPort.close(sp)
# end

function connect(obj::TCLabDT, arduino::String, baud::Int)
    """
    Establish a connection to the Arduino

    baud: baud rate
    """
    global _connected

    if _connected
        error("You already have an open connection")
    end

    _connected = true

    LibSerialPort.open(obj.sp)
    sleep(2)
    Q1(obj, 0.0)  # fails if not connected
    obj.baud = baud
end

include("labtime.jl")
include("version.jl")
include("utils.jl")

export TCLabDT

end # module TCLab
