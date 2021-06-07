module DiffImages

using Flux,
      Images,
      Zygote

using Flux:@functor, unsqueeze
using ImageTransformations

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")

end # module
