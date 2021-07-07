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
    return SVector{2,Float64}(y[1:2]/y[end])
end

function (h::homography{T})(x::SVector{2,K}) where {T,K}
    return h(SVector{3,K}(x...,1))
end

function Base.inv(h::homography{T}) where T
    i = inv(h.H)
    return homography{T}(i)
end

function custom_autorange(R::CartesianIndices, tform)
    mn = mx = tform(SVector(first(R).I))
    for I in (first(R), last(R))
        x = tform(SVector(I.I))
        # we map min and max to prevent type-inference issues
        # (because min(::SVector,::SVector) -> Vector)
        mn = map(min, x, mn)
        mx = map(max, x, mx)
    end
    ImageTransformations._autorange(Tuple(mn), Tuple(mx))
end

custom_autorange(A::AbstractArray, tform) = custom_autorange(CartesianIndices(A), tform)

# function warp_me2(img::AbstractArray{T}, tform) where T
#     img = ImageTransformations.box_extrapolation(img, fillvalue = Interpolations.Flat())
#     e = eltype(img)
#     inds = DiffImages.custom_autorange(img, inv(tform))
#     map(x -> ImageTransformations._getindex(img, tform(SVector(x.I))), CartesianIndices(inds))
#   end
