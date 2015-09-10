### Lines

A simple line plot of the 3 columns.

```julia
plot(rand(100,3))
```

![](../gadfly_example_1.png)

### Global

Change the guides/background without a separate call.

```julia
plot(rand(10); title="TITLE",xlabel="XLABEL",ylabel="YLABEL",background_color=:red)
```

![](../gadfly_example_3.png)

### Vectors

Plot multiple series with different numbers of points.

```julia
plot(Vector[rand(10),rand(20)]; marker=:ellipse,markersize=8)
```

![](../gadfly_example_4.png)

### Vectors w/ pluralized args

Mix arguments that apply to all series with arguments unique to each series.

```julia
plot(Vector[rand(10),rand(20)]; marker=:ellipse,markersize=8,markercolors=[:red,:blue])
```

![](../gadfly_example_5.png)

