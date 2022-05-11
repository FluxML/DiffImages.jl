@adjoint function sumfinite(A::AbstractArray{T,N}; kwargs...) where {T,N}
  y = ImageBase.sumfinite(identity, A; kwargs...)
  function pullback(Δ)
    return (fill(Δ,size(A)),)
  end
  return (y, pullback)
end

@adjoint function meanfinite(A::AbstractArray{T,N}; kwargs...) where {T,N}
  y = ImageBase.meanfinite(identity, A; kwargs...)
  function pullback(Δ)
    return (fill(Δ / length(A),size(A)),)
  end
  return (y, pullback)
end

@adjoint function maximum_finite(A::AbstractArray{T,N}; kwargs...) where {T,N}
  y = ImageBase.maximum_finite(identity, A; kwargs...)
  final = zeros(Float64, size(A))
  function pullback(Δ)
    final[last(findall(x -> x == y, A))] = Δ
    return (final,)
  end
  return (y, pullback)
end

@adjoint function minimum_finite(A::AbstractArray{T,N}; kwargs...) where {T,N}
  y = ImageBase.minimum_finite(identity, A; kwargs...)
  final = zeros(Float64, size(A))
  function pullback(Δ)
    final[first(findall(x -> x == y, A))] = Δ
    return (final,)
  end
  return (y, pullback)
end