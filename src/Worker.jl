using JSON
using Spark

#function Worker(port::Int64, masterhostname::ASCIIString, masterport::Int64)
#    Worker(port, true, {}, masterhostname, masterport)
#end

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

function create_partition(worker::Worker, rdd_id::Int64, partition_id::Int64, partition::Partition, 
    source_rdds::Array{Array{PID}}, op_type::String, op_args::Dict{})
    rdds::Array{Array{}} = Array(Array, 0)
    for rdd in source_rdds
        rdd_data:Array{}
        for partition in rdd
            partition_data::Array
            
            #attempt to get partition data. If partition cannot be found
            #tell the master to rebuild it.
            while true
                #partition_data = get_partition(partition)
                #if get_partition fails
                #call rebuild_partition (or similar) method on the master
                #need to update the partition data to reflect partition may be in a
                #different worker after rebuilding it.
                #else, break out the loop
            end
            rdd_data = vcat(rdd_data, partition_data)
        end
    end
    
    #handle_op executes operation dependant code and adds the new partition to worker.data
    handle_op(worker, rdd_id, partition_id, partition, op_type, op_args, rdd_data)
end
