using Flux, Zygote, Images
using Flux:@functor

# struct affine
#     W
#     b
#     function affine(x::Matrix{T}) where T
#         new(x,rand(size(x)[1]))
#     end
#     function affine(x,y)
#         new(x,y)
#     end
# end

# (m::affine)(x)=m.W*x.+m.b
img = rand(RGB,16,16,1,3)

# function Gray(m::AbstractArray{T}) where T<:Float64
#     m = gray.(m)
#     m = reshape(m, (size(m)[1:end-1]...,1,size(m)[end]))
#     return m
# end
function Gray(m::AbstractArray{T}) where T<:Colorant
    m = Gray.(m)
    m = reshape(m, (size(m)[1:end-1]...,1,size(m)[end]))
    return gray.(m)
end
function rgb(m::AbstractArray{T}) where T<:RGB
    m=channelview(m)
    m=permutedims(m,(2,3,1,4))
    return m
end

# @functor Gray
