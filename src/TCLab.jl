module TCLab
using LibSerialPort
const __version__ = "0.1.0"

const sep = ' ' # command/value separator in TCLab firmware

const arduinos = [
    ((9025, 67), "Arduino Uno"),
]

const sketchurl = "https://github.com/jckantor/TCLab-sketch"
global _connected = false


include("utils.jl")

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

function TCLabDT(; debug::Bool=false)
    debug = false
    port, arduino = find_arduino()
    baud = 19200
    _P1 = 10.0
    _P2 = 10.0
    sp = LibSerialPort.SerialPort(port)
    LibSerialPort.open(sp)
    LibSerialPort.isopen(sp)
    LibSerialPort.close(sp)
    TCLabDT(debug, port, arduino, baud, _P1, _P2, sp)
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

function connect!(tclab::TCLabDT, baud::Int)
    if _connected
        throw(AlreadyConnectedError("You already have an open connection"))
    end

    try
        tclab.sp = LibSerialPort.open(tclab.port, baud)  # 打开指定端口
        sleep(2)  # 等待硬件响应
        #Q1(tclab, 0)  # 发送初始化命令，失败时应处理错误
        global _connected = true
    catch e
        global _connected = false  # 确保连接状态被重置
        rethrow(e)  # 重新抛出异常以便调用者处理
    end
end

function Q1(tclab::TCLabDT, value::Int)
    send_and_receive(tclab, "Q1 $(value)")
end

# 需要一个发送和接收函数
function send_and_receive(tclab::TCLabDT, command::String)
    write(tclab.sp, command * "\r\n")
    sleep(1)  # 等待设备处理命令
    return readline(tclab.sp)  # 读取响应
end


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

export TCLabDT

end # module TCLab
