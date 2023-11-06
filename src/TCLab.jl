module TCLab
using LibSerialPort
include("labtime.jl")
include("version.jl")
include("utils.jl")


const sep = ' '

arduinos = [
    ("USB VID:PID=16D0:0613", "Arduino Uno")
]

_sketchurl = "https://github.com/jckantor/TCLab-sketch"
_connected = false


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

port, arduino = find_arduino()
# find_arduino()
# list_ports()
 # sp = LibSerialPort.open("COM7", 9600)
# write(sp, "VER\n")
# sleep(3)
# println(readline(sp))
# LibSerialPort.close(sp)

# Constructor

function TCLabDT(; debug::Bool=false, port::String="COM5", arduino::String="Arduino Uno", baud::Int=9600, _P1::Float64=0.0, _P2::Float64=0.0)
    sp = LibSerialPort.open(port, baud)
    return TCLabDT(debug, port, arduino, baud, _P1, _P2, sp)
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
function Q1(tclab::TCLabDT, val::Union{Float64, Nothing,Int64}=nothing)
    if isnothing(val)
        msg = "R1"
    else
        msg = "Q1$sep$(clip(val))"
    end
    return send_and_receive(tclab, msg, Float64)
end

function Q2(tclab::TCLabDT ,val::Union{Float64, Nothing,Int64}=nothing)
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

function connect(obj::TCLabDT,arduino::String,baud::Int)
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

export TCLabDT

end # module TCLab
