abstract Partition

type HashPartition <: Partition
    partition_number::Int
    total_partitions::Int
end

type RangePartition{T} <: Partition
    range_start::T
    range_end::T
end

type PID
    node::(String, Int)
    ID::Int64
    partition::Partition
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

type Worker
    ID::Int
    hostname::ASCIIString
    port::Int64
    active::Bool # can be turned off by an RPC

    coworkers::Array{}
    masterhostname::ASCIIString
    masterport::Int64

    rdds::Dict{Int64, RDD}
    data::Dict{Int64, Dict{Int64, Array{}}}

    function Worker(hostname::ASCIIString, port::Int64)
        new(0, hostname, port, true, {}, "", 0, Dict{Int64, RDD}(), Dict{Int64, Dict{Int64, Array{}}}())
    end
end

type Master
    hostname::ASCIIString
    port::Int64

    rdds::Array{RDD}
    workers::Array{Worker} # seems redundant with below
    activeworkers::Array{(ASCIIString, Int64, Base.TcpSocket)}
    inactiveworkers::Array{(ASCIIString, Int64)}

    function Master(hostname::ASCIIString, port::Int64)
        new(hostname, port, {}, {}, {}, {})
    end
end
