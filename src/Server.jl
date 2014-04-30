PORT = 6666

server = listen(IPv4(0), PORT)
while true
    sock = accept(server)
    @async while true
        try
            line = deserialize(sock)
            readline(sock)
            println(line(3))
            #write(sock, serialize(sock, "echo")) # echo
        catch e
            println(e)
            println("Network exception - stream closed")
            break
        end
    end
end
