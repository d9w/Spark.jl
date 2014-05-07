abstract Partitioner

type HashPartitioner <: Partitioner
#    partition_number::Int
#    total_partitions::Int
end

type WorkerRef # for the master
    hostname::ASCIIString
    port::Int64
    socket::Any
    active::Bool
end

type Transformation
    name::ASCIIString
    arguments::Dict
end

type Action
    name::ASCIIString
    arguments::Dict
end

type RDD
    ID::Int64
    partitions::Dict{Int64, WorkerRef}
    dependencies::Dict{Int64, Dict{Int64, WorkerRef}}
    operation::Transformation
    partitioner::Partitioner
end

type WorkerPartition
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

    masterhostname::ASCIIString
    masterport::Int64

    rdds::Dict{Int64, WorkerRDD}

    function Worker(hostname::ASCIIString, port::Int64)
        x = new()
        x.hostname = hostname
        x.port = port
        x.rdds = Dict{Int64, WorkerRDD}()
        x.active = true
        return x
    end
end

type Master
    hostname::ASCIIString
    port::Int64

    rdds::Array{RDD}
    workers::Array{WorkerRef}

    function Master(hostname::ASCIIString, port::Int64)
        x = new()
        x.hostname = hostname
        x.port = port
        x.rdds = {}
        x.workers = {}
        return x
    end
end
