"""
    homography{T} <: CoordinateTransformations.Transformation
Basic struct for a homography warp.

Fields:
    `H::SMatrix{3,3,T,9}`
"""
struct homography{T} <: CoordinateTransformations.Transformation
    H::SMatrix{3,3,T,9}
end

@functor homography (H,)

# Defining required methods for ImageTransformations.warp to work
function (h::homography{T})(x::SVector{3,K}) where {T,K}
    y = h.H*x
    return y[1:2] # (y./y[end])[1:2]
end

function (h::homography{T})(x::SVector{2,K}) where {T,K}
    return h(SVector{3,K}(x...,1))
end

function Base.inv(h::homography{T}) where T
    i = inv(h.H)
    return homography{T}(i)
end

# adjoint for round(args; kwargs...) since only adjoint for round(args) was defined.
function ChainRules.rrule(f::typeof(round), x; kwargs...)
    ȳ = round(x; kwargs...)
    function pbs(Δ)
        return (NoTangent(), Δ*zero(x))
    end
    return (ȳ, pbs)
end
