


function Historian(sources::Vector{Tuple{String, Function}}, dbfile=":memory::")
    db = dbfile == ":memory:" ? nothing : TagDB(dbfile)
    columns = ["Time"]
    fields = [[]]
    logdict = Dict("Time" => fields[1])
    t = fields[1]
    for (name, _) in sources
        push!(columns, name)
        push!(fields, [])
        logdict[name] = fields[end]
    end
    tstart = labtime.time()
    return Historian(sources, dbfile, db, tstart, columns, fields, logdict, t)
end

function build_fields!(historian::Historian)
    historian.fields = [[] for _ in historian.columns]
    historian.logdict = Dict(zip(historian.columns, historian.fields))
    historian.t = historian.logdict["Time"]
end

function update(historian::Historian, tnow::Union{Float64, Nothing}=nothing)
    if tnow isa Nothing
        historian.tnow = labtime.time() - historian.tstart
    else
        historian.tnow = tnow
    end

    for (name, valuefunction) in historian.sources
        if valuefunction !== nothing
            v = valuefunction()
            try
                values = iter(v)
            catch e
                values = iter([v])
            end
            try
                value = next(values)
            catch e
                throw(ArgumentError("valuefunction did not return enough values"))
            end
            push!(historian.logdict[name], value)
            if historian.db !== nothing && name != "Time"
                record(historian.db, historian.tnow, name, value)
            end
        end
    end
end

function log(historian::Historian)
    return map(collect, values(historian.logdict))
end

function timeindex(historian::Historian, t::Float64)
    return max(bisect_left(historian.t, t) - 1, 0)
end

function timeslice(historian::Historian, tstart::Float64=0.0, tend::Union{Float64, Nothing}=nothing, columns::Union{Vector{String}, Nothing}=nothing)
    start = timeindex(historian, tstart)
    if tend isa Nothing
        stop = length(historian.t) + 1
    end
    if tend == tstart
        stop = start + 1
    end
    if columns isa Nothing
        columns = historian.columns
    end
    return [historian.logdict[c][start:stop] for c in columns]
end

function at(historian::Historian, t::Float64, columns::Union{Vector{String}, Nothing}=nothing)
    return [c[1] for c in timeslice(historian, t, t, columns)]
end

function after(historian::Historian, t::Float64, columns::Union{Vector{String}, Nothing}=nothing)
    return timeslice(historian, t, columns=columns)
end

function _dbcheck(historian::Historian)
    if historian.db === nothing
        throw(NotImplementedError("Sessions not supported without dbfile"))
    end
    return true
end

function new_session(historian::Historian)
    _dbcheck(historian)
    new_session(historian.db)
    historian.session = historian.db.session
    historian.tstart = labtime.time()
    build_fields!(historian)
end

function get_sessions(historian::Historian)
    _dbcheck(historian)
    return get_sessions(historian.db)
end
