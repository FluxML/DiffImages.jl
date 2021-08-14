using Test,
      Zygote,
      Flux,
      DiffImages,
      ImageCore,
      ImageTransformations,
      Interpolations,
      StaticArrays,
      FiniteDifferences,
      ChainRulesCore,
      CoordinateTransformations

@testset "DiffImages" begin
    @info "Testing Colorspace modules"
    @testset "Colorspace" begin
        include("colors/conversions.jl")
    end

    @info "Testing Geometry modules"
    @testset "Adjoints" begin
        include("geometry/adjoints.jl")
    end
    @testset "Warps" begin
        include("geometry/warp.jl")
    end
end
