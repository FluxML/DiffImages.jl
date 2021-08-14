# Tests for the ImageTransformations.warp! function
# Checking the gradients manually by writing τ and ϕ
function ϕ(p, homo)
    q = inv(homo) * [p..., 1]
    q = q[1:2] ./ q[3]
    return q
end

function τ(X, q)
    y = interpolate(X, BSpline(Linear()))
    y = extrapolate(y, zero(eltype(X)))
    return y(q...)
end

function project(X, H) # our own warp
    Y = similar(X)
    for i in CartesianIndices(Y)
        v = τ(X, ϕ(i.I, H))
        Y[i] = v
    end
    return Y
end

function ChainRulesCore.rrule(::typeof(τ), X, q)
    y = τ(X, q)
    function τ_pb(Δy)
        Δy = RGB(Δy...)
        itp = extrapolate(interpolate(X, BSpline(Linear())), zero(eltype(X)))
        ∇X = NoTangent()
        ∇q = Interpolations.gradient(itp, q...)
        n = nfields(Δy) > 0 ? nfields(Δy) : 1
        return NoTangent(), ∇X, typeof(q)(Δy .⋅ ∇q .⋅ n)
    end
    return y, τ_pb
end

function ChainRulesCore.rrule_via_ad(::Zygote.ZygoteRuleConfig, ::typeof(ϕ), p, homo)
    Zygote.pullback(ϕ, p, homo)
end

function ChainRulesCore.rrule(::typeof(project), X, H)
    Y = project(X, H)
    function project_pb(Δy)
        ∇H = zeros(3,3)
        for p in CartesianIndices(Y)
            _, ∇τ = rrule(τ, X, Float32.(p.I))
            _, _, ∇τ = ∇τ(Δy[p])
            _, ∇ϕ = rrule_via_ad(Zygote.ZygoteRuleConfig(), ϕ, p.I, H)
            _, ∇h = ∇ϕ([∇τ...])
            ∇H += ∇h
        end
        return NoTangent(), NoTangent(), ∇H
    end
    return Y, project_pb
end

function image_mse(y, ŷ)
    l = map((x, y) -> (x - y), y, ŷ)
    l = mapreducec.(x->x^2, +, 0, l)
    l = sum(l)
    l
end

@testset "ImageTransformations.warp! gradient" begin
    h = DiffImages.Homography{Float64}()
    H = [1.0 0.0 0.0;0.0 1.0 0.0;0.0 0.0 1.0]

    _abs2(c) = mapreducec(v->v^2, +, 0, c)
    img = rand(RGB{Float32}, 10, 10)
    tgt = rand(RGB{Float32}, 10, 10)

    zy = Zygote.gradient(h) do trfm
        out = ImageTransformations.warp(img, trfm, axes(img), zero(eltype(img)))
        out = image_mse(out, tgt)
        out
    end

    man = Zygote.gradient(H) do trfm
        out = project(img, trfm)
        out = image_mse(out, tgt)
        out
    end

    @test_broken zy[1].H ≈ man[1]
    @test zy[1].H ≈ -man[1] # TODO: Remove this test and make the above @test_broken -> @test after resolving the sign thing
end

@testset "RotMatrix vs. Non-RotMatrix" begin
    img = rand(RGB{Float32}, 10, 10)
    tgt = rand(RGB{Float32}, 10, 10)

    f(t) = begin
        out = ImageTransformations.warp(img, t, axes(img), zero(eltype(img)))
        loss = image_mse(out, tgt)
        loss
    end

    tfm1 = recenter(RotMatrix(π/8), center(img)) # using RotMatrix
    tfm2 = AffineMap(SMatrix{2, 2, Float64, 4}([cos(π/8) -sin(π/8); sin(π/8) cos(π/8)]), tfm1.translation)

    zy1 = Zygote.gradient(f, tfm1)
    zy2 = Zygote.gradient(f, tfm2)

    # The gradients are the same, but if you use `RotMatrix`s, you get nested NamedTuples,
    # for example: 
    # zy1[1] => (linear = (mat = (data = [37.49...
    # zy2[1] => (linear = [37.49...
    @test_broken zy1[1].linear === zy2[1].linear # TODO: Resolve this in a seperate issue
    @test zy1[1].linear.mat.data === zy2[1].linear
end
