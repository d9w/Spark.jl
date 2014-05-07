using Spark

master = Master("127.0.0.1", 3333)

partition = Transformation("partition_by", Dict())
RDD
doop(master, {rdd}, partition)

# start worker threads

function test_reader(line::String)
    return chomp(line)
end

function test()
    worker_read("test", 1, 1, test_reader, String)
    worker_read("test", 1, 2, test_reader, String)
    worker_read("test", 1, 9, test_reader, String)
end
