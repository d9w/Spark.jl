#############
## Actions ##
#############

import Base.collect

# Count all the keys in an RDD
function count(master::Master, rdd::RDD)
    op = Action("count", Dict())
    results = doop(master, rdd, op) 
    return sum(results)
end

function count(worker::Worker, rdd::WorkerRDD, part_id::Int64, args::Dict)
    return length(collect(keys(rdd.partitions[part_id].data)))
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

