# TODO(arcAman07): support RGB inputs, currently works only for GrayScale Images
# TODO(arcAman07): support N dimensional case, currently works only for 2 dimensional case
@adjoint function fdiff(A::AbstractArray; kwargs...)
  y = fdiff!(similar(A, maybe_floattype(eltype(A))), A; kwargs...)
  final = similar(A, eltype(A))
  function pullback(Δ)
    fill!(final, Δ)
    return (final,)
  end
  return (y, pullback)
end