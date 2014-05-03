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

type Worker
    hostname::ASCIIString
    port::Int64
    active::Bool # can be turned off by an RPC

    coworkers::Array{}
    masterhostname::ASCIIString
    masterport::Int64

    rdds::Dict{Int64, RDD}
    data::Dict{Int64, Dict{Int64, Array{}}}
end

type Master
    hostname::ASCIIString
    port::Int64

    rdds::Array{RDD}
    workers::Array{Worker} # seems redundant with below
    activeworkers::Array{Base.TcpSocket}
    inactiveworkers::Array{(ASCIIString, Int64)}
end
