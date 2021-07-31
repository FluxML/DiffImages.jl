module DiffImages

using ImageTransformations: include
using Flux,
      Images,
      Zygote,
      ChainRules,
      ImageTransformations,
      StaticArrays,
      OffsetArrays,
      CoordinateTransformations,
      ColorVectorSpace,
      Interpolations,
      ChainRulesCore

using Flux: @functor, unsqueeze
using Zygote: @adjoint
using ChainRulesCore: NoTangent

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")
include("geometry/adjoints.jl")

end # module
