using Spark

# using master from setup.jl

function input_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "test_reader")
    @assert rdd != false
    @assert length(keys(rdd.partitions)) == 3
end

function collect_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    for kv in collection
        @assert kv[1] <= 10
        @assert length(kv[2]) == 1
        @assert kv[2][1] <= 10
    end
    @assert length(collection) == 10
end

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

function partition_by_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    partitioned_rdd = Spark.partition_by(master, rdd, Spark.HashPartitioner())
    @assert Spark.count(master, rdd) == Spark.count(master, partitioned_rdd)
    for kv in collection
        @assert kv[2] == Spark.lookup(master, partitioned_rdd, kv[1])
    end
end

function filter_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    filtered = Spark.filter(master, rdd, "number_filter")
    count = Spark.count(master, filtered)
    val = Spark.lookup(master, filtered, 7)
    @assert count == 5
    @assert val == false
end

function map_test(master::Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    mapped_rdd = map(master, rdd, "double_map")
    @assert Spark.count(master, rdd) == Spark.count(master, partitioned_rdd)
    for kv in collection
        values = Spark.lookup(master, mapped_rdd, kv[1])
        @assert 2*(kv[2][1]) == values[1]
    end
end

function group_by_key_test(master::Master)
end

function join_test(master::Master)
end
