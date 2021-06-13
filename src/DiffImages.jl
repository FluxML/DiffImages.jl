module DiffImages

using Flux,
      Images,
      Zygote,
      ChainRules,
      ImageTransformations

using Flux:@adjoint, @functor, unsqueeze
using ChainRules:NoTangent

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")

end # module
