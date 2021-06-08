@testset "Colorspace transforms tests" begin
    f = Chain(x->HSV.(x),channelify,flatten,Dense(768,16),Dense(16,10),x->σ.(x))
    g_3 = Chain(Conv((3,3),7=>4,relu),
              Conv((3,3),4=>3,relu),
              x->colorify(RGB,x),
              x->HSV.(x),
              channelify,
              flatten,
              Dense(256*3,16),
              Dense(16,10),
              x->σ.(x))
    g_1 = Chain(Conv((3,3),7=>4,relu),
              Conv((3,3),4=>3,relu),
              x->colorify(RGB,x),
              x->Gray.(x),
              channelify,
              flatten,
              Dense(256*1,16),
              Dense(16,10),
              x->σ.(x))

    @testset "Testing channelify" begin
        @test size(f(rand(RGB,16,16,3))) == (10,3)
        @test size(f(rand(Gray,16,16,3))) == (10,3)
    end
    @testset "Testing colorify" begin
        @test size(g_3(rand(20,20,7,3))) == (10,3)
        @test size(g_1(rand(20,20,7,3))) == (10,3)
    end
end
