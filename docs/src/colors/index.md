```@meta
CurrentModule = DiffImages
```
# Colorspace Transforms

!!! note "Consistency with the batch dimension"
    Since we require the last dimension to be the batch dimension, 
    kindly unsqueeze the last dimension if you would like to pass a
    single image.

```@autodocs
Modules = [DiffImages]
Pages = ["colors/conversions.jl"]
```
