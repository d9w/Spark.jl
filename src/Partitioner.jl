using Spark

function range_partitioner(master::Master, rdd::RDD)
    partitions::Partition = Array(Partition, 0)
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
