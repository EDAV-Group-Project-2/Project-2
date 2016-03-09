// Move element to front (from https://gist.github.com/trtg/3922684)
d3.selection.prototype.moveToFront = function() {
	return this.each(function(){
		this.parentNode.appendChild(this);
	});
};

var svg_width=1000, svg_height=550;
var margin = {
		'top': 50,
		'right': 50,
		'bottom': 50,
		'left': 50
	};
var map_width = svg_width - (margin.left + margin.right),
	map_height = svg_height - (margin.top + margin.bottom);

// Various formatting rules used
var format = d3.time.format("%d-%b-%y"),
		yearFormat = d3.time.format('%Y'),
		monthFormat = d3.time.format('%m'),
		monthName = d3.time.format('%B'),
		dateDisplay = d3.time.format('%Y-%m'),
		color_scale = d3.scale.category20()
		numberFormat = d3.format(',');

// queue()
// 	.defer(d3.json, "data/WorldMap.json")
// 	.defer(d3.csv, "data/GlobalFloodsRecord_d3.csv")
queue()
	.defer(d3.json, "https://dl.dropboxusercontent.com/u/532771/edav_p2/WorldMap.json")
	.defer(d3.csv, "https://dl.dropboxusercontent.com/u/532771/edav_p2/GlobalFloodsRecord_d3.csv")
	.await(function(error, world_json, floods_data) {
		var countries = world_json['features'];

		// Only add events with dates
		var clean_data = []
		floods_data.forEach(function(d){
			d['Began'] = format.parse(d['Began']);
			d['Ended'] = format.parse(d['Ended']);

			if (d['Began']) {
				d['Year'] = yearFormat(d['Began']);
				d['Month'] = monthFormat(d['Began']);
			}
			
			if (d['Year']) {
				clean_data.push(d)
			}
		})
		floods_data = clean_data
		
		// Group by years, then months
		var nested_data = d3.nest()
			.key(function(d){ return d['Year']; })
			.key(function(d){ return d['Month']; })
			.entries(floods_data);

		// Scales for the data
		var max_disp = d3.max(floods_data, function(d){ return +d['Displaced']; });
		var disp_scale = d3.scale.log().domain([1, max_disp]).range([5, 35]);

		var time_extent = d3.extent(floods_data, function(d){ return d['Began']; }),
			time_scale = d3.time.scale().domain(time_extent).range([0, map_width]),
			time_axis = d3.svg.axis().scale(time_scale).orient('bottom').tickFormat(yearFormat).ticks(10);

		// Append map elements
		var svg = d3.select("#map")
			.append('svg')
			.attr("viewBox", "0 0 " + svg_width + " " + svg_height)
			.style("max-width", svg_width + "px")
			.attr("preserveAspectRatio", "xMidYMid meet")
			.attr('id', 'svg');

		var map = svg.append("g")
			.attr('class', 'svg-map')
			.attr('transform', "translate(" + margin.left + ", " + margin.top + ")");

		var floods = svg.append("g")
			.attr('class', 'svg-flood')
			.attr('transform', "translate(" + margin.left + ", " + margin.top + ")");

		var flood_circles = floods.selectAll('circle')

		// Mercator project centered on Europe
		var projection = d3.geo.mercator()
				.center([1, 32])
				.scale(140),
			path = d3.geo.path().projection(projection);

		// Draw the world map
		map.selectAll("path")
			.data(countries)
			.enter()
			.append("path")
			.attr('d', path)
			.attr('class', function(d){
				return "country-" + d['properties']['name'];
			})
			.style('fill', '#e1e1e1')
			.style('stroke', '#ffffff');
		
		// Draws the flood events for a given year/month combination
		function draw_floods(year, month) {
			if (nested_data[year]['values'][month]['values']) {
				var temp_circles = flood_circles
					.data(nested_data[year]['values'][month]['values'])
					.enter()
					.append('circle')
					.attr('class', 'flood-circles')
					.style('fill', '#3182bd')
					.on('mouseover', function(d){
						var parentOffset = $('.container').offset();
						d3.select(this).moveToFront();
						d3.select(this).style('opacity', .8);
						d3.select('#tooltip')
							.style('visibility','visible')
							.style('top', d3.event.pageY + 10 + 'px')
							.style('left', d3.event.pageX + 20 + 'px')
							.html(tooltip_text(d))
							.transition().style('opacity', .9);
				    })
				    .on('mouseout', function(d){
						d3.select(this).style('opacity', .5);
						d3.select('#tooltip')
							.transition().style('opacity', 0);
				    });

				temp_circles = temp_circles.transition()
					.attr('r', 1)
					.attr('cx', function(d){
						return projection([d['Longitude'],d['Latitude']])[0];
					})
					.attr('cy', function(d){
						return projection([d['Longitude'],d['Latitude']])[1];
					})
					.style('opacity', 0.5);

				var temp_circles = temp_circles
					.transition()
					.attr('r', function(d){
						if (disp_scale(d['Displaced']) > 0) {
							return disp_scale(d['Displaced']);;
						}
						else {
							return 3;
						}
					});

				d3.select('#current-month')
					.html('<span id="month-name">'+ monthName(new Date(2016,month+1,6)) +'</span><br>'+(year+1985))
				
				return temp_circles;
			}
		};

		// Formatting text inside the tooltip
		function tooltip_text(d) {
			text = '<h4>' + d['Country'] + '</h4>' + 
				'<ul><li><b>Location</b>: '+ d['Detailed Locations'] +
				'</li><li><b>Duration</b>: '+ d['Duration'] + ' days' +
				'</li><li><b>Main Cause</b>: ' + d['Main cause'] + 
				'</li><li><b>Displaced</b>: ' + numberFormat(d['Displaced']) +
				'</li><li><b>Dead</b>: ' + numberFormat(d['Dead']) +
				'</li></ul>';
			return text;
		}

		// Logic for what happens when the slider is manually moved
		var year_slider = d3.slider().axis(time_axis).scale(time_scale).step(2629746)
			.on("slide", function(evt, value) {
				var start_time = 473403600000;
				current_time = (value - start_time)*1000 + (start_time);

				current_date = new Date(current_time)
				if (current_date){				
					current_year = +yearFormat(current_date) - 1985
					current_month = +monthFormat(current_date)
				}
				if (paused) {
					clear_circles();
					slider_time = time_to_slider(current_month, current_year);
					year_slider.value(slider_time);
					draw_floods(current_year, current_month);
				}
			});

		// Initialize the slider
		d3.select('#slider').call(year_slider);

		// Loop through years and months, update the slider as it goes.
		current_year = 0
		current_month = 0
		paused = false;
		function play_loop() {
			var int_id = setInterval(function(){
				if (paused) {
					draw_floods(current_year, current_month);
					clearInterval(int_id);
				}
				else {
					floods = draw_floods(current_year, current_month);
					floods.transition()
						.delay(750)
						.attr('r', 0)
				}

				slider_time = time_to_slider(current_month, current_year);
				year_slider.value(slider_time);

				current_month += 1
				if (current_month == 12) {
					current_month = 0;
					current_year += 1;
				};
				if (current_year == nested_data.length) { current_year = 0; };
			}, 150);
		}
		play_loop();

		// Slider's axis is wonky. It knows the start date UNIX time in milliseconds, but does delta in seconds
		//	So this function reconciles that
		function time_to_slider(month, year) {
			var current_time = dateDisplay.parse((year+1985) + "-" + month);
			var epoch_time = +current_time;
			return (473403600000 + (epoch_time - 473403600000)/1000);
		}

		// Manually clear circles when playing after pause
		function clear_circles() {
			d3.selectAll('.flood-circles')
				.transition()
				.delay(750)
				.attr('r', 0);
		}

		// Play/pause controls logic
		$('#play-pause-link').click(function(){
			if ($(this).text() == "Pause") {
				// The user hit pause
				paused = true;
				$(this).text("Play");
			}
			else {
				// The user hit play
				paused = false;
				clear_circles();
				play_loop();
				$(this).text("Pause");
			}
		});

		// Play/pause hover aesthetic
		$('#play-pause-button').mouseenter(function(){
			$(this).css('background-color', '#bdbdbd')
		});
		$('#play-pause-button').mouseleave(function(){
			$(this).css('background-color', 'lightgrey')
		});
	});