using Spark

include("op_tests.jl")
include("fault_tests.jl")

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

    function run_test(test::Function)
        println(test, " test running")
        try
            test(master)
            print_with_color(:green, string(test, " test passed\n"))
        catch e
            println(e)
            print_with_color(:red, string(test, " test failed\n"))
        end
    end

    # operation tests
#    run_test(input_test)
#    run_test(collect_test)
#    run_test(count_test)
#    run_test(lookup_test)
#    run_test(partition_by_test)
#    run_test(filter_test)
#    run_test(map_test)
#    run_test(group_by_key_test)
#    run_test(join_test)

    # fault tests
    run_test(basic_disc_fault)
    run_test(join_disc_fault)
end

main()
