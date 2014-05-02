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
    try
      line = deserialize(sock)
      readline(sock)
      println(line)
    catch e
      println(e)
      break
    end
  end
end
