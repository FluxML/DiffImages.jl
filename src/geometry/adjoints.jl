# function ChainRulesCore.rrule(::Interpolations.BSplineInterpolation, T, A, it, axs)
#     y = Interpolations.BSplineInterpolation(T, A, it, axs)
#     function bspline_pb(Δy)
#         return NoTangent(), NoTangent(), Δy, NoTangent(), NoTangent()
#     end
#     return y, bspline_pb
# end TODO: Remove the rrule later.

function ChainRulesCore.rrule(::Type{Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}}, A, axs, it) where {T, N, TA, IT, TAX}
    y = Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}(A, axs, it)
    function bspline_const_pb(Δy)
        return NoTangent(), Δy, NoTangent(), NoTangent()
    end
    return y, bspline_const_pb
end

function ChainRulesCore.rrule(::Type{Interpolations.Extrapolation{T, N, ITPT, IT, ET}}, itp, et::Union{Interpolations.Flat, Interpolations.Reflect, Interpolations.Line}) where {T,N,ITPT,IT,ET}
    y = Interpolations.Extrapolation{T,N,ITPT,IT,ET}(itp, et)
    function extrap_const_pb(Δy)
        return NoTangent(), Δy, NoTangent()
    end
    return y, extrap_const_pb
end

Zygote.@nograd Interpolations.tweight
Zygote.@nograd Interpolations.tcoef

function ChainRulesCore.rrule(::typeof(Interpolations.copy_with_padding), T, A, it)
    y = Interpolations.copy_with_padding(T, A, it)
    function copy_with_padding_pullback(Δy)
        return NoTangent(), NoTangent(), Δy, NoTangent()
    end
    return y, copy_with_padding_pullback
end

function ChainRulesCore.rrule(::Type{Interpolations.FilledExtrapolation}, itp, fv)
    y = Interpolations.FilledExtrapolation(itp, fv)
    function filledextra_const_pb(Δy)
        return NoTangent(), Δy, NoTangent()
    end
    return y, filledextra_const_pb
end

function ChainRulesCore.rrule(::Type{SVector{N, T}}, x...) where {N, T}
    y = SVector{N,T}(x...)
    function svector_const_pb(Δy)
        Δy = map(t->eltype(x...)(t...), Δy)
        return NoTangent(), Δy
    end
    return y, svector_const_pb
end

function ChainRulesCore.rrule(::typeof(ImageTransformations._getindex), A::AbstractExtrapolation, x)
    y = A(Tuple(x)...)
    function _getindex_pb(Δy)
        # Δy :: NamedTuple{(:r, :g, :b)} or something similar
        Δy = eltype(A)(Δy...)
        gr = Interpolations.gradient(A, x...)
        n = nfields(Δy) > 0 ? nfields(Δy) : 1
        return NoTangent(), NoTangent(), (Δy .⋅ gr) * n
    end
    return y, _getindex_pb
end

function ChainRulesCore.rrule(h::DiffImages.Homography, x::SVector{2,K}) where {K}
    # elements of x => (i₀,j₀)
    y = h(x) # Gives us (i j)
    function Homography_pb(Δy)
        # Δy => (∂g/∂i ∂g/∂j) :: SVector{2, Float64}
        v₁ = h.H * SVector((x..., 1.0)) # Gives us (i₁ j₁ z)
        ∂ij_∂W = begin
            r₁ = [x[1] x[2] one(K)]
            r₂ = zeros(K, 1, 3)
            [1 / v₁[3] * vcat(r₁, r₂, -y[1] * r₁), 1 / v₁[3] * vcat(r₂, r₁, -y[2] * r₁)]
        end
        return Tangent{DiffImages.Homography}(H = Δy' * ∂ij_∂W), (h.H[1:2, 1:2]*Δy) ./ v₁[3]
    end
    return y, Homography_pb
end

function ChainRulesCore.rrule_via_ad(::Zygote.ZygoteRuleConfig, h::DiffImages.Homography, x::SVector{2, K}) where K
    Zygote.pullback((x, y)->x(y), h, x)
end

function ChainRulesCore.rrule(::typeof(ImageTransformations.warp!), out, img::AbstractExtrapolation, tform)
    out = ImageTransformations.warp!(out, img, tform)
    function warp!_pb(Δy)
        ∇out = NoTangent()
        ∇img = @not_implemented("To be implemented.")
        ∇tform = Tangent{DiffImages.Homography}(H = zeros(eltype(tform.H), 3, 3)) # TODO: Change this to Tangent{LinearMap} when generalized in future
        Δy = collect(Δy)
        for p in CartesianIndices(out)
            _, ∇τ = rrule(ImageTransformations._getindex, img, p.I)
            _, _, ∇τ = ∇τ(Δy[p])
            _, ∇ϕ = rrule_via_ad(Zygote.ZygoteRuleConfig(), tform, SVector(p.I))
            ∇h, _ = ∇ϕ(∇τ)
            ∇tform += Tangent{DiffImages.Homography}(H = ∇h.H)
        end
        return NoTangent(), ∇out, ∇img, ∇tform
    end
    return out, warp!_pb
end
