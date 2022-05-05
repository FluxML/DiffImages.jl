module DiffImages
using ImageCore,
      Zygote,
      ImageTransformations,
      StaticArrays,
      CoordinateTransformations,
      Interpolations,
      ChainRulesCore,
      LinearAlgebra,  
      Rotations

using Zygote: @adjoint
using ChainRulesCore: NoTangent

export colorify, channelify
include("colors/conversions.jl")
include("geometry/warp.jl")
include("geometry/adjoints.jl")

end
