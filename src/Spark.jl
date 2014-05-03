using JSON

module Spark

export Worker, start
export RDD

include("types.jl")
include("Worker.jl")
include("Master.jl")
include("RPC.jl")

end
