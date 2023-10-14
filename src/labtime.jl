mutable struct Labtime
    realtime::Float64
    labtime::Float64
    rate::Float64
    running::Bool
    lastsleep::Float64
end

function Labtime()
    realtime = time()
    labtime = 0.0
    rate = 1.0
    running = true
    lastsleep = 0.0
    return Labtime(realtime, labtime, rate, running, lastsleep)
end

function tclabtime(lt::Labtime)
    if lt.running
        elapsed = time() - lt.realtime
        return lt.labtime + lt.rate * elapsed
    else
        return lt.labtime
    end
end

function set_rate!(lt::Labtime, rate::Float64=1.0)
    if rate <= 0
        throw(ArgumentError("Labtime rates must be positive."))
    end
    lt.labtime = tclabtime(lt)
    lt.realtime = time()
    lt.rate = rate
end

function get_rate(lt::Labtime)
    return lt.rate
end

# function sleep(lt::Labtime, delay::Float64)
#     lt.lastsleep = delay
#     if lt.running
#         sleep_time = Dates.Millisecond(round(delay * 1000 / lt.rate))
#         sleep(sleep_time)
#     else
#         throw(RuntimeWarning("sleep is not valid when labtime is stopped."))
#     end
# end

function stop(lt::Labtime)
    lt.labtime = time(lt)
    lt.realtime = time()
    lt.running = false
end

function start(lt::Labtime)
    lt.realtime = time()
    lt.running = true
end

function reset(lt::Labtime, val::Float64=0.0)
    lt.labtime = val
    lt.realtime = time()
end

labtime = Labtime()

function setnow(tnow::Float64=0.0)
    reset(labtime, tnow)
end

# function clock(period::Float64, step::Float64=1.0, tol::Float64=Inf, adaptive::Bool=true)
#     start_time = time(labtime)
#     now = 0.0

#     while round(now, digits=2) <= period
#         yield round(now, digits=2)
#         if round(now) >= period
#             break
#         elapsed = time(labtime) - (start_time + now)
#         rate = get_rate(labtime)
#         if (rate != 1.0) && adaptive
#             if elapsed > step
#                 set_rate!(labtime, 0.8 * rate * step / elapsed)
#             elseif (elapsed < 0.5 * step) && (rate < 50.0)
#                 set_rate!(labtime, 1.25 * rate)
#             end
#         else
#             if elapsed > step + tol
#                 message = "Labtime clock lost synchronization with real time. Step size was $step s, but $(round(elapsed, digits=2)) s elapsed ($(round(elapsed - step, digits=2)) too long). Consider increasing step."
#                 throw(RuntimeError(message))
#             end
#         end
#         sleep(labtime, step - (time(labtime) - start_time) % step)
#         now = time(labtime) - start_time
#     end
# end