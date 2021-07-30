using Base: Tuple
function ChainRulesCore.rrule(::typeof(Interpolations.BSplineInterpolation), T, A, it, axs)
    y = Interpolations.BSplineInterpolation(T, A, it, axs)
    return (y, Δ -> begin
        (NoTangent(), NoTangent(), Δ, NoTangent(), NoTangent())
    end)
end

function ChainRulesCore.rrule(::typeof(Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}), A, axs, it) where {T, N, TA, IT, TAX}
    y = Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}(A, axs, it)
    return (y, Δ -> begin
        (NoTangent(), Δ, NoTangent(), NoTangent())
    end)
end

function ChainRulesCore.rrule(::typeof(Interpolations.Extrapolation{T, N, ITPT, IT, ET}), itp, et::Union{Interpolations.Flat, Interpolations.Reflect, Interpolations.Line}) where {T,N,ITPT,IT,ET}
    y = Interpolations.Extrapolation{T,N,ITPT,IT,ET}(itp, et)
    return (y, Δ -> begin
        (NoTangent(), Δ, NoTangent())
    end)
end

Zygote.@nograd Interpolations.tweight
Zygote.@nograd Interpolations.tcoef

function ChainRulesCore.rrule(::typeof(Interpolations.copy_with_padding), T, A, it)
    y = Interpolations.copy_with_padding(T, A, it)
    return (y, Δ -> begin
        (NoTangent(), NoTangent(), Δ, NoTangent())
    end)
end

function ChainRulesCore.rrule(::typeof(Interpolations.FilledExtrapolation), itp, fv)
    y = Interpolations.FilledExtrapolation(itp, fv)
    return (y, Δ -> begin
        (NoTangent(), Δ, NoTangent())
    end)
end

function ChainRulesCore.rrule(::typeof(SVector{N, T}), x...) where {N, T}
    y = SVector{N,T}(x...)
    return (y, Δ -> begin
        (NoTangent(), Δ)
    end)
end

function ChainRulesCore.rrule(::typeof(CartesianIndices), t::Tuple)
    y = CartesianIndices(t)
    return (y, Δ -> begin
        (NoTangent(), Δ)
    end)
end
