module DiffImages

using Flux,
      Images,
      Zygote,
      ChainRules

using Flux:@functor, unsqueeze
using ImageTransformations
using ChainRules, ChainRulesCore

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")

end # module
