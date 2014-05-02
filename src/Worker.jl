using JSON

type Worker
    port::Int64
    active::Bool # can be turned off by an RPC
    coworkers::Array{}
end

function Worker(port::Int64)
    Worker(port,true,{})
end

function start(worker::Worker)
    server = listen(IPv4(0), worker.port)
    println("starting")
    while worker.active
        sock = accept(server)
        while worker.active
            try
                line = readline(sock)
                handle(worker, line)
            catch e
                showerror(STDERR, e)
                break
            end
        end
    end
end

function handle(worker::Worker, line::ASCIIString)
    # General format of a message:
    # {:call => "funcname", :args => {anything}}
    # this is dispatched to any function call - fine since we're assuming
    # a private non-adversarial network.
    msg = JSON.parse(strip(line))
    if "call" in keys(msg)
        eval(Expr(:call, symbol(msg["call"]), worker, msg["args"]))
    end
end

# Get RDD info from the master
function getRDD(id)
    # TODO - fill this in with real hostname/port
    master = connect(hostname, port)
    println(master, json({"id" => id}))
    result = readline(master)
    # TODO - will the RDD actually be JSON-encoded?  probably not
    return JSON.parse(result)["rdd"]
end

# RPC functions here - called by the master, other workers
function kill(worker::Worker, args::Dict)
    worker.active = false
end

function wprint(worker::Worker, args::Dict)
    println(args["str"])
end

# Receive a list of coworkers from the master
function shareworkers(worker::Worker, args::Dict)
    worker.coworkers = args["workers"]
end
