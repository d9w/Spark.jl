using JSON

module Spark

export Worker, start
export RDD
export Master

include("types.jl")
include("Worker.jl")
include("Master.jl")
include("RPC.jl")
include("FileInput.jl")

end
