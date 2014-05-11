using Spark
using ArgParse

include("op_tests.jl")
include("fault_tests.jl")

function parse_cli()
    s = ArgParseSettings("run_tests.jl")

    @add_arg_table s begin
        "tests"
            help = "Names of test, 'operation', 'fault', or 'all'"
            arg_type = ASCIIString
            default = "all"
    end

    return parse_args(s)
end

function start_worker(port::Int64)
    worker = Spark.Worker("127.0.0.1", port)
    Spark.start(worker)
    println("done")
end

function main()
    master = Spark.Master("127.0.0.1", 3333)
    for i in 0:2
        @async start_worker(6666+i)
    end
    # fill in master.workers
    Spark.load(master, "default_workers.json")
    # start master listener
    Spark.initserver(master)

    function run_test(test::ASCIIString)
        println(test, " test running")
        try
            eval(Expr(:call, symbol(test), master))
            print_with_color(:green, string(test, " test passed\n"))
        catch e
            println(e)
            print_with_color(:red, string(test, " test failed\n"))
        end
    end

    args = parse_cli()
    test = args["tests"]
    op_tests = {"input_test", "collect_test", "count_test", "lookup_test","partition_by_test", "filter_test", "map_test", "group_by_key_test", "join_test"}
    fault_tests = {"basic_disc_fault", "join_disc_fault"}

    tests = {}
    if test == "operation"
        tests = cat(1, tests, op_tests)
    elseif test == "fault"
        tests = cat(1, tests, fault_tests)
    elseif test == "all"
        tests = cat(1, tests, op_tests)
        tests = cat(1, tests, fault_tests)
    else
        tests = cat(1, tests, test)
    end

    for t in tests
        run_test(t)
    end
end

main()
