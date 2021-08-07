"""
    channelify(m::AbstractArray{CT,N}) where {CT <: Colorant, N}
Channelify function.

Input should be in ``WHN`` order ``\\implies (*, batch)``.
Output will be in the order ``(*, channels, batch)``.

# Examples
```jldoctest; setup = :(using ImageCore, DiffImages)
julia> input_size = (16, 16, 2)
(16, 16, 2)

julia> size(channelify(HSV.(rand(BGR,input_size...))))
(16, 16, 3, 2)
```
"""
function channelify(m::AbstractArray{CT,N}) where {CT <: Colorant, N}
    e = eltype(m)
    m = channelview(m)
    if e <: AbstractGray
        m = reshape(m, 1, size(m)...)
    end
    t = ntuple(identity, ndims(m))
    m = permutedims(m, (t[2:end-1]...,1,t[end]))
    return m
end

@adjoint function channelview(x::AbstractArray{T,N}) where {T, N}
    e = eltype(x)
    y = channelview(x)
    function pullback(Δ)
        return (collect(colorview(e,Δ)),)
    end
    return (y, pullback)
end

@adjoint function colorview(T, x)
    y = colorview(T,x)
    function pullback(Δ)
        return (nothing, channelview(Δ))
    end
    return (y, pullback)
end

# adjoint for (::Colorant{T,N})(x::Real)
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
    @eval @adjoint function $f(x::Real...)
        y = $f(x::Real...)
        function pull(Δ...)
            return (Δ...,)
        end
        return (y, pull)
    end
end

# Constructor adjoint
# function ChainRules.rrule(::Type{HSL{T}}, x, y, z) where T <: AbstractFloat
#     β = HSL{T}(x, y, z)
#     function Lab_pullback(Δ)
#         @show Δ x y z β
#         return (ChainRules.NoTangent(),Δ.h,Δ.s,Δ.l)
#     end
#     return (β, Lab_pullback)
# end

"""
    colorify(color::Type{CT}, m::AbstractArray) where CT <: Colorant
Colorify function.

Expecting an input of the type ``(*, channels, batch)``.
Converts the array to the `color` specified.


# Examples
```jldoctest; setup = :(using ImageCore, DiffImages)
julia> input_size = (25, 25, 3, 7)
(25, 25, 3, 7)

julia> size(colorify(HSV, rand(input_size...)))
(25, 25, 7)
```
"""
function colorify(color::Type{CT}, m::AbstractArray) where CT <: Colorant
    t = ntuple(identity, ndims(m))
    m = permutedims(m, (t[end-1],t[1:end-2]...,t[end]))
    if color <: AbstractGray
        m = dropdims(m; dims=1)
    end
    m = colorview(color, m)
    return m
end
# TODO: adjoints for `colorview(T, gray1, gray2...)` are not added yet.
