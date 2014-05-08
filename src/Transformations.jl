#####################
## Transformations ##
#####################

# narrow
function map(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# narrow
function filter(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# narrow
function flat_map(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    return true
end

# wide
function group_by_key(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
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
function join(master::Master, rddA::RDD, rddB::RDD, newPartitioner::Partitioner)
    partition_by(master, rddA, newPartitioner)
    partition_by(master, rddB, newPartitioner)
    op = Transformation("join", {"rddA" => rddA, "rddB" => rddB})
    doop(master, {rddA, rddB}, op, newPartitioner)
end

# merge the dictionaries with append as the key conflict behavior
function append_merge(source::Dict, dest::Dict)
    for key in keys(source)
        if key in keys(dest)
            push!(dest[key], source[key])
        else
            dest[key] = {source[key]}
        end
    end
end

# makes the assumption that RDDs are co-partitioned, if the partition exists
function join(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    if args["rddA"].ID in keys(worker.rdds)
        worker_rdd = worker.rdds[args["rddA"].ID]
        append_merge(worker_rdd.partitions[part_id], newRDD.partitions[part_id])
    end
    if args["rddB"].ID in keys(worker.rdds)
        worker_rdd = worker.rdds[args["rddB"].ID]
        append_merge(worker_rdd.partitions[part_id], newRDD.partitions[part_id])
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
    println("master - doing partition_by")
    op = Transformation("partition_by", {"partitioner" => partitioner})
    doop(master, {rdd}, op, partitioner)
end

function partition_by(worker::Worker, newRDD::WorkerRDD, part_id::Int64, args::Dict)
    println("worker - doing partition_by")
    partitioner = args["partitioner"]
    old_rdd_id = keys(newRDD.rdd.dependencies)[1]
    local_rdd_copy = worker.rdds[old_rdd_id]
    for partition in local_rdd_copy.partitions
        for key in keys(partition.data)
            new_partitions = assign(partitioner, newRDD.rdd, key)
            for new_partition in new_partitions
                new_worker = newRDD.rdd.partitions[new_partition]
                send_key(worker, newRDD.rdd.ID, new_partition, key, partition.data[key])
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
        for kv in kv_pairs
            if kv[2] in keys(partition.data)
                push!(partition.data[kv[1]], kv[2])
            else
                partition.data[kv[1]] = {kv[2]}
            end
        end
    end

    #Adds partition to partition map
    newRDD.partitions[part_id] = partition
end
