using JSON

type Worker
    port::Int64
    active::Bool # can be turned off by an RPC

    coworkers::Array{}
    masterhostname::ASCIIString
    masterport::Int64
end

include("RDD.jl") # RDD requires Worker type

function Worker(port::Int64, masterhostname::ASCIIString, masterport::Int64)
    Worker(port, true, {}, masterhostname, masterport)
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

####
# Worker->Master: Get RDD info from the master
####
function getRDD(worker::Worker, ID::Int64)
    master = connect(worker.masterhostname, worker.masterport)
    println(master, json({"id" => id}))
    result = readline(master)
    return JSON.parse(result)["rdd"]
end

####
# Worker->Worker RPC: coworker functions for sharing data
####

function send_coworker(coworker::Array, rdd::RDD) # TODO etc.
    coworker = connect(coworker[0], coworker[1])
    args = {"rdd" => rdd}
    println(coworker, json({:call => "recv_send_coworker", :args => args}))
end

function recv_send_coworker(worker::Worker, args::Dict)
    # Do something with the received RDD TODO
    rdd = args["rdd"]
end

# TODO etc. (get, get_keys)

####
# Master->Worker RPC functions here - called by the master, other workers
####
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
