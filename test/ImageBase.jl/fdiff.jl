using ImageBase.FiniteDiff: fdiff, fdiff!
@testset "fdiff" begin
  # Base.diff doesn't promote integer to float
  @test ImageBase.FiniteDiff.maybe_floattype(Int) == Int
  @test ImageBase.FiniteDiff.maybe_floattype(N0f8) == Float32
  @test ImageBase.FiniteDiff.maybe_floattype(RGB{N0f8}) == RGB{Float32}
  @testset "NumericalTests" begin
    a = reshape(collect(1:9), 3, 3)
    b_fd_1 = [1 1 1; 1 1 1; -2 -2 -2]
    b_fd_2 = [3 3 -6; 3 3 -6; 3 3 -6]
    b_bd_1 = [-2 -2 -2; 1 1 1; 1 1 1]
    b_bd_2 = [-6 3 3; -6 3 3; -6 3 3]
    out = similar(a)

    @test fdiff(a, dims=1) == b_fd_1
    @test fdiff(a, dims=2) == b_fd_2
    @test fdiff(a, dims=1, rev=true) == b_bd_1
    @test fdiff(a, dims=2, rev=true) == b_bd_2
    fdiff!(out, a, dims=1)
    @test out == b_fd_1
    fdiff!(out, a, dims=2)
    @test out == b_fd_2
    fdiff!(out, a, dims=1, rev=true)
    @test out == b_bd_1
    fdiff!(out, a, dims=2, rev=true)
    @test out == b_bd_2
  end
  @testset "Differentiability" begin
    a_fd_1 = [2 4 8; 3 9 27; 4 16 64]
    a_fd_2 = [3 6 9; 6 18 27; 9 27 54; 12 36 81]
    @testset "Testing basic fdiff" begin
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=1))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=2))[1] == ones(Float64,size(a_fd_2))
    end
    @testset "Testing fdiff with rev" begin
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1,rev=true))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=2,rev=true))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=1,rev=true))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=2,rev=true))[1] == ones(Float64,size(a_fd_2))
    end
    @testset "Testing fdiff with boundary condition" begin
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1,boundary=:periodic))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=2,boundary=:periodic))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1,boundary=:zero))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=2,boundary=:zero))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1,rev=true,boundary=:periodic))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=2,rev=true,boundary=:periodic))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=1,rev=true,boundary=:zero))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_1,dims=2,rev=true,boundary=:zero))[1] == ones(Float64,size(a_fd_1))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=1,boundary=:periodic))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=2,boundary=:periodic))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=1,boundary=:zero))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=2,boundary=:zero))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=1,rev=true,boundary=:periodic))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=2,rev=true,boundary=:periodic))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=1,rev=true,boundary=:zero))[1] == ones(Float64,size(a_fd_2))
      @test Zygote.gradient(x -> sum(x),fdiff(a_fd_2,dims=2,rev=true,boundary=:zero))[1] == ones(Float64,size(a_fd_2))
    end
  end
end