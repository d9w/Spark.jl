using Spark

function master_read(master::Master, file_name::String, reader::String)
    stream = open(file_name)
    total_lines = countlines(stream)

    #Get array of workers
    workers = master.worker
    active_workers = Array(Worker, 0)
    for worker in workers
        if worker.active
            append!(active_workers, worker)
        end
    end
    num_workers::Int = length(active_workers)

    #calculate range of lines for each worker
    lines_partition = floor(total_lines / num_workers)
    partition_ranges = Array((Int, Int), 0)
    for p = 1:num_workers
        begin_line::Int = lines_partition * (p - 1) + 1
        end_line::Int = lines_partition * p
        append!(partition_ranges, (begin_line, end_line))
        if p == num_workers
            partition_ranges[p] = (begin_line, total_lines)
        end
    end

    ID::Int64 = length(master.rdds)+1
    partitions::Array{PID} = Array(PID, 0)
    for p = 1:num_workers
        current_worker::Int = p
        success = false
        args::Dict = Dict()
        args["file_name"] = file_name
        args["begin_line"] = partition_ranges[p][1]
        args["end_line"] = partition_ranges[p][2]
        args["reader"] = reader
        args["rdd_id"] = ID
        args["partition_id"] = p
        while !success
            rpc(active_workers[current_worker], "read_file", args)
            #TODO figure out how to tell if rpc is successful
            #if rpc successful
            #   append!(partitions, PID(active_workers[current_worker], p)
            #   success = true
            #else
            #   current_worker += 1
            #end
        end
    end
    dependencies::Array{Int64} = Array(Int64, 0)
    history::Array{Record} = Array(Record, 0)
    origin_file::String = file_name

    # create RDD
    rdd::RDD = RDD(ID, dependencies, history, partitions, origin_file)

    # send actual rdd to each worker
    #TODO, in practice this code should account fo the case where
    #a worker becomes inactive after successfully processing a partition
    for w = 1:num_workers
        success = false
        args::Dict = {"rdd" => rdd}
        while !success
            rpc(active_workers[w], "send_rdd", args)
            #if rpc successful
            #   success = true
            #end
        end
    end
end

#reads file between lines begin_line and end_line, inclusive. The first line 
#is indexed 1 instead of 0 to match julia's behaviour for arrays, etc. 
function worker_read(worker::Worker, file_name::String, begin_line::Int, end_line::Int, reader::String, rdd_id::Int64, partition_id::Int64)
    stream = open(file_name)
    seek_line(stream, begin_line)
    partition = Array()

    if begin_line < 1
        begin_line = 1
    end

    for l = begin_line:end_line
        line::String = readline(stream)
        record = eval(Expr(:call, reader, line))
        push!(partition, record)
    end

    #Adds partition to partition map
    worker.data[rdd_id][partition_id] = partition
end

#Moves the stream at the beginning of line line_number
function seek_line(stream::IOStream, line_number::Int)
    if line_number <= 1
        return
    end

    for l = 1:line_number
        line::String = readline(stream)
    end
end

#Sends rdd to worker and workers updates it.
function send_rdd(worker::Worker, rdd::RDD)
    worker.rdds[rdd.ID] = rdd
end

#TODO fix terms. The logic that reads the file was barely changed so it
#should work without many complications.
#Tests
function test_reader(line::String)
    return chomp(line)
end

function test()
    worker_read("test", 1, 1, test_reader, String) 
    worker_read("test", 1, 2, test_reader, String) 
    worker_read("test", 1, 9, test_reader, String) 
end
