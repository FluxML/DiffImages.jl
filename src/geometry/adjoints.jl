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

function ChainRulesCore.rrule(::Type{Interpolations.ScaledInterpolation{T, N, TA, IT, RN}}, itp, rn) where {T, N, TA, IT, RN}
    y = Interpolations.ScaledInterpolation{T, N, TA, IT, RN}(itp, rn)
    function scaledinterp_pb(Δy)
        @show "here"
        return NoTangent(), Δy, NoTangent()
    end
    return y, scaledinterp_pb
end

Zygote.@adjoint function Interpolations.ScaledInterpolation{T, N, TA, IT, RN}(itp, rn) where {T, N, TA, IT, RN}
  Interpolations.ScaledInterpolation{T, N, TA, IT, RN}(itp, rn), Δ -> (Δ, nothing)
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

function ChainRulesCore.rrule(::Type{SArray{D, T, ND, L}}, x...) where {D, T, ND, L}
    y = SArray{D, T, ND, L}(x...)
    function sarray_pb(Δy)
        Δy = map(t->eltype(x...)(t...), Δy)
        return NoTangent(), Δy
    end
    return y, sarray_pb
end

function ChainRulesCore.rrule(p::Type{RotMatrix{N, T, L}}, x) where {N, T, L}
    y = p(x)
    function rotmat_pb(Δy)
        Δy = p(Δy)
        return NoTangent(), Δy
    end
    return y, rotmat_pb
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

function ChainRulesCore.rrule_via_ad(::Zygote.ZygoteRuleConfig, h::DiffImages.Homography, x::SVector{2, K}) where K
    Zygote.pullback((x, y)->x(y), h, x)
end

function ChainRulesCore.rrule(::typeof(ImageTransformations.warp!), out, img::AbstractExtrapolation, tform)
    out = ImageTransformations.warp!(out, img, tform)
    function warp!_pb(Δy)
        ∇out = NoTangent()
        ∇img = @not_implemented("To be implemented.")
        flds = fieldnames(typeof(tform))
        ∇tform = canonicalize(Tangent{typeof(tform)}())
        Δy = collect(Δy)
        for p in CartesianIndices(out)
            _, ∇τ = rrule(ImageTransformations._getindex, img, p.I)
            _, _, ∇τ = ∇τ(Δy[p])
            _, ∇ϕ = rrule_via_ad(Zygote.ZygoteRuleConfig(), tform, SVector(p.I))
            ∇h, _ = ∇ϕ(∇τ)
            ∇tform += Tangent{typeof(tform)}(;NamedTuple{flds}(∇h)...)
        end
        return NoTangent(), ∇out, ∇img, ∇tform
    end
    return out, warp!_pb
end
