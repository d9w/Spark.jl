require("ArgParse")
require("src/Spark")
using ArgParse
using Spark

function parse_cli()
  s = ArgParseSettings("start_worker.jl")

  @add_arg_table s begin
    "port"
      help = "Listening port on worker for RPC calls"
      arg_type = Int64
      default = 6666
  end

  return parse_args(s)
end

function main()
  args = parse_cli()
  port = args["port"]
  worker = Worker("127.0.0.1", port)
  start(worker)
  println("done")
end

main()
