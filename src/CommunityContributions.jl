## contributions() - Calculate diversity contributions from subcommunities
##
## Calculates proportions that subcommunities each contribute to
## ecosystem diversity per subcommunity (perindividual = false), or
## per individual (perindividual = true) - in the latter case scaled
## so that the total # of individuals is 1, since we only have
## relative abundances.
##
## Arguments:
## - measure - diversity measure to use
## - proportions - population proportions
## - qs - single number or vector of values of parameter q
## - perindividual - do we measure per individual in population (true)
##                   or per subcommunity (false)
## - Z - similarity matrix
## - returnecosystem - boolean describing whether to return the
##                     ecosystem diversity
## - returnsubcommunity - boolean describing whether to return the
##                     subcommunity diversities
## - returnweights - boolean describing whether to return subcommunity weights
##
## Returns:
## - contributions of subcommunities to ecosystem diversity (of type measure)
## - and none, some or all (in a tuple) of:
##   - vector of ecosystem diversities representing values of q
##   - array of diversities, first dimension representing subcommunities, and
##     last representing values of q
##   - vector of subcommunity weights
function contributions{S <: FloatingPoint,
                       T <: Number}(measure::Function,
                                    proportions::Matrix{S},
                                    qs::Union(T, Vector{T}),
                                    perindividual::Bool = true,
                                    Z::Matrix{S} = eye(size(proportions, 1)),
                                    returnecosystem::Bool = false,
                                    returnsubcommunity::Bool = false,
                                    returnweights::Bool = false)
    ## We need our qs to be a vector of floating points
    powers = 1. - convert(Vector{S}, [qs])
    
    ## Then calculate the subcommunity and ecosystem diversity measures
    ed, cd, w = diversity(measure, proportions, qs, Z, true, true, true)

    ## And calculate the contributions
    results = zeros(cd)
    for (i, power) in enumerate(powers)
        if (isinf(power))
            if (power > 0) # +Inf -> Maximum, so 1 for top otherwise 0
                results[i, indmax(cd[i, :])] = 1.
            else # -Inf -> Minimum, so 1 for bottom otherwise 0
                results[i, indmin(cd[i, :])] = 1.
            end
        else
            ## We want to use scaled values so that ultimately we can
            ## get everything relative to total and find out
            ## contribution per individual or subcommunity rather than
            ## any kind of actual value
            if (isapprox(power, 0))
                results[i, :] = w .* log(cd[i, :])
                ## IS THIS THE RIGHT WAY TO NORMALISE UNDER LOG?
                results[i, :] -= w .* sum(results[i, :])
            else
                results[i, :] = w .* (cd[i, :] .^ power)
                results[i, :] /= sum(results[i, :])
            end
        end
    end
    contrib = perindividual ? (results ./ w) : results
    ## And then return the right bits
    return (returnecosystem ?
            (returnsubcommunity ?
             (returnweights ? (contrib, ed, cd, w) : (contrib, ed, cd)) :
             (returnweights ? (contrib, ed, w) : (contrib, ed))) :
            (returnsubcommunity ?
             (returnweights ? (contrib, cd, w) : (contrib, cd)) :
             (returnweights ? (contrib, w) : (contrib))))
end
