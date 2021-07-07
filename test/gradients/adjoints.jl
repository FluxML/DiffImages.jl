# Tests for different adjoints written here.

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
   L(x) = sum(x)
   m = rand(Float64, 6, 6)
   g = interpolate(m, BSpline(Linear()))
   @test gradient(L, g)[1] == ones(size(m)...)
end
