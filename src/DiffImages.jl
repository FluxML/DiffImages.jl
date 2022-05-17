module DiffImages
using ImageCore,
      Zygote,
      ImageTransformations,
      StaticArrays,
      CoordinateTransformations,
      Interpolations,
      ChainRulesCore,
      LinearAlgebra, 
      Rotations,
      ImageBase

using Zygote: @adjoint
using ChainRulesCore: NoTangent

export colorify, channelify, fdiff
include("colors/conversions.jl")
include("geometry/warp.jl")
include("geometry/adjoints.jl")
include("ImageBase.jl/fdiff.jl")
include("ImageBase.jl/statistics.jl")

end
