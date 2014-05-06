##############################
# General RPC definition
##############################

# General outgoing message broadcasting - use msg to send
# to a particular active worker, broadcastmsg to send
# to all of them.
function allrpc(master::Master, func::ASCIIString, args::Dict=Dict())
    success = true
    for w in master.workers
        if w.active && !rpc(w, func, args)
            success = false
        end
    end
    return success
end

function rpc(worker::WorkerRef, func::ASCIIString, args::Dict)
    if !worker.socket
        worker.socket = connect(worker.hostname, worker.port)
    end
    m = {:call => func, :args => args}
    encoded = json(m)
    try
        println(worker.socket, encoded)
        result = JSON.parse(readline(worker.socket))
        return result["result"]
    catch e
        worker.active = false
        return false
    end
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
    for w = 1:length(master.workers)
        rpc(master, w, "identify", {:hostname => master.hostname, :port => master.port, :ID => w})
    end
end

# handler: set the master hostname and port on the worker
function identify(worker::Worker, args::Dict)
    worker.id = args["ID"]
    worker.masterhostname=args["hostname"]
    worker.masterport=args["port"]
    return true
end

# call: Demo RPC
function wprint(master::Master, s)
    allrpc(master, "wprint", {:str => s})
end

# handler: Demo RPC
function wprint(worker::Worker, args::Dict)
    println(args["str"])
    return true
end

# call: share all workers with active workers so they can connect to each other
function shareworkers(master::Master, workers)
    allrpc(master, "shareworkers", {:workers => workers})
end

# handler: receive a list of coworkers from the master
function shareworkers(worker::Worker, args::Dict)
    worker.coworkers = args["workers"]
    return true
end

# call: do a transformation (do is a keyword, using "apply")
# operation should include every argument needed to complete the transformation (id of rdds (there can be more than one), nameof functions, comparator, etc. 
function apply(master::Master, rdds::Array{RDD}, oper::Transformation)
    # create new RDD history and partitioning by transformation
    # send new RDD and transformation (something like:)
    # allrpc(master, "apply", {:RDD => new_RDD, :oper => oper})

    ID::Int64 = length(master.rdds) + 1
    # assume hash partition with n = number of active workers
    partitions = create(HashPartitioner(), master)
    dependencies = Dict{Any, Array{Any}}()
    for rdd in rdds
        dependencies[rdd.ID] = rdd.partitions
    end

    new_RDD = RDD(ID, partitions, dependencies, oper)
    allrpc(master, "apply", {:rdd => new_RDD, :oper => oper})

#    @parallel for i = 1:length(new_partitions)
#        processed_partition = false
#        while !processed_partition
#            #select an active worker (preferably unique for each partition)
#            #args = {:rdd_id => new_ID, :partition_id => new_partitions[i].ID, :partition = new_partitions[i].partition, :dependencies => new_dependencies, :oper => oper}
#            #rpc(worker, "create_partition", args)
#            #if successful processed_partition = true
#        end
#    end
#
    #send rdd to all workers that got a partition in the last step
end

# call: do an action
function apply(master::Master, rdd::RDD, oper::Action)
    allrpc(master, "apply", {:rdd => rdd, :oper => oper})
end

# handler: perform the transformation OR action (operation)
function apply(worker::Worker, args::Dict)
    # send to an evaluator for each operation, based on name, like:
    oper = args["oper"]
    eval(Expr(:call, symbol(oper.name), args["rdd"], oper.args))
    return true
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
    # Convert to WorkerRDD, include master RDD copy in WorkerRDD.rdd
    return json({:rdd => WorkerRDD(Dict{Int64, WorkerPartition}(), master.rdds[args["id"]])})
end

# call: ping the master for activeness (any information to piggyback?)
function ping(worker::Worker)
    master = connect(worker.masterhostname, worker.masterport)
    println(master, json({:call => "ping", :args => {:id => worker.ID}}))
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


# Get an RDD from the master or return our local copy if it exists
function fetch_worker_rdd(worker::Worker, rdd_int::Int64)
    if !(rdd_int in keys(worker.rdds))
        worker.rdds[rdd_int] = getRDD(worker, rdd_int)
    end
    return worker.rdds[rdd_int]
end

# Returns tuple (boolean, data) where the first element should tell whether the operation was
# successful. data contains all the key in the remote partition that belong in the partition
function get_keys(worker::Worker, rdd_int::Int64, partition_id::Int64)
    args = {:rdd_int => rdd_int, :partition_id => partition_id}
    rdd = fetch_worker_rdd(worker, rdd_int)
    origin_worker = worker.rdds[rdd_int].rdd.partitions[partition_id].node
    return rpc(origin_worker, "get_keys", args)
end

# Returns keys in partition that belong to the provided partition object 
function get_keys(worker::Worker, args::Dict)
    rdd_id::Int64 = args["rdd_id"]
    partition_id::Int64 = args["partition_id"]
    data = worker.rdds[rdd_id].partitions[partition_id].data
    data_keys = keys(data)
    return {"result" => data_keys}
end

# Get the data for a specific key
function get_key_data(worker::Worker, rdd_int::Int64, key::Any)
    rdd = fetch_worker_rdd(worker, rdd_int)
    partition_id = assign(worker.rdds[rdd_int].rdd.partitioner, worker.rdds[rdd_int].rdd, key)
    origin_worker = worker.rdds[rdd_int].rdd.partitions[partition_id].node
    args = {:rdd_id => rdd_id, :partition_id => partition_id, :key => key}
    return rpc(origin_worker, "get_key_data", args)
end

# Returns key data for a particular (rdd, partition, key)
function get_key_data(worker::Worker, args::Dict)
    rdd_id::Int64 = args["rdd_id"]
    partition_id::Int64 = args["partition_id"]
    key::Any = args["key"]
    data = worker.rdds[rdd_id].partitions[partition_id].data[key]
    return {"result" => data}
end
