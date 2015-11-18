# Modules
d3 = require('d3')


# Functions
# Canvas
vis = d3.select('#canvas')
width = parseInt(vis.style("width"))
height = parseInt(vis.style("height"))
size = Math.min(width, height)
vis.style("width", size)
  .style("height", size)
width = size
height = size

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
      .style("fill", "white")

    @dot.on('mouseover', @pulse.bind(@dot))
      .on('mouseout',  @unpulse.bind(@dot))
      .on('click', (d) ->
        d3.select(this).remove()
        stage.caption.fadeOut()
        stage.snake.show()
      )

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
      .attr("stroke", "white")
      .attr("stroke-width", 0)
      .attr("stroke-linecap", "round")
      .attr("d",
        ["M"+x(50)+" "+y(50),
         "l"+@r+" 0",
         "a"+@r+","+@r+" 0 0,0 -"+(2*@r)+",0",
         "a"+@r+","+@r+" 0 0,0 +"+(2*@r)+",0",
        ].join(" "))
      
    @L = @snake[0][0].getTotalLength()

  show: (stage) ->
    @snake.attr("stroke-width", 10)
      .attr("stroke-dasharray", @L)
      .attr("stroke-dashoffset", @L)
      .transition()
      .duration(3000)
      .ease("linear")
      .attr("stroke-dasharray", @L - @r)
      .attr("stroke-dashoffset", -@r)
      .each("end", (=>
        @stage.circle = new Cell(r=@r)
        @snake.remove()
        @stage.circle.swell()
        delete @stage.snake

      ))


class Caption
  constructor: (stage) ->
    @_text = vis.append("text")
      .attr("x", x(50))
      .attr("y", y(85))
      .attr("font-family", "sans-serif")
      .attr("font-size", "20px")
      .attr("fill", "white")
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
  constructor: (@r) ->
    @g = vis.append("g")
      .attr("transform", "translate("+x(50)+","+y(50)+")")

    @circle = @g.append("circle")
      .attr("cx", 0)
      .attr("cy", 0)
      .attr("r", @r)
      .style("fill", "none")
      .style("stroke", "white")
      .style("stroke-width", 10)
    return this

  swell: ->
    @r += 40
    @circle.transition()
      .duration(3000)
      .ease("cubic-out")
      .attr("r", @r)
      .each("end", => @addReceptors(10))

  addReceptors: (n) ->
    angles = (i * 360 / n for i in [1..n])
    @g.selectAll(".receptor")
      .data(angles)
      .enter()
      .append("path")
      .style("opacity", 0)
      .attr("stroke", "white")
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
      .attr("class", "receptor")
      .transition()
      .duration(1000)
      .delay((d) -> 3000 * Math.random())
      .style("opacity", 1)


# Animation
class Stage
  constructor: ->
    @caption = new Caption(this)
    @snake = new Snake(this)
    @dot = new Dot(this)

    #cell = new Cell(50)
    #  .addReceptors()

new Stage()
