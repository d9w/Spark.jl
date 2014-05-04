# Master REPL functions
using Spark


# Load a list of workers from a file, contact them
function load(master::Master, configfile)
    #global activeworkers
    f = open(configfile)
    config = JSON.parse(readall(f))
    for worker in config
        # Read the configuration file and try to connect to all the workers
        hostname = worker[1]
        port = worker[2]
        #master.workers = cat(1, master.workers, [Worker(hostname, port)])
        try
            # Try to connect to all the clients
            client = connect(hostname, port)
            master.activeworkers = cat(1, master.activeworkers, [client])
        catch e
            println("Couldn't connect to $hostname:$port...")
            # Saved failed connections in inactiveworkers for later retrial
            master.inactiveworkers = cat(1, master.inactiveworkers, [(hostname, port)])
        end
    end
    Spark.shareworkers(master, config)
end

# Set up the local RPC server for worker->master RDD requests
function initserver(master::Master)
    server = listen(IPv4(0), master.port)
    println("Starting server")
    @async while true
        sock = accept(server)
        while true
            try
                line = readline(sock)
                parsed = JSON.parse(line)
                response = json(handle(parsed))
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
    if "call" in keys(msg)
        eval(Expr(:call, symbol(msg["call"]), master, msg["args"]))
    end
end
