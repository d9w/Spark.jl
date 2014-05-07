#############
## Actions ##
#############

function count(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return 0
end

function collect(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return None
end

function reduce(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return None
end

function lookup(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return None
end

function save(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return None
end

