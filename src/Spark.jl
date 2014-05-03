using JSON

module Spark

export Worker
export RDD

include("types.jl")
include("Worker.jl")
include("Master.jl")
include("RPC.jl")

end
