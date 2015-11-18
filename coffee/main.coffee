# Modules
d3 = require('d3')


# Canvas
vis = d3.select('#canvas')
width = parseInt(vis.style("width"))
height = parseInt(vis.style("height"))
size = Math.min(width, height)
vis.style("width", size)
  .style("height", size)
width = size
height = size

# Svg filters
defs = vis.append('svg:defs')
defs.append('svg:filter')
  .attr({id: 'blurFilter'})
  .append('feGaussianBlur')
  .attr({
    'in': "SourceGraphic",
    'stdDeviation': 1
  })

# Support coordinates
x = d3.scale.linear()
  .domain([0, 100])
  .range([0, width])
y = d3.scale.linear()
  .domain([100, 0])
  .range([0, height])


# Animating objects
class Dot
  constructor: (stage) ->
    @dot = vis.append("circle")
      .attr("cx", x(50))
      .attr("cy", y(50))
      .attr("r", 5)
      .attr("class", "brightFill")

    @pulse.bind(@dot)()

  pulse: (d) ->
    repeat = =>
      @transition()
        .duration(600)
        .attr("r", 8)
        .transition()
        .duration(600)
        .attr("r", 5)
        .each("end", repeat)
    repeat()
  
  unpulse: (d) ->
    @transition()
      .duration(1000)
      .attr("r", 5)


class Snake
  r: 60

  constructor: (stage) ->
    @stage = stage
    @snake = vis.append("path")
      .attr("fill", "none")
      .attr("class", "brightStroke")
      .attr("stroke-width", 0)
      .attr("stroke-linecap", "round")
      .attr("d",
        ["M"+x(50)+" "+y(50),
         "l"+@r+" 0",
         "a"+@r+","+@r+" 0 0,0 -"+(2*@r)+",0",
         "a"+@r+","+@r+" 0 0,0 +"+(2*@r)+",0",
        ].join(" "))
      
    @L = @snake[0][0].getTotalLength()

    @marker = vis.append("circle")
      .attr("r", 0)
      .attr("class", "brightFill")
      .attr("stroke-width", 0)
      .attr("transform", "translate("+x(50)+","+y(50)+")")

  start: (callback) ->
    translateAlong = (path) ->
      l = path.getTotalLength()
      return (i) ->
        ((t) ->
          p = path.getPointAtLength(t * l)
          "translate("+p.x+","+p.y+")"
        )

    @marker.attr("r", 6)
      .attr("filter", "url(#blurFilter)")
      .transition()
      .duration(3000)
      .ease("linear")
      .attrTween("transform", translateAlong(@snake.node()))

    @snake.attr("stroke-width", 10)
      .attr("stroke-dasharray", @L)
      .attr("stroke-dashoffset", @L)
      .transition()
      .duration(3000)
      .ease("linear")
      .attr("stroke-dasharray", @L - @r)
      .attr("stroke-dashoffset", -@r)
      .each("end", -> callback?())

  end: ->
    @marker.remove()
    @snake.remove()



class Caption
  constructor: (stage) ->
    @_text = vis.append("text")
      .attr("x", x(50))
      .attr("y", y(85))
      .attr("font-family", "sans-serif")
      .attr("font-size", "20px")
      .attr("class", "brightFill")
      .attr("text-anchor", "middle")
      .text("Click on the dot to start")

  text: (text) -> @_text.text(text)

  fadeOut: (duration=1000) ->
    @_text.transition()
      .duration(duration)
      .style("opacity", 0)
      
  fadeIn: (duation=1000) ->
    @_text.transition()
      .duration(500)
      .style("opacity", 1)



class Cell
  constructor: (@stage, @r) ->

  show: ->
    @g = vis.append("g")
      .attr("transform", "translate("+x(50)+","+y(50)+")")

    @circle = @g.append("circle")
      .attr("cx", 0)
      .attr("cy", 0)
      .attr("r", @r)
      .attr("class", "brightStroke")
      .style("fill", "none")
      .style("stroke-width", 10)

    return this

  swell: (callback) ->
    @r += 40
    @circle.transition()
      .duration(3000)
      .ease("cubic-out")
      .attr("r", @r)
      .each("end", -> callback?())

  addReceptors: (n, callback) ->
    angles = (i * 360 / n for i in [1..n])
    n_receptors = 0

    @g.selectAll(".receptor")
      .data(angles)
      .enter()
      .append("path")
      .classed("brightStroke", true)
      .classed("receptor", true)
      .attr("fill", "none")
      .attr("stroke-width", 4)
      .attr("d",
        ["M"+@r+" 5",
         "l20 0",
         "a5,5 0 0,0 10,0"
         "l0 -10",
         "a5,5 0 0,0 -10,0"
         "l-20 0",
        ].join(" "))
      .attr("transform", (angle) -> "rotate("+angle+")")
      .style("opacity", 0)
      .transition()
      .duration(1000)
      .delay((d) -> 3000 * Math.random())
      .style("opacity", 1)
      .each("end", (=>
        n_receptors += 1
        if(n_receptors == angles.length)
          callback?()
      ))


# Animation
class Stage
  constructor: ->

  run: ->
    @caption = new Caption(this)
    @snake = new Snake(this)
    @cell = new Cell(this, r=@snake.r)
    @dot = new Dot(this)

    @dot.dot.on('click', => @animate())

  animate: ->
    @dot.dot.remove()
    @caption.fadeOut()
    
    @snake.start(=>
      @snake.end()
      delete this.snake
      @cell.show()
      @caption.text("This is a B cell")
      @cell.swell()
      @caption.fadeIn()
    )

    
  test: ->
    @cell = new Cell(r=100)
    @cell.show()


stage = new Stage()
stage.run()
