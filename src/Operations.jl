#####################
## Transformations ##
#####################

# narrow
function map(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# narrow
function filter(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# narrow
function flat_map(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# wide
function group_by_key(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# wide
function reduce_by_key(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# call on 2 RDDs returns 1 RDD whose partitions are the union of those of the parents.
# each child partition is computed through a narrow dependency on its parent
function union(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# can have wide or narrow dependencies
function join(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# wide
function cogroup(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# wide
function cross_product(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# narrow
function map_values(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end

# wide
function sort(worker::Worker, newRDD::WorkerRDD, args::Dict{Any, Any})
    return true
end


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

