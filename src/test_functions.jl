function test_reader(line::String)
    return {(convert(Int64, hash(line)), chomp(line))}
end

# map functions should take a key, value pair and return an array
# of key, value pairs, where values are all arrays of values,
# consistent with the RDD datatype
function test_map(key, value::Array)
    new_kvs = {}
    for v in value
        push!(new_kvs, (v, {key}))
    end
end
