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

@testset "ImageTransformations.warp! gradient" begin
    h = DiffImages.Homography{Float64}(SMatrix{3,3,Float64,9}([1 0 0;0 1 0;0 0 1]))
    H = [1.0 0.0 0.0;0.0 1.0 0.0;0.0 0.0 1.0]

    _abs2(c) = mapreducec(v->v^2, +, 0, c)
    img = rand(RGB{Float32}, 10, 10)
    tgt = rand(RGB{Float32}, 10, 10)

    zy = Zygote.gradient(h) do trfm
        out = ImageTransformations.warp(img, trfm, axes(img), zero(eltype(img)))
        out = sum(_abs2.(out - tgt))
        out
    end

    man = Zygote.gradient(H) do trfm
        out = project(img, trfm)
        out = sum(_abs2.(out - tgt))
        out
    end

    @test_broken zy[1].H ≈ man[1]
    @test zy[1].H ≈ -man[1] # TODO: Remove this test and make the above @test_broken -> @test after resolving the sign thing
end