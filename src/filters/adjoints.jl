using ImageFiltering
using ImageFiltering.TiledIteration
using ImageFiltering: imfilter, 
                      imfilter!, 
                      default_resource, 
                      alg_defaults, 
                      Alg,
                      ProcessedKernel,
                      AbstractBorder,
                      __imfilter_inbounds!,
                      safe_for_prod,
                      copydata!,
                      factorkernel,
                      factorstridedkernel,
                      padarray,
                      filter_algorithm

function ChainRulesCore.rrule(::typeof(imfilter!), out::AbstractArray, 
                                                   img::AbstractArray, 
                                                   kernel::ProcessedKernel, 
                                                   border::AbstractBorder, 
                                                   alg::Alg)
    # imfilter! places a snag because of a try catch block.
    y = imfilter!(out, img, kernel, border, alg)
    function ∇imfilter!_try(Δy)
        k = default_resource(alg_defaults(alg, out, kernel))
        ret = imfilter!(k, out, img, kernel, border)
        _, ∇ret = rrule_via_ad(Zygote.ZygoteRuleConfig(), imfilter!, k, out, img, kernel, border)
        ∇k, ∇out, ∇img, ∇kernel, ∇border = ∇ret(Δy)
        return NoTangent(), ∇out, ∇img, ∇kernel, ∇border, ∇k
    end
    return y, ∇imfilter!_try
end # needed and works

## writing adjoints for `__imfilter_inbounds!` -> where the mutation takes place
function ChainRulesCore.rrule(::typeof(__imfilter_inbounds!), r, 
                                                              out, 
                                                              A::OffsetArray, 
                                                              kern::OffsetArray, 
                                                              border, 
                                                              R, 
                                                              z)
    y = __imfilter_inbounds!(r, out, A, kern, border, R, z)
    function ∇__imfilter_inbounds!(Δy)
        # ∇out should not have any gradients 
        # since it is just being alloted the values
        # after processing. ∇border also should not have 
        # gradients since it does not make sense (for now).
        ∇out = NoTangent()
        ∇border = NoTangent()

        # Don't exactly know what r, R and z are actually.

        off, k = CartesianIndex(kern.offsets), parent(kern)
        o, O = safehead(off), safetail(off)
        Rnew = CartesianIndices(map((x,y)->x.+y, R.indices, Tuple(off)))
        Rk = CartesianIndices(axes(k))
        offA, pA = CartesianIndex(A.offsets), parent(A)
        oA, OA = safehead(offA), safetail(offA)
        # ∇A, ∇kern should have some values.
        ∇A = 0
        ∇kern = 0 # since k is not an OffsetArray

        for I in safetail(Rnew)
            IA = I-OA
            for i in safehead(Rnew)
                tmp = z
                iA = i-oA
                dk = zeros(eltype(k), size(k))
                dA = zeros(eltype(pA), size(pA))
                @inbounds for J in safetail(Rk), j in safehead(Rk)
                    _, ∇prod = rrule_via_ad(Zygote.ZygoteRuleConfig(), (a, b, c) -> safe_for_prod(a, b) * c, 
                                                                    pA[iA+j, IA+J], 
                                                                    tmp, 
                                                                    k[j, J])
                    dA_j_J, _, dk_j_J = ∇prod(Δy[iA+j, IA+J])
                    dA[iA+j, IA+J] += dA_j_J
                    dk[j+J] += dk_j_J
                end
                ∇A += dA
                ∇kern += dk
            end
        end
        ∇z = NoTangent()
        ∇R = NoTangent()
        ∇r = NoTangent()

        return NoTangent(), ∇r, ∇out, ∇A, ∇kern, ∇border, ∇R, ∇z
    end
    return y, ∇__imfilter_inbounds!
end

Zygote.@nograd TiledIteration.TileBuffer # needed, works
# Zygote.@nograd ImageFiltering.padindices # not needed
Zygote.@nograd ImageFiltering.filter_algorithm # ~~should be correct~~ is correct
Zygote.@nograd ImageFiltering.Pad{N} where N

# what should the gradient of copyto! be? It is being used in various places throughout the filters

function ChainRulesCore.rrule(::typeof(padarray), t::Type{T}, img::AbstractArray, border) where T
    y = padarray(t, img, border)
    function padarray_pb(Δy)
        ba, ba_pb = rrule_via_ad(Zygote.ZygoteRuleConfig(), BorderArray, img, border)
        out = similar(ba, T, axes(ba))
        copy!(out, ba)
        ∇img, ∇border = ba_pb(Δy)
        return NoTangent(), NoTangent(), ∇img, ∇border
    end
    return y, padarray_pb
end

function ChainRulesCore.rrule(::typeof(factorkernel), kernel::AbstractMatrix{T}) where T
    y = factorkernel(kernel)
    function factorkernel_pb(Δy)
        ##
        inds = axes(kernel)
        m, n = map(length, inds)
        kern = Array{T}(undef, m, n)
        copyto!(kern, 1:m, 1:n, kernel, inds[1], inds[2])
        ##
        _, kernel_pb = rrule_via_ad(Zygote.ZygoteRuleConfig(), factorstridedkernel, inds, kern)

        return NoTangent(), kernel_pb(Δy)
    end
    return y, factorkernel_pb
end

# function ChainRulesCore.rrule(::typeof(copydata!), dest::OffsetArray, img, inds::Tuple{Vararg{OffsetArray}})
#     y = copydata!(dest, img, inds)
#     function copydata!_pb(Δy)
#         @show typeof(Δy)
#         println("copydata! here")
#         # dest = parent(dest)
#         # inds = map(parent, inds)
#         # if isempty(img)
#         #     ∇img = canonicalize(Tangent{typeof(img)}())
#         # else
#         #     ∇img = Tangent{typeof(img)}(;ones(eltype(img), size(img)))
#         # end
#         return NoTangent(), NoTangent(), Δy, NoTangent()
#     end
#     return y, copydata!_pb
# end

## ~~make copyto! gradients correct~~ final task

## it is still not getting inside the final mutation loop adjoint, figure that out asap.
