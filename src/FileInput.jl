
function master_read(file_name::String)
    stream = open(file_name)
    total_lines = countlines(stream)
    
    #Get array of workers
    #calculate range of lines for each worker
    #for each worker
    #   send worker_read rpc to all the workers
    #wait for results
    #Create rdd

end

#=reads file between lines begin_line and end_line, inclusive. The first line is indexed 1 instead=#
#=of 0 to match julia's behaviour for arrays, etc. =#
function worker_read(file_name::String, begin_line::Int, end_line::Int, reader::Function, rdd_type::Type)
    stream = open(file_name)
    seek_line(stream, begin_line)
    partition = Array(rdd_type, 0)

    if begin_line < 1
        begin_line = 1
    end

    for l = begin_line:end_line
        line::String = readline(stream)
        record = reader(line)
        push!(partition, record)
    end
    
    #Needs to do something about the partition. For now it prints it to stdin
    println(partition)
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


#Tests
function test_reader(line::String)
    return chomp(line)
end

function test()
    worker_read("test", 1, 1, test_reader, String) 
    worker_read("test", 1, 2, test_reader, String) 
    worker_read("test", 1, 9, test_reader, String) 
end

test()
