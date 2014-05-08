using JSON

module Spark

include("Types.jl")
include("test_functions.jl")
include("RPC.jl")
include("Worker.jl")
include("Master.jl")
include("Partitioner.jl")
include("Transformations.jl")
include("Actions.jl")

end
