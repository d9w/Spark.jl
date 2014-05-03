type Worker
    port::Int64
    active::Bool # can be turned off by an RPC
    IP::Base.IPv4

    coworkers::Array{}
    masterhostname::ASCIIString
    masterport::Int64
end

type Master
    rdds::Array{RDD}
    workers::Array{Worker}
end

type PID
    node::Worker
    ID::Int64
end

type Record
    operation::Function
    argument::Any
    sources::Dict{Int64,Array{(Int64,PID)}}
end

type RDD
    ID::Int64
    partitions::Array{PID}
    dependencies::Array{Int64}
    history::Array{Record}
end


