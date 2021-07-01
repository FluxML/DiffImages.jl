module DiffImages

using Flux,
      Images,
      Zygote,
      ChainRules,
      ImageTransformations,
      StaticArrays,
      OffsetArrays,
      Interpolations,
      CoordinateTransformations,
      ImageProjectiveGeometry

using Flux:@functor, unsqueeze
using Zygote:@adjoint
using ChainRules:NoTangent

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")

end # module
