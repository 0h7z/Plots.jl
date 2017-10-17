
# https://github.com/tbreloff/Qwt.jl


supported_attrs(::QwtBackend) = merge_with_base_supported([
    :annotations,
    :linecolor,
    :fillrange,
    :fillcolor,
    :label,
    :legend,
    :seriescolor, :seriesalpha,
    :linestyle,
    :linewidth,
    :markershape,
    :markercolor,
    :markersize,
    :bins,
    :pos,
    :title,
    :window_title,
    :guide, :lims, :ticks, :scale,
  ])
supported_types(::QwtBackend) = [:path, :scatter, :hexbin, :bar]
supported_markers(::QwtBackend) = [:none, :auto, :rect, :circle, :diamond, :utriangle, :dtriangle, :cross, :xcross, :star5, :star8, :hexagon]
supported_scales(::QwtBackend) = [:identity, :log10]
is_subplot_supported(::QwtBackend) = true


# --------------------------------------------------------------------------------------

function _initialize_backend(::QwtBackend; kw...)
  @eval begin
    warn("Qwt is no longer supported... many features will likely be broken.")
    import Qwt
    export Qwt
  end
end

# -------------------------------

const _qwtAliases = KW(
    :bins => :heatmap_n,
    :fillrange => :fillto,
    :linewidth => :width,
    :markershape => :marker,
    :hexbin => :heatmap,
    :path => :line,
    :steppost => :step,
    :steppre => :stepinverted,
    :star5 => :star1,
    :star8 => :star2,
  )

function fixcolors(d::KW)
  for (k,v) in d
    if typeof(v) <: ColorScheme
      d[k] = getColor(v)
    end
  end
end

function replaceQwtAliases(d, s)
  if haskey(_qwtAliases, d[s])
    d[s] = _qwtAliases[d[s]]
  end
end

function adjustQwtKeywords(plt::Plot{QwtBackend}, iscreating::Bool; kw...)
  d = KW(kw)
  st = d[:seriestype]
  if st == :scatter
    d[:seriestype] = :none
    if d[:markershape] == :none
      d[:markershape] = :circle
    end

  elseif st in (:hline, :vline)
    addLineMarker(plt, d)
    d[:seriestype] = :none
    d[:markershape] = :circle
    d[:markersize] = 1
    if st == :vline
      d[:x], d[:y] = d[:y], d[:x]
    end

  elseif !iscreating && st == :bar
    d = barHack(; kw...)
  elseif !iscreating && st == :histogram
    d = barHack(; histogramHack(; kw...)...)
  end

  replaceQwtAliases(d, :seriestype)
  replaceQwtAliases(d, :markershape)

  for k in keys(d)
    if haskey(_qwtAliases, k)
      d[_qwtAliases[k]] = d[k]
    end
  end

  d[:x] = collect(d[:x])
  d[:y] = collect(d[:y])

  d
end

# function _create_plot(pkg::QwtBackend, d::KW)
function _create_backend_figure(plt::Plot{QwtBackend})
  fixcolors(plt.attr)
  dumpdict(plt.attr,"\n\n!!! plot")
  o = Qwt.plot(zeros(0,0); plt.attr..., show=false)
  # plt = Plot(o, pkg, 0, d, KW[])
  # plt
end

# function _series_added(::QwtBackend, plt::Plot, d::KW)
function _series_added(plt::Plot{QwtBackend}, series::Series)
  d = adjustQwtKeywords(plt, false; series.d...)
  fixcolors(d)
  dumpdict(d,"\n\n!!! plot!")
  Qwt.oplot(plt.o; d...)
  # push!(plt.seriesargs, d)
  # plt
end


# ----------------------------------------------------------------

function updateLimsAndTicks(plt::Plot{QwtBackend}, d::KW, isx::Bool)
  lims = get(d, isx ? :xlims : :ylims, nothing)
  ticks = get(d, isx ? :xticks : :yticks, nothing)
  w = plt.o.widget
  axisid = Qwt.QWT.QwtPlot[isx ? :xBottom : :yLeft]

  if typeof(lims) <: Union{Tuple,AVec} && length(lims) == 2
    if isx
      plt.o.autoscale_x = false
    else
      plt.o.autoscale_y = false
    end
    w[:setAxisScale](axisid, lims...)
  end

  if typeof(ticks) <: Range
    if isx
      plt.o.autoscale_x = false
    else
      plt.o.autoscale_y = false
    end
    w[:setAxisScale](axisid, float(minimum(ticks)), float(maximum(ticks)), float(step(ticks)))
  elseif !(ticks in (nothing, :none, :auto))
    warn("Only Range types are supported for Qwt xticks/yticks. typeof(ticks)=$(typeof(ticks))")
  end

  # change the scale
  scalesym = isx ? :xscale : :yscale
  if haskey(d, scalesym)
    scaletype = d[scalesym]
    scaletype == :identity  && w[:setAxisScaleEngine](axisid, Qwt.QWT.QwtLinearScaleEngine())
    # scaletype == :log       && w[:setAxisScaleEngine](axisid, Qwt.QWT.QwtLogScaleEngine(e))
    # scaletype == :log2      && w[:setAxisScaleEngine](axisid, Qwt.QWT.QwtLogScaleEngine(2))
    scaletype == :log10     && w[:setAxisScaleEngine](axisid, Qwt.QWT.QwtLog10ScaleEngine())
    scaletype in supported_scales() || warn("Unsupported scale type: ", scaletype)
  end

end


function _update_plot_object(plt::Plot{QwtBackend}, d::KW)
  haskey(d, :title) && Qwt.title(plt.o, d[:title])
  haskey(d, :xguide) && Qwt.xlabel(plt.o, d[:xguide])
  haskey(d, :yguide) && Qwt.ylabel(plt.o, d[:yguide])
  updateLimsAndTicks(plt, d, true)
  updateLimsAndTicks(plt, d, false)
end

function _update_plot_pos_size(plt::AbstractPlot{QwtBackend}, d::KW)
  haskey(d, :size) && Qwt.resizewidget(plt.o, d[:size]...)
  haskey(d, :pos) && Qwt.movewidget(plt.o, d[:pos]...)
end


# ----------------------------------------------------------------

        # curve.setPen(Qt.QPen(Qt.QColor(color), linewidth, self.getLineStyle(linestyle)))
function addLineMarker(plt::Plot{QwtBackend}, d::KW)
  for yi in d[:y]
    marker = Qwt.QWT.QwtPlotMarker()
    ishorizontal = (d[:seriestype] == :hline)
    marker[:setLineStyle](ishorizontal ? 1 : 2)
    marker[ishorizontal ? :setYValue : :setXValue](yi)
    qcolor = Qwt.convertRGBToQColor(getColor(d[:linecolor]))
    linestyle = plt.o.widget[:getLineStyle](string(d[:linestyle]))
    marker[:setLinePen](Qwt.QT.QPen(qcolor, d[:linewidth], linestyle))
    marker[:attach](plt.o.widget)
  end

  # marker[:setValue](x, y)
  # marker[:setLabel](Qwt.QWT.QwtText(val))
  # marker[:attach](plt.o.widget)
end

function createQwtAnnotation(plt::Plot, x, y, val::PlotText)
  marker = Qwt.QWT.QwtPlotMarker()
  marker[:setValue](x, y)
  qwttext = Qwt.QWT.QwtText(val.str)
  qwttext[:setFont](Qwt.QT.QFont(val.font.family, val.font.pointsize))
  qwttext[:setColor](Qwt.convertRGBToQColor(getColor(val.font.color)))
  marker[:setLabel](qwttext)
  marker[:attach](plt.o.widget)
end

function createQwtAnnotation(plt::Plot, x, y, val::AbstractString)
  marker = Qwt.QWT.QwtPlotMarker()
  marker[:setValue](x, y)
  marker[:setLabel](Qwt.QWT.QwtText(val))
  marker[:attach](plt.o.widget)
end

function _add_annotations(plt::Plot{QwtBackend}, anns::AVec{Tuple{X,Y,V}}) where {X,Y,V}
  for ann in anns
    createQwtAnnotation(plt, ann...)
  end
end

# ----------------------------------------------------------------

# accessors for x/y data

function getxy(plt::Plot{QwtBackend}, i::Int)
  series = plt.o.lines[i]
  series.x, series.y
end

function setxy!(plt::Plot{QwtBackend}, xy::Tuple{X,Y}, i::Integer) where {X,Y}
  series = plt.o.lines[i]
  series.x, series.y = xy
  plt
end


# -------------------------------

# -------------------------------

# # create the underlying object (each backend will do this differently)
# function _create_subplot(subplt::Subplot{QwtBackend}, isbefore::Bool)
#   isbefore && return false
#   i = 0
#   rows = Any[]
#   row = Any[]
#   for (i,(r,c)) in enumerate(subplt.layout)
#     push!(row, subplt.plts[i].o)
#     if c == ncols(subplt.layout, r)
#       push!(rows, Qwt.hsplitter(row...))
#       row = Any[]
#     end
#   end
#   # for rowcnt in subplt.layout.rowcounts
#   #   push!(rows, Qwt.hsplitter([plt.o for plt in subplt.plts[(1:rowcnt) + i]]...))
#   #   i += rowcnt
#   # end
#   subplt.o = Qwt.vsplitter(rows...)
#   # Qwt.resizewidget(subplt.o, getattr(subplt,1)[:size]...)
#   # Qwt.moveToLastScreen(subplt.o)  # hack so it goes to my center monitor... sorry
#   true
# end

function _expand_limits(lims, plt::Plot{QwtBackend}, isx::Bool)
  for series in plt.o.lines
    _expand_limits(lims, isx ? series.x : series.y)
  end
end


function _remove_axis(plt::Plot{QwtBackend}, isx::Bool)
end


# ----------------------------------------------------------------

function Base.show(io::IO, ::MIME"image/png", plt::Plot{QwtBackend})
  Qwt.refresh(plt.o)
  Qwt.savepng(plt.o, "/tmp/dfskjdhfkh.png")
  write(io, readall("/tmp/dfskjdhfkh.png"))
end

# function Base.show(io::IO, ::MIME"image/png", subplt::Subplot{QwtBackend})
#   for plt in subplt.plts
#     Qwt.refresh(plt.o)
#   end
#   Qwt.savepng(subplt.o, "/tmp/dfskjdhfkh.png")
#   write(io, readall("/tmp/dfskjdhfkh.png"))
# end


function Base.display(::PlotsDisplay, plt::Plot{QwtBackend})
  Qwt.refresh(plt.o)
  Qwt.showwidget(plt.o)
end

# function Base.display(::PlotsDisplay, subplt::Subplot{QwtBackend})
#   for plt in subplt.plts
#     Qwt.refresh(plt.o)
#   end
#   Qwt.showwidget(subplt.o)
# end
