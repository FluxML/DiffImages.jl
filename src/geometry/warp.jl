"""
    Homography{T} <: CoordinateTransformations.Transformation
Wrapper enclosing a Homography matrix, internally represented as a `SMatrix` from `StaticArrays`. Supports all the features
that a `CoordinateTransformations.Transformation` supports. Outputs homogenous coordinates.

# Examples
```jldoctest; setup = :(using DiffImages, StaticArrays)
julia> h = DiffImages.Homography()
DiffImages.Homography{Float64} with:
3×3 SMatrix{3, 3, Float64, 9} with indices SOneTo(3)×SOneTo(3):
 1.0  0.0  0.0
 0.0  1.0  0.0
 0.0  0.0  1.0

julia> h(SVector((1.0, 2.0, 3.0)))
2-element SVector{2, Float64} with indices SOneTo(2):
 0.3333333333333333
 0.6666666666666666
```
"""
struct Homography{T} <: CoordinateTransformations.Transformation
    H::SMatrix{3,3,T,9}
end

function Homography()
    return Homography{Float64}(SMatrix{3,3,Float64}([1 0 0;0 1 0;0 0 1]))
end

function Homography{T}() where T
    sc = UniformScaling{T}(1)
    m = Matrix(sc, 3, 3)
    return Homography{T}(SMatrix{3, 3, T, 9}(m))
end

function (h::Homography{K})(x::SVector{3, L}) where {L, K}
    hmap = LinearMap(h.H)
    out = hmap(x)
    out = out[1:2] / out[3]
    return SVector{2, K}(out)
end

function (h::Homography{K})(x::AbstractVector{L}) where {L, K}
    x = SVector(x...)
    return h(x)
end

function (h::Homography{K})(x::SVector{2, L}) where {L, K}
    x = SVector(x..., one(K))
    return h(x)
end

# Fancy way to print the Homography struct
function Base.show(io::IO, mime::MIME"text/plain", h::DiffImages.Homography{K}) where K
    println(io, "DiffImages.Homography{$K} with:")
    show(io, mime, h.H)
end
