#####################
## Transformations ##
#####################

# narrow
function map()
end

# narrow
function filter()
end

# narrow
function flat_map()
end

# wide
function group_by_key()
end

# wide
function reduce_by_key()
end

# call on 2 RDDs returns 1 RDD whose partitions are the union of those of the parents.
# each child partition is computed through a narrow dependency on its parent
function union()
end

# can have wide or narrow dependencies
function join()
end

# wide
function cogroup()
end

# wide
function cross_product()
end

# narrow
function map_values()
end

# wide
function sort()
end


#############
## Actions ##
#############

function count()
end

function collect()
end

function reduce()
end

function lookup()
end

function save()
end

