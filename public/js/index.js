d3.json("commit_counts.json", function(err, dataset) {
  var barHeight = 15;
  var barPadding = 1;
  var labelPadding = 5;

  // FIXME
  //var svgWidth = _.max(dataset, function(data) { return data.count }).count;
  var svgWidth = 1000;
  var svgHeight = dataset.length * barHeight;


  var svg = d3.select("#graph")
    .append("svg")
    .attr("width", svgWidth)
    .attr("height", svgHeight);

  svg.selectAll("rect")
    .data(dataset)
    .enter()
    .append("rect")
    .attr("fill", "#43768E")
    .attr("x", 0)
    .attr("y", function(data, i ) {
      return i * barHeight;
    })
    .attr("width", function(data) {
      return data.count;
    })
    .attr("height", barHeight - barPadding);

  svg.selectAll("text")
    .data(dataset)
    .enter()
    .append("text")
    .attr("x", function(data) {
      return data.count + labelPadding;
    })
    .attr("y", function(data, i ) {
      return (i + 1) * barHeight;
    })
    .attr("font-family", "sans-serif")
    .attr("font-size", "10px")
    .attr("fill", "#f0f0f0")
    .text(function(data) {
      return data.count + ' : ' + data.file_name;
    });
});
