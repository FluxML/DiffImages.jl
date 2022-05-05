@testset "Colorspace transforms tests" begin
    # f = Chain(x->HSV.(x),channelify,flatten,Dense(768,16),Dense(16,10),x->σ.(x))
    # g_3 = Chain(Conv((3,3),7=>4,relu),
    #           Conv((3,3),4=>3,relu),
    #           x->colorify(RGB,x),
    #           x->HSV.(x),
    #           channelify,
    #           flatten,
    #           Dense(256*3,16),
    #           Dense(16,10),
    #           x->σ.(x))
    # g_1 = Chain(Conv((3,3),7=>4,relu),
    #           Conv((3,3),4=>3,relu),
    #           x->colorify(RGB,x),
    #           x->Gray.(x),
    #           channelify,
    #           flatten,
    #           Dense(256*1,16),
    #           Dense(16,10),
    #           x->σ.(x))
    ds = (7, 7, 5)
    ds4 = (7, 7, 4, 5)
    ds3 = (7, 7, 3, 5)
    ds2 = (7, 7, 2, 5)
    ds1 = (7, 7, 1, 5)
    
    cspaces_with_random = (YIQ,  
                           LCHab,  
                           Lab,  
                           BGRA, ABGR, BGR,  
                           RGBA, ARGB, RGB,  
                           HSL,  
                           AGray, GrayA, Gray,  
                           HSV) # colorspaces those have samplers defined for Base.Random

    cspaces_all = (HSV, AHSV, HSVA,
               Gray, AGray, GrayA,
               HSL, AHSL, HSLA,
               RGB, ARGB, RGBA,
               BGR, ABGR, BGRA,
               XYZ, AXYZ, XYZA,
               xyY, AxyY, xyYA,
               Lab, ALab, LabA,
               Luv, ALuv, LuvA,
               LCHab, ALCHab, LCHabA,
               LCHuv, ALCHuv, LCHuvA,
               DIN99, ADIN99, DIN99A,
               LMS, ALMS, LMSA,
               YIQ, AYIQ, YIQA) # tuple of all of Colorspaces and their transparent variants
    
    cspaces_4 = (BGRA, ABGR,
                 RGBA, ARGB,
                 AHSL, HSLA,
                 AHSV, HSVA,
                 AXYZ, XYZA,
                 AxyY, xyYA,
                 ALab, LabA,
                 ALuv, LuvA,
                 ALCHab, LCHabA,
                 ALCHuv, LCHuvA,
                 ADIN99, DIN99A,
                 ALMS, LMSA,
                 AYIQ, YIQA) # all 4 channel colorspaces

    i_2 = rand(BGR, 5, 3) # 2-dim input testing
    i_4 = rand(RGBA, 9, 9, 2) # 4-channel testing; RGBA chosen because Random sampler available
    @testset "Testing channelify" begin
        @test size(channelify(i_2)) == (5, 3, 3) # to check if 2-dim inputs are working. Currently no use of them.
        @test size(channelify(i_4)) == (9, 9, 4, 2) # to check if 4 channel outputs are correct.
        for cs in cspaces_with_random
            i = rand(cs, ds...)
            if cs ∈ (Gray,)
                @test size(channelify(i)) == (ds[1:end - 1]..., 1, ds[end])
            elseif cs ∈ (AGray, GrayA)
                @test size(channelify(i)) == (ds[1:end - 1]..., 2, ds[end])
            elseif cs ∈ (BGRA, ABGR, RGBA, ARGB)
                @test size(channelify(i)) == (ds[1:end - 1]..., 4, ds[end])
            else
                @test size(channelify(i)) == (ds[1:end - 1]..., 3, ds[end])
            end
        end
    end
    @testset "Testing colorify" begin
        for cs in cspaces_all
            if cs ∈ cspaces_4
                i = rand(ds4...)
                @test size(colorify(cs, i)) == (ds4[1:end - 2]..., ds4[end])
            elseif cs ∈ (AGray, GrayA)
                i = rand(ds2...)
                @test size(colorify(cs, i)) == (ds4[1:end - 2]..., ds4[end])
            elseif cs ∈ (Gray,)
                i = rand(ds1...)
                @test size(colorify(cs, i)) == (ds4[1:end - 2]..., ds4[end])
            else
                i = rand(ds3...)
                @test size(colorify(cs, i)) == (ds4[1:end - 2]..., ds4[end])
            end
        end
    end
    @testset "Testing reversibilty" begin
        for cs in cspaces_all
            if cs ∈ cspaces_4
                i = rand(ds4...)
                @test channelify(colorify(cs, i)) == i
            elseif cs ∈ (AGray, GrayA)
                i = rand(ds2...)
                @test channelify(colorify(cs, i)) == i
            elseif cs ∈ (Gray,)
                i = rand(ds1...)
                @test channelify(colorify(cs, i)) == i
            else
                i = rand(ds3...)
                @test channelify(colorify(cs, i)) == i
            end
        end
    end
    @testset "Testing Differentiability" begin
        # channelview
        @testset "Testing channelview" begin
            for cs in cspaces_with_random
                i = rand(cs, ds...)
                if cs ∈ (Gray,)
                    @test channelview(Zygote.gradient(x -> sum(channelview(x)), i)[1]) == ones(Float64, ds...)
                elseif cs ∈ (AGray, GrayA)
                    @test channelview(Zygote.gradient(x -> sum(channelview(x)), i)[1]) == ones(Float64, 2, ds...)
                elseif cs ∈ (BGRA, ABGR, RGBA, ARGB)
                    @test channelview(Zygote.gradient(x -> sum(channelview(x)), i)[1]) == ones(Float64, 4, ds...)
                else
                    @test channelview(Zygote.gradient(x -> sum(channelview(x)), i)[1]) == ones(Float64, 3, ds...)
                end
            end
        end
        # colorview
        # TODO: colorview(T, gray1, gray2...) tests will have to be written, after writing their adjoints.
        @testset "Testing colorview" begin
            for cs in cspaces_all
                if cs ∈ cspaces_4
                    i = rand(ds4[end - 1], ds4[1:end - 2]..., ds4[end])
                    @test Zygote.gradient(x->sum(channelview(colorview(cs,x))),i)[1]==ones(size(i))
                elseif cs ∈ (AGray, GrayA)
                    i = rand(ds2[end - 1], ds2[1:end - 2]..., ds2[end])
                    @test Zygote.gradient(x->sum(channelview(colorview(cs,x))),i)[1]==ones(size(i))
                elseif cs ∈ (Gray,)
                    i = rand(ds1[1:end - 2]..., ds1[end])
                    @test Zygote.gradient(x->sum(channelview(colorview(cs,x))),i)[1]==ones(size(i))
                else
                    i = rand(ds3[end - 1], ds3[1:end - 2]..., ds3[end])
                    @test Zygote.gradient(x->sum(channelview(colorview(cs,x))),i)[1]==ones(size(i))
                end
            end
        end
        # channelify
        @testset "Testing channelify" begin
            for cs in cspaces_with_random
                i = rand(cs, ds...)
                if cs ∈ (Gray,)
                    @test channelify(Zygote.gradient(x -> sum(channelify(x)), i)[1]) == ones(Float64, ds[1:end-1]..., 1, ds[end])
                elseif cs ∈ (AGray, GrayA)
                    @test channelify(Zygote.gradient(x -> sum(channelify(x)), i)[1]) == ones(Float64, ds[1:end-1]..., 2, ds[end])
                elseif cs ∈ (BGRA, ABGR, RGBA, ARGB)
                    @test channelify(Zygote.gradient(x -> sum(channelify(x)), i)[1]) == ones(Float64, ds[1:end-1]..., 4, ds[end])
                else
                    @test channelify(Zygote.gradient(x -> sum(channelify(x)), i)[1]) == ones(Float64, ds[1:end-1]..., 3, ds[end])
                end
            end
        end
        # colorify
        @testset "Testing colorify" begin
            for cs in cspaces_all
                if cs ∈ cspaces_4
                    i = rand(ds4...)
                    @test Zygote.gradient(x->sum(channelify(colorify(cs,x))),i)[1]==ones(size(i))
                elseif cs ∈ (AGray, GrayA)
                    i = rand(ds2...)
                    @test Zygote.gradient(x->sum(channelify(colorify(cs,x))),i)[1]==ones(size(i))
                elseif cs ∈ (Gray,)
                    i = rand(ds1...)
                    @test Zygote.gradient(x->sum(channelify(colorify(cs,x))),i)[1]==ones(size(i))
                else
                    i = rand(ds3...)
                    @test Zygote.gradient(x->sum(channelify(colorify(cs,x))),i)[1]==ones(size(i))
                end
            end
        end
    end
end
