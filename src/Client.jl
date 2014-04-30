client = connect(6666)
@async while true
    write(STDOUT, readline(client))
end
while true
    data = x -> x^2 + 2x - 4
    println(client, serialize(client, data))
end
