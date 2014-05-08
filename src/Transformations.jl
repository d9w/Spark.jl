#####################
## Transformations ##
#####################

import Base.collect


# merge the dictionaries with append as the key conflict behavior
function append_merge(source::Dict, dest::Dict)
    for key in keys(source)
        if key in keys(dest)
            for val in source[key]
                push!(dest[key], val)
            end
        else
            dest[key] = source[key]
        end
    end
end

# merge a list of (k,{v}) tuples into a dict with append
function append_merge(source::Array, dest::Dict)
    for kv in source
        if kv[1] in keys(dest)
            for val in kv[2]
                push!(dest[kv[1]], val)
            end
        else
            dest[kv[1]] = kv[2]
        end
    end
end

# require that map function is of the form func(key::Any, value::Array{Any})
function map(master::Master, rdd::RDD, map_func::ASCIIString)
    op = Transformation("map", {"function" => map_func})
    doop(master, {rdd}, op, NoPartitioner())
end

# assumes co-partitioning between new and old
function map(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    map_func = args["function"]
    old_rdd_id = collect(keys(newRDD.rdd.dependencies))[1]
    partition = worker.rdds[old_rdd_id].partitions[part_id].data
    for key in keys(partition)
        kv_pairs = eval(Expr(:call, symbol(map_func), key, partition[key]))
        append_merge(kv_pairs, newRDD.partitions[part_id].data)
    end

    return true
end

function filter(master::Master, rdd::RDD, filter_func::ASCIIString)
    op = Transformation("filter", {"function" => filter_func})
    doop(master, {rdd}, op, NoPartitioner())
end

# assumes co-partitioning between new and old
function filter(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    func = args["function"]
    old_rdd_id = collect(keys(newRDD.rdd.dependencies))[1]
    partition = worker.rdds[old_rdd_id].partitions[part_id].data
    newRDD.partitions[part_id].data = filter(func, partition)
    return true
end

# narrow
function flat_map(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

function group_by_key(master::Master, rdd::RDD)
    newRDD = partition_by(master, rdd, HashPartitioner())
    if newRDD == false
        return false
    end
    op = Transformation("group_by_key", Dict())
    doop(master, {newRDD}, op, HashPartitioner())
end

function group_by_key(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    old_rdd_id = collect(keys(newRDD.rdd.dependencies))[1]
    partition = worker.rdds[old_rdd_id].partitions[part_id].data
    append_merge(partition, newRDD.partitions[part_id].data)
    return true
end

# wide
function reduce_by_key(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# call on 2 RDDs returns 1 RDD whose partitions are the union of those of the parents.
# each child partition is computed through a narrow dependency on its parent
function union(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# can have wide or narrow dependencies
function join(master::Master, rddA::RDD, rddB::RDD)
    newA = partition_by(master, rddA, HashPartitioner())
    newB = partition_by(master, rddB, HashPartitioner())
    if newA == false || newB == false
        return false
    end
    op = Transformation("join", Dict())
    doop(master, {newA, newB}, op, HashPartitioner())
end

# makes the assumption that RDDs are co-partitioned, if the partition exists
function join(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    id_a = collect(keys(newRDD.rdd.dependencies))[1]
    id_b = collect(keys(newRDD.rdd.dependencies))[2]
    if id_a in keys(worker.rdds)
        worker_rdd = worker.rdds[id_a]
        append_merge(worker_rdd.partitions[part_id].data, newRDD.partitions[part_id].data)
    end
    if id_b in keys(worker.rdds)
        worker_rdd = worker.rdds[id_b]
        append_merge(worker_rdd.partitions[part_id].data, newRDD.partitions[part_id].data)
    end
    return true
end

# wide
function cogroup(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# wide
function cross_product(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# narrow
function map_values(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# wide
function sort(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

function partition_by(master::Master, rdd::RDD, partitioner::Partitioner)
    op = Transformation("partition_by", {"partitioner" => partitioner})
    doop(master, {rdd}, op, partitioner)
end

function partition_by(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    partitioner = mkPartitioner(args["partitioner"])
    old_rdd_id = collect(keys(newRDD.rdd.dependencies))[1]
    local_rdd_copy = worker.rdds[old_rdd_id]
    for pid in keys(local_rdd_copy.partitions)
        partition = local_rdd_copy.partitions[pid]
        for key in keys(partition.data)
            new_partitions = assign(partitioner, newRDD.rdd, key)
            for new_partition in new_partitions
                new_worker = newRDD.rdd.partitions[new_partition]
                send_key(worker, new_worker, newRDD.rdd.ID, new_partition, key, partition.data[key])
            end
        end
    end
    return true
end

function input(master::Master, filename::ASCIIString, reader::ASCIIString)
    op = Transformation("input", {"filename" => filename, "reader" => reader})
    doop(master, {}, op, NoPartitioner())
end

function input(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    reader = args["reader"]
    file_name = args["filename"]

    stream = open(file_name)
    total_lines = countlines(stream)
    seekstart(stream)


    lines_partition = floor(total_lines / length(newRDD.rdd.partitions))
    begin_line = lines_partition * part_id
    end_line = lines_partition * (part_id + 1) - 1
    if part_id == (length(newRDD.rdd.partitions) - 1)
        end_line = total_lines - 1 # last partition always goes to the end
    end
    for l = 0:begin_line-1
        line::String = readline(stream)
    end
    partition = WorkerPartition(Dict{Any, Array{Any}}())

    for l = begin_line:end_line
        line::String = readline(stream)
        kv_pairs = eval(Expr(:call, symbol(reader), line))
        append_merge(kv_pairs, partition.data)
    end

    #Adds partition to partition map
    newRDD.partitions[part_id] = partition
end
