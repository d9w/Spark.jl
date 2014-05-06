#This object describes a deterministic partitioning
#keys for which hash(key) = partition mod total_partitions
#is true are in this partition. The rdd should probably store the
#partitioning to be able to recover specific partitions.
type Partitioner
    partition_number::Int
    total_partitions::Int
end

type PID
    node::(String, Int)
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

type Record
    operation::Transformation
    sources::Dict{Int64,Array{(Int64,PID)}}
end

type RDD
    ID::Int64
    partitions::Array{PID}
    dependencies::Array{Int64}
    history::Array{Record}
    origin_file::String
end

type WorkerRDD
    ID::Int64
    partitions::Array{WorkerPartition}
    dependencies::Array{Int64}
    history::Array{Record}
    origin_file::String
end

type WorkerPartition
    ID::Int64
    data::Dict{Any, Array{Any}}
end

type Worker
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
    activeworkers::Array{(ASCIIString, Int64, Base.TcpSocket)}
    inactiveworkers::Array{(ASCIIString, Int64)}

    function Master(hostname::ASCIIString, port::Int64)
        new(hostname, port, {}, {}, {}, {})
    end
end
