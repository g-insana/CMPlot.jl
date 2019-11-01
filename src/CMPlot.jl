#=
    CMPlot is OpenSource Julia code to plot and compare
    categorical data using Cloudy Mountain plots

    Copyright (C) 2019- Giuseppe Insana

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.

    Contact the developer: <http://insana.net/i/#contact>
    Online documentation: <https://cmplot.readthedocs.io>
=#

module CMPlot
export cmplot
using Random #shuffle()
using Distributions #TDist & mean()
using PlotlyJS
using DataFrames


function cmplot(data_frame::DataFrame; xcol=nothing, ycol=nothing,
           xsuperimposed=false, xlabel=nothing, ylabel=nothing, title=nothing, orientation="h",
           inf="hdi", conf_level=0.95, hdi_iter=10000, showboxplot=true,
           ycolorgroups=true, side="alt", altsidesflip=false, spanmode=nothing,
           showpoints=true, pointsoverdens=false, pointsopacity=0.4,
           markoutliers=true, colorrange=nothing, colorshift=0,
           pointshapes=nothing, pointsdistance=0.6, pointsmaxdisplayed=0)
#=
    Cloudy Mountain Plot:
        an RDI (Raw data, Descriptive statistics, and Inferential data)
        categorical distribution plot inspired by Violin, Bean and Pirate plots

    Coded in Julia & Python by Dr Giuseppe Insana, Aug & Oct 2019

    Online documentation: <https://cmplot.readthedocs.io>

    Arguments:
        The only mandatory arguments for CMPlot are a dataframe containing the
        data and either a string or a list of strings which label the columns
        containing the discrete independent variables in the dataframe, as shown
        above in the Quickstart section.

        Several additional optional arguments can be specified to customize the
        result, both in terms of content and of form.

        * `xcol`: a string or an array of strings, column name(s) of the
        dataframe that you wish to plot as "x".

        This should be the categorical independent variable. If more than one
        column name is given, the combination of these will be used as "x". See
        examples for interpretation. e.g. `xcol="Species"`

        * `ycol`: a string or an array of strings, column name(s) of the
        dataframe that you wish to plot as "y". Optional.

        These should be the continuous dependent variables. If ycol is not
        specified, then the function will plot all the columns of the dataframe
        except those specified in `xcol`.

        e.g. `ycol=["Sepal.Length","Sepal.Width"]` would plot sepals' length and
        width as a function of the flower species

        * `orientation`: 'h' | 'v', default is 'h'

        Orientation of the plot (horizontal or vertical)

        * `xsuperimposed`: boolean, default is false

        The default behaviour is to plot each value of the categorical variable
        (or each combination of values for multiple categorical variables) in a
        separate position. Set to true to superimpose the plots. This is useful
        in combination with "side='alt'" to create asymmetrical plots and
        comparing combinations of categorical variables (e.g. Married + Gender ~
        Wage).

        * `xlabel`: string or list of strings

        Override for labelling (and placing) the plots of the categorical
        variables. Only relevant when using `xsuperimposed`

        * `ylabel`: string or list of strings

        Override for labelling the dependent variables. If not specified,
        the labels for the dataframe ycol are used.

        * `title`: string

        If not specified, the plot title will be automatically created from the
        names of the variables plotted.

        e.g. `title="Length of petals for the three species"`

        * `side`: 'pos' | 'neg' | 'both' | 'alt', default is 'alt'

        'pos' would create kernel density curves rising towards the positive end
        of the axis, 'neg' towards the negative, 'both' creates symmetric curves
        (like violin/bean/pirate plots). 'alt' will alternate between 'pos' and
        'neg' in case where multiple ycol are plotted.

        e.g. `side='both'`

        * altsidesflip: boolean, default is false

        Set to true to flip the order of alternation between sides for the
        kernel density curves. Only relevant when `side`='alt'

        * `ycolorgroups`: boolean, default is true

        Set to false to have the function assign a separate colour when plotting
        different values of the categorical variable. Leave as true if all
        should be coloured the same.

        * `spanmode`: 'soft' | 'hard', default is 'soft'

        Controls the rounding of the kernel density curves or their sharp drop at
        their extremities. With 'hard' the span goes from the sample's minimum to
        its maximum value and no further.

        * `pointsoverdens`: boolean, default is false

        Set to true to plot the raw data points over the kernel density curves.
        This is obviously the case when `side`='both', but otherwise by default
        points are plotted on the opposite side.

        * `showpoints`: boolean, default is true

        Set to false to avoid plotting the cloud of data points

        * `pointsopacity`: float, range 0-1, default is 0.4

        The default is to plot the data points at 40% opacity. 1 would make
        points completely opaque and 0 completely transparent (in that case
        you'd be better served by setting `showpoints` to false).

        * `inf`: 'hdi' | 'ci' | 'iqr' | 'none', default is 'hdi'

        To select the method to use for calculating the confidence interval for
        the inference band around the mean. 'hdi' for Bayesian Highest Density
        Interval, 'ci' for Confidence Interval based on Student's T, 'iqr' for
        Inter Quantile Range. Use 'none' to avoid plotting the inference band.

        * conf_level: float, range 0-1, default is 0.95

        Confidence level to use when `inf`='ci', credible mass for `inf`='hdi'

        * hdi_iter: integer, default is 10000

        Iterations to use when performing Bayesian t-test when `inf`='hdi'

        * showboxplot: boolean, default is true

        Set to false to avoid displaying the mini boxplot

        * markoutliers: boolean, default is true

        Set to false to avoid marking the outliers

        * pointshapes: array of strings

        You can specify manually which symbols to use for each distribution
        plotted. If not specified, a random symbol is chosen for each
        distribution.

        * pointsdistance: float, range 0-1, default is 0.6

        Distance at which data points will be plotted, measured from the base of
        the density curve. 0 is at the base, 1 is at the top.

        * pointsmaxdisplayed: integer, default is 0

        This option sets the maximum number of points to be drawn on the graph.
        The default value '0' corresponds to no limit (plot all points). This
        option can be useful when the data amount is massive and would prove
        inefficient or inelegant to plot.

        * colorrange: integer, default is nothing

        By default, the distribution will be coloured independently, with the
        colours automatically chosen as needed for a single plot, maximising the
        difference in hue across the colour spectrum. You can override this by
        specifying a number to accomodate. This is useful when joining different
        plots together. E.g. if the total number of colours to be accomodating,
        after joining two plots, would equal 4, then set colorrange=4

        * colorshift: integer, default is 0

        This option is used in combination with `colorrange` to skip a certain
        amount of colours when they are to be assigned to the distributions to
        be plotted. This is useful when joining different plots together, to
        avoid having distributions plotted with the same colour.

    Returns:
        * traces: list of instances of plotly GenericTrace
        * layout: instance of plotly Layout
    =#

  # # 0) Helper functions:
    function t_test_ci(x_val; conf_level=0.95)
        #=
        t_test confidence interval: T-distribution based confidence interval when
            population variance is unknown
        note: the t-confidence interval hinges on the normality assumption
            of the data
        =#
        deg_freedom = length(x_val) - 1
        alpha = (1 - conf_level)
        tstar = quantile(TDist(deg_freedom), 1 - alpha/2) #tstar: the 1−α/2 quantile of a T-distribution with n-1 d.o.f.
        SE = std(x_val)/sqrt(length(x_val))
        xmean = mean(x_val)

        lo = xmean - tstar * SE
        hi = xmean + tstar * SE
        return(lo, hi)
    end

    function hdi_from_mcmc(posterior_samples; credible_mass=0.95)
        #=
        Computes highest density interval from a sample of representative values,
        estimated as the shortest credible interval
        Takes Arguments posterior_samples (samples from posterior) and credible
        mass (normally .95)
        Originally from https://stackoverflow.com/questions/22284502/
             highest-posterior-density-region-and-central-credible-region
        Adapted to Julialang by Giuseppe Insana
        Arguments:
            posterior_samples=array of values
            credible_mass (default 0.95)
        Returns: low and hi range for the HDI
        =#
        sorted_points = sort(posterior_samples)
        ci_idx_inc = Int(ceil(credible_mass * length(sorted_points)))
        n_ci_s = length(sorted_points) - ci_idx_inc
        ci_width = repeat([0.0], n_ci_s)
        for i in range(1, stop=n_ci_s)
            ci_width[i] = sorted_points[i + ci_idx_inc] - sorted_points[i]
        end
        hdi_min = sorted_points[findfirst(isequal(minimum(ci_width)), ci_width)]
        hdi_max = sorted_points[findfirst(isequal(minimum(ci_width)), ci_width)+ci_idx_inc]
        return(hdi_min, hdi_max)
    end

    function ttest_bayes_ci(x_val; iterations=1000, credible_mass=0.95)
        #=
        Originally from https://github.com/tszanalytics/BayesTesting.jl
        Adapted and extended by Giuseppe Insana on 2019.08.19
        Arguments:
            x_val=array of values
            iterations=iterations for samples of posterior
            credible_mass (for HDI highest density interval)
        Returns:
            hdi: highest density interval of posterior for specified credible_mass
        =#

        num = length(x_val)
        dof = num - 1
        xmean = mean(x_val)
        std_err = std(x_val) / sqrt(num)
        t_s = std_err .* rand(TDist(dof), iterations) .+ xmean
        hdi = hdi_from_mcmc(t_s, credible_mass=credible_mass)
        return hdi
    end

    # # 1) Arguments' parsing:

    dfsymbols = names(data_frame) #all column names

    if xcol == nothing
        throw(ArgumentError("you need to specify xcol argument, e.g. :Species"))
    end
    xsymbols = []
    if isa(xcol, Array{Symbol, 1})
        xsymbols = xcol #already array of symbols
    elseif isa(xcol, Symbol)
        xsymbols = [xcol] #create array of a single symbol
    else
        throw(TypeError(xcol, "xcol must be of type Symbol, e.g. :Species or an Array of Symbols, e.g. [:Gender,:Species]"))
    end
    if length(intersect(Set(xsymbols), Set(dfsymbols))) != length(Set(xsymbols)) #check sanity of specified xcol
        throw(DomainError(xcol,"xcol contains symbols not present in the dataframe"))
    end
    ysymbols = []
    if ycol == nothing
        ysymbols = setdiff(Set(dfsymbols), Set(xsymbols))
    else
        if isa(ycol, Array{Symbol, 1}) #if specified
            ysymbols = ycol #already an array of symbols
        elseif isa(ycol, Symbol)
            ysymbols = [ycol] #create array of a single symbol
        else
            throw(TypeError(ycol,"ycolumns must be a Symbol or an Array of Symbols, e.g. [:SepalLength,:SepalWidth]"))
        end
        if length(intersect(Set(ysymbols), Set(dfsymbols))) != length(Set(ysymbols)) #check sanity of specified ycols
            throw(DomainError(ycol,"ycol contains symbols not present in the dataframe"))
        end
        if length(intersect(Set(xsymbols), Set(ysymbols))) != 0 #check for common symbols
            throw(ArgumentError("ycol and xcol should not contain the same symbol(s)!"))
        end
    end

    if !(orientation in ("v","h"))
        throw(DomainError(orientation,"if defining orientation, use either h or v"))
    end
    if !(inf in ("hdi", "ci", "iqr", "none"))
        throw(DomainError(inf,"if defining inference band type, use either
                  ci (Student's t-test confidence intervals)
                  or hdi (Bayesian Posterior Highest Density Interval)
                  or iqr (InterQuartileRange)
                  or none (no band)"))
    end
    plot_title = ""
    if title == nothing
        plot_title = string(join(xsymbols, ", ", " & ")," ~ ", join(ysymbols, ", ", " & "))
    else
        plot_title = title
    end

    if xlabel != nothing
        if ! isa(xlabel, Array) #if it's not already an array, make it so
            xlabel = [xlabel]
        end
    end
    
    if ylabel != nothing
        if ! isa(ylabel, Array) #if it's not already an array, make it so
            ylabel = [ylabel]
        end
        if length(ysymbols) != length(ylabel)
            println("WARNING: you specified ", length(ylabel),
                " ylabel overrides but you are plotting ", length(ysymbols),
                " dependent variables => labels will be cycled")
        end
    end

    if spanmode == nothing
        spanmode = "soft"
    else
        if !(spanmode in ("soft","hard"))
            throw(DomainError(spanmode,"if defining spanmode, only 'soft' and 'hard' are allowed values"))
        end
    end

    # # 2) divide up data by xsymbols and then ysymbol and calculate stats, preparing datas array:

    datas = []
    sides_x = Dict() #useful when xsuperimposed
    sideindex = 0
    xlabelsoverride = Dict() #useful when xsuperimposed
    xlabelindex = 0
    ylabelindex = 0
    rand_int = rand(1:10000) #for scalegroup, to be unique for each cmplot call

    #separating distributions for each categorical x:
    for sub_data_frame in groupby(data_frame, xsymbols)
        for ysymbol in ysymbols #by default for all Ys present (or all those specified)
            xvalue = join(sub_data_frame[1, xsymbols],"&")
            xname = join([String(sym) for sym in xsymbols],"&")
            if ylabel == nothing
                yname = String(ysymbol)
            else
                yname = ylabel[ylabelindex % length(ylabel) + 1]
                ylabelindex += 1
                println("NOTE: ylabel $ysymbol -> $yname")
            end
            #x = [join(r,"&") for r in eachrow(sub_data_frame[:, xsymbols])]
            y_val = sub_data_frame[:, ysymbol]
            if length(y_val) < 2 #cannot compute inf
                y_lo, y_hi = nothing, nothing
            else
                y_lo, y_hi = if inf == "hdi" ttest_bayes_ci(y_val, iterations=hdi_iter, credible_mass=conf_level)
                    elseif inf == "ci" t_test_ci(y_val, conf_level=conf_level)
                    elseif inf == "iqr" quantile(y_val, [0.25, 0.75])
                    else nothing, nothing end
            end
            #println("confidence: $y_lo .. $y_hi")
            #y_mode = maximum(modes(y_val))
            if xsuperimposed
                thislabel = String(sub_data_frame[1, xsymbols][1])
                if xlabel == nothing
                    x_0 = if length(xsymbols)==1 " " else thislabel end
                else
                    if ! haskey(xlabelsoverride, thislabel)
                        xlabelsoverride[thislabel] = xlabel[xlabelindex % length(xlabel) + 1]
                        xlabelindex += 1
                        println("NOTE: xlabel $thislabel -> ", xlabelsoverride[thislabel])
                    end
                    x_0 = xlabelsoverride[thislabel]
                end
                if length(xsymbols)==1
                    x_1 = xvalue
                else
                    x_1 = String(sub_data_frame[1, xsymbols][length(xsymbols)])
                end
            else
                x_0 = xvalue
                x_1 = xvalue
            end
            if ! haskey(sides_x, x_1)
                sideindex += 1
                sides_x[x_1] = sideindex
            end
            data=(
                  xvalue=string(xvalue),
                  xname=xname,
                  yname=yname,
                  x_0=x_0,
                  x_1=x_1,
                  y_val=y_val,
                  #mode=y_mode,
                  lo=y_lo,
                  hi=y_hi
            )
            push!(datas, data)
        end
    end

    # # 3.1) Stylistic variants:
    sides = []
    jitter = 0.3
    if side == "both"
        sides = ["both"]
        jitter = 0.4
        pointpositions = [0]
    elseif side == "alt"
        if altsidesflip
            sides = ["positive", "negative"]
            pointpositions = [-pointsdistance, pointsdistance]
        else
            sides = ["negative", "positive"]
            pointpositions = [pointsdistance,-pointsdistance]
        end
    elseif side == "pos"
        sides = ["positive"]
        pointpositions = [-pointsdistance]
    elseif side == "neg"
        sides = ["negative"]
        pointpositions = [pointsdistance]
    else
        throw(DomainError(side,"if defining side, use one of both|alt|pos|neg"))
    end
    if pointsoverdens
        #invert the values and hence the sides of the raw points positions
        pointpositions *= -1
        #(not applicable when side==both)
    end

    label_seen = Dict()
    if ycolorgroups
        legend_tracegroupgap = 0
    else
        legend_tracegroupgap = 10
    end

    # # 3.2) Coloring setup
    colorarraylength = length(datas)
    colorindexes = Dict()

    if ycolorgroups
        i = colorshift #override 0 index start if colorshift specified
        for data in datas
            if ! haskey(colorindexes, data.yname)
                i += 1
                colorindexes[data.yname]=i
            end
        end
        colorarraylength = length(colorindexes)
    end

    if colorrange != nothing #then override colorarraylength
        colorarraylength = colorrange
    end

    colorstart = 0
    colorend = 330
    if colorarraylength > 12
        colorend = 350
    end
    fillcolors = ["hsla($j, 50%, 50%, 0.3)" for j in
                  range(colorstart, stop=colorend, length=colorarraylength + 1)]
    linecolors = ["hsla($j, 20%, 20%, 0.8)" for j in
                  range(colorstart, stop=colorend, length=colorarraylength + 1)]
    markerlinecolors = ["hsla($j, 20%, 20%, 0.4)" for j in
                        range(colorstart, stop=colorend, length=colorarraylength + 1)]
    markerfillcolors = ["hsla($j, 70%, 70%, 1)" for j in
                        range(colorstart, stop=colorend, length=colorarraylength + 1)]
    if pointshapes != nothing #override given
        if isa(pointshapes, Array{String, 1})
            markersymbols = pointshapes
        else
            throw(TypeError(pointshapes,"pointshapes must be an Array of markersymbol strings, e.g. [\"circle\", \"diamond\"]"))
        end
    else
        markersymbols = ["circle", "diamond", "cross", "triangle-up",
                         "triangle-left", "triangle-right",
                         "triangle-down", "pentagon", "hexagon", "star",
                         "hexagram", "star-triangle-up",
                         "star-square", "star-diamond"]
        markersymbols = shuffle(markersymbols) #change randomly symbols at each call of the function
    end
    cifillcolors = ["hsla($j, 45%, 45%, 0.4)" for j in
                    range(colorstart, stop=colorend, length=colorarraylength + 1)]
    boxlinecolors = ["hsla($j, 30%, 30%, 1)" for j in
                     range(colorstart, stop=colorend, length=colorarraylength + 1)]
    outliercolors = ["hsla($j, 50%, 50%, 0.9)" for j in
                     range(colorstart, stop=colorend, length=colorarraylength + 1)]

    # # 4) Define traces:

    traces = GenericTrace[]
    i = colorshift #override 0 index start if colorshift specified
    for data in datas
        if ycolorgroups
            i = colorindexes[data.yname]
            label = data.yname
            legendgroup = data.yname
            legend_tracegroupgap = 0
        else
            i += 1 #if no ycoloring, then simply choose a new color
            label = string(data.yname," ", data.xvalue)
            legendgroup = data.xvalue
            legend_tracegroupgap = 10
        end
        showlegend = true
        if haskey(label_seen, label)
            showlegend = false #stop adding new legends if already printed one
        else
            label_seen[label] = true
        end
        push!(traces,
            violin( # main trace: kernel density + raw data + meanline
                orientation=orientation,
                x0=if orientation == "v" data.x_0 else nothing end,
                x=if orientation == "v" nothing else data.y_val end,
                y0=if orientation == "v" nothing else data.x_0 end,
                y=if orientation == "v" data.y_val else nothing end,
                width=0,
                name=label,
                showlegend=showlegend,
                points=if showpoints && (pointsmaxdisplayed == 0 || pointsmaxdisplayed >= length(data.y_val)) "all" else false end,
                jitter=jitter,
                pointpos=if xsuperimposed pointpositions[sides_x[data.x_1] % length(pointpositions) + 1]
                         else pointpositions[i % length(pointpositions) + 1] end,
                spanmode=spanmode,
                scalemode="count",
                scalegroup=string(data.xvalue, rand_int),
                legendgroup=legendgroup,
                line=attr(width=1, color=linecolors[i % length(linecolors) + 1]),
                side=if xsuperimposed sides[sides_x[data.x_1] % length(sides) + 1] else sides[i % length(sides) + 1] end,
                #text="mode: $(data.mode)",
                hoveron="points+kde+violins",
                hoverinfo=if orientation == "v" "y+name+text" else "x+name+text" end,
                hoverlabel=attr(bgcolor=cifillcolors[i % length(cifillcolors) + 1]),
                meanline=attr(visible=true, width=1, color=linecolors[i % length(linecolors) + 1]),
                fillcolor=fillcolors[i % length(fillcolors) + 1],
                marker=attr(opacity=pointsopacity, size=9, color=markerfillcolors[i % length(markerfillcolors) + 1],
                            line=attr(width=0.5, color=markerlinecolors[i % length(markerlinecolors) + 1]),
                            symbol=markersymbols[i % length(markersymbols) + 1]
                )
            )
        )
        if showpoints && pointsmaxdisplayed != 0 && pointsmaxdisplayed < length(data.y_val)
            #if only a reduced number of points needs to be displayed
            push!(traces,
                violin( #optional trace: points by themselves
                    orientation=orientation,
                    x0=if orientation == "v" data.x_0 else nothing end,
                    x=if orientation == "v" nothing else data.y_val[1:pointsmaxdisplayed] end,
                    y0=if orientation == "v" nothing else data.x_0 end,
                    y=if orientation == "v" data.y_val[1:pointsmaxdisplayed] else nothing end,
                    width=0,
                    name="",
                    showlegend=false,
                    scalegroup=string(data.xvalue, rand_int),
                    legendgroup=legendgroup,
                    #hoverinfo="none",
                    points="all",
                    hoveron="points",
                    hoverinfo=if orientation == "v" "y" else "x" end,
                    jitter=jitter,
                    pointpos=if xsuperimposed pointpositions[sides_x[data.x_1] % length(pointpositions) + 1]
                             else pointpositions[i % length(pointpositions) + 1] end,
                    meanline_visible=false,
                    box_visible=false,
                    spanmode=spanmode,
                    fillcolor="rgba(0, 0, 0, 0)",
                    line=attr(width=0, color="rgba(0, 0, 0, 0)"),
                    side=if xsuperimposed sides[sides_x[data.x_1] % length(sides) + 1] else sides[i % length(sides) + 1] end,
                    marker=attr(opacity=pointsopacity, size=9, color=markerfillcolors[i % length(markerfillcolors) + 1],
                            line=attr(width=0.5, color=markerlinecolors[i % length(markerlinecolors) + 1]),
                            symbol=markersymbols[i % length(markersymbols) + 1]
                    )
                ) #optional trace for reduced number of points
            ) #push
        end # if pointsmaxdisplayed != 0
        if data.lo != nothing
            push!(traces,
                violin( #secondary trace: interval band
                    orientation=orientation,
                    x0=if orientation == "v" data.x_0 else nothing end,
                    x=if orientation == "v" nothing else data.y_val end,
                    y0=if orientation == "v" nothing else data.x_0 end,
                    y=if orientation == "v" data.y_val else nothing end,
                    width=0,
                    #name=data.yname,
                    name="",
                    showlegend=false,
                    #scalemode="count",
                    scalegroup=string(data.xvalue, rand_int),
                    legendgroup=legendgroup,
                    #hoveron="violins",
                    #hoverinfo=if orientation == "v" "y" else "x" end,
                    hoverinfo="none",
                    points=if markoutliers "outliers" else false end,
                    jitter=0,
                    pointpos=0,
                    meanline_visible=false,
                    box_visible=showboxplot,
                    box = attr(fillcolor="rgba(0, 0, 0, 0)", width=0.25,
                               line_color=boxlinecolors[i % length(boxlinecolors) + 1], line_width=0.5),
                    #box = attr(fillcolor=boxfillcolors[i % length(boxfillcolors) + 1], width=0.1, line_color="", line_width=0),
                    spanmode="manual",
                    span=[data.lo, data.hi],
                    line_width=0,
                    fillcolor=cifillcolors[i % length(cifillcolors) + 1],
                    side=if xsuperimposed sides[sides_x[data.x_1] % length(sides) + 1] else sides[i % length(sides) + 1] end,
                    marker=attr(size=11, #OUTLIERS ONLY
                                symbol=markersymbols[i % length(markersymbols) + 1],
                                color=outliercolors[i % length(outliercolors) + 1],
                                line=attr(width=0.5, color=markerlinecolors[i % length(markerlinecolors) + 1])
                           )
                ) #second violin trace for interval band
            ) #push
        end #if data.lo != nothing
    end #for data in datas

    # # 5) Define layout
    layout = Layout(
        paper_bgcolor="#eeeeff",
        plot_bgcolor="#ffffff",
        showlegend=true,
        legend_tracegroupgap=legend_tracegroupgap,
        violingap=0, violingroupgap=0,
        violinmode="overlay",
        yaxis_side="left",
        title=plot_title,
        margin=attr(l=80, r=10, t=10, b=40),
        legend=attr(x=1.1, y=1.1, xanchor="right"),
        xaxis=attr(
            showline=true, showticklabels=true,
            zeroline=true, visible=true, showgrid=if orientation == "h" false else true end
        ),
        yaxis=attr(
            showline=true, showticklabels=true,
            zeroline=true, visible=true, showgrid=if orientation == "h" true else false end
        ),
        xaxis_title=if orientation == "h" string(join(ysymbols, ", ", " & "))
                    else string(join(xsymbols, ", ", " & ")) end,
        yaxis_title=if orientation == "h" string(join(xsymbols, ", ", " & "))
                    else string(join(ysymbols, ", ", " & ")) end
    )

    # # 6) return both traces and layout, so that layout can be further tweaked
    # #      (or traces added) before plotting
    return traces, layout
end
end #module
