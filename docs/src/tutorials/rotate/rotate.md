## Rotation transforms
```@contents
Pages = ["rotate.md"]
Depth = 5
```
Rotation transforms are pretty straightforward - they rotate the image about a certain point through a certain angle `θ`.
In this tutorial, I will train a Rotation matrix.

### Importing the required libraries

Let us first import the required libraries.
```@repl rot
using DiffImages, ImageTransformations, CoordinateTransformations, ImageCore, FileIO, StaticArrays
```

### Loading the image
For this tutorial, we shall use the Julia Dots logo.
```@example rot
img = load("julia_dots.png") .|> RGB{Float32}
img = imresize(img, ratio = 1/3)
```

### Initializing the transform
We shall rotate the image from the origin at an arbitrary angle `θ`. Let us create a function which initializes the matrix to a `LinearMap`.
```math
\begin{bmatrix}
\cos{\theta} & \sin{\theta}\\
-\sin{\theta} & \cos{\theta}
\end{bmatrix}
```

```@repl rot
m(θ) = LinearMap(SMatrix{2, 2, Float32, 4}([cos(θ) -sin(θ); sin(θ) cos(θ)]))
```

### Setting the target image
Let us set our target image to angle of `π/6`. 

```@example rot
tgt = ImageTransformations.warp(img, m(π/6), axes(img), zero(eltype(img)))
tgt = imresize(tgt, ratio = 1/3)
```

### Setting the hyperparameters
Let us initialize the hyperparameters - the learning rate `η`, the total number of iterations `num_iters` we should train for, and the initial angle `θ` from where we should start training.
```@repl rot
η = 1e-6
num_iters = 100
θ = 0.05 # Starting from zero will get you stuck in a local minima, so start a bit off.
```

### Defining the criterion
Great! Now before we jump to the training loop, let us first define an `Images`-centric version of the mean squared error loss as our criterion.
```@repl rot
function image_mse(y, ŷ)
    l = map((x, y) -> (x - y), y, ŷ)
    l = mapreducec.(x->x^2, +, 0, l)
    l = sum(l)
    l
end
```

### Training loop
Now that we are ready, let's get to train our matrix. Here we only have a single scalar parameter `θ` for training.
```julia
for i in 1:100
    ∇θ, = Zygote.gradient(θ) do θ
            out = ImageTransformations.warp(img, m(θ), axes(img), zero(eltype(img)))
            out = image_mse(out, tgt)
            out
        end

    out = ImageTransformations.warp(img, m(θ), axes(img), zero(eltype(img)))
    println("Iteration: $i Loss: $(image_mse(out, tgt))")

    θ = θ + η*∇θ
end
```

### Results
A finely trained model will train the image like this -

| `θ = π/6` | `θ = π/12` |
|-------------|-------------|
| ![π/6](pi_6.gif) | ![π/12](pi_12.gif) |
