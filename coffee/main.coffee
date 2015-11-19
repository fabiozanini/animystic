# Modules
d3 = require('d3')


# Utils
setTO = (time, callback) -> setTimeout(callback, time)


# Canvas
svg = d3.select('#canvas')
width = parseInt(svg.style("width"))
height = parseInt(svg.style("height"))
vis = svg.append('g')

# Svg filters
defs = vis.append('svg:defs')
defs.append('svg:filter')
  .attr({id: 'blurFilter'})
  .append('feGaussianBlur')
  .attr({
    'in': "SourceGraphic",
    'stdDeviation': 1
  })

defs.append("svg:marker")
    .attr("id", "arrowEnd")
    .attr("class", "brightFill")
    .attr("viewBox", "0 -2 4 4")
    .attr("refX", 0)
    .attr("refY", 0)
    .attr("markerWidth", 2)
    .attr("markerHeight", 2)
    .attr("orient", "auto")
    .append("svg:path")
    .attr("d", "M0,-2L4,0L0,2")


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

  fadeInDNA: (callback) ->
    @dna = @g.append("path")
      .datum({x: -50, y: 30, width: 120, height: 50})
      .attr("id", "dna")
      .attr("stroke-width", 8)
      .attr("stroke-linecap", "round")
      .classed("brightStroke", true)
      .attr("fill", "none")
      .attr("d", (d) -> ["M"+d.x+" "+d.y,
        "c40,-40 70,10 "+d.width+",-"+d.height
      ].join(" "))
      .style("opacity", 0)

    @dna.transition()
      .duration(1000)
      .style("opacity", 1)
      .each("end", -> callback?())

  zoomInDna: (callback) ->
    # This comes from http://bl.ocks.org/mbostock/4699541
    d = @dna.datum()
    dx = d.width
    dy = d.height
    x = x(50) + d.x + d.width / 2
    y = y(50) + d.y - d.height / 2
    @stage.scale = scale = .85 / Math.max(dx / width, dy / height)
    @stage.translate = translate = [width / 2 - scale * x, height / 2 - scale * y]

    @dna.transition()
      .duration(1000)
      .style("stroke-width", 4)

    vis.transition()
      .duration(1000)
      .attr("transform", "translate("+translate+") scale("+scale+")")
      .each("end", -> callback?())

  zoomOutDna: (callback) ->
    vis.transition()
      .duration(1000)
      .attr("transform", "translate(0, 0) scale(1)")
      .each("end", -> callback?())

  transcribe: (callback) ->
    path = @dna.node()
    l = path.getTotalLength()
    subPath = []
    for i in [0..4]
      {x, y} = path.getPointAtLength((0.32 + 0.04 * i) * l)
      subPath.push({x: x, y: y - 4})

      line = (offset={x: 0, y: 0}) ->
        d3.svg.line()
          .x((d) -> d.x + offset.x)
          .y((d) -> d.y + offset.y)
          .interpolate('basis')

    @rna = @g.append('g')
      .style("opacity", 0)
    
    @rna.append('path')
      .attr("id", "badGene")
      .datum(subPath)
      .style("stroke", "yellow")
      .style("stroke-width", 3)
      .attr("d", line().defined((d) -> d.x < path.getPointAtLength(0.42 * l).x))

    @rna.append('path')
      .attr("id", "goodGene")
      .datum(subPath)
      .style("stroke", "steelblue")
      .style("stroke-width", 3)
      .attr("d", line().defined((d) -> d.x > path.getPointAtLength(0.38 * l).x))

    @rna.transition()
      .duration(1000)
      .style("opacity", 1)
      .transition()
      .duration(1000)
      .attr("transform", "translate(0, -10)")
      .each("end", -> callback?())

  vdj: (callback) ->
    @stage.rect.style("fill-opacity", 0)
      .style("fill", "#FFF")

    @dna.transition()
      .duration(50)
      .style("stroke", "#000")
      .duration(100)
      .style("stroke", "#333")
      .transition()
      .duration(500)
      .style("stroke", "#DFDFDF")

    @stage.rect.transition()
      .duration(50)
      .style("fill-opacity", 1)
      .transition()
      .duration(100)
      .style("fill", "#EEE")
      .transition()
      .duration(500)
      .style("fill-opacity", 0)
      .transition()
      .duration(0)
      .style("fill", "none")
      .style("fill-opacity", 1)

    @rna.select('path')
      .style("opacity", 1)
      .transition()
      .delay(120)
      .duration(10)
      .ease("cubic-out")
      .style("stroke", "#742")
      .attr("transform", "translate(-10, -5)rotate(-10)")
      .style("stroke-width", 2)
      .style("stroke-dasharray", 2)
      .transition()
      .delay(1500)
      .duration(2000)
      .style("opacity", 0)
      .each("end", ->
        this.remove()
        callback?()
      )
      
  fadeInDNACaption: (callback) ->
    caption = "In each B cell, DNA determines which microbes it recognizes."

    @dnaCaption = vis.append("g")
      .attr("opacity", 0)

    @dnaCaption.selectAll('line')
      .data([
        {x1: x(50) - 40, x2: x(75), y1: y(50) + 35, y2: y(25)},
        {x1: x(50) + 70, x2: x(75), y1: y(50) - 20, y2: y(25)},
      ])
      .enter()
      .append("line")
      .attr("x1", (d) -> d.x1)
      .attr("y1", (d) -> d.y1)
      .attr("x2", (d) -> d.x2)
      .attr("y2", (d) -> d.y2)
      .classed("brightStroke", true)
      .attr("stroke-width", 2)
      .attr("stroke-dasharray", 15)

    @dnaCaption.append("foreignObject")
      .attr("x", x(65))
      .attr("y", y(20))
      .attr("width", x(90) - x(65))
      .attr("height", y(0) - y(20))
      .append("xhtml:div")
      .style("font-family", "sans-serif")
      .style("font-size", "20px")
      .style("text-anchor", "middle")
      .attr("class", "brightColor")
      .html(caption)

    @dnaCaption.transition()
      .duration(1000)
      .attr("opacity", 1)
      .each("end", -> callback?())

  fadeOutDNACaption: (callback) ->
    @dnaCaption.transition()
      .duration(1000)
      .attr("opacity", 0)
      .transition()
      .each("end", ->
        this.remove()
        callback?()
      )

  moveToSurface: (callback) ->
    path = @rna.select("#goodGene").node()
    l = path.getTotalLength()
    source = path.getPointAtLength(0.5 * l)
    source = {x: source.x, y: source.y - 20}

    arrowLine = d3.svg.line()
      .interpolate('basic')
      .x((d) => if ('x' of d) then d.x else 0.7 * @r * Math.cos(Math.PI / 180 * d.angle))
      .y((d) => if ('y' of d) then d.y else 0.7 * @r * -Math.sin(Math.PI / 180 * d.angle))


    @arrows = @g.append("g")
      .attr("id", "arrows")

    @arrows.selectAll('path')
      .data([
        [source, {angle: 50}],
        [source, {angle: 110}],
        [source, {angle: 170}],
      ])
      .enter()
      .append('path')
      .attr("stroke-linecap", "round")
      .classed("brightStroke", true)
      .style("stroke-width", 2)
      .attr("d", arrowLine)
      .attr("marker-end", "url(#arrowEnd)")
      .style("opacity", 0)

    nArrows = 0
    @arrows.selectAll('path')
      .each((d) ->
        l = d3.select(this).node().getTotalLength()
        d3.select(this)
          .attr("stroke-dasharray", l)
          .attr("stroke-dashoffset", l)
          .style("opacity", 1)
          .transition()
          .duration(1000)
          .attr("stroke-dashoffset", 0)
          .each("end", ->
            nArrows += 1
            if (nArrows == 3)
              callback?()
          )
      )


  addReceptors: (callback) ->
    angles = [50, 112, 172]
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
      .attr("transform", (angle) -> "rotate("+(-angle)+")")
      .style("opacity", 0)
      .transition()
      .duration(1000)
      .delay((d) -> 2000 * Math.random())
      .style("opacity", 1)
      .each("end", (=>
        n_receptors += 1
        if(n_receptors == angles.length)
          callback?()
      ))


# Animation
class Stage
  constructor: ->
    @rect = vis.append("rect")
      .attr("width", width)
      .attr("height", width)
      .classed("brightStroke", true)
      .style("stroke-width", 1.5)
      .style("fill", "none")

  run: ->
    @caption = new Caption(this)
    @snake = new Snake(this)
    @cell = new Cell(this, r=@snake.r)
    @dot = new Dot(this)

    @dot.dot.on('click', => @animate())

  animate: ->
    @dot.dot.remove()
    @caption.fadeOut()
    
    @snake.start =>
      @snake.end()
      delete this.snake
      @cell.show()
      @caption.text("This is a B cell")
      @caption.fadeIn()
      @cell.swell =>
        @cell.fadeInDNA()
        @cell.fadeInDNACaption =>
          setTO 1000, =>
            @cell.fadeOutDNACaption()
            @cell.zoomInDna =>
              @cell.transcribe =>
                @cell.vdj =>
                  @cell.zoomOutDna =>
                    @cell.moveToSurface =>
                      @cell.addReceptors()

    
  test: ->
    @cell = new Cell(stage, r=140)
    @cell.show()
    @cell.fadeInDNA(=>
      @cell.zoomInDna(=>
        @cell.transcribe(=>
          @cell.vdj(=>
            @cell.zoomOutDna(=>
              @cell.moveToSurface(=>
                @cell.addReceptors()
              )
            )
          )
        )
      )
    )


stage = new Stage()
stage.run()
