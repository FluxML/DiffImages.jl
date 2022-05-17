@testset "Statistics" begin
  a_fd_1 = [2 4 8; 3 9 27; 4 16 64]
  a_fd_2 = [3 6 9; 6 18 27; 9 27 54; 12 36 81]
  a_fd_3 = rand(10, 10)
  a_fd_4 = randn(6, 4)
  b_fd_1 = zeros(Float64, size(a_fd_1))
  b_fd_2 = zeros(Float64, size(a_fd_2))
  b_fd_3 = zeros(Float64, size(a_fd_3))
  b_fd_4 = zeros(Float64, size(a_fd_4))
  e_fd_1 = zeros(Float64, size(a_fd_1))
  e_fd_2 = zeros(Float64, size(a_fd_2))
  e_fd_3 = zeros(Float64, size(a_fd_3))
  e_fd_4 = zeros(Float64, size(a_fd_4))
  c_fd_1 = minimum_finite(a_fd_1)
  c_fd_2 = minimum_finite(a_fd_2)
  c_fd_3 = minimum_finite(a_fd_3)
  c_fd_4 = minimum_finite(a_fd_4)
  d_fd_1 = maximum_finite(a_fd_1)
  d_fd_2 = maximum_finite(a_fd_2)
  d_fd_3 = maximum_finite(a_fd_3)
  d_fd_4 = maximum_finite(a_fd_4)
  @testset "NumericalTests" begin
    @testset "Testing sumfinite" begin
      @test sumfinite(a_fd_1) == sum(a_fd_1)
      @test sumfinite(a_fd_2) == sum(a_fd_2)
      @test sumfinite(a_fd_3) == sum(a_fd_3)
      @test sumfinite(a_fd_4) == sum(a_fd_4)
      @test sumfinite(a_fd_1) == 137
      @test sumfinite(a_fd_2) == 288
    end
    @testset "Testing meanfinite" begin
      @test meanfinite(a_fd_1) ≈ mean(a_fd_1)
      @test meanfinite(a_fd_2) ≈ mean(a_fd_2)
      @test meanfinite(a_fd_3) ≈ mean(a_fd_3)
      @test meanfinite(a_fd_4) ≈ mean(a_fd_4)
      @test meanfinite(a_fd_1) ≈ 15.222222222222221
      @test meanfinite(a_fd_2) ≈ 24.0
    end
    @testset "Testing minimum_finite" begin
      @test minimum_finite(a_fd_1) == minimum(a_fd_1)
      @test minimum_finite(a_fd_2) == minimum(a_fd_2)
      @test minimum_finite(a_fd_3) == minimum(a_fd_3)
      @test minimum_finite(a_fd_4) == minimum(a_fd_4)
      @test minimum_finite(a_fd_1) == 2
      @test minimum_finite(a_fd_2) == 3
    end
    @testset "Testing maximum_finite" begin
      @test maximum_finite(a_fd_1) == maximum(a_fd_1)
      @test maximum_finite(a_fd_2) == maximum(a_fd_2)
      @test maximum_finite(a_fd_3) == maximum(a_fd_3)
      @test maximum_finite(a_fd_4) == maximum(a_fd_4)
      @test maximum_finite(a_fd_1) == 64
      @test maximum_finite(a_fd_2) == 81
    end
  end
  @testset "Testing Differentiability" begin
    @testset "Testing sumfinite" begin
      @test Zygote.gradient(sumfinite, a_fd_1)[1] == ones(Float64, size(a_fd_1))
      @test Zygote.gradient(sumfinite, a_fd_2)[1] == ones(Float64, size(a_fd_2))
      @test Zygote.gradient(sumfinite, a_fd_3)[1] == ones(Float64, size(a_fd_3))
      @test Zygote.gradient(sumfinite, a_fd_4)[1] == ones(Float64, size(a_fd_4))
    end
    @testset "Testing meanfinite" begin
      @test Zygote.gradient(meanfinite, a_fd_1)[1] == fill((1 / length(a_fd_1)), size(a_fd_1))
      @test Zygote.gradient(meanfinite, a_fd_2)[1] == fill((1 / length(a_fd_2)), size(a_fd_2))
      @test Zygote.gradient(meanfinite, a_fd_3)[1] == fill(1 / length(a_fd_3), size(a_fd_3))
      @test Zygote.gradient(meanfinite, a_fd_4)[1] == fill(1 / length(a_fd_4), size(a_fd_4))
    end
    @testset "Testing minimum_finite" begin
      b_fd_1[first(findall(x -> x == c_fd_1, a_fd_1))] = 1
      b_fd_2[first(findall(x -> x == c_fd_2, a_fd_2))] = 1
      b_fd_3[first(findall(x -> x == c_fd_3, a_fd_3))] = 1
      b_fd_4[first(findall(x -> x == c_fd_4, a_fd_4))] = 1
      @test Zygote.gradient(minimum_finite, a_fd_1)[1] == b_fd_1
      @test Zygote.gradient(minimum_finite, a_fd_2)[1] == b_fd_2
      @test Zygote.gradient(minimum_finite, a_fd_3)[1] == b_fd_3
      @test Zygote.gradient(minimum_finite, a_fd_4)[1] == b_fd_4
    end
    @testset "Testing maximum_finite" begin
      e_fd_1[last(findall(x -> x == d_fd_1, a_fd_1))] = 1
      e_fd_2[last(findall(x -> x == d_fd_2, a_fd_2))] = 1
      e_fd_3[last(findall(x -> x == d_fd_3, a_fd_3))] = 1
      e_fd_4[last(findall(x -> x == d_fd_4, a_fd_4))] = 1
      @test Zygote.gradient(maximum_finite, a_fd_1)[1] == e_fd_1
      @test Zygote.gradient(maximum_finite, a_fd_2)[1] == e_fd_2
      @test Zygote.gradient(maximum_finite, a_fd_3)[1] == e_fd_3
      @test Zygote.gradient(maximum_finite, a_fd_4)[1] == e_fd_4
    end
  end
end