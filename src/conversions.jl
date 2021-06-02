"""
    channelify!(m::AbstractArray{<:Color})
Channelify function.

Input should be in _WHCN_ order _(*, batch)_.
Output will be in the order _(*, 1, batch)_.
"""
function channelify!(m::AbstractArray{T}) where T<:Color
    m = channelview(m)
    t = collect(1:ndims(m))
    if T <: Gray
        unsqueeze(m, t[end-1])
    end
    m = permutedims(m, (t[2:end-1]...,1,t[end]))
    return m
end

"""
    colorify!(color::Type{<:Color}, m::AbstractArray{T}) where T
Colorify function.

Expecting an input of the type ``\textit{(*, channels, batch)}``.
Converts the array to the `color` specified.

# Examples
```jldoctest; setup = :(using Images)
julia> img = rand(25,25,3,7)

julia> channelify!(colorify!(RGB,img))==img
true
```
"""
function colorify!(color::Type{<:Color}, m::AbstractArray{T}) where T
    t = collect(1:ndims(m))
    m = permutedims(m, (t[end-1],t[1:end-2]...,t[end]))
    if color <: Gray
        m = dropdims(m; dims=1)
    end
    m = colorview(color, m)
    return m
end
