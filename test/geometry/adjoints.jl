m = rand(3, 3)
axs = (1:3, 1:3)
ty = Interpolations.BSplineInterpolation{Float64, ndims(m), typeof(m), BSpline{Linear{Throw{OnGrid}}}, typeof(axs)}
etty = Interpolations.Extrapolation{Float64, 2, Interpolations.BSplineInterpolation{Float64, 2, Matrix{Float64}, BSpline{Linear{Throw{OnGrid}}}, Tuple{UnitRange{Int64}, UnitRange{Int64}}}, BSpline{Linear{Throw{OnGrid}}}, Flat{Nothing}}

@testset "Interpolations.BSplineInterpolation constructor gradient" begin
    zg = Zygote.gradient((x,y,z)->ty(x,y,z) |> sum, m, axs, BSpline(Linear()))
    fd = grad(central_fdm(5,1), 
              x->ty(x, axs, BSpline(Linear())) |> sum, 
              m)
    @test isapprox(zg[1], fd[1])
    @test zg[2:3] == (nothing, nothing)
end

@testset "Interpolations.BSplineInterpolation functor gradient" begin
    zg = Zygote.gradient((x,y,z,w)->Interpolations.BSplineInterpolation(x,y,z,w) |> sum, Float64, m, BSpline(Linear()), axs)
    fd = grad(central_fdm(5,1), 
              x->Interpolations.BSplineInterpolation(Float64, x, BSpline(Linear()), axs) |> sum, 
              m)
    @test isapprox(zg[2], fd[1])
    @test findall(==(nothing), zg) == [1, 3, 4]
end

@testset "Interpolations.Extrapolation constructor gradient" begin
    itp = ty(m, axs, BSpline(Linear()))
    zg = Zygote.gradient((x,y)->etty(x,y) |> sum, itp, Flat())
    fd = grad(central_fdm(5,1), 
              x->etty(itp, Flat()) |> sum, 
              m)
    @test isapprox(zg[1], fd[1])
    @test findall(==(nothing), zg) == [2]
end

@testset "Interpolations.copy_with_padding function gradient" begin
    zg = Zygote.gradient((x,y,z)->Interpolations.copy_with_padding(x,y,z) |> sum, Float64, m, BSpline(Linear()))
    fd = grad(central_fdm(5,1), 
              x->Interpolations.copy_with_padding(Float64, x, BSpline(Linear())) |> sum, 
              m)
    @test isapprox(zg[2], fd[1])
    @test findall(==(nothing), zg) == [1, 3]
end

@testset "Interpolations.FilledExtrapolation constructor gradient" begin
    itp = ty(m, axs, BSpline(Linear()))
    zg = Zygote.gradient((x,y)->Interpolations.FilledExtrapolation(x,y) |> sum, itp, 0.0)
    fd = grad(central_fdm(5,1), 
              x->Interpolations.FilledExtrapolation(x, 0.0) |> sum, 
              itp)
    @test isapprox(zg[1], fd[1])
    @test findall(==(nothing), zg) == [2]
end
