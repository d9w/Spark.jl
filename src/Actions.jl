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

# Collect all keys in the RDD
function collect(master::Master, rdd::RDD)
    op = Action("collect", Dict())
    results = {}
    results = cat(1, results, doop(master, rdd, op))
    return results
end

function collect(worker::Worker, rdd::WorkerRDD, part_id::Int64, args::Dict)
    results = {}
    for key in keys(rdd.partitions[part_id].data)
        push!(results, (key, rdd.partitions[part_id].data[key]))
    end
    return results
end

function reduce(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return None
end

# Look up a particular item in the RDD
function lookup(master::Master, rdd::RDD, key::Any)
    op = Action("lookup", {"key" => key})
    results = doop(master, rdd, op) 
    return results
end

function lookup(worker::Worker, rdd::WorkerRDD, part_id::Int64, args::Dict)
    #results = {}
    #for key in keys(rdd.partitions[part_id].data)
    #    if key == args["key"]
    #        push!(results, (key, rdd.partitions[part_id].data[key]))
    #    end
    #end
    #return results 
end
