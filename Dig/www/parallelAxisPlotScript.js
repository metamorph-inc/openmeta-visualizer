// Sources:
//     https://www.d3-graph-gallery.com/graph/parallel_basic.html
//     https://observablehq.com/collection/@d3/d3-brush

Shiny.addCustomMessageHandler("dataframe",
	function(message){

		d3.select("#singleParallelPlotID").remove();  // Do we need to delete/rebuild the entire graph?

        // set the dimensions and margins of the graph
		var margin = {top: 45, right: 65, bottom: 10, left: 0},
    		width = window.innerWidth - margin.left - margin.right,
    		height = 500 - margin.top - margin.bottom;  // should height be tied to a scaled version of input_data.length?

        // append the svg object to the body of the page
		var svg = d3.select("#div_parallel_axis_plot")
            .append("svg")
		      .attr("id", "singleParallelPlotID")
		      .attr("width", width + margin.left + margin.right)
		      .attr("height", height + margin.top + margin.bottom)
		    .append("g")
		      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
        
        // message is an Array of Objects
        // each row in the R dataframe is represented as an Object
        // with dataframe column names and row values represented as Properties
        // Example:
        //     0: {age: 18, length: 6, vehicle_driver_age: 18, vehicle_footprint_area: 18, width: 3}
        //     1: {age: 42, length: 7, vehicle_driver_age: 21, vehicle_footprint_area: 100, width: 3.14159}
        //     ...
		var input_data = message;
        
        // Extract the list of dimensions we want to keep in the plot
        var dimensions = d3.keys(input_data[0]);
        // TODO: Make this tied to a Reactive R Shiny selection... like Pairs Plot tab

        // For each dimension, build a linear scale. Store all in y Object
        var yScales = {}
        dimensions.forEach(
            function(d) {  // for each element d in dimensions
                yScales[d] = d3.scaleLinear()  // create a d3.scaleLinear for that particular dimension
                  .domain( d3.extent(input_data, function(p) { return +p[d]; }) )  // accessor returns d Property Value for each Object in input_data Array
                  .range([height, 0])
            });

        // Build the horizontal scale
        var xScale = d3.scalePoint()
          .domain(dimensions)
          .range([0, width])
          .padding(1);
          
        // For user-repositioning of vertical axes
		var dragging = {};

		// Add grey background lines for context
        var background = svg
            .append("g")
              .attr("class", "background")
              .selectAll("path")
              .data(input_data)
            .enter().append("path")
              .attr("d", path);

		// Add blue foreground lines for focus
        var foreground = svg
            .append("g")
              .attr("class", "foreground")
              .selectAll("path")
              .data(input_data)
            .enter().append("path")
              .attr("d", path);

        
		// Add a group element for each dimension.
		var groupDimensionSelection = svg.selectAll(".dimension")
			.data(dimensions).enter().append("g")
			  .attr("class", "dimension")
			  .attr("transform", function(d) { return "translate(" + xScale(d) + ")"; })
              .call(d3.drag()
				.subject(function(d) { return {x: xScale(d)}; })
				.on("start", dragstarted)
				.on("drag", draginprogress)
				.on("end", dragended)
			);
            
        function dragstarted(event, d) {
            dragging[d] = xScale(d);
		    background.attr("visibility", "hidden");
        }
        
        function draginprogress(event, d) {
            dragging[d] = Math.min(width, Math.max(0, event.x));
            foreground.attr("d", path);
            dimensions.sort(function(a, b) { return position(a) - position(b); });
            xScale.domain(dimensions);
            groupDimensionSelection .attr("transform", function(d) { return "translate(" + position(d) + ")"; });
        }
        
        function dragended(event, d) {
            delete dragging[d];
            transition(d3.select(this)).attr("transform", "translate(" + xScale(d) + ")");
            transition(foreground).attr("d", path);
            background
              .attr("d", path)
              .transition()
              .delay(500)
              .duration(0)
              .attr("visibility", null);
        }
            
        groupDimensionSelection
            // build the axis with the call function
            .each(function(d) { d3.select(this).call(d3.axisLeft().scale(yScales[d])); })
            // Add axis title for each dimension
            .append("text")
              .style("text-anchor", "middle")
              .style("fill", "black")
              .attr("y", -9)
              .text(function(d) { return d; });
        
        // Add brushes for each dimension axis
        groupDimensionSelection
            .append("g")
                .each(function(d) {
                    d3.select(this)
                        .call(yScales[d].brush = d3.brushY()
                          .extent([[-10, 0], [10, height]])
                          .on("start", brushstart)
                          .on("brush", brush));
            });
            
		function brushstart(event) {
		  event.sourceEvent.stopPropagation();
        }
        
        // brush event toggles the display of foreground lines, highlighting a subset of points
		function brush(event) {
		  console.log("do nothing");
		}
        
        // The path function take a row of the csv as input, and return x and y coordinates of the line to draw
        function path(row) {
            return d3.line()(dimensions.map(
                function(d) {  // dimension
                    return [position(d), yScales[d](row[d])]; }));
        }
        
		function position(d) {
		  var v = dragging[d];
		  return typeof v === 'undefined' ? xScale(d) : v;
		}
        
		function transition(g) {
		  return g.transition().duration(500);
		}
	}
);

Shiny.addCustomMessageHandler("resize",
	function(message){
		
  // resize code here - mostly duplicated from data frame message handler
  
	}
	
);