```@meta
CurrentModule = DiffImages
```

# DiffImages.jl

[![CI status](https://github.com/SomTambe/DiffImages.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/SomTambe/DiffImages.jl/actions/workflows/ci.yml)
[![Docs-Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://somtambe.github.io/DiffImages.jl/dev/)
[![codecov](https://codecov.io/gh/SomTambe/DiffImages.jl/branch/main/graph/badge.svg?token=T9WFI8C9Q9)](https://codecov.io/gh/SomTambe/DiffImages.jl)

DiffImages.jl is a Computer Vision library, which aims to make relavant parts of the [JuliaImages](https://github.com/JuliaImages) ecosystem differentiable. 

We have started with making parts of [Images.jl](https://github.com/JuliaImages/Images.jl) and [ImageTransformations.jl](https://github.com/JuliaImages/ImageTransformations.jl) differentiable.

Currently, we provide support to the following modules:
- Warping modules inside of ImageTransformations.jl.
    - which includes [`ImageTransformations.warp`](https://juliaimages.org/ImageTransformations.jl/stable/reference/#ImageTransformations.warp), with support for transformations from [CoordinateTransformations.jl](https://github.com/JuliaGeometry/CoordinateTransformations.jl).
- Colorspace modules from [ImageCore.jl](https://github.com/JuliaImages/ImageCore.jl).

In the future, we aim to extend support to kernels from [ImageFiltering.jl](https://github.com/JuliaImages/ImageFiltering.jl) as well as extend support to image derivatives which are not currently possible due to no implementations for different types of interpolants used in [Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl).

Have a look at the tutorials given below to see what you an do using this package :)
```@contents
Pages = ["tutorials/homog/warp.md", "tutorials/rotate/rotate.md"]
Depth = 2
```
