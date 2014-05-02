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


