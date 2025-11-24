import Unitful: m, s, cm, DimensionError
import Plots: PLOTS_SEED, Plot, with
import SentinelArrays: ChainedVector
import GeometryBasics
import OffsetArrays
import ImageMagick
import FreeType  # for `unicodeplots`
import LibGit2
import Aqua

using VisualRegressionTests
using RecipesPipeline
using FilePathsBase
using LaTeXStrings
using RecipesBase
using TestImages
using Unitful
using FileIO
using Plots
using Dates
using Test
using Plots: JSON.json, OrderedDict as ODict

# NOTE: don't use `plotly` (test hang, not surprised), test only the backends used in the docs
const TEST_BACKENDS = :gr, :unicodeplots, :pythonplot, :pgfplotsx, :plotlyjs, :gaston

using Pkg: Pkg

@static if isinteractive()
    Pkg.update()
end

let sources = Pkg.TOML.parsefile(Base.active_project())["sources"]
    Pkg.add(url = sources["StatsPlots"]["url"])
end

# initial load - required for `should_warn_on_unsupported`
unicodeplots()
pgfplotsx()
plotlyjs()
hdf5()
gr()

# https://github.com/JuliaPlots/PlotReferenceImages.jl
# ENV["VISUAL_REGRESSION_TESTS_AUTO"] = true
# ENV["JULIA_PKGEVAL"] = true

is_auto() = Plots.bool_env("VISUAL_REGRESSION_TESTS_AUTO", "false")
is_pkgeval() = Plots.bool_env("JULIA_PKGEVAL", "false")
is_ci() = Plots.bool_env("CI", "false")

for name in (
    "quality",
    "misc",
    "utils",
    "args",
    "defaults",
    "dates",
    "axes",
    "layouts",
    "contours",
    "components",
    "shorthands",
    "recipes",
    "unitful",
    "hdf5plots",
    "pgfplotsx",
    "plotly",
    "animations",
    "output",
    "backends",
)
    @testset "$name" begin
        if is_auto() || is_pkgeval()
            # skip the majority of tests if we only want to update reference images or under `PkgEval` (timeout limit)
            name != "backends" && continue
        end
        gr()  # reset to default backend (safer)
        include("test_$name.jl")
    end
end
is_ci() || Pkg.rm("StatsPlots")

