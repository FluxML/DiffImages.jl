"""
    channelify(m::AbstractArray{<:Color})
Channelify function.

Input should be in ``WHN`` order ``\\implies (*, batch)``.
Output will be in the order ``(*, channels, batch)``.

"""
function channelify(m::AbstractArray{T,N}) where {T <: Color, N}
    e = eltype(m)
    m = channelview(m)
    if e <: AbstractGray
        m = unsqueeze(m, 1)
    end
    t = ntuple(identity, ndims(m))
    m = permutedims(m, (t[2:end-1]...,1,t[end]))
    return m
end

#adjoint for channelview
@adjoint function channelview(x::AbstractArray{T,N}) where {T, N}
    e = eltype(x)
    y = channelview(x)
    function pullback(Δ)
        return (colorview(e,Δ),)
    end
    return (y, pullback)
end

# adjoint for colorview
@adjoint function colorview(T, x) where {T}
    y = colorview(T,x)
    function pullback(Δ)
        return (nothing, channelview(Δ))
    end
    return (y, pullback)
end

# adjoint for (::Colorant{T,N})(x)
for f in (:HSV,:AHSV,:HSVA,
          :Gray,:AGray,:GrayA,
          :HSL,:AHSL,:HSLA,
          :RGB,:ARGB,:RGBA,
          :BGR,:ABGR,:BGRA,
          :XYZ,:AXYZ,:XYZA,
          :xyY,:AxyY,:xyYA,
          :Lab,:ALab,:LabA,
          :Luv,:ALuv,:LuvA,
          :LCHab,:ALCHab,:LCHabA,
          :LCHuv,:ALCHuv,:LCHuvA,
          :DIN99,:ADIN99,:DIN99A,
          :LMS,:ALMS,:LMSA,
          :YIQ,:AYIQ,:YIQA)
    @eval @adjoint function $f(x...)
        y = $f(x...)
        function pullback(Δ)
            return (Δ,)
        end
        return (y, pullback)
    end
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
    t = ntuple(identity, ndims(m))
    @show t size(m) (t[end-1],t[1:end-2]...,t[end])
    m = permutedims(m, (t[end-1],t[1:end-2]...,t[end]))
    if color <: AbstractGray
        m = dropdims(m; dims=1)
    end
    m = colorview(color, m)
    return m
end
