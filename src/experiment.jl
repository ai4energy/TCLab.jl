
mutable struct Experiment
    connected::Bool
    plot::Bool
    twindow::Int
    time::Int
    dbfile::String
    speedup::Float64
    synced::Bool
    tol::Float64
    lab::TCLabModel
    historian::Historian
    plotter::Plotter
end

function Experiment(; connected=true, plot=true, twindow=200, time=500, dbfile=":memory:", speedup=1.0, synced=true, tol=0.5)
    if (speedup != 1.0 || !synced) && connected
        throw(ArgumentError("The real TCLab can only run in real time."))
    end

    lab = connected ? TCLab() : TCLabModel(synced=synced)
    historian = Historian(lab.sources, dbfile=dbfile)
    plotter = plot ? Plotter(historian, twindow=twindow) : nothing

    return Experiment(connected, plot, twindow, time, dbfile, speedup, synced, tol, lab, historian, plotter)
end

function Base.close(experiment::Experiment)
    close(experiment.lab)
    close(experiment.historian)
end

function clock(experiment::Experiment)
    if experiment.synced
        times = clock(experiment.time, tol=experiment.tol)
    else
        times = 0:experiment.time-1
    end

    for t in times
        yield(t)
        if experiment.plot
            update(experiment.plotter, t)
        else
            update(experiment.historian, t)
        end

        if !experiment.synced
            update(experiment.lab, t)
        end
    end
end

function runexperiment(function, kwargs...)
    experiment = Experiment(kwargs...)
    for t in clock(experiment)
        function(t, experiment.lab)
    end
    return experiment