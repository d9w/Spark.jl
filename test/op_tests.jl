using Spark

# using master from setup.jl

function input_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "test_reader")
    @assert rdd != false
    @assert length(keys(rdd.partitions)) == 3
end

function collect_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    for kv in collection
        @assert kv[1] <= 10
        @assert length(kv[2]) == 1
        @assert kv[2][1] <= 10
    end
    @assert length(collection) == 10
end

function count_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "test_reader")
    count = Spark.count(master, rdd)
    @assert count == 10
end

function lookup_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    val = Spark.lookup(master, rdd, 3)
    @assert val == {3}
end

function partition_by_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    partitioned_rdd = Spark.partition_by(master, rdd, Spark.HashPartitioner())
    @assert Spark.count(master, rdd) == Spark.count(master, partitioned_rdd)
    for kv in collection
        @assert kv[2] == Spark.lookup(master, partitioned_rdd, kv[1])
    end
end

function filter_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    filtered = Spark.filter(master, rdd, "number_filter")
    count = Spark.count(master, filtered)
    val = Spark.lookup(master, filtered, 7)
    @assert count == 5
    @assert val == {}
end

function map_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    mapped_rdd = Spark.map(master, rdd, "double_map")
    @assert Spark.count(master, rdd) == Spark.count(master, mapped_rdd)
    for kv in collection
        values = Spark.lookup(master, mapped_rdd, kv[1])
        @assert 2*(kv[2][1]) == values[1]
    end
end

function group_by_key_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    collection = Spark.collect(master, rdd)
    mapped_rdd = Spark.map(master, rdd, "one_map")
    collection = Spark.collect(master, mapped_rdd)
    grouped_rdd = Spark.group_by_key(master, mapped_rdd)
    collection = Spark.collect(master, grouped_rdd)
    lookedup = Spark.lookup(master, grouped_rdd, 1)
    @assert Spark.count(master, grouped_rdd) == 1
    @assert length(Spark.lookup(master, grouped_rdd, 1)) == 10
end

function join_test(master::Spark.Master)
    rdd_a = Spark.input(master, "RDDA.txt", "int_reader")
    rdd_b = Spark.input(master, "RDDA.txt", "int_reader")
    joined_rdd = Spark.join(master, rdd_a, rdd_b)
    joined_collection = Spark.collect(master, joined_rdd)
    @assert length(joined_collection) == 10
    for kv in joined_collection
        @assert length(kv[2]) == 2
    end
end

function recover_test(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    master.workers[1].active = false
    println("here's the worker")
    dump(master.workers[1])
    println("=============STARTING MAPPED RDD===================")
    mapped_rdd = Spark.map(master, rdd, "double_map")
    println("mapped RDD here")
    dump(mapped_rdd)
    Spark.recover(master, rdd.ID)
    mapped_rdd = Spark.map(master, rdd, "double_map")
    mapped_collection = Spark.collect(master, mapped_rdd)
    @assert length(mapped_collection) == 10
end
