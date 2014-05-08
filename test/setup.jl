using Spark

function start_worker(port::Int64)
    worker = Spark.Worker("127.0.0.1", port)
    Spark.start(worker)
    println("done")
end

function test_reader(line::String)
    return {hash(line), chomp(line)}
end

function main()
    master = Spark.Master("127.0.0.1", 3333)
    for i in 0:2
        @async start_worker(6666+i)
    end
    # fill in master.workers
    Spark.load(master, "default_workers.json")
    # start master listener
    Spark.initserver(master)
    println("done initserver")
    rdd = Spark.input(master, "RDDA.txt", "test_reader")
    println("done reading")
    partitioned_rdd = Spark.partition_by(master, rdd, Spark.HashPartitioner())
    println("done partition_by")
    println(Spark.count(master, partitioned_rdd))
end

main()
