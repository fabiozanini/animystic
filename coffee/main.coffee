# Modules
d3 = require('d3')


# Functions
pulse = (d) ->
  circle = d3.select(this)
  repeat = ->
    circle.transition()
      .duration(600)
      .attr("r", 8)
      .transition()
      .duration(600)
      .attr("r", 5)
      .each("end", repeat)
  repeat()

unpulse = (d) ->
  d3.select(this)
    .transition()
    .duration(1000)
    .attr("r", 5)


# Canvas
vis = d3.select('#canvas')
width = parseInt(vis.style("width"))
height = parseInt(vis.style("height"))

# Support coordinates
x = d3.scale.linear()
  .domain([0, 100])
  .range([0, width])
y = d3.scale.linear()
  .domain([100, 0])
  .range([0, height])

line = d3.svg.line()
  .x((d) -> x(d.x))
  .y((d) -> y(d.y))

# Animation
class Snake
  constructor: ->
    @snake = d3.select('#canvas')
      .append("path")
      .datum([{x: 50, y: 50},
              {x: 70, y: 50},
              {x: 70, y: 70},
              {x: 30, y: 70},
              {x: 30, y: 50},
              {x: 50, y: 50}
      ])
      .attr("stroke", "white")
      .attr("stroke-width": 0)
      .attr("stroke-linecap", "round")
      .attr("d", line)
      
    @snakeLength = @snake[0][0].getTotalLength()

  showSnake: (delay=0) ->
    @snake.attr("stroke-width": 10)
      .attr("stroke-dasharray": @snakeLength)
      .attr("stroke-dashoffset", @snakeLength)
      .transition()
      .delay(delay)
      .duration(3000)
      .ease("linear")
      .attr("stroke-dashoffset": 0)

snake = new Snake()

dot = vis.append("circle")
  .attr("cx", x(50))
  .attr("cy", y(50))
  .attr("r", 5)
  .style("fill", "white")
  .on('mouseover', pulse)
  .on('mouseout',  unpulse)
  .on('click', (d) ->
    unpulse.bind(this)(d)
      .remove()
    snake.showSnake(1000)
  )
