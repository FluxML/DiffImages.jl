# Tests for different adjoints written here.
L(x) = sum(x)
function warp_me2(img::AbstractArray{T}, tform) where T
   img = ImageTransformations.box_extrapolation(img, Flat())
   inds = DiffImages.custom_autorange(img, inv(tform))
   inds = map(x->SVector{length(x),Float64}(x.I),CartesianIndices(inds))
   img = map(x -> ImageTransformations._getindex(img, tform(x)), inds)
   return
end

@testset "Testing ∂g/∂(i,j)" begin
   """
   g is the Interpolation scheme.
   (i,j) are the indices where we are calculating the interpolation/interpolation gradient.
   """
   m = rand(Float64, 6, 6)
   g = interpolate(m, BSpline(Linear()))
   ∂g(itp,i,j) = begin
       ∂1 = g(i+1,j) - g(i,j)
       ∂2 = g(i,j+1) - g(i,j)
       return SVector((∂1,∂2))
   end
   @test ∂g(g, 4, 4) == Interpolations.gradient(g, 4, 4)
   @test size(Interpolations.gradient(g, 4, 4)) == (2,)
end

@testset "Testing ∂L/∂g" begin
   """
   Testing the ∂L/∂g derivatives, where:
      L = Loss/Objective
      g = Interpolation scheme
   TODO: Test with a variety of losses(?)
   """
   m = rand(Float64, 6, 6)
   g = interpolate(m, BSpline(Linear()))
   @test gradient(L, g)[1] == ones(size(m)...)
end

@testset "Testing ∂L/∂W" begin
   """
   Testing ∂L/∂W instead of testing ∂(i,j)/∂W or ∂g/∂W, where:
      W = transform (here homography)
   """
   h = homography(rand(SMatrix{3,3,Float64,9}))
   img_plain = rand(Float64, 10, 10)
   img_src = rand(RGB, 10, 10)
   @testset "FloatTypes testing" begin
      outp = Zygote.gradient(img_plain, h) do img, tform
                   c = L(warp_me2(img, tform))
                   c
                 end[2].H
      @test size(outp) == (3,3)
      @test eltype(outp) == eltype(h.H)
   end
   @testset "Colorant Types testing" begin
      outp = Zygote.gradient(img_plain, h) do img, tform
                   c = L(warp_me2(img, tform))
                   c
                 end[2].H
      @test size(outp) == (3,3)
      @test eltype(outp) == eltype(h.H)
   end
end
