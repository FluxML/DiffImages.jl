"""
    homography{T} <: CoordinateTransformations.Transformation
Basic struct for a homography warp.

Fields:
    `H::SMatrix{3,3,T,9}`
"""
struct homography{T} <: CoordinateTransformations.Transformation
    H::SMatrix{3,3,T,9}
    homography() = new{Float64}(rand(SMatrix{3,3,Float64,9}))
    homography{T}() where T = new{T}(rand(SMatrix{3,3,T,9}))
end

function (h::homography{T})(x::SVector{3,K}) where {T,K}
    y = h.H*x
    return SVector{2,Float64}(y[1:2]/y[end])
end

function (h::homography{T})(x::SVector{2,K}) where {T,K}
    return h(SVector{3,K}(x...,1))
end

function Base.inv(h::homography{T}) where T
    i = inv(h.H)
    return homography{T}(i)
end
