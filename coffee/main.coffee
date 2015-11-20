# Modules
d3 = require('d3')
global.d3 = d3


# Utils
setTO = (time, callback) -> setTimeout(callback, time)


# Canvas
svg = d3.select('#canvas')
width = parseInt(svg.style("width"))
height = parseInt(svg.style("height"))
scene = svg.append('g')
vis = scene.append('g')
sta = scene.append('g')


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
    .attr("viewBox", "0 -4 8 8")
    .attr("refX", 0)
    .attr("refY", 0)
    .attr("markerWidth", 6)
    .attr("markerHeight", 6)
    .attr("orient", "auto")
    .append("svg:path")
    .attr("d", "M0,-4L8,0L0,4")


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
    caption = "Click on the dot to start"

    @g = vis.append("g")
    @_text = @g.append("foreignObject")
      .attr("x", x(0))
      .attr("y", y(85))
      .attr("width", width)
      .attr("height", y(70) - y(85))

    @_text.append("xhtml:div")
      .attr("id", "caption1")
      .style("font-family", "serif")
      .style("font-size", "20px")
      .attr("align", "center")
      .attr("class", "brightColor")
      .html(caption)

  text: (text) ->
    @_text.select('#caption1')
      .html(text)

  endInitial: (callback) ->
    @_text.transition()
      .duration(1000)
      .style("opacity", 0)
      .each("end", ->
        callback?()
      )

  startBCell: (callback) ->
    textFirst = "This is a B cell "
    textSecond = ["right after its birth ", "in the bone marrow"]
    @text(textFirst+(textSecond).join(""))

    data = []
    xData = 0
    tmp = vis
      .append("text")
      .style("opacity", 0)
      .style("font-family", "serif")
      .style("font-size", "20px")
    for text in textSecond
      w = tmp.text(text)
        .node()
        .getComputedTextLength()
      data.push({text: text, w: w, x: xData})
      xData += w

    tmp.remove()
        
    x0 = x(50) - 120
    rects = @g.append("g")
      .attr("id", "rects")
    rects.selectAll("rect")
      .data(data)
      .enter()
      .append("rect")
      .attr("x", (d, i) -> x0 + d.x + 1)
      .attr("y", y(86))
      .attr("width", (d) -> d.w + 5)
      .attr("height", y(80) - y(85))
      .classed("darkFill", true)
      .style("opacity", 1)

    nMissing = data.length
    @_text.transition()
      .duration(1000)
      .style("opacity", 1)
      .each("end", (=>
        rects.selectAll("rect")
          .transition()
          .delay((d, i) -> 1000  + 2000 * i)
          .duration(3000)
          .style("opacity", 0)
          .each("end", ->
            nMissing -= 1
            this.remove()
            if (nMissing == 0)
              callback?()
          )
    ))

  hide: ->
    @_text.style("opacity", 0)

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
    @r += 50
    @circle.transition()
      .duration(5000)
      .ease("cubic-out")
      .attr("r", @r)
      .each("end", -> callback?())

  fadeInDNA: (callback) ->
    dnaData = {x: -50, y: 30, width: 120, height: 50}
    geneData = [[-55, -30],
                [-30, -5],
                [-5, 20],
                [20, 75]]

    defs.append("g")
      .attr("id", "geneClips")
      .selectAll("clipPath")
      .data(geneData)
      .enter()
      .append("clipPath")
      .attr("id", (d, i) -> "geneClip"+i)
      .append("rect")
      .attr("x", (d) -> d[0])
      .attr("y", dnaData.y - dnaData.height - 5)
      .attr("width", (d) -> d[1] - d[0])
      .attr("height", dnaData.height + 10)

    @dna = @g.append("g")
      .attr("id", "dna")
      .datum(dnaData)
      .style("opacity", 0)

    @dna.selectAll('path.gene')
      .data(geneData)
      .enter()
      .append("path")
      .classed("gene", true)
      .attr("stroke-width", 8)
      .attr("stroke-linecap", "round")
      .classed("brightStroke", (d, i) -> (i != 1) & (i != 2))
      .classed("geneStroke", (d, i) -> i == 2)
      .classed("geneAltStroke", (d, i) -> i == 1)
      .attr("fill", "none")
      .attr("d", ["M"+dnaData.x+" "+dnaData.y,
        "c40,-40 70,10 "+dnaData.width+",-"+dnaData.height
      ].join(" "))
      .attr("clip-path", (d, i) -> "url(#geneClip"+i+")")

    @dna.select("path.geneStroke")
      .attr("id", "geneGood")

    @dna.transition()
      .duration(1000)
      .style("opacity", 1)
      .each("end", -> callback?())

  zoomInDna: (callback) ->
    # This comes from http://bl.ocks.org/mbostock/4699541
    d = @dna.datum()
    dx = d.width
    dy = d.height
    xd = x(50) + d.x + d.width / 2
    yd = y(50) + d.y - d.height / 2
    scale = .85 / Math.max(dx / width, dy / height)
    translate = [width / 2 - scale * xd, height / 2 - scale * yd]
    @stage.zoom =
      scale: scale
      translate: translate
      x: xd - d.width / 2
      y: yd - d.height / 2
      width: width / scale
      height: height / scale

    @dna.transition()
      .duration(3000)
      .style("stroke-width", 4)

    vis.transition()
      .duration(3000)
      .attr("transform", "translate("+translate+") scale("+scale+")")
      .each("end", -> callback?())

  zoomOutDna: (callback) ->
    vis.transition()
      .duration(1000)
      .attr("transform", "translate(0, 0) scale(1)")
      .each("end", -> callback?())

  vdj: (callback) ->
    @stage.rect.style("fill-opacity", 0)
      .style("fill", "#FFF")
      .transition()
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

    @geneCaptionLine.selectAll('.geneCaptionLine')
      .filter((d) -> d.gene != "good")
      .remove()

    bright = @dna.select('path.brightStroke')
      .style("stroke")

    @dna.selectAll('path.brightStroke')
      .transition()
      .duration(50)
      .style("stroke", "#000")
      .duration(100)
      .style("stroke", "#333")
      .transition()
      .duration(500)
      .style("stroke", bright)

    @dna.select('path.geneAltStroke')
      .attr("stroke-linecap", "butt")
      .transition()
      .delay(120)
      .duration(30)
      .ease("cubic-out")
      .style("stroke", "#742")
      .style("stroke-width", 2)
      .style("stroke-dasharray", 2)
      .each("end", ->
        callback?()
      )

  fadeInGeneCaption: (callback) ->
    captions = [{
      y: 85,
      delay: 0,
      text: "Several genes compete to determine the B cell specificity,</br>i.e. which microbes it will attack.",
    },{
      y: 75,
      delay: 2000,
      text: "The cell randomly chooses one of them.",
    }]

    @geneCaption = sta.append("g")
      .attr("id", "geneCaption")
    
    @geneCaption.selectAll()
      .data(captions)
      .enter()
      .append("foreignObject")
      .classed("caption", true)
      .style("opacity", 0)
      .attr("x", x(5))
      .attr("y", (d) -> y(d.y))
      .attr("width", width)
      .attr("height", 0.3 * height)
      .append("xhtml:div")
      .style("font-family", "serif")
      .style("font-size", "20")
      .style("align", "left")
      .attr("class", "brightColor")
      .html((d) -> d.text)

    @geneCaptionLine = sta.append("g")
      .style("opacity", 0)
    
    @geneCaptionLine.selectAll('.geneCaptionLine')
      .data([{x: 30, gene: "bad"}, {x: 45, gene: "good"}])
      .enter()
      .append('line')
      .classed("geneCaptionLine", true)
      .classed("brightStroke", true)
      .attr("x1", x(20))
      .attr("y1", y(68))
      .attr("x2", (d) -> x(d.x))
      .attr("y2", y(50))
      .style("stroke-width", 5)

    @geneCaption.selectAll('.caption')
      .transition()
      .delay((d) -> d.delay)
      .duration(1000)
      .style("opacity", 1)
      .each("end", (d, i) ->
        if (i == captions.length - 1)
          callback?()
      )

    @geneCaptionLine.transition()
      .duration(1000)
      .style("opacity", 1)

  fadeOutGeneCaption: (callback) ->
    @geneCaptionLine.transition()
      .duration(1000)
      .style("opacity", 0)
      .each("end", -> this.remove())

    @geneCaption.transition()
      .duration(1000)
      .style("opacity", 0)
      .each("end", ->
        this.remove()
        callback?()
      )

  transcribe: (callback) ->
    clone = (selector, newParent) ->
      node = selector.node()
      d3.select(newParent.node().appendChild(node.cloneNode(true)))

    @rna = clone(@dna.select('#geneGood'), @g)
      .attr("id", "rna")

    @rnaCaption = sta.append("g")
      .attr("id", "rnaCaption")

    captions = [{
      y: 85
      text: "The cell activates the chosen gene"
      delay: 0
    }]

    @rnaCaption.selectAll()
      .data(captions)
      .enter()
      .append("foreignObject")
      .classed("caption", true)
      .style("opacity", 0)
      .attr("x", x(5))
      .attr("y", (d) -> y(d.y))
      .attr("width", 0.45 * width)
      .attr("height", 0.3 * height)
      .append("xhtml:div")
      .style("font-family", "serif")
      .style("font-size", "20")
      .style("align", "left")
      .attr("class", "brightColor")
      .html((d) -> d.text)

    @rna.transition()
      .duration(1000)
      .attr("transform", "translate(0, -10)")

    @rnaCaption.selectAll('.caption')
      .transition()
      .delay((d) -> d.delay)
      .duration(1000)
      .style("opacity", 1)
      .each("end", (d, i) ->
        if (i == captions.length - 1)
          callback?()
      )

  fadeInDNACaptionLine: (callback) ->
    @dnaCaptionLine = vis.selectAll('.dnaCaptionLine')
      .data([
        {x1: x(50) - 40, x2: x(75), y1: y(50) + 35, y2: y(25)},
        {x1: x(50) + 70, x2: x(75), y1: y(50) - 20, y2: y(25)},
      ])
      .enter()
      .append("line")
      .classed("dnaCaptionLine", true)
      .attr("x1", (d) -> d.x1)
      .attr("y1", (d) -> d.y1)
      .attr("x2", (d) -> d.x2)
      .attr("y2", (d) -> d.y2)
      .classed("brightStroke", true)
      .attr("stroke-width", 2)
      .attr("stroke-dasharray", 15)
      .style("opacity", 0)

    @dnaCaptionLine.transition()
      .duration(1000)
      .style("opacity", 1)
      .each("end", -> callback?())

  fadeOutDNACaptionLine: (callback) ->
    @dnaCaptionLine.transition()
      .style("opacity", 1)
      .each("end", ->
        this.remove()
        callback?()
      )
      
  fadeInDNACaption: (callback) ->
    caption = "Its DNA contains instructions to fight potentially "+
               "<i>any</i> microbe. </br></br>However, these instructions "+
               "must be processed first."

    @dnaCaption = vis.append("foreignObject")
      .attr("id", "caption2")
      .attr("x", x(65))
      .attr("y", y(20))
      .attr("width", x(90) - x(65))
      .attr("height", y(0) - y(20))
      .style("opacity", 0)

    @dnaCaption.append("xhtml:div")
      .style("font-family", "serif")
      .style("font-size", "20px")
      .style("align", "left")
      .attr("class", "brightColor")
      .html(caption)

    @dnaCaption.transition()
      .duration(1000)
      .style("opacity", 1)
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
    source = {x: 5, y: -5}

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
    nMissing = angles.length

    @g.selectAll(".receptor")
      .data(angles)
      .enter()
      .append("path")
      .classed("geneStroke", true)
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
      .each("end", =>
        nMissing -= 1
        if(nMissing == 0)
          callback?()
      )

    data = @rnaCaption.selectAll('.caption').data()
    newData = [{
      delay: 0
      text: " and makes receptors that are specific for a single microbe."
      x: 5
      dx: 348
      y: 85
    }, {
      delay: 3000
      text: "Because receptors live on the <u>cell surface</u>, they can probe the environment around the B cell."
      x: 5
      dx: 0
      y: 80
    }, {
      delay: 9000
      x: 5
      y: 75
      dx: 0
      text: "Now our B cell is equipped for fighting. But before it is allowed into the bloodstream..."
      final: true
    }]
    data.push newData...

    @rnaCaption.selectAll('.caption')
      .data(data)
      .enter()
      .append("foreignObject")
      .classed("caption", true)
      .attr("x", (d) -> x(d.x) + d.dx)
      .attr("y", (d) -> y(d.y))
      .attr("width", 0.8 * width)
      .attr("height", 0.3 * height)
      .append("xhtml:div")
      .style("font-family", "serif")
      .style("font-size", "20")
      .style("align", "left")
      .attr("class", "brightColor")
      .html((d) -> d.text)
      .style("opacity", 0)
      .each(=> nMissing += 1)
      .classed("final", (d) -> d.final)
      .transition()
      .delay((d) -> d.delay)
      .duration(1000)
      .style("opacity", 1)
      .each("end", (=>
        nMissing -= 1
        if(nMissing == 0)
          callback?()
      ))


# Animation
class Stage
  constructor: ->
    @rect = vis.append("rect")
      .attr("width", width)
      .attr("height", width)
      .style("fill", "none")

  fadeOut: (callback) ->
    vis.style("opacity", 1)
      .transition()
      .duration(3000)
      .style("opacity", 0)
      .each("end", ->
        d3.select(this).selectAll("*")
          .remove()
        d3.select(this).attr("transform", "")
        d3.select(this).style("opacity", 1)
      )

    sta.selectAll("div")
      .transition()
      .delay(-> 0 + d3.select(this).classed("final") * 6000)
      .duration(1000)
      .style("opacity", 0)
      .each("end", ->
        if (d3.select(this).classed("final"))
          sta.selectAll("*")
            .remove()
          sta.style("opacity", 1)
      )
 
  run: ->
    @caption = new Caption(this)
    @snake = new Snake(this)
    @cell = new Cell(this, r=@snake.r)
    @dot = new Dot(this)

    @dot.dot.on('click', => @animate())

  animate: ->
    @dot.dot.remove()
    @caption.endInitial()
    
    @snake.start =>
      @snake.end()
      delete this.snake
      @cell.show()
      @cell.swell()
      @caption.startBCell =>
        @cell.fadeInDNA()
        @cell.fadeInDNACaptionLine()
        @cell.fadeInDNACaption =>
          setTO 5000, =>
            @cell.fadeOutDNACaptionLine()
            @cell.fadeOutDNACaption()
            @cell.zoomInDna =>
              @caption.hide()
              @cell.fadeInGeneCaption =>
                setTO 2500, =>
                  @cell.vdj =>
                    setTO 2000, =>
                      @cell.fadeOutGeneCaption =>
                        @cell.transcribe =>
                          @cell.zoomOutDna =>
                            @cell.moveToSurface =>
                              @cell.addReceptors =>
                                setTO 2000, =>
                                  @fadeOut()

    
  test: ->
    @caption = new Caption(this)
    @cell = new Cell(this, r=110)
    @cell.show()
    @cell.fadeInDNA =>
      @cell.zoomInDna =>
        @caption.hide()
        @cell.fadeInGeneCaption =>
          setTO 3000, =>
            @cell.vdj =>
              setTO 2000, =>
                @cell.fadeOutGeneCaption =>
                  @cell.transcribe =>
                    @cell.zoomOutDna =>
                      @cell.moveToSurface =>
                        @cell.addReceptors =>
                          setTO 2000, =>
                            @fadeOut()


stage = new Stage()
stage.run()
