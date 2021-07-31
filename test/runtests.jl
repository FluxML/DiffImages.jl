using Test,
      Zygote,
      Flux,
      DiffImages,
      Images,
      ImageTransformations,
      Interpolations,
      StaticArrays,
      FiniteDifferences

@testset "DiffImages" begin
    @info "Testing Colorspace modules"
    @testset "Colorspace" begin
        include("colors/conversions.jl")
    end

    @info "Testing Geometry modules"
    @testset "Adjoints" begin
        include("geometry/adjoints.jl")
    end
end
