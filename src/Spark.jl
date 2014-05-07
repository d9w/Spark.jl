using JSON

module Spark

include("types.jl")
include("RPC.jl")
include("Worker.jl")
include("Master.jl")
include("Partitioner.jl")
include("Transformations.jl")
include("Actions.jl")

end
