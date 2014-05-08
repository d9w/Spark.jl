using Spark

function create(p::NoPartitioner, master::Master)
    partitions = Dict{Int64, WorkerRef}()
    part_i = 0
    for worker in master.workers
        if worker.active
            partitions[part_i] = worker
            part_i = part_i + 1
        end
    end
    return partitions
end

function assign(p::NoPartitioner, rdd::RDD, key::Any)
    return keys(rdd.partitions)
end

function create(p::HashPartitioner, master::Master)
    return create(NoPartitioner(), master)
end

function assign(p::HashPartitioner, rdd::RDD, key::Any)
    return {convert(Int64, hash(key) % length(rdd.partitions))}
end

# range_partitioner not yet implemented
function range_partitioner(master::Master, rdd::RDD)
    rdd_values = Array()
    #TODO collect rdd values
    sort!(rdd_values)
    partitions::Array{Partition} = Array(Partition, 0)
    num_partitions = 0
    for worker in master.Workers
        if worker.active
            num_partitions += 1
        end
    end

    partition_size = length(rdd_values) / num_partitions
    for p = 1:(num_partitions - 1)
        start_range = rdd_values[(p-1) * partition_size  + 1]
        end_range = rdd_values[p * partition_size]
        append!(partitions, RangePartition(start_range, end_range))
    end

    #append last partition
    start_range = rdd_values[(p-1) * partition_size + 1]
    end_range = rdd_values[length(rdd_values)]
    append!(partitions, start_range, end_range)

    return partitions
end
