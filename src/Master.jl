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
