using DataFrames

type FileReader{T}
    converter::Function

    FileReader(converter) = new(converter)
    
    function readFile(file::String, header::Bool, numPartitions::Int)
        data::DataFrame = readtable(file, header=header, quotemark=['\"'])
        numRecords = size(data, 1)
        recordsPerPartition = numRecords / numPartitions
        workers::Array{PID}
        #API call to get pid's from cluster manager
        partition = Array(T, 0)

        partitionCounter::Int = 1 
        for i = 1:numRecords
            if size(partition) > recordsPerPartition && 
                partitionCounter < size(workers)
                #API call to send partition to worker
                partitionCounter++
                partition = Array(T, 0) 
            end
            record::T = converter(data[i, :])
            append!(partition, record)
        end
        ##send final partition to last worker
        
        #API to get a new RDD i 
        ID::Int64
        dependencies = Array(Int64, 0)
        sources = Dict{Int64, Array{(Int64, PID)}}()
        for i = 1:size(workers)
            sources[workers[i].ID] = Array((Int64, PID), 0)
        end
        record = Record(converter, 0, sources) 
        history = Array(Record, 0)
        append!(history, record)
        rdd = RDD(ID, workers, dependencies, history)

        return rdd
    end
end
