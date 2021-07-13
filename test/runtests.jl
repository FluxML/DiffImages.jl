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
    @info "Testing adjoints"
    @testset "Gradients" begin
          include("gradients/adjoints.jl")
    end
end
