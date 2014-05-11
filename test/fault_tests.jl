using Spark

function basic_disc_fault(master::Spark.Master)
    rdd = Spark.input(master, "RDDA.txt", "int_reader")
    master.workers[1].active = false
    mapped_rdd = Spark.map(master, rdd, "double_map")
    @assert mapped_rdd == false
    # recovery
    new_rdd = Spark.recover(master, rdd.ID)
    collection = Spark.collect(master, new_rdd)
    mapped_rdd = Spark.map(master, new_rdd, "double_map")
    @assert Spark.count(master, new_rdd) == Spark.count(master, mapped_rdd)
    for kv in collection
        values = Spark.lookup(master, mapped_rdd, kv[1])
        @assert 2*(kv[2][1]) == values[1]
    end
end
