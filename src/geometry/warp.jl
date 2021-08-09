"""
    Homography{T} <: CoordinateTransformations.Transformation
Wrapper enclosing a Homography matrix, internally represented as a `SMatrix` from `StaticArrays`. Supports all the features
that a `CoordinateTransformations.Transformation` supports. Outputs homogenous coordinates.

# Examples
```jldoctest; setup = :(using DiffImages, StaticArrays)
julia> h = DiffImages.Homography()
Homography{Float64}([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0])

julia> h(SVector((1.0, 2.0, 3.0)))
2-element SVector{2, Float64} with indices SOneTo(2):
 0.3333333333333333
 0.6666666666666666
```
"""
struct Homography{T} <: CoordinateTransformations.Transformation
    H::SMatrix{3,3,T,9}
    Homography() = new{Float64}(SMatrix{3,3,Float64}([1 0 0;0 1 0;0 0 1]))
    Homography{T}() where T = new{T}(rand(SMatrix{3,3,T,9}))
    Homography{T}(m::SMatrix{3,3,T,9}) where T = new(m)
end

function (h::Homography{T})(x::SVector{3,K}) where {T,K}
    y = h.H * x
    return SVector{2,T}(y[1:2] ./ y[end])
end

function (h::Homography{T})(x::SVector{2,K}) where {T,K}
    return h(SVector{3,K}(x...,1))
end

function Base.inv(h::Homography{T}) where T
    i = inv(h.H)
    return Homography{T}(i)
end

# Fancy way to print the Homography struct
function Base.show(::IO, ::MIME"text/plain", h::DiffImages.Homography{K}) where K
    println("DiffImages.Homography{$K} with:")
    display(h.H)
end

Base.:-(ŷ::NamedTuple) = map(x->-x, ŷ)
