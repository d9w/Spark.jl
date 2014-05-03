type Worker
    port::Int64
    active::Bool # can be turned off by an RPC

    coworkers::Array{}
    masterhostname::Base.IPv4
    masterport::Int64
    
    #=rdds::Dict{Int64, RDD}=#
    data::Dict{Int64, Dict{Int64, Array{}}}
end

type PID
    #TODO solve circular dependency. Possible fix: store (ip, port) tuple
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
    origin_file::String
end

type Master
    rdds::Array{RDD}
    workers::Array{Worker}
end
