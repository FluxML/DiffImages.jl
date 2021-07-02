function custom_autorange(R::CartesianIndices, tform)
    tform = _round(tform)
    mn = mx = tform(SVector(first(R).I))
    for I in (first(R), last(R))
        x = tform(SVector(I.I))
        # we map min and max to prevent type-inference issues
        # (because min(::SVector,::SVector) -> Vector)
        mn = map(min, x, mn)
        mx = map(max, x, mx)
    end
    @show mn mx
    _autorange(Tuple(mn), Tuple(mx))
end

custom_autorange(A::AbstractArray, tform) = custom_autorange(CartesianIndices(A), tform)

_autorange(mn,mx) = map((a,b)->floor(Int,a):ceil(Int,b), mn, mx)

function warp_me(img::AbstractArray{T}, tform; bc = Flat()) where T
    img = box_extrapolation(img, fillvalue = bc)
    e = eltype(img)
    inds = custom_autorange(img, inv(tform))
    out = similar(img, inds)
    # warp!(out, img, tform)
    map(x -> ImageTransformations._getindex(img, tform(SVector(x.I))), CartesianIndices(inds))
end
# add args and kwargs

# Base.convert(::Type{RGB{Float64}}, v::NamedTuple{(:r, :g, :b), Tuple{Float64, Float64, Float64}}) = RGB{Float64}(v.r, v.g, v.b)

function ChainRules.rrule(::typeof(ImageTransformations.warp!), out, img::AbstractExtrapolation, tform)
    out_p = similar(out, custom_autorange(img, inv(tform)))
    warp!(out, img, tform) # inplace operation => out
    λ(x) = _getindex(img, tform(x))

    
    function α(out_α, img_α, tform_α)
        R = map(x->SVector(x.I), CartesianIndices(out_α)) # indices in the form of SVector
        outn = map(y->λ(y), R)
        outn
        # return (out_α, img_α, tform_α, R)
    end

    function Δ_warp!(Δ)
        @show typeof(Δ) size(Δ) out_p.offsets
        Δ = OffsetArray(collect(Δ), (out_p.offsets)...)
        # Δ = reinterpret.()
        @show typeof(Δ)
        _, α_pb = pullback(α, out_p, img, tform)
        # _, β_pb = pullback(β, o_α, ig_α, tf_α, R_α)
        # @show typeof(α_pb((Δ,))) size(α_pb((Δ,)))
        # @show typeof(β_pb(identity)) size(β_pb(identity))
        # final_pb(δ) = β_pb(α_pb(δ)...)
        # return (ChainRules.NoTangent(), final_pb(Δ)...)
        return (ChainRules.NoTangent(), α_pb(Δ)...)
    end
    return (out, Δ_warp!)
end

rgb(A::RGB{T}) where T = A.r + A.g + A.b # dummy function


Zygote.@adjoint function Interpolations.BSplineInterpolation(T, A, it, axs)
  Interpolations.BSplineInterpolation(T, A, it, axs), Δ -> begin
    (nothing, Δ, nothing, nothing)
  end
end

Zygote.@adjoint function Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}(A, axs, it) where {T, N, TA, IT, TAX}
  Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}(A, axs, it), Δ -> begin
    (Δ, nothing, nothing)
  end
end

Zygote.@adjoint function Interpolations.Extrapolation{T,N,ITPT,IT,ET}(itp, et::Union{Interpolations.Flat, Interpolations.Reflect, Interpolations.Line}) where {T,N,ITPT,IT,ET}
  Interpolations.Extrapolation{T,N,ITPT,IT,ET}(itp, et), Δ -> (Δ, nothing)
end

Zygote.@nograd Interpolations.tweight
Zygote.@nograd Interpolations.tcoef

Zygote.@adjoint function Interpolations.copy_with_padding(T, A, it)
  Interpolations.copy_with_padding(T, A, it), Δ -> begin
    (nothing, Δ, nothing)
  end
end

Zygote.@adjoint function Interpolations.FilledExtrapolation(itp, fv)
  Interpolations.FilledExtrapolation(itp, fv), Δ -> begin
    (Δ, nothing)
  end
end

# function ChainRulesCore.rrule(itp::AbstractExtrapolation, x...)
#   y = itp(x...)
#   function pullback(Δy)
#     (ChainRulesCore.NoTangent(), Δy * Interpolations.gradient(itp, x...)...)
#   end
#   y, pullback
# end

function ChainRulesCore.rrule(itp::AbstractExtrapolation, x...)
  y = itp(x...)
  function pullback(Δy)
    (Δy, Interpolations.gradient(itp, x...)...)
  end
  y, pullback
end

Zygote.@adjoint function SVector{N,T}(x...) where {T,N}
  SVector{N,T}(x...), Δ -> (Δ...,)
end
