using Spark

function basic_disc_fault(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    master.workers[1].active = false
    mapped_rdd = Spark.map(master, rdd, "double_map")
    @assert mapped_rdd == false
    # recovery
    new_rdd = Spark.recover(master, rdd)
    collection = Spark.collect(master, new_rdd)
    new_mapped_rdd = Spark.map(master, new_rdd, "double_map")
    @assert Spark.count(master, new_rdd) == Spark.count(master, new_mapped_rdd)
    for kv in collection
        values = Spark.lookup(master, new_mapped_rdd, kv[1])
        @assert 2*(kv[2][1]) == values[1]
    end
    master.workers[1].active = true
end

function join_disc_fault(master::Spark.Master)
    rdd_a = Spark.input(master, "RDDA.txt", "int_reader")
    rdd_b = Spark.input(master, "RDDA.txt", "int_reader")
    # first join
    joined_rdd = Spark.join(master, rdd_a, rdd_b)
    # first collection
    joined_collection = Spark.collect(master, joined_rdd)
    # failure
    master.workers[1].active = false
    # first map
    mapped_rdd = Spark.map(master, joined_rdd, "double_map")
    @assert mapped_rdd == false
    # recover
    new_joined_rdd = Spark.recover(master, joined_rdd)
    # second collect
    joined_collection = Spark.collect(master, new_joined_rdd)
    @assert new_joined_rdd != false
    new_mapped_rdd = Spark.map(master, new_joined_rdd, "double_map")
    @assert new_mapped_rdd != false
    @assert Spark.count(master, new_joined_rdd) == 10
    for kv in joined_collection
        @assert length(kv[2]) == 2
    end
    master.workers[1].active = true
end
