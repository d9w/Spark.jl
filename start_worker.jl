require("ArgParse")
require("Spark")
using ArgParse
using Spark

function parse_cli()
  s = ArgParseSettings("start_worker.jl")

  @add_arg_table s begin
    "port"
      help = "Listening port on worker for RPC calls"
      arg_type = Int64
      default = 6666
    "masterhostname"
      help = "Hostname of master to contact for RDD queries"
      arg_type = ASCIIString
      default = "localhost"
    "masterport"
      help = "Port of master to contact for RDD queries"
      arg_type = Int64
      default = 6668
  end

  return parse_args(s)
end

function main()
  args = parse_cli()
  port = args["port"]
  masterhostname = args["masterhostname"]
  masterport = args["masterport"]
  worker = Worker(port, masterhostname, masterport)
  start(worker)
  println("done")
end

main()
