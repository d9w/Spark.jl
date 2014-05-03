##############################
# General RPC definition
##############################

# General outgoing message broadcasting - use msg to send
# to a particular worker (reference in activeworkers), broadcastmsg to send
# to all of them.
function allrpc(master::Master, func::ASCIIString, args::Dict=Dict())
    for w in master.activeworkers
        rpc(w, func, args)
    end
end

function rpc(worker::Base.TcpSocket, func::ASCIIString, args::Dict)
    m = {:call => func, :args => args}
    encoded = json(m)
    println(worker, encoded)
end

##############################
# RPC: Master->Worker
##############################
# TODO put more here - do(RDD, transformation), do(RDD, action), status(RDD)

# call: kill all workers
function kill(master::Master)
    allrpc(master, "kill")
end

# handler: set active flag as false on the worker
function kill(worker::Worker, args::Dict)
    worker.active = false
end

# call: tell the workers the master hostname and port
function identify(master::Master)
    allrpc(master, "identify", {:hostname => master.hostname, :port => master.port})
end

# handler: set the master hostname and port on the worker
function identify(worker::Worker, args::Dict)
    worker.masterhostname=args["hostname"]
    worker.masterport=args["port"]
end

# call: Demo RPC
function wprint(master::Master, s)
    allrpc(master, "wprint", {:str => s})
end

# handler: Demo RPC
function wprint(worker::Worker, args::Dict)
    println(args["str"])
end

# call: share all workers with activeworkers so they can connect to each other
function shareworkers(master::Master, workers)
    allrpc(master, "shareworkers", {:workers => workers})
end

# handler: receive a list of coworkers from the master
function shareworkers(worker::Worker, args::Dict)
    worker.coworkers = args["workers"]
end

# call: do a transformation (do is a keyword, using "apply")
function apply(master::Master, RDD_ID::Int64, oper::Transformation)
    # create new RDD history and partitioning by transformation
    # send new RDD and transformation (something like:)
    # allrpc(master, "apply", {:RDD => new_RDD, :oper => oper})
end

# call: do an action
function apply(master::Master, RDD_ID::Int64, oper::Action)
    # no new RDD is necessary, should just be:
    # allrpc(master, "apply", {:RDD => master.RDDs[RDD_ID], :oper => oper})
end

# handler: perform the transformation OR action (operation)
function apply(worker::Worker, args::Dict)
    # send to an evaluator for each operation, based on name, like:
    # oper = args["oper"]
    # eval(Expr(:call, symbol(oper.name), args["RDD"], oper.args))
end

##############################
# RPC: Worker->Master
##############################

# call: get RDD info from the master
function getRDD(worker::Worker, ID::Int64)
    master = connect(worker.masterhostname, worker.masterport)
    println(master, json({:call => "getRDD", :args => {:id => ID}}))
    result = readline(master)
    return JSON.parse(result)["rdd"]
end

# handler: return RDD info from master to worker
function getRDD(master::Master, args::Dict)
    return {"rdd" => master.rdds[args["id"]]}
end

# call: ping the master for activeness (any information to piggyback?)
function ping(worker::Worker)
    master = connect(worker.masterhostname, worker.masterport)
    println(master, json({:call => "ping", :args => {:id => worker.ID}}))
    #TODO: tell each worker their position in master.workers
end

# handler: set the worker active flag
function ping(master::Master)
    master.Workers[args["id"]].active = true
end

##############################
# Worker->Worker RPC: coworker functions for sharing data
##############################

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
