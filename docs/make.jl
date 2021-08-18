using Documenter, DiffImages

makedocs(;
    modules = [DiffImages],
    doctest = true,
    authors = "Som V Tambe <somvt@iitk.ac.in>",
    repo = "https://github.com/SomTambe/DiffImages.jl/blob/{commit}{path}#L{line}",
    sitename = "DiffImages.jl",
    # format = Documenter.HTML(;
    #     prettyurls = get(ENV, "CI", "false") == "true",
    #     canonical = "https://fluxml.ai/Flux3D.jl",
    #     assets = String["assets/favicon.ico"],
    #     analytics = "UA-154580699-2",
    # ),
    pages = [
        "Home" => "index.md",
        # "Tutorials" => [
        # ],
        "Colorspace Transforms" => "colors/index.md",
        "Geometry modules" => 
            ["Warp Modules" => "geometry/warp.md"],
        "Tutorials" => 
            ["Homography warps" => "tutorials/homog/warp.md",
             "Rotation transforms" => "tutorials/rotate/rotate.md"]
    ],
)

deploydocs(devbranch = "main", repo = "github.com/SomTambe/DiffImages.jl.git")
