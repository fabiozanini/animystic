# Modules
#SVG = require('svg.js')
#global.SVG = SVG

# Support functions
callOrAttr = (callback, attr='after') ->
  if (typeof callback == 'function')
    callback()
  else
    callback?[attr]?()

callAfter = (callback) -> callOrAttr(callback, 'after')


# Globals
vis = null
sta = null
width = null
height = null

drawCell = (callback) ->
  r = 140
  snake = vis.path([
    "M"+width/2+" "+height/2,
    "l"+r+" 0",
    "a"+r+","+r+" 0 0,0 -"+(2*r)+",0",
    "a"+r+","+r+" 0 0,0 +"+(2*r)+",0",
  ].join(" "))
    .fill("none")
    .addClass("brightStroke")
    .stroke({
      width: 10
      linecap: "round"
    })
    .opacity(0)

  cell = vis.group()
    .id("cell")
    .transform({
      x: width / 2
      y: height / 2
    })
    
  circle = cell.circle(2 * r)
    .move(-r, -r)
    .fill("none")
    .addClass("brightStroke")
    .stroke({
      width: 10
    })
    .opacity(0)

  receptorAngles = (i * 40 for i in [0..10])
  receptorGroup = cell.group()
    .id('receptors')
  drawReceptor = (angle) ->
    rec = receptorGroup.path([
        "M"+r+" 5",
         "l20 0",
         "a5,5 0 0,0 10,0"
         "l0 -10",
         "a5,5 0 0,0 -10,0"
         "l-20 0",
        ].join(" "))
      .addClass("geneStroke")
      .stroke({
        width: 4
        linecap: "round"
      })
      .fill("none")
      .attr({transform: "rotate(-"+angle+")"})

    l = rec.length()
    rec.stroke({
        dasharray: l
        dashoffset: l
      })
      .animate(800, '-', 0)
      .stroke({
        dashoffset: 0
      })

  l = snake.length()
  snake.stroke({
    dasharray: l
    dashoffset: l
    })
    .opacity(1)
    .animate(5000, '<>', 0)
    .stroke({
      dasharray: l - r
      dashoffset: -r
    })
    .during((pos) ->
      startCircle = r / l
      if (pos > startCircle) and receptorAngles.length
        angle = 360 * (pos - startCircle) / (1.0 - startCircle)
        if angle > receptorAngles[0]
          angle = receptorAngles.shift()
          drawReceptor(angle)

      callback?.during?(pos)
    )
    .after(->
      circle.opacity(1)
      snake.remove()

      callAfter(callback)
    )


fadeInInitialCaption = ->
  sta.text("Our B cell can now recognize microbes")
    .addClass("brightFill")
    .move(width / 2, 50)
    .font({
      family: "serif"
      size: 20
      anchor: "middle"
    })
    .opacity(0)
    .animate(2000, '-', 0)
    .opacity(1)
    


run = ->
  svg = SVG.get('#canvas')
  {height, width} = svg.node.getBoundingClientRect()

  scene = svg.group()
    .id('scene')
  vis = scene.group()
    .id('vis')
  sta = scene.group()
    .id('sta')

  drawCell
    during: (pos) ->
      if pos > 0.5
        fadeInInitialCaption()
        fadeInInitialCaption = () -> console.log pos

    after: -> console.log "done"



  console.log("ciao")

module.exports = run
