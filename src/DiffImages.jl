module DiffImages

using Flux,
      Images,
      Zygote,
      CUDA

using Flux:@functor
include("conversions.jl")

end # module
