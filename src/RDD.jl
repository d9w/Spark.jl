type PID
  node::Int64
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


