# Tutorials

## Homography warps
```@contents
Pages = ["warp.md"]
Depth = 5
```
Homography matrices are projective transformations. They can be represented using `DiffImages.Homography()` in Julia using `DiffImages`.

In this example, we will train a homography matrix using DiffImages.jl.
### Importing the libraries
```@setup homo
using Pkg
Pkg.add(["ImageTransformations", "ImageCore", "Zygote", "FileIO", "ImageMagick"])
```
```@repl homo
using DiffImages, ImageCore, ImageTransformations, FileIO, Zygote
```

### Loading the images
Let us load the images first. We will also convert them to `Float32` precision type since we do not need such high precision.
```@repl homo
img = load("source.jpg") .|> RGB{Float32}
tgt = load("target.jpg") .|> RGB{Float32}
```
| Source Image | Destination Image |
|--------------|-------------------|
| ![src](source.jpg) | ![tgt](target.jpg) |

### Initializing the matrix and hyperparameters
Now let us define the homography matrix and other parameters such as the learning rate.
```@repl homo
h = DiffImages.Homography{Float32}()
η = 2e-11 # Varies a lot example to example
num_iters = 100
```
### Defining the criterion
Nice! Now before we jump to the training loop, let us first define an `Images`-centric version of the mean squared error loss as our criterion.
```@repl homo
function image_mse(y, ŷ)
    l = map((x, y) -> (x - y), y, ŷ)
    l = mapreducec.(x->x^2, +, 0, l)
    l = sum(l)
    l
end
```

### Defining the training loop
Great! Now that we have defined our criterion, let us now define the training loop.
```julia
for i in 1:num_iters
    ∇H, = Zygote.gradient(h) do trfm
            out = ImageTransformations.warp(img, trfm, axes(img), zero(eltype(img)))
            out = image_mse(out, tgt)
            out
        end

    out = ImageTransformations.warp(img, h, axes(img), zero(eltype(img)))
    println("Iteration: $i Loss: $(image_mse(out, tgt))")

    h = h.H - η * (∇H.H)
    h = DiffImages.Homography(h |> SMatrix{3, 3, Float32, 9})
end
```
```
Iteration: 1 Loss: 7519.01
Iteration: 2 Loss: 8512.313
Iteration: 3 Loss: 8508.674
Iteration: 4 Loss: 8503.572
Iteration: 5 Loss: 8494.75
Iteration: 6 Loss: 8463.264
Iteration: 7 Loss: 8371.489
Iteration: 8 Loss: 8107.0605
Iteration: 9 Loss: 7883.7715
Iteration: 10 Loss: 7920.1157
Iteration: 11 Loss: 7897.9946
Iteration: 12 Loss: 7637.454
Iteration: 13 Loss: 7465.2075
Iteration: 14 Loss: 7369.2275
Iteration: 15 Loss: 7361.462
...
Iteration: 90 Loss: 7450.904
Iteration: 91 Loss: 7260.4014
Iteration: 92 Loss: 7292.6904
Iteration: 93 Loss: 7172.2715
Iteration: 94 Loss: 7313.829
Iteration: 95 Loss: 7288.0854
Iteration: 96 Loss: 7205.045
Iteration: 97 Loss: 7223.6016
Iteration: 98 Loss: 7304.29
Iteration: 99 Loss: 7179.936
Iteration: 100 Loss: 7162.128
```

Here, `∇H` is the gradient of the matrix with respect to the scalar output. It can be represented mathematically to be -
```math
∇H = 
\begin{bmatrix}
\frac{\partial{L}}{\partial{H_{ij}}}
\end{bmatrix}
```

### Results
After training your matrix successfully, you shall get something like this.

| `η = 1e-10` | `η = 2e-10` |
|-------------|-------------|
| ![homo-gif](warp.gif) | ![homo-gif2](warp2.gif) |

It is apparently difficult to train a homography matrix. Therefore, finding the right hyperparameters is the key to training it correctly.
