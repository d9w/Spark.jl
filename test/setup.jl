using Spark

function start_worker(port::Int64)
    worker = Worker("127.0.0.1", port)
    start(worker)
    println("done")
end

function main()
    master = Master("127.0.0.1", 3333)
    for i in {1:4}
        @async start_worker(6666+i)
    end
    # fill in master.workers
    load(master, "default_workers.json")
    # start master listener
    initserver(master)
