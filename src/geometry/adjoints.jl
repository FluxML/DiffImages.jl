function ChainRules.rrule(::typeof(ImageTransformations.warp!), out, img::AbstractExtrapolation, tform)
    out_p = similar(out, custom_autorange(img, inv(tform)))
    warp!(out, img, tform) # inplace operation => out
    λ(x) = _getindex(img, tform(x))
    
    function α(out_α, img_α, tform_α)
        R = map(x->SVector(x.I), CartesianIndices(out_α)) # indices in the form of SVector
        outn = map(y->λ(y), R)
        outn
    end

    function Δ_warp!(Δ)
        Δ = OffsetArray(collect(Δ), (out_p.offsets)...)
        _, α_pb = pullback(α, out_p, img, tform)
        return (ChainRules.NoTangent(), α_pb(Δ)...)
    end
    return (out, Δ_warp!)
end

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
