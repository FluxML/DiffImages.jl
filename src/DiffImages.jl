module DiffImages

using Flux,
      Images,
      Zygote,
      CUDA

using Flux:@functor, unsqueeze

export colorify!
include("conversions.jl")

end # module
