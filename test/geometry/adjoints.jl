m = rand(3, 3)
axs = (1:3, 1:3)
ty = Interpolations.BSplineInterpolation{Float64, ndims(m), typeof(m), BSpline{Linear{Throw{OnGrid}}}, typeof(axs)}
etty = Interpolations.Extrapolation{Float64, 2, Interpolations.BSplineInterpolation{Float64, 2, Matrix{Float64}, BSpline{Linear{Throw{OnGrid}}}, Tuple{UnitRange{Int64}, UnitRange{Int64}}}, BSpline{Linear{Throw{OnGrid}}}, Flat{Nothing}}
fieldsum(x) = mapreduce(y->getfield(x, y), +, ntuple(identity, nfields(x)))

@testset "Interpolations.BSplineInterpolation constructor gradient" begin
    zg = Zygote.gradient((x,y,z)->sum(ty(x,y,z)), m, axs, BSpline(Linear()))
    fd = grad(central_fdm(5,1), 
              x->sum(ty(x, axs, BSpline(Linear()))), 
              m)
    @test isapprox(zg[1], fd[1])
    @test zg[2:3] == (nothing, nothing)
end

@testset "Interpolations.BSplineInterpolation functor gradient" begin
    zg = Zygote.gradient((x,y,z,w)->sum(Interpolations.BSplineInterpolation(x,y,z,w)), Float64, m, BSpline(Linear()), axs)
    fd = grad(central_fdm(5,1), 
              x->sum(Interpolations.BSplineInterpolation(Float64, x, BSpline(Linear()), axs)), 
              m)
    @test isapprox(zg[2], fd[1])
    @test findall(==(nothing), zg) == [1, 3, 4]
end

@testset "Interpolations.Extrapolation constructor gradient" begin
    itp = ty(m, axs, BSpline(Linear()))
    zg = Zygote.gradient((x,y)->sum(etty(x,y)), itp, Flat())
    fd = grad(central_fdm(5,1), 
              x->sum(etty(itp, Flat())), 
              m)
    @test isapprox(zg[1], fd[1])
    @test findall(==(nothing), zg) == [2]
end

@testset "Interpolations.copy_with_padding function gradient" begin
    zg = Zygote.gradient((x,y,z)->sum(Interpolations.copy_with_padding(x,y,z)), Float64, m, BSpline(Linear()))
    fd = grad(central_fdm(5,1), 
              x->sum(Interpolations.copy_with_padding(Float64, x, BSpline(Linear()))), 
              m)
    @test isapprox(zg[2], fd[1])
    @test findall(==(nothing), zg) == [1, 3]
end

@testset "Interpolations.FilledExtrapolation constructor gradient" begin
    @test_broken begin
        itp = ty(m, axs, BSpline(Linear()))
        zg = Zygote.gradient((x,y)->sum(Interpolations.FilledExtrapolation(x,y)), itp, 0.0)
        fd = grad(central_fdm(5,1), 
                x->sum(Interpolations.FilledExtrapolation(x, 0.0)), 
                itp)
        @test_broken isapprox(zg[1], fd[1])
        @test_broken findall(==(nothing), zg) == [2]
    end # TODO: Remove the @test_broken after tests work.
end

@testset "SVector{N, T} and SMatrix{N, N, T, L} gradient" begin
    for t in (Float32, Float64, RGB{Float32}, RGB{Float64})
        inp = rand(t, 2)
        inp_mat = rand(t, 3, 3)
        _sep(x) = x.r + x.g + x.b
        if t ∈ (Float32, Float64)
            @test Zygote.gradient(x->sum(SVector{2, t}(x)), inp)[1] == ones(t, 2)
            @test Zygote.gradient(x->sum(SMatrix{3, 3, t, 9}(x)), inp_mat)[1] == ones(t, 3, 3)
        else
            @test Zygote.gradient(x->_sep(sum(SVector{2, t}(x))), inp)[1] == ones(t, 2)
            @test Zygote.gradient(x->_sep(sum(SMatrix{3, 3, t, 9}(x))), inp_mat)[1] == ones(t, 3, 3)
        end
    end
end

@testset "DiffImages.Homography method gradient" begin
    h = DiffImages.Homography{Float64}()
    v = rand(SVector{2, Float64})
    zy = Zygote.gradient((x,y)->sum(y(x)), v, h)
    fd = grad(central_fdm(5,1), (x,y)->sum(y(x)), v, h)

    @test zy[2].H ≈ fd[2].H
    @test typeof(zy[2].H) == typeof(fd[2].H)
end

@testset "CoordinateTransformations.LinearMap gradient" begin
    m = CoordinateTransformations.LinearMap(rand(3, 3))
    sm = CoordinateTransformations.LinearMap(rand(SMatrix{3, 3, Float64}))
    v = rand(3)
    sv = rand(SVector{3, Float64})
    zy = Zygote.gradient((x, y)->sum(x(y)), m, v)
    fd = grad(central_fdm(5,1), (x, y)->sum(x(y)), m, v)
    zy_s = Zygote.gradient((x, y)->sum(x(y)), sm, sv)
    fd_s = grad(central_fdm(5,1), (x, y)->sum(x(y)), sm, sv)

    @test zy[1].linear ≈ fd[1].linear
    @test zy[2] ≈ fd[2]
    @test typeof(zy[1].linear) == typeof(fd[1].linear)
    @test zy_s[1].linear ≈ fd_s[1].linear
    @test zy_s[2] ≈ fd_s[2]
    @test_broken typeof(zy_s[1].linear) == typeof(fd_s[1].linear) # TODO: fix in another issue.
end

@testset "Rotations.RotMatrix{N, T, L} gradient" begin
    rm = RotMatrix(π/4)
    v = rand(2)
    zy = Zygote.gradient((x, y)->sum(LinearMap(x)(y)), rm, v)
    fd = grad(central_fdm(5,1), (x, y)->sum(LinearMap(x)(y)), rm, v)
    @test zy[1] ≈ fd[1]
    @test zy[2] ≈ fd[2]
end

@testset "ImageTransformations._getindex gradient" begin
    _sep(x) = x.r + x.g + x.b
    for t in (Float32, Float64, RGB{Float32}, RGB{Float64})
        itp = extrapolate(interpolate(rand(t, 3, 3), BSpline(Linear())), zero(t))
        for ind in ((2.5, 2.5), (5, 5))
            if t <: Colorant
                zy = Zygote.gradient((x,y)->_sep(ImageTransformations._getindex(x,y)), itp, ind)
                @test zy[2] ≈ fieldsum.(Interpolations.gradient(itp, ind...))
            else
                zy = Zygote.gradient((x,y)->ImageTransformations._getindex(x,y), itp, ind)
                @test zy[2] ≈ Interpolations.gradient(itp, ind...)
            end
        end
    end
end
