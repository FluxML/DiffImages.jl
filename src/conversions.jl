"""
    Gray(<:AbstractArray{T}) where T<:Colorant
Stackable colorspace transform from a `Colorant` type to `Gray`.
Input should be in _WHCN_ order `(width, height, batch)`.
Output will be in the order `(width, height, 1, batch)`.
"""
function Gray(m::AbstractArray{T}) where T<:Colorant
    m = Gray.(m)
    m = reshape(m, (size(m)[1:end-1]...,1,size(m)[end]))
    return gray.(m)
end
