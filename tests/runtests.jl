using Test,
      Zygote,
      Flux,
      DiffImages,
      Images,
      ImageTransformations

@testset "DiffImages" begin
    @info "Testing Colorspace modules"
    @testset "Colorspace" begin
        include("colors/conversions.jl")
    end
end

