# Copyright (C) 2024 Heptazhou <zhou@0h7z.com>
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

standalone_html(plt::AbstractPlot;
	title::AbstractString = get(plt.attr, :window_title, "Plots.jl"), kw...) =
	"""
	<!DOCTYPE html>
	<html>
	<head>
		<meta charset="UTF-8" />
		<meta name="color-scheme" content="dark light" />
		<meta name="referrer" content="no-referrer" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />
		<link rel="dns-prefetch" href="https://cdnjs.cloudflare.com/" />
		<title>$title</title>
		<style>
			html, body, main { display: flex; height: 100%; overflow: hidden; }
			html, body, main, main > div { flex: auto; margin: 0; padding: 0; }
		</style>
		$(html_head(plt; kw...) |> strip)
	</head>
	<body>
		$(html_body(plt; kw...) |> strip)
	</body>
	</html>
	"""

embeddable_html(plt::AbstractPlot; kw...) = html_head(plt; kw...) * html_body(plt; kw...)

