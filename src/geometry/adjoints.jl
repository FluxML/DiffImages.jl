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

function ChainRulesCore.rrule(::Type{CartesianIndices{N, T}}, x::Tuple) where {N,T}
    y = CartesianIndices{N,T}(x)
    function cartesian_pb(Δy)
        # ∇x does not exist mathematically since x::Tuple{UnitRange, UnitRange}
        return NoTangent(), NoTangent()
    end
    return y, cartesian_pb
end
