using JSON
using Spark

function start(worker::Worker)
    server = listen(IPv4(0), worker.port)
    println("Starting worker")
    while worker.active
        sock = accept(server)
        while worker.active
            try
                line = readline(sock)
                result = handle(worker, line)
                println(sock, json({"result" => result}))
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
    r = false
    if "call" in keys(msg)
        r = eval(Expr(:call, symbol(msg["call"]), worker, msg["args"]))
    end
    return r
end
