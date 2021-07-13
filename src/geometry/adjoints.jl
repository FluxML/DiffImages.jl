# function ChainRules.rrule(::typeof(ImageTransformations.warp!), out, img::AbstractExtrapolation, tform)
#     out_p = similar(out, custom_autorange(img, inv(tform)))
#     warp!(out, img, tform) # inplace operation => out
#     λ(x) = _getindex(img, tform(x))
#
#     function α(out_α, img_α, tform_α)
#         R = map(x->SVector(x.I), CartesianIndices(out_α)) # indices in the form of SVector
#         outn = map(y->λ(y), R)
#         outn
#     end
#
#     function Δ_warp!(Δ)
#         Δ = OffsetArray(collect(Δ), (out_p.offsets)...)
#         _, α_pb = pullback(α, out_p, img, tform)
#         return (ChainRules.NoTangent(), α_pb(Δ)...)
#     end
#     return (out, Δ_warp!)
# end

Zygote.@adjoint function Interpolations.BSplineInterpolation(T, A, it, axs)
  Interpolations.BSplineInterpolation(T, A, it, axs), Δ₁ -> begin
    (nothing, Δ₁, nothing, nothing)
  end
end

Zygote.@adjoint function Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}(A, axs, it) where {T, N, TA, IT, TAX}
  Interpolations.BSplineInterpolation{T, N, TA, IT, TAX}(A, axs, it), Δ₂ -> begin
    (Δ₂, nothing, nothing)
  end
end

Zygote.@adjoint function Interpolations.Extrapolation{T,N,ITPT,IT,ET}(itp, et::Union{Interpolations.Flat, Interpolations.Reflect, Interpolations.Line}) where {T,N,ITPT,IT,ET}
  Interpolations.Extrapolation{T,N,ITPT,IT,ET}(itp, et), Δ₃ -> begin
    (Δ₃, nothing)
  end
end

Zygote.@nograd Interpolations.tweight
Zygote.@nograd Interpolations.tcoef

Zygote.@adjoint function Interpolations.copy_with_padding(T, A, it)
  Interpolations.copy_with_padding(T, A, it), Δ₄ -> begin
    (nothing, Δ₄, nothing)
  end
end

Zygote.@adjoint function Interpolations.FilledExtrapolation(itp, fv)
  Interpolations.FilledExtrapolation(itp, fv), Δ₅ -> begin
    (Δ₅, nothing)
  end
end

Zygote.@adjoint function SVector{N,T}(x...) where {T,N}
  SVector{N,T}(x...), Δ -> begin
    (Δ,)
  end
end

Zygote.@adjoint function CartesianIndices(t::Tuple)
  CartesianIndices(t), Δ -> (Δ,)
end

# adjoint for round(args; kwargs...) since only adjoint for round(args) was defined.
# function ChainRules.rrule(f::typeof(round), x; kwargs...)
#   ȳ = round(x; kwargs...)
#   function pbs(Δ)
#       return (NoTangent(), Δ*zero(x))
#   end
#   return (ȳ, pbs)
# end

Zygote.@nograd custom_autorange

Zygote.@adjoint function ImageTransformations._getindex(A::AbstractExtrapolation, x)
  y = A(Tuple(x)...)
  function ∇(δ)
      gr = Interpolations.gradient(A, Tuple(x)...)
      return (nothing, (gr,))
  end
  return (y, ∇)
end

function ChainRulesCore.rrule(h::DiffImages.homography, x::SVector{2,K}) where K
     # elements of x => (i₀,j₀)
     y = h(x) # Gives us (i j)
     function ∇homography(Δ)
         # Δ => (∂g/∂i ∂g/∂j)
         v₁ = h.H*SVector((x...,1.0)) # Gives us (i₁ j₁ z)
         (∂i_∂W, ∂j_∂W) = begin
             r₁ = [x[1] x[2] 1]
             r₂ = [0.0 0.0 0.0]
             (1/v₁[3]*vcat(r₁, r₂, -y[1]*r₁), 1/v₁[3]*vcat(r₂, r₁, -y[2]*r₁))
         end
         return (Tangent{DiffImages.homography}(H = Δ[1][1]*∂i_∂W + Δ[1][2]*∂j_∂W), ((h.H[1:2, 1:2]*Δ[1])[1]/v₁[3])')
     end
     return (y, ∇homography)
 end
