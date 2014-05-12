Spark.jl
===========

A basic implementation of Apache Spark for Julia. Examples of use can be found
in the test directory. A user will specify workers in a JSON file like
`default_workers.json` and call `julia start_worker.jl` on them, specifying the
correct port.

Locally, the user can then start a Spark.Master instance and use it to create
and manipulate resilient distributed datasets:

```julia

using Spark
master = Spark.Master("127.0.0.1", 3333)
# fill in master.workers
Spark.load(master, "default_workers.json")
# start master listener
Spark.initserver(master)

# Create and manipulate RDDs
rdd = Spark.input(master, "RDDA.txt", "int_reader")
filtered_rdd = Spark.filter(master, rdd, "number_filter")
results = Spark.collect(master, filtered_rdd)
```
