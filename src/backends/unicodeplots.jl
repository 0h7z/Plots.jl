
# https://github.com/Evizero/UnicodePlots.jl

supported_args(::UnicodePlotsBackend) = merge_with_base_supported([
    :label,
    :legend,
    :seriescolor,
    :seriesalpha,
    :linestyle,
    :markershape,
    :bins,
    :title,
    :guide, :lims,
  ])
supported_types(::UnicodePlotsBackend) = [
    :path, :scatter,
    :histogram2d
]
supported_styles(::UnicodePlotsBackend) = [:auto, :solid]
supported_markers(::UnicodePlotsBackend) = [:none, :auto, :circle]
supported_scales(::UnicodePlotsBackend) = [:identity]
is_subplot_supported(::UnicodePlotsBackend) = true


# don't warn on unsupported... there's just too many warnings!!
warnOnUnsupported_args(pkg::UnicodePlotsBackend, d::KW) = nothing

# --------------------------------------------------------------------------------------

function _initialize_backend(::UnicodePlotsBackend; kw...)
    @eval begin
        import UnicodePlots
        export UnicodePlots
    end
end

# -------------------------------


# do all the magic here... build it all at once, since we need to know about all the series at the very beginning
function rebuildUnicodePlot!(plt::Plot)
    plt.o = []

    for sp in plt.subplots
        xaxis = sp[:xaxis]
        yaxis = sp[:yaxis]
        xlim =  axis_limits(xaxis)
        ylim =  axis_limits(yaxis)

        # make vectors
        xlim = [xlim[1], xlim[2]]
        ylim = [ylim[1], ylim[2]]

        # we set x/y to have a single point, since we need to create the plot with some data.
        # since this point is at the bottom left corner of the plot, it shouldn't actually be shown
        x = Float64[xlim[1]]
        y = Float64[ylim[1]]

        # create a plot window with xlim/ylim set, but the X/Y vectors are outside the bounds
        width, height = plt[:size]
        canvas_type = isijulia() ? UnicodePlots.AsciiCanvas : UnicodePlots.BrailleCanvas
        o = UnicodePlots.Plot(x, y, canvas_type;
            width = width,
            height = height,
            title = sp[:title],
            xlim = xlim,
            ylim = ylim,
            border = isijulia() ? :ascii : :solid
        )

        # set the axis labels
        UnicodePlots.xlabel!(o, xaxis[:guide])
        UnicodePlots.ylabel!(o, yaxis[:guide])

        # now use the ! functions to add to the plot
        for series in series_list(sp)
            addUnicodeSeries!(o, series.d, sp[:legend] != :none, xlim, ylim)
        end

        # save the object
        push!(plt.o, o)
    end
end


# add a single series
function addUnicodeSeries!(o, d::KW, addlegend::Bool, xlim, ylim)
    # get the function, or special handling for step/bar/hist
    st = d[:seriestype]
    if st == :histogram2d
        UnicodePlots.densityplot!(o, d[:x], d[:y])
        return
    end

    if st == :path
        func = UnicodePlots.lineplot!
    elseif st == :scatter || d[:markershape] != :none
        func = UnicodePlots.scatterplot!
    else
        error("Linestyle $st not supported by UnicodePlots")
    end

    # get the series data and label
    x, y = [collect(float(d[s])) for s in (:x, :y)]
    label = addlegend ? d[:label] : ""

    # if we happen to pass in allowed color symbols, great... otherwise let UnicodePlots decide
    color = d[:linecolor] in UnicodePlots.color_cycle ? d[:linecolor] : :auto

    # add the series
    func(o, x, y; color = color, name = label)
end

# -------------------------------

# since this is such a hack, it's only callable using `png`... should error during normal `writemime`
function png(plt::AbstractPlot{UnicodePlotsBackend}, fn::AbstractString)
    fn = addExtension(fn, "png")

    # make some whitespace and show the plot
    println("\n\n\n\n\n\n")
    gui(plt)

    # @osx_only begin
    @compat @static if is_apple()
        # BEGIN HACK

        # wait while the plot gets drawn
        sleep(0.5)

        # use osx screen capture when my terminal is maximized and cursor starts at the bottom (I know, right?)
        # TODO: compute size of plot to adjust these numbers (or maybe implement something good??)
        run(`screencapture -R50,600,700,420 $fn`)

        # END HACK (phew)
        return
    end

    error("Can only savepng on osx with UnicodePlots (though even then I wouldn't do it)")
end

# -------------------------------

# we don't do very much for subplots... just stack them vertically

function _update_plot_object(plt::Plot{UnicodePlotsBackend})
  w, h = plt[:size]
  plt.attr[:size] = div(w, 10), div(h, 20)
  plt.attr[:color_palette] = [RGB(0,0,0)]
  rebuildUnicodePlot!(plt)
end

function _writemime(io::IO, ::MIME"text/plain", plt::Plot{UnicodePlotsBackend})
  map(show, plt.o)
  nothing
end


function _display(plt::Plot{UnicodePlotsBackend})
  map(show, plt.o)
  nothing
end

