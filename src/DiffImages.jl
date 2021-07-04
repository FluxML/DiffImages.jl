module DiffImages

using Flux,
      Images,
      Zygote,
      ChainRules,
      ImageTransformations,
      StaticArrays,
      OffsetArrays,
      Interpolations,
      CoordinateTransformations

using Flux: @functor, unsqueeze
using Zygote: @adjoint
using ChainRules: NoTangent
using ChainRulesCore

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")
include("geometry/adjoints.jl")

end # module
