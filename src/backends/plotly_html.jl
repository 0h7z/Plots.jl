# Copyright (C) 2024-2025 Heptazhou <zhou@0h7z.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

html_head(plt::Plot{PlotlyBackend}; kw...) = plotly_html_head(plt; kw...)
html_body(plt::Plot{PlotlyBackend}; kw...) = plotly_html_body(plt; kw...)

# https://github.com/plotly/plotly.js/blob/master/src/plot_api/plot_config.js
function plotly_config(plt::Plot; responsive::Bool = true, _...)
	KW([:responsive => responsive, :showTips => false])
end

function plotly_html_head(plt::Plot; _...)
	# https://cdnjs.com/libraries/mathjax
	# https://cdnjs.com/libraries/plotly.js
	mathjax   = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.2/es5/tex-svg-full.min.js"
	plotly_js = "https://cdnjs.cloudflare.com/ajax/libs/plotly.js/2.35.3/plotly.min.js"

	script(src::String) = """\t<script src="$src"></script>\n"""
	script(mathjax) * script(plotly_js)
end

function plotly_html_body(plt::Plot; kw...)
	id = uuid4()
	"""
		<main>
			<div id="$id"></div>
		</main>
		<!-- beautify ignore:start -->
		<script>
		/*   beautify ignore:start  */
	$(js_body(plt, id; kw...) |> strip)
		/*   beautify ignore:end    */
		</script>
		<!-- beautify ignore:end   -->
	"""
end

function js_body(plt::Plot, id::Base.UUID; kw...)
	f = sort! ∘ OrderedDict
	s = JSON.json(["$id",
			plotly_series(plt) .|> f,
			plotly_layout(plt; kw...) |> f,
			plotly_config(plt; kw...) |> f,
		], 4)
	"""
	Plotly.newPlot(
		$(strip(∈("[\t\n]"), s))
	)
	"""
end

plotly_show_js(io::IO, plot::Plot) =
	JSON.print(io, OrderedDict(
		:data   => plotly_series(plot),
		:layout => plotly_layout(plot),
		:config => plotly_config(plot),
	))

