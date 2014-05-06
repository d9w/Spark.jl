type WorkerRef # for the master
    hostname::ASCIIString
    port::Int64
    socket::Any
    active::Bool
end

type PID
    node::WorkerRef
    ID::Int64
end

type Transformation
    name::ASCIIString
    arguments::Dict{String, Any}
end

type Action
    name::ASCIIString
    arguments::Dict{String, Any}
end

type RDD
    ID::Int64
    partitions::Array{PID}
    dependencies::Dict{Int64,Array{PID}}
    operation::Transformation
    origin_file::String
end

type WorkerPartition
    ID::Int64
    data::Dict{Any, Array{Any}}
end

type WorkerRDD
    partitions::Dict{Int64, WorkerPartition}
    rdd::RDD
end

type Worker # for the worker
    ID::Int
    hostname::ASCIIString
    port::Int64
    active::Bool # can be turned off by an RPC

    coworkers::Array{}
    masterhostname::ASCIIString
    masterport::Int64

    rdds::Dict{Int64, WorkerRDD}

    function Worker(hostname::ASCIIString, port::Int64)
        new(0, hostname, port, true, {}, "", 0, Dict{Int64, RDD}(), Dict{Int64, Dict{Int64, Array{}}}())
    end
end

type Master
    hostname::ASCIIString
    port::Int64

    rdds::Array{RDD}
    workers::Array{WorkerRef}

    function Master(hostname::ASCIIString, port::Int64)
        new(hostname, port, {}, {})
    end
end
