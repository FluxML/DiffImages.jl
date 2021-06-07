"""
    channelify(m::AbstractArray{<:Color})
Channelify function.

Input should be in ``WHCN`` order ``\\implies (*, batch)``.
Output will be in the order ``(*, channels, batch)``.
"""
function channelify(m::AbstractArray{T}) where T <: Color
    m = channelview(m)
    t = collect(1:ndims(m))
    if T <: AbstractGray
        m = unsqueeze(m, t[end-1])
    end
    m = permutedims(m, (t[2:end-1]...,1,t[end]))
    return m
end

"""
    colorify(color::Type{<:Color}, m::AbstractArray)
Colorify function.

Expecting an input of the type ``(*, channels, batch)``.
Converts the array to the `color` specified.

# Examples
```jldoctest; setup = :(using Images)
julia> img = rand(25,25,3,7)

julia> colorify(HSV, img)

julia> channelify(colorify(RGB,img))==img
true
```
"""
function colorify(color::Type{<:Color}, m::AbstractArray)
    t = collect(1:ndims(m))
    m = permutedims(m, (t[end-1],t[1:end-2]...,t[end]))
    if color <: AbstractGray
        m = dropdims(m; dims=1)
    end
    m = colorview(color, m)
    return m
end
