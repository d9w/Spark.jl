using Spark

# using master from setup.jl
function count_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "test_reader") 
    count = Spark.count(master, rdd)
    @assert count == 10
end

function lookup_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "direct_reader") 
    val = Spark.lookup(master, rdd, "3")
    @assert val == "3"
end

function filter_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    filtered = Spark.filter(master, rdd, "number_filter")
    count = Spark.count(master, filtered)
    val = Spark.lookup(master, filtered, 7)
    @assert count == 5
    @assert val == false
end
