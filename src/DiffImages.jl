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
      ChainRulesCore

using Flux: @functor, unsqueeze
using Zygote: @adjoint
using ChainRulesCore: NoTangent

export colorify, channelify
include("colors/conversions.jl")
include("geometry/adjoints.jl")

end