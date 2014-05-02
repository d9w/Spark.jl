using JSON

module Spark

export Worker
export RDD

include("Worker.jl")
include("RDD.jl")

activeworkers = []
inactiveworkers = []
rdds = {}

# Load a list of workers from a file, contact them
function load(configfile)
    global activeworkers
    f = open(configfile)
    config = JSON.parse(readall(f))
    for worker in config
        # Read the configuration file and try to connect to all the workers
        hostname = worker[1]
        port = worker[2]
        try
            # Try to connect to all the clients
            client = connect(hostname, port)
            activeworkers = cat(1, activeworkers, [client])
        catch e
            println("Couldn't connect to $hostname:$port...")
            # Saved failed connections in inactiveworkers for later retrial
            inactiveworkers = cat(1, inactiveworkers, [(hostname, port)])
        end
    end
    shareworkers(config)
end

# Set up the local RPC server for worker->master RDD requests
function initserver(port)
    server = listen(IPv4(0), port)
    println("Starting server")
    @async while true
        sock = accept(server)
        while true
            try
                line = readline(sock)
                parsed = JSON.parse(line)
                response = json(rddhandle(parsed))
                println(sock, response)
            catch e
                showerror(STDERR, e)
                break
            end
        end
    end 
end

# Return RDD info for the requesting worker
function rddhandle(args::Dict)
    global rdds
    rddID = int(args["id"])
    return {"rdd" => rdds[rddID]}
end

# RPC functions master -> worker
# TODO put more here - do(RDD, transformation), do(RDD, action), status(RDD)

# Kills all the workers simultaneously
function kill()
    allrpc("kill")
end

# Demo RPC
function wprint(s)
    allrpc("wprint", {:str => s})
end

# Share all workers with activeworkers so they can connect to each other
function shareworkers(workers)
    allrpc("shareworkers", {:workers => workers})
end

# General outgoing message broadcasting - use msg to send
# to a particular worker (reference in activeworkers), broadcastmsg to send
# to all of them.
function allrpc(func::ASCIIString, args::Dict=Dict())
    for w in activeworkers
        rpc(w, func, args)
    end
end

function rpc(worker::Base.TcpSocket, func::ASCIIString, args::Dict)
    m = {:call => func, :args => args}
    encoded = json(m)
    println(worker, encoded)
end

end
