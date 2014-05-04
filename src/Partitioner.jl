using Spark

# TODO i thought that the partitioner would be given the num partitions, 
# so the function callling it would already know the number of active workers and stuff
# This way the code would be less redundant, no?
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

function hash_partitioner(master::Master, rdd::RDD)

    partitioned_keys = Dict{Int64,Any}()
    #TODO get keys, ie. rdd_values
    for key in keys
        pid = hash(key) % total_partitions
        if has(partitioned_keys, pid)
            push(ref(partitioned_keys, pid), key)
        else
            partitioned_keys[pid] = [key]
        end
    end
    return partitioned_keys
end
