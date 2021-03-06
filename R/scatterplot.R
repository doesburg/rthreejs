#' scatterplot3js Three.js 3D scatterplot widget.
#'
#' A 3D scatterplot widget using three.js. Many options
#' follow the \code{scatterplot3d} function from the eponymous package.
#'
#' @param x Either a vector of x-coordinate values or a  three-column
#' data matrix with columns corresponding to the x,y,z
#' coordinate axes. Column labels, if present, are used as axis labels.
#' @param y (Optional) vector of y-coordinate values, not required if
#' \code{x} is a matrix.
#' @param z (Optional) vector of z-coordinate values, not required if
#' \code{x} is a matrix.
#' @param width The container div width.
#' @param height The container div height.
#' @param axis A logical value that when \code{TRUE} indicates that the
#' axes will be displayed.
#' @param num.ticks A three-element vector with the suggested number of
#' ticks to display per axis. Set to NULL to not display ticks. The number
#' of ticks may be adjusted by the program.
#' @param x.ticklabs A vector of tick labels of length \code{num.ticks[1]}, or
#' \code{NULL} to show numeric labels.
#' @param y.ticklabs A vector of tick labels of length \code{num.ticks[2]}, or
#' \code{NULL} to show numeric labels.
#' @param z.ticklabs A vector of tick labels of length \code{num.ticks[3]}, or
#' \code{NULL} to show numeric labels.
#' @param color Either a single hex or named color name (all points same color),
#' or a vector of #' hex or named color names as long as the number of data
#' points to plot.
#' @param size The plot point radius, either as a single number or a
#' vector of sizes of length \code{nrow(x)}. A vector of sizes is only
#' supported by the \code{canvas} renderer. The \code{webgl} renderer accepts
#' a single size value for all points.
#' @param labels  Either NULL (no labels), or a vector of labels as long as the
#' number of data points displayed when the mouse hovers over each point.
#' @param label.margin A CSS-style margin string used to display the point
#' labels.
#' @param flip.y Reverse the direction of the y-axis (the default value of
#' TRUE produces plots similar to those rendered by the R
#' \code{scatterplot3d} package).
#' @param grid Set FALSE to disable display of a grid.
#' @param stroke A single color stroke value (surrounding each point). Set to
#' null to omit stroke (only available in the canvas renderer).
#' @param renderer Select from available plot rendering techniques of
#' 'auto', 'canvas', or 'webgl'.
#' @param signif Number of significant digits used to represent point
#' coordinates. Larger numbers increase accuracy but slow plot generation
#' down.
#' @param bg  The color to be used for the background of the device region.
#' @param xlim Optional two-element vector of x-axis limits. Default auto-scales to data.
#' @param ylim Optional two-element vector of y-axis limits. Default auto-scales to data.
#' @param zlim Optional two-element vector of z-axis limits. Default auto-scales to data.
#' @param pch Not yet used but one day will support changing the point glyph.
#'
#' @note
#' Use the \code{renderer} option to manually select from the available
#' rendering options.
#' The \code{canvas} renderer is the fallback rendering option when \code{webgl}
#' is not available. Select \code{auto} to automatically choose between
#' the two. The two renderers produce slightly different-looking output
#' and have different available options (see above). Use the \code{webgl}
#' renderer for plotting large numbers of points (if available). Use the
#' \code{canvas} renderer to excercise finer control of plotting of smaller
#' numbers of points. See the examples.
#'
#' @references
#' The three.js project \url{http://threejs.org}.
#' 
#' @examples
#' \dontrun{
#' # Gumball machine
#' N <- 100
#' i <- sample(3, N, replace=TRUE)
#' x <- matrix(rnorm(N*3),ncol=3)
#' lab <- c("small", "bigger", "biggest")
#' scatterplot3js(x, color=rainbow(N), labels=lab[i],
#'                size=i, renderer="canvas")
#'
#' # Example 1 from the scatterplot3d package (cf.)
#' z <- seq(-10, 10, 0.1)
#' x <- cos(z)
#' y <- sin(z)
#' scatterplot3js(x,y,z, color=rainbow(length(z)),
#'    labels=sprintf("x=%.2f, y=%.2f, z=%.2f", x, y, z))
#'
#' # Interesting 100,000 point cloud example, should run this with WebGL!
#' N1 <- 10000
#' N2 <- 90000
#' x <- c(rnorm(N1, sd=0.5), rnorm(N2, sd=2))
#' y <- c(rnorm(N1, sd=0.5), rnorm(N2, sd=2))
#' z <- c(rnorm(N1, sd=0.5), rpois(N2, lambda=20)-20)
#' col <- c(rep("#ffff00",N1),rep("#0000ff",N2))
#' scatterplot3js(x,y,z, color=col, size=0.25)
#'
#' # A shiny example
#' shiny::runApp(system.file("examples/scatterplot",package="threejs"))
#' }
#' 
#' @seealso scatterplot3d, rgl
#' @export
scatterplot3js <- function(
  x, y, z,
  height = NULL,
  width = NULL,
  axis = TRUE,
  num.ticks = c(6,6,6),
  x.ticklabs = NULL,
  y.ticklabs = NULL,
  z.ticklabs = NULL,
  color = "steelblue",
  size = 1,
  labels = NULL,
  label.margin = "10px",
  stroke = "black",
  flip.y = TRUE,
  grid = TRUE,
  renderer = c("auto","canvas","webgl"),
  signif = 8,
  bg = "#ffffff",
  xlim, ylim, zlim, pch)
{
  # validate input
  if(!missing(y) && !missing(z)) x = cbind(x=x,y=y,z=z)
  if(ncol(x)!=3) stop("x must be a three column matrix")
  if(is.data.frame(x)) x = as.matrix(x)
  if(!is.matrix(x)) stop("x must be a three column matrix")
  if(missing(pch)) pch = NULL
  if(missing(renderer) && nrow(x)>10000)
  {
    renderer = "webgl"
  } else
  {
    renderer = match.arg(renderer)
  } 

  # Strip alpha channel from colors
  i = grep("^#",color)
  if(length(i)>0)
  {
    j = nchar(color[i])>7
    if(any(j))
    { 
      color[i][j] = substr(color[i][j],1,7)
    }
  }
  i = grep("^#",bg)
  if(length(i)>0)
  {
    if(nchar(bg)>7)
    { 
      bg = substr(bg,1,7)
    }
  }

  # create options
  options = as.list(environment())
  options = options[!(names(options) %in% c("x","y","z","i","j"))]
  # javascript does not like dots in names
  i = grep("\\.",names(options))
  if(length(i)>0) names(options)[i] = gsub("\\.","",names(options)[i])

  # re-order so z points up as expected.
  x = x[,c(1,3,2)]

  # Our s3d.js Javascript code assumes a coordinate system in the unit box.
  # Scale x to fit in there.
  n = nrow(x)
  mn = apply(x,2,min)
  mx = apply(x,2,max)
  if(!missing(xlim) && length(xlim)==2)
  {
    mn[1] = xlim[1]
    mx[1] = xlim[2]
  }
  if(!missing(ylim) && length(ylim)==2)
  {
    mn[3] = ylim[1]
    mx[3] = ylim[2]
  }
  if(!missing(zlim) && length(zlim)==2)
  {
    mn[2] = zlim[1]
    mx[2] = zlim[2]
  }
  x = (x - rep(mn, each=n))/(rep(mx - mn, each=n))
  if(flip.y) x[,3] = 1-x[,3]
  
  # convert matrix to a JSON array required by scatterplotThree.js and strip
  # them (required by s3d.js)
  if(length(colnames(x))==3) options$axisLabels = colnames(x)
  colnames(x)=c()
  x = as.vector(t(signif(x,signif)))

  # Ticks
  if(!is.null(num.ticks))
  {
    if(length(num.ticks)!=3) stop("num.ticks must have length 3")
    num.ticks = num.ticks[c(1,3,2)]

    t1 = seq(from=mn[1], to=mx[1], length.out=num.ticks[1])
    p1 = (t1 - mn[1])/(mx[1] - mn[1])
    t2 = seq(from=mn[2], to=mx[2], length.out=num.ticks[2])
    p2 = (t2 - mn[2])/(mx[2] - mn[2])
    t3 = seq(from=mn[3], to=mx[3], length.out=num.ticks[3])
    p3 = (t3 - mn[3])/(mx[3] - mn[3])
    if(flip.y) t3 = t3[length(t3):1]

    pfmt = function(x,d=2)
    {
      ans = sprintf("%.2f",x)
      i = (abs(x) < 0.01 && x!=0)
      if(any(i))
      {
        ans[i] = sprintf("%.2e",x)
      }
      ans
    }

    options$xticklab = pfmt(t1)
    options$yticklab = pfmt(t2)
    options$zticklab = pfmt(t3)
    if(!is.null(x.ticklabs)) options$xticklab = x.ticklabs
    if(!is.null(y.ticklabs)) options$zticklab = y.ticklabs
    if(!is.null(z.ticklabs)) options$yticklab = z.ticklabs
    options$xtick = p1
    options$ytick = p2
    options$ztick = p3
  }

  # create widget
  htmlwidgets::createWidget(
      name = "scatterplotThree",
      x = list(data=x, options=options, pch=pch, bg=bg),
               width = width,
               height = height,
               htmlwidgets::sizingPolicy(padding = 0, browser.fill = TRUE),
               package = "threejs")
}

#' @rdname threejs-shiny
#' @export
scatterplotThreeOutput <- function(outputId, width = "100%", height = "500px") {
    shinyWidgetOutput(outputId, "scatterplotThree", width, height,
                        package = "threejs")
}

#' @rdname threejs-shiny
#' @export
renderScatterplotThree <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) { expr <- substitute(expr) } # force quoted
    shinyRenderWidget(expr, scatterplotThreeOutput, env, quoted = TRUE)
}
