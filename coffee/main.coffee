d3 = require('d3')

d3.select('#plot')
  .append('svg')
  .attr("width", 50)
  .attr("height", 50)
  .append("circle")
  .attr("cx", 25)
  .attr("cy", 25)
  .attr("r", 25)
  .style("fill", "purple")

console.log "ciao"
