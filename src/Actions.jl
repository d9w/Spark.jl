#############
## Actions ##
#############

import Base.collect

#### Count ####

# Count all the keys in an RDD
function count(master::Master, rdd::RDD)
    op = Action("count", Dict())
    results = doop(master, rdd, op) 
    return sum(results)
end

function count(worker::Worker, rdd::WorkerRDD, part_id::Int64, args::Dict)
    return length(collect(keys(rdd.partitions[part_id].data)))
end

#### Collect ####

# Collect all keys in the RDD
function collect(master::Master, rdd::RDD)
    op = Action("collect", Dict())
    results = doop(master, rdd, op)
    r = {}
    for i in results
        append!(r, i)
    end
    return r
end

function collect(worker::Worker, rdd::WorkerRDD, part_id::Int64, args::Dict)
    data = rdd.partitions[part_id].data
    return {(k, data[k]) for k in keys(data)}
end

#TODO reduce
function reduce(worker::Worker, rdd::WorkerRDD, args::Dict{Any, Any})
    return None
end

#### Lookup ####

# Look up a particular item in the RDD
function lookup(master::Master, rdd::RDD, key::Any)
    op = Action("lookup", {"key" => key})
    results = doop(master, rdd, op) 
    for r in results
        if length(r) == 1
            return r
        end
    end
end

function lookup(worker::Worker, rdd::WorkerRDD, part_id::Int64, args::Dict)
    results = {}
    for key in keys(rdd.partitions[part_id].data)
        if key == args["key"]
            push!(results, (key, rdd.partitions[part_id].data[key]))
        end
    end
    return results
end
