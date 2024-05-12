module TCLab
using LibSerialPort, Random, Dates
const __version__ = "0.1.0"

const sep = ' ' # command/value separator in TCLab firmware

# We should add more devices to this list.
const arduinos = [
    ((9025, 67), "Arduino Uno"),
]

const sketchurl = "https://github.com/jckantor/TCLab-sketch"
const _connected = Ref(false)

"""Limit value to be between lower and upper limits"""
function clip(val::Real; lower=0, upper=100)
    return max(lower, min(val, upper))
end

"""Construct command to TCLab-sketch."""
function command(name::String, argument::Real; lower=0, upper=100)
    return name * sep * string(clip(argument; lower=lower, upper=upper))
end

"""Locates Arduino and returns port and device."""
function find_arduino()
    ports = LibSerialPort.get_port_list()
    for port in ports
        sp = LibSerialPort.SerialPort(port)
        vid_pid = LibSerialPort.sp_get_port_usb_vid_pid(sp.ref)
        if !isnothing(vid_pid)
            vid, pid = vid_pid
            for (identifier, arduino) in arduinos
                if (vid, pid) == identifier
                    println("Found Arduino: ", arduino, " on port ", port)
                    return port, arduino
                end
            end
        end
    end
    println("--- No Arduino Found in These Serial Port(s): ---")
    for port in ports
        println("Port name: ", port)
    end
    return nothing, nothing
end

struct AlreadyConnectedError <: Exception
    msg::String
    AlreadyConnectedError(msg="Already connected!") = new(msg)
end

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
    sp::Union{LibSerialPort.SerialPort, Nothing}
    firmwareversion::String
end

# 默认构造函数
TCLabDT() = TCLabDT(false, "", "", 19200, 10.0, 10.0, nothing, "")

function initialize!(tclab::TCLabDT; debug::Bool=false)
    println("TCLab (Julia) version", __version__)
    port, arduino = find_arduino()
    sp = LibSerialPort.SerialPort(port)
    
    tclab.debug = debug
    tclab.port = port
    tclab.arduino = arduino
    tclab.sp = sp

    try
        baud = 19200
        LibSerialPort.open(sp, baud_rate=baud)
        _connected[] = true
    catch e
        if isa(e, AlreadyConnectedError)
            rethrow(e)
        else
            _connected[] = false                
            LibSerialPort.close(sp)
            baud = 9600  # 以低速重新连接
            try
                LibSerialPort.open(sp, baud_rate=baud)
                println("Could not connect at high speed, but succeeded at low speed.")
                println("This may be due to an old TCLab firmware.")
                println("New Arduino TCLab firmware available at:")
                println(_sketchurl)
                _connected[] = true
            catch
                throw(RuntimeError("Failed to Connect."))
            end
        end
    end

    tclab.baud = baud
    tclab._P1 = 10.0
    tclab._P2 = 10.0
    
    if LibSerialPort.isopen(sp)
        println("$(tclab.arduino) connected on port $(tclab.port) at $(tclab.baud) baud.")
    end
end
#tclab=TCLabDT()

function connect!(tclab::TCLabDT, baudrate::Int)
    if _connected[]
        throw(AlreadyConnectedError("You already have an open connection"))
    end

    try
        tclab.sp = LibSerialPort.open(tclab.port, baudrate)  # 打开指定端口
        sleep(2)  # 等待硬件响应
        Q1(tclab, 0)  # 发送初始化命令，失败时应处理错误
        _connected[] = true
        tclab.baud=baudrate
    catch e
        _connected[] = false  # 确保连接状态被重置
        if tclab.sp !== nothing
            LibSerialPort.close(tclab.sp)
        end
        rethrow(e)  # 重新抛出异常以便调用者处理
    end
end

function close(tclab::TCLabDT)
    Q1(tclab, 0)
    Q2(tclab, 0)
    send_and_receive(tclab, "X")
    close(tclab.sp)
    _connected[] = false
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

"""
用于从Arduino接收数据和发送命令的方法
"""
function send_and_receive(tclab::TCLabDT, msg::AbstractString, target_type::Union{Type{T},Nothing}=nothing) where {T}
    send(tclab, msg)
    #sleep(1.0)
    response = receive(tclab)
    if isnothing(target_type)
        return response  # 如果没有提供 target_type，返回原始响应
    else
        try
            return parse(T, response)  # 尝试解析响应为指定类型
        catch error
            error_msg = "Failed to parse response '$response' as type $T: $error"
            @error error_msg
            throw(ArgumentError(error_msg))
        end
    end
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

function P1(tclab::TCLabDT, val::Real)
    # 确保传入值在合法范围内
    clipped_val = clip(val; lower=0, upper=255)
    # 发送命令并更新 _P1 值
    tclab._P1 = send_and_receive(tclab, command("P1", clipped_val; lower=0, upper=255), Float64)
end

function P2(tclab::TCLabDT)
    return tclab._P2
end

function P2(tclab::TCLabDT, val::Real)
    # 确保传入值在合法范围内
    clipped_val = clip(val; lower=0, upper=255)
    # 发送命令并更新 _P2 值，确保使用关键字参数
    tclab._P2 = send_and_receive(tclab, command("P2", clipped_val; lower=0, upper=255), Float64)
end


function Q1(tclab::TCLabDT, value::Union{Nothing,Float64,Int}=nothing)
    if isnothing(value)
        # 如果未提供值，则发送获取当前 Q1 设置的命令
        msg = "R1"
    else
        # 确保传入的值是整数，如果是浮点数则向下取整
        # 因为加热器设置应该是整数
        int_value = isa(value, Float64) ? floor(Int, value) : value
        # 使用 command 函数生成设置新 Q1 值的命令，确保值的合法范围
        msg = command("Q1", int_value; lower=0, upper=100)
    end
    # 发送命令并返回解析后的响应，假设响应需要解析为 Float64
    return send_and_receive(tclab, msg, Float64)
end


function Q2(tclab::TCLabDT, value::Union{Nothing,Float64,Int}=nothing)
    if isnothing(value)
        # 没有提供值时，获取当前 Q2 设置的命令
        msg = "R2"
    else
        # 将浮点值向下取整为整数，因为加热器设置应为整数
        int_value = isa(value, Float64) ? floor(Int, value) : value
        # 使用 command 函数生成设置新 Q2 值的命令，确保值的合法范围
        msg = command("Q2", int_value; lower=0, upper=100)
    end
    # 发送命令并返回解析后的响应，将其解析为 Float64
    return send_and_receive(tclab, msg, Float64)
end

# Define scan function
function scan(tclab::TCLabDT)
    try
        T1_val = T1(tclab)
        T2_val = T2(tclab)
        Q1_val = Q1(tclab)
        Q2_val = Q2(tclab)
        return (T1_val, T2_val, Q1_val, Q2_val)
    catch e
        println("Error occurred during scanning: ", e)
        return (nothing, nothing, nothing, nothing)  # 或者根据需要返回默认值
    end
end


"""
`U1(tclab)` - Get the current setting for heater 1.
`U1(tclab, val)` - Set a new value for heater 1.
"""
U1(tclab::TCLabDT) = Q1(tclab)
U1(tclab::TCLabDT, val::Real) = Q1(tclab, val)

"""
`U2(tclab)` - Get the current setting for heater 2.
`U2(tclab, val)` - Set a new value for heater 2.
"""
U2(tclab::TCLabDT) = Q2(tclab)
U2(tclab::TCLabDT, val::Real) = Q2(tclab, val)


mutable struct TCLabModel
    debug::Bool
    synced::Bool
    Ta::Float64  # ambient temperature
    #    tstart::DateTime  # start time
    #    tlast::DateTime  # last update time
    _P1::Float64  # max power heater 1
    _P2::Float64  # max power heater 2
    _Q1::Float64  # initial heater 1 power
    _Q2::Float64  # initial heater 2 power
    _T1::Float64  # temperature thermistor 1
    _T2::Float64  # temperature thermistor 2
    _H1::Float64  # temperature heater 1
    _H2::Float64  # temperature heater 2
    #   maxstep::Float64  # maximum time step for integration

    # TCLabModel(; debug::Bool=false, synced::Bool=true) = new(debug, synced, 21.0, now(), now(), 200.0, 100.0, 0.0, 0.0, 21.0, 21.0, 21.0, 21.0, 0.2)
end

# Initialization and debug prints
# function init_lab(model::TCLabModel)
#     println("TCLab version ", __version__)
#     println("Simulated TCLab")
#     model.tstart = now()
#     model.tlast = model.tstart
# end

function close(model::TCLabModel)
    # 设置加热器功率为0，模拟关闭加热器
    Q1(model, 0)
    Q2(model, 0)
    println("TCLab Model disconnected successfully.")
end

#using Dates

function update!(model::TCLabModel, t::DateTime=nothing)
    if isnothing(t)
        if model.synced
            model.tnow = now() - model.tstart
        else
            return
        end
    else
        model.tnow = t
    end

    teuler = model.tlast
    while teuler < model.tnow
        dt = min(model.maxstep, (model.tnow - teuler) / Millisecond(1) / 1000)  # Convert milliseconds to seconds
        DeltaTaH1 = model.Ta - model._H1
        DeltaTaH2 = model.Ta - model._H2
        DeltaT12 = model._H1 - model._H2
        dH1 = model._P1 * model._Q1 / 5720 + DeltaTaH1 / 20 - DeltaT12 / 100
        dH2 = model._P2 * model._Q2 / 5720 + DeltaTaH2 / 20 + DeltaT12 / 100
        dT1 = (model._H1 - model._T1) / 140
        dT2 = (model._H2 - model._T2) / 140

        model._H1 += dt * dH1
        model._H2 += dt * dH2
        model._T1 += dt * dT1
        model._T2 += dt * dT2
        teuler += Dates.Millisecond(dt * 1000)  # Convert seconds back to datetime
    end

    model.tlast = model.tnow
end

"""
Simulate flashing TCLab LED
val : specified brightness (default 100).
"""
function LED(model::TCLabModel, val::Int=100)
    update!(model)  # 更新模型状态
    return clip(val, 0, 100)  # 调整亮度值确保在0到100的范围内
end

"""
Return a float denoting TCLab temperature T1 in degrees C.
"""
function T1(model::TCLabModel)
    update!(model)  # 确保模型状态是最新的
    return measurement(model, model._T1)  # 返回经过量化处理的 T1 温度
end

"""
Return a float denoting TCLab temperature T2 in degrees C.
"""
function T2(model::TCLabModel)
    update!(model)  # 更新模型状态，确保最新
    return measurement(model, model._T2)  # 返回量化后的 T2 温度
end

# 获取 P1 属性的值
"""
Return the maximum power of heater 1 in PWM.
"""
function P1(model::TCLabModel)
    update!(model)  # 更新模型状态，确保是最新的
    return model._P1  # 返回加热器1的最大功率
end

# 设置 P1 属性的值
"""
Set the maximum power of heater 1 in PWM, range 0 to 255.
"""
function P1(model::TCLabModel, val::Int)
    update!(model)  # 更新模型状态，确保是最新的
    model._P1 = clip(val, 0, 255)  # 将值限制在范围 0 到 255 并设置为加热器1的最大功率
    return model._P1  # 可以返回设置后的值作为确认
end

# 获取 P2 属性的值
"""
Return the maximum power of heater 2 in PWM.
"""
function P2(model::TCLabModel)
    update!(model)  # 更新模型状态，确保是最新的
    return model._P2  # 返回加热器2的最大功率
end

# 设置 P2 属性的值
"""
Set the maximum power of heater 2 in PWM, range 0 to 255.
"""
function P2(model::TCLabModel, val::Int)
    update!(model)  # 更新模型状态，确保是最新的
    model._P2 = clip(val, 0, 255)  # 将值限制在范围 0 到 255 并设置为加热器2的最大功率
    return model._P2  # 可以返回设置后的值作为确认
end

# 获取或设置加热器1的功率
"""
Get or set TCLabModel heater power Q1.
val: Value of heater power, range is limited to 0-100.
"""
function Q1(model::TCLabModel, val::Int=nothing)
    update!(model)
    if !isnothing(val)
        model._Q1 = clip(val, 0, 100)  # 限制功率值在0到100之间
    end
    return model._Q1
end

# 获取或设置加热器2的功率
"""
Get or set TCLabModel heater power Q2.
val: Value of heater power, range is limited to 0-100.
"""
function Q2(model::TCLabModel, val::Int=nothing)
    update!(model)
    if !isnothing(val)
        model._Q2 = clip(val, 0, 100)  # 限制功率值在0到100之间
    end
    return model._Q2
end

# 扫描和返回各种测量数据
"""
Perform a scan and return temperatures and heater powers.
"""
function scan(model::TCLabModel)
    update!(model)
    return (
        measurement(model, model._T1),
        measurement(model, model._T2),
        model._Q1,
        model._Q2
    )
end

"""
Quantize model temperatures to mimic Arduino A/D conversion.
"""
function quantize(T::Float64)
    quantized_temp = T - mod(T, 0.3223)  # 减去模0.3223的余数，实现量化效果
    return max(-50.0, min(132.2, quantized_temp))  # 限制量化温度在-50到132.2之间
end

function measurement(model::TCLabModel, T::Float64)
    """
    Return a quantized temperature value after adding normal-distributed noise.
    """
    noisy_temp = T + randn() * 0.043  # 添加正态分布的随机噪声，均值为 0，标准偏差为 0.043
    return quantize(noisy_temp)  # 对温度值进行量化
end




# # Basic setters and getters for properties
# P1(model::TCLabModel) = model._P1
# P1(model::TCLabModel, val::Real) = model._P1 = clip(val, 0, 255)

# P2(model::TCLabModel) = model._P2
# P2(model::TCLabModel, val::Real) = model._P2 = clip(val, 0, 255)

# Q1(model::TCLabModel, val::Real=0) = (model._Q1 = clip(val, 0, 100); model._Q1)
# Q2(model::TCLabModel, val::Real=0) = (model._Q2 = clip(val, 0, 100); model._Q2)

# # Helper functions
# function clip(val::Real, lower::Real, upper::Real)
#     return max(lower, min(val, upper))
# end

# function quantize(T::Float64)
#     return max(-50.0, min(132.2, T - mod(T, 0.3223)))
# end

# function measurement(model::TCLabModel, T::Float64)
#     quantize(T + randn() * 0.043)
# end

# function update(model::TCLabModel, t::DateTime=now())
#     dt = min(model.maxstep, (t - model.tlast) / Millisecond(1) / 1000)
#     model.tlast = t

#     # Euler integration for the model equations
#     while (t - model.tlast) > Millisecond(dt * 1000)
#         dH1 = model._P1 * model._Q1 / 5720 + (model.Ta - model._H1) / 20 - (model._H1 - model._H2) / 100
#         model._H1 += dt * dH1
#         # Similar for _H2, _T1, and _T2
#     end
# end

# function scan(model::TCLabModel)
#     update(model)
#     (measurement(model, model._T1), measurement(model, model._T2), model._Q1, model._Q2)
# end

# export TCLabModel, init_lab, close, P1, P2, Q1, Q2, scan

export TCLabDT

end # module TCLab
