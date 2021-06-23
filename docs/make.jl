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
        # "Datasets" =>
        #     ["ModelNet" => "datasets/modelnet.md", "Custom Dataset" => "datasets/utils.md"],
        # "Transforms" => "api/transforms.md",
        # "Metrics" => "api/metrics.md",
        # "API Documentation" => [
        #     "Conversions" => "api/conversions.md",
        #     "Helper function" => "api/utils.md",
        #     "Visualization" => "api/visualize.md",
        #     "3D Models" => "api/models.md",
        # ],
    ],
)

deploydocs(devbranch = "main"; repo = "github.com/SomTambe/DiffImages.jl.git")
