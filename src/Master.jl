# Master REPL functions
using Spark


# Load a list of workers from a file, contact them
function load(master::Master, configfile)
    f = open(configfile)
    config = JSON.parse(readall(f))
    for worker in config
        # Read the configuration file and try to connect to all the workers
        hostname = worker[1]
        port = worker[2]
        socket = None
        active = false
        try
            # Try to connect to all the clients
            socket = connect(hostname, port)
            active = true
        catch e
            println("Couldn't connect to $hostname:$port...")
            showerror(STDERR, e)
        end
        wf = WorkerRef(hostname, port, active)
        master.workers = cat(1, master.workers, [wf])
        master.sockets[wf] = socket
    end
    identify(master)
end

# Set up the local RPC server for worker->master RDD requests
function initserver(master::Master)
    server = listen(IPv4(0), master.port)
    println("Starting server")
    @async while true
        sock = accept(server)
        @async while true
            try
                line = readline(sock)
                response = handle(master, line)
                println(sock, response)
            catch e
                showerror(STDERR, e)
                break
            end
        end
    end
end

# General handle, in case we want more Worker -> Master RPC like ping
function handle(master::Master, line::ASCIIString)
    # General format of a message:
    # {:call => "funcname", :args => {anything}}
    # this is dispatched to any function call - fine since we're assuming
    # a private non-adversarial network.
    msg = JSON.parse(strip(line))
    r = false
    if "call" in keys(msg)
        r = eval(Expr(:call, symbol(msg["call"]), master, msg["args"]))
    end
    return r
end

#recovers given partition
function recover_partition(master::Master, rdd_id::Int64, partition_id::Int64)

    #Check if rdd comes directly from disk. If so, recover partition and return
    if length(master.rdds[rdd_id].dependencies) == 0
        recover_part(master, master.rdds[rdd_id], partition_id)
        return
    end

    lost_partitions::Array{(Int64, Int64)} = Array((Int64, Int64), 0)
    #finds lost predecessors
    for rdd in master.rdds[rdd_id].dependencies
        for partition in rdd[2]
            if !partition[2].active
                push!(lost_partitions, (rdd[1], partition[1]))
            end
        end
    end

    if length(lost_partitions) == 0
        return
    else
        for partition in lost_partitions
            recover_partition(master, partition[1], partition[2])
        end
        recover_part(master, master.rdds[rdd_id], partition_id)
    end
end

#recovers all lost partitions of the given rdd
function recover(master::Master, rdd::RDD)
    rdd_id = rdd.ID
    lost_partitions::Array{Int64} = Array(Int64, 0)
    for worker in master.rdds[rdd_id].partitions
        if !worker[2].active
            push!(lost_partitions, worker[1])
        end
    end

    for partition_id in lost_partitions
        recover_partition(master, rdd_id, partition_id)
    end
    return partition_by(master, master.rdds[rdd_id], HashPartitioner())
end
