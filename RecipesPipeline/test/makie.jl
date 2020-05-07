using AbstractPlotting, CairoMakie
using MakieRecipes
using MakieRecipes.RecipesBase
using MarketData, TimeSeries

# ## The simplest example model

struct T end

RecipesBase.@recipe function plot(::T, n = 1; customcolor = :green)
    markershape --> :auto        # if markershape is unset, make it :auto
    markercolor :=  customcolor       # force markercolor to be customcolor
    xrotation   --> 45           # if xrotation is unset, make it 45
    zrotation   --> 90           # if zrotation is unset, make it 90
    rand(10,n)                   # return the arguments (input data) for the next recipe
end

@test_nowarn recipeplot(T(); seriestype = :path)

# ## Testing out series decomposition

sc = Scene()
@test_nowarn recipeplot!(sc, rand(10, 2); seriestype = :scatter)
@test_nowarn recipeplot!(sc, 1:10, rand(10, 1); seriestype = :path)

# ## Distributions

# ###

# ## Differential Equations

using OrdinaryDiffEq, StochasticDiffEq, DiffEqNoiseProcess

# ### A simple exponential growth model

f(u,p,t) = 1.01.*u
u0 = [1/2, 1]
tspan = (0.0,1.0)
prob = ODEProblem(f,u0,tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)
@test_nowarn recipeplot(sol)

# ### Matrix DiffEq

A  = [1. 0  0 -5
      4 -2  4 -3
     -4  0  0  1
      5 -2  2  3]
u0 = rand(4,2)
tspan = (0.0,1.0)
f(u,p,t) = A*u
prob = ODEProblem(f,u0,tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)
@test_nowarn recipeplot(sol)

# ### Stochastic DiffEq

f(du,u,p,t) = (du .= u)
g(du,u,p,t) = (du .= u)
u0 = rand(4,2)

W = WienerProcess(0.0,0.0,0.0)
prob = SDEProblem(f,g,u0,(0.0,1.0),noise=W)
sol = solve(prob,SRIW1())
@test_nowarn recipeplot(sol)

# ## Phylogenetic tree
using Phylo
assetpath = joinpath(dirname(pathof(MakieRecipes)), "..", "docs", "src", "assets")
hummer = open(t -> parsenewick(t, NamedPolytomousTree), joinpath(assetpath, "hummingbirds.tree"))
evolve(tree) = Phylo.map_depthfirst((val, node) -> val + randn(), 0., tree, Float64)
trait = evolve(hummer)

scp = recipeplot!(
    Scene(scale_plot = false, show_axis = false),
    hummer;
    treetype = :fan,
    line_z = trait,
    linewidth = 5,
    showtips = false,
    cgrad = :RdYlBu,
    seriestype = :path
)

# ## GraphRecipes
using GraphRecipes

# ### Julia AST with GraphRecipes

code = quote
    function mysum(list)
        out = 0
        for value in list
            out += value
        end
        out
    end
end

@test_nowarn recipeplot(code; fontsize = 12, shorten = 0.01, axis_buffer = 0.15, nodeshape = :rect)

# ### Type tree with GraphRecipes

@test_nowarn recipeplot(AbstractFloat; method = :tree, fontsize = 10)

# Timeseries with market data
@test_nowarn recipeplot(MarketData.ohlc; seriestype = :path)
