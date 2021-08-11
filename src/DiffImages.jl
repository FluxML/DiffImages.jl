module DiffImages
using Flux,
      ImageCore,
      Zygote,
      ChainRules,
      ImageTransformations,
      StaticArrays,
      CoordinateTransformations,
      ColorVectorSpace,
      Interpolations,
      ChainRulesCore,
      LinearAlgebra

using Flux: @functor, unsqueeze
using Zygote: @adjoint
using ChainRulesCore: NoTangent

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")
include("geometry/adjoints.jl")

end
