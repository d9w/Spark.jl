using JSON

type Worker
    port::Int64
    active::Bool # can be turned off by an RPC
end

function Worker(port::Int64)
    Worker(port,true)
end

function start(worker::Worker)
    server = listen(IPv4(0), worker.port)
    println("starting")
    while worker.active
        sock = accept(server)
        while worker.active
            try
                line = readline(sock)
                handleline(worker, line)
            catch e
                showerror(STDERR, e)
                break
            end
        end
    end
end

function handleline(worker::Worker, line::ASCIIString)
    msg = JSON.parse(strip(line))
    if "kill_worker" in keys(msg)
        worker.active = false
    end
end
