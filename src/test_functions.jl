function test_reader(line::String)
    return {(convert(Int64, hash(line)), {chomp(line)})}
end

function direct_reader(line::String)
    return {(strip(line), {strip(line)})}
end

function int_reader(line::String)
    return {(parse(chomp(line)), {parse(chomp(line))})}
end

# map functions should take a key, value pair and return an array
# of key, value pairs, where values are all arrays of values,
# consistent with the RDD datatype
function test_map(key, value::Array)
    new_kvs = {}
    for v in value
        push!(new_kvs, (v, {key}))
    end
    return new_kvs
end

function double_map(key, value::Array)
    new_kvs = {}
    for v in value
        push!(new_kvs, (key, {2*v}))
    end
    return new_kvs
end

function one_map(key, value::Array)
    new_kvs = {}
    for v in value
        push!(new_kvs, (1, {v}))
    end
    return new_kvs
end

function test_filter(key, value::Array)
    length(value) == 1
end

function number_filter(key, value::Array)
    key <= 5
end
