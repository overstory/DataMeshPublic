
// ToDo: Need to set these values to the actual size of the #diagram container so that the nodes float to the center.

var width = 1200,
	height = 600;

var incIdentifier;

// FixMe: This needs to be moved into the RDF Element Maps records, or something similar
var imageMap =
{
	"http://rdf.overstory.co.uk/rdf/terms/Address": "/web/img/address-icon.png",
	"http://xmlns.com/foaf/0.1/Group": "/web/img/group-icon.gif",
	"http://xmlns.com/foaf/0.1/Organization": "/web/img/orga-icon.png",
	"http://www.w3.org/ns/org#Organization": "/web/img/orga-icon.png",
	"http://xmlns.com/foaf/0.1/Person": "/web/img/person-icon.png",
	"http://www.w3.org/ns/org#Site": "/web/img/site-icon.jpg",
	"http://data.semanticweb.org/ns/swc/ontology#Presenter": "/web/img/presenter-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#ConferenceEvent": "/web/img/conference-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#SessionEvent": "/web/img/conference-session-icon.jpg",
	"http://data.semanticweb.org/ns/swc/ontology#BreakEvent": "/web/img/coffee-icon.png",
	"http://data.semanticweb.com/ns/conf#UnknownEvent": "/web/img/speaker-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#TutorialEvent": "/web/img/tutorial-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#OrganizedEvent": "/web/img/special-event-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#TalkEvent": "/web/img/keynote-speaker-icon.jpg",
	"http://data.semanticweb.org/ns/swc/ontology#SocialEvent": "/web/img/social-icon.gif",
	"http://data.semanticweb.org/ns/swc/ontology#TrackEvent": "/web/img/tracks-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#WorkshopEvent": "/web/img/workshop-icon.png",
	"http://data.semanticweb.org/ns/swc/ontology#PanelEvent": "/web/img/panel-icon.png",
	"http://www.w3.org/2004/02/skos/core#Concept": "/web/img/brain-gears-icon.jpg",
	"http://xmlns.com/foaf/0.1/OnlineAccount": "/web/img/online-icon.png"
};

// FixMe: get these from the DB, hack for now
var curieMap =
{
	"http://rdf.overstory.co.uk/rdf/terms/": "ost",
	"http://xmlns.com/foaf/0.1/": "foaf",
	"http://www.w3.org/ns/org#": "org",
	"http://data.semanticweb.org/ns/swc/ontology#": "swc",
	"http://www.w3.org/2004/02/skos/core#": "skos",
	"http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf",
	"http://www.w3.org/2000/01/rdf-schema#": "rdfs",
	"http://www.w3.org/2001/vcard-rdf/3.0#": "vcardrdf",
	"http://purl.org/dc/elements/1.1/": "dc11",
	"http://purl.org/dc/terms/": "dc",
	"http://creativecommons.org/ns#": "cc"
};

var nodes = [];
var links = [];
var nodeUriMap = [];
var linkMap = [];

var node;
var link;
//var text;
var path;
var clickedIdentifier;

var svg;
var tooltip;
var defs;
var circleWidth;
var linkGroup, nodeGroup;
var force;

var scale = 1.0;

function buildDiagram (identifier, json)
{
	// ToDo: Need to clear any current objects when re-entering here.

	incIdentifier = identifier;

	scale = 1.0;

	d3.select("body").on("keypress", keypress);

	d3.select("#diagram")
		.append("svg")
		.attr("id", "svgFrame")
		.attr("width", "100%")
		.attr("height", "100%")
		.append("rect")
		.attr ("x", 2)
		.attr ("y", 2)
		.attr ("width", "99.5%")
		.attr ("height", "99.5%")
		.style ("fill", "#eeeeee")
		.style ("stroke", "blue")
		.style ("stroke-width", 2)
		.on("click", function(d){ d3.select("#literals").style("display", "none"); })
	;

	d3.select("#svgFrame")
		.append("text")
		.attr("x", 15)
		.attr("y", 20)
		.text("Single click to pin/unpin a node, double click to expand a node (be patient), right click for detail. Use + and - to zoom, 1 to reset size");

	svg = d3.select("#svgFrame").append("svg:g")
		.attr ("id", "diagramSvg")
		.attr ("x", 0)
		.attr ("y", 0)
		.attr("width", "100%")
		.attr("height", "100%")
	;

	tooltip = d3.select("#diagram")
		.append("div")
		.style("position", "absolute")
		.style("z-index", "10")
		.style("visibility", "hidden")
		.text("a simple tooltip");

	defs = svg.append("defs");

	defs.selectAll("marker").data(["end"])
		.enter().append("svg:marker")
		.attr("id", String)
		.attr("viewBox", "0 -5 10 10")
		.attr("refX", 32)
		.attr("refY", -4)
		.attr("markerWidth", 6)
		.attr("markerHeight", 6)
		.attr("orient", "auto")
		.append("svg:path")
		.attr("d", "M0,-5L10,0L0,5");


	defs.append('svg:pattern')
		.attr('id', 'defaultPattern')
		//.attr('patternUnits', 'userSpaceOnUse')
		.attr("patternUnits","userSpaceOnUse")
		.attr("x", -20)
		.attr("y", -18)
		.attr('width', '50')
		.attr('height', '50')
		.append('svg:image')
		//.attr('xlink:href', 'kenny.jpg')
		.attr('xlink:href', '/web/img/resource-icon.jpg')
		.attr('x', 0)
		.attr('y', 0)
		.attr('width', 35)
		.attr('height', 35);


	//push current id
	pushNodeIf (incIdentifier);

	circleWidth = 20;

	//buildNodes (json);
	//buildLinks (json, incIdentifier);
	buildNodesAndLinks (json, incIdentifier);

	force = d3.layout.force()
		.nodes(nodes)
		.links(links)
		.size([width, height])
		.linkDistance(110)
		.charge(-300)
		.gravity(0.1)
		.on("tick", tick)
		.start();


	linkGroup = svg.append("svg:g").attr("id", "link-group");
	nodeGroup = svg.append("svg:g").attr("id", "node-group");

	restart();
}

function tick()
{
	link
		.attr("d", function(d) {
			var dx = d.target.x - d.source.x,
				dy = d.target.y - d.source.y,
				dr = Math.sqrt (dx * dx + dy * dy);
			return "M " + d.source.x + "," + d.source.y + " A " + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y;
		});

	node
		.attr("transform", function(d) {
			return "translate(" + d.x + "," + d.y + ")";
		});
}

function restart()
{
	force.links(links);

	link = linkGroup.selectAll("path.link").data (links);

	link.enter().append("svg:path")
		.attr("class", function(d) { return "link " + d.type; })
		.attr("marker-end", "url(#end)");

	link.exit().remove();

	force.nodes(nodes);

	node = nodeGroup.selectAll(".node").data (nodes);

	node.enter().append("svg:g")
		.attr("class", "node")
		.call(force.drag)

		.on("click", nodeClicked)
		.on("mousedown", mouseDown)
		.on("mousemove", mouseMove)
		.on("mouseup", mouseUp)
		.on("dblclick", nodeDoubleClicked)
		.on("contextmenu", contextMenu)

		.on("mouseover", function(d){
			return tooltip
				.style("visibility", "visible")
				.style("top", (d.y - 25) * scale).style("left", (d.x - 30) * scale).style("background-color", "white").text(d.label);
		})


/*
		.on("mousemove", function(d){
			var x = (d3.event.pageX - 120)+"px",
				y = (d3.event.pageY - 90)+"px";
			return tooltip.style("top", y).style("left", x).style("background-color", "white").text(d.label);})
*/

		.on("mouseout", function(d){
			var x = (d3.event.pageX - 120)+"px",
				y = (d3.event.pageY - 90)+"px";
			return tooltip.style("visibility", "hidden").style("top", y).style("left", x).style("background-color", "white").text(d.label);})

		.selectAll("circle")
			.data(function(d) {
				return [
					{ "style": "fill: white; stroke: none" },
					{ "style": "fill: url(#" + d.pattern + "); stroke: none" },
					{ "style": "fill: none; stroke: #333333; stroke-width: 2" }
				]
			})
			.enter()
			.append("circle")
			.attr ("cx", 0)
			.attr ("cy", 0)
			.attr ("r", circleWidth)
			.attr ("style", function(d){ return d.style; })
	;

	node.exit().remove();

	force.start();
}


function nodeClicked (d)
{
	if (d.moved == false) {
		d.fixed = ! d.fixed;
		d.x = d.x + 20;

		force.start();
	}
}

function mouseDown (d)
{
	d.moved = false;
}

function mouseMove (d)
{
	d.moved = true;
}

function mouseUp (d)
{
}

function nodeDoubleClicked (d)
{
	expandOutbound(d.name);
}

function contextMenu (d)
{
	//console.log("node clicked");
	var l = d3.select("#literals");
	var literals = $("#literals");

	d3.select("#literaltable").style("display", "none");

	clickedIdentifier = d.name;

	if (literals.css('display') == "none") {

		$("#literalbody").html("");
		//console.log("build preview d name is: " + d.name);
		var htmltest = buildResourcePreview (d.name);
		//console.log("build preview html is: ", htmltest);

		var name = d.name;
		var predicate = d.predicate;

		$("#literalbody").html(htmltest);

		var x = (d.x * scale) + (40 * scale),
			y = d.y * scale;

		l.style("top", y).style("left", x).style("display", "block");
	} else {
		l.style("display", "none");
	}

	d3.event.preventDefault()
}

function keypress (d)
{
	var key = d3.event.key;

	if ((key != "-") && (key != "+") && (key != "=") && (key != "1")) return;

	if (key == "1") {
		scale = 1.0;
	} else if (key == "-") {
		scale = scale * 0.8;
	} else {
		scale = scale * 1.2;
	}

	if (scale < 0.1) scale = 0.1;

	d3.select ("#diagramSvg").attr ("transform", function(d){ return "scale(" + scale + ")"; });

	force.size ([width / scale, height / scale]);

	force.start();
}

// --------------------------------------------------

function pushNodeIf (id)
{
	var index = nodeUriMap[id];

	if (index != null) return index;

	nodes.push({ "name": id, "label": getLabel(id), "pattern": getPattern(id) });

	index = nodes.length - 1;

	nodeUriMap[id] = index;

	return index;
}

function pushLinkIf (sourceIndex, targetIndex)
{
	var key = sourceIndex + "-" + targetIndex;
	var index = linkMap[key];

	if (index != null) return index;

	links.push({ "source": sourceIndex, "target": targetIndex });

	index = nodes.length - 1;

	linkMap[key] = index;

	return index;
}

function buildNodesAndLinks (json, source)
{
	var sourceIndex = pushNodeIf (source);

	for (var i = 0; i < json.results.bindings.length; i++) {
		var predicate = json.results.bindings[i].p.value;
		var object = json.results.bindings[i].o.value;
		var objecttype = json.results.bindings[i].o.type;

		if (predicate == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
			nodes[sourceIndex].type = object;
		}

		if ((objecttype == 'uri') && (predicate != "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") && (predicate != "http://xmlns.com/foaf/0.1/depiction")) {
			var objectIndex = pushNodeIf (object);

			pushLinkIf (sourceIndex, objectIndex);
		}
	}
}

function buildResourcePreview (identifier)
{
	var html = "";
	var types = [];
	$.ajax({
		url: '/datamesh/rdf/triple/id/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + "Not Found")
		},
		success: function(data) {

			for (var i = 0; i < data.results.bindings.length; i++){
				if (data.results.bindings[i].p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"){
					types.push(data.results.bindings[i].o.value)
				}
			}

			for (var i = 0; i< types.length; i++) {
				html = html + buildResourcePreviewByType(types[i], data);
			}
		},
		type: 'GET'
	});

	return html;
}


function buildResourcePreviewByType (rdftype, json)
{
	var commonButtons = "<hr/><button type='button' class='btn btn-success btn-xs' onclick='expandNodeOut()'>Outbound</button> " +
		"<button type='button' class='btn btn-success btn-xs' onclick='expandNodeIn()'>Inbound</button> " +
		"<button type='button' class='btn btn-success btn-xs' onclick='allProperties()' id='btnShowAllProperties'>All Properties</button>";
	var html = "";

	if (rdftype == "http://rdf.overstory.co.uk/rdf/terms/Address") {
		//build address
		var address, city, postCode, country;
		var types = [];

		$.each(json.results.bindings, function(i, v) {

			if (v.p.value == "http://www.w3.org/2006/vcard/ns#street-address") {
				address = v.o.value;
				html = html + "<span>" + address + "</span><br/>"
			} else if (v.p.value == "http://www.w3.org/2006/vcard/ns#locality") {
				city = v.o.value;
				html = html + "<span>" + city + "</span><br/>"
			} else if (v.p.value == "http://www.w3.org/2006/vcard/ns#postal-code") {
				postCode = v.o.value;
				html = html + "<span>" + postCode + "</span><br/>"
			} else if (v.p.value == "http://www.w3.org/2006/vcard/ns#country-name") {
				country = v.o.value;
				html = html + "<span>" + country + "</span><br/>"
			} else if (v.p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
				types.push(getTypeFromURI(v.o.value))
			}

		});

		var typesHtml = "<div class='previewTypes'>RDF Type: "+ $.each(types, function(i, v) { console.log("<a href='/record/type/"+ v +"'>" + v + "</a>") }) +"</div>";
		return "<div class='address'>" + html + typesHtml + commonButtons + "</div>";

	} else if (rdftype == "http://www.w3.org/ns/org#Organization" || rdftype == "http://xmlns.com/foaf/0.1/Organization") {
		//build organization preview

		var prefName, homepage, linkedin, twitter, facebook, workPhone, fax, html, picture;
		var types = [];

		$.each(json.results.bindings, function(i, v) {

			if (v.p.value == "http://www.w3.org/2004/02/skos/core#prefLabel") {
				prefName = v.o.value;
				html = "<h4>" + prefName + "</h4>"
			} else if (v.p.value == "http://xmlns.com/foaf/0.1/name"){
				if (prefName === undefined) {
					prefName = v.o.value;
					html = "<h4>" + prefName + "</h4>"
				}
			} else if (v.p.value == "http://xmlns.com/foaf/0.1/depiction") {
				picture = v.o.value;
				html = html + "<img class='person-img' src='" + picture + "'/>"
			} else if (v.p.value == "http://xmlns.com/foaf/0.1/homepage") {
				homepage = v.o.value;
				html = html + "<a href='" + homepage + "'>" +homepage +"</a><br/>";
			} else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/linkedin") {
				linkedin = v.o.value;
				html = html + "<a href='" + linkedin + "'><i class='fa fa-linkedin icon'></i></a>";
			} else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/twitter") {
				twitter = v.o.value;
				html = html + "<a href='" + twitter + "'><i class='fa fa-twitter icon'></i></a>";
			} else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/facebook") {
				facebook = v.o.value;
				html = html + "<a href='" + facebook + "'><i class='fa fa-facebook icon'></i></a>";
			} else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/workPhone") {
				workPhone = v.o.value;
				html = html + "<p><i class='fa fa-phone'></i>"+ workPhone +"</p>";
			} else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/fax") {
				fax = v.o.value;
				html = html + "<p><i class='fa fa-fax'></i>"+ fax +"</p>";
			} else if (v.p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
				types.push(getTypeFromURI(v.o.value))
			}
		});

		var typesHtml = "<div class='previewTypes'>RDF Type: "+ $.each(types, function(i, v) { "<a href='/record/type/"+ v +"'>" + v + "</a>" }) +"</div>";

		return "<div class='organization'>" + html + typesHtml + commonButtons + "</div>";

	} else if (rdftype == "http://xmlns.com/foaf/0.1/Person") {
		//build person preview
		var types = [];
		var name, fname, surname, email, homephone, mobile, picture;

		html = html + "<img class='person-img' src='" + findImage(json) + "'/>";

		$.each(json.results.bindings, function(i, v) {
			if (v.p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
				types.push(getTypeFromURI(v.o.value))
			}

			else if (v.p.value == "http://xmlns.com/foaf/0.1/name") {
				name = "<h3>" + v.o.value + "</h3>";

			}

			else if (v.p.value == "http://xmlns.com/foaf/0.1/firstName") {
				fname = v.o.value;
			}

			else if (v.p.value == "http://xmlns.com/foaf/0.1/surname") {
				surname = v.o.value;
			}

			else if (v.p.value == "http://xmlns.com/foaf/0.1/mbox") {
				email = v.o.value;
				html = html + "<p><u>" + email + "</u></p>";
			}

			else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/homePhone") {
				homephone = v.o.value;
				html = html + "<p><b>" + homephone + "</b></p>";
			}

			else if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/mobilePhone") {
				mobile = v.o.value;
				html = html + "<p><b>" + mobile + "</b></p>";
			}

		});

		var typesHtml = "<div class='previewTypes'>RDF Type: "+ $.each(types, function(i, v) { console.log("<a href='/record/type/"+ v +"'>" + v + "</a>") }) +"</div>";

		if (name === undefined)  name = "<h3>" + fname + " " + surname + "</h3>";

		return "<div class='person'>" + name + html + typesHtml + commonButtons + "</div>";

	} else if (rdftype == "http://www.w3.org/ns/org#Site") {
		//build site preview

		var siteLabel;
		var types = [];

		$.each(json.results.bindings, function(i, v) {
			if (v.p.value == "http://www.w3.org/2004/02/skos/core#prefLabel") {
				siteLabel = v.o.value;
				html = html + "<h4>" + siteLabel + "</h4>"
			} else if (v.p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
				types.push(getTypeFromURI(v.o.value))
			} else if (v.p.value == "http://xmlns.com/foaf/0.1/depiction") {
				picture = v.o.value;
				html = html + "<img class='person-img' src='" + picture + "'/>"
			}

		});
		var typesHtml = "<div class='previewTypes'>RDF Type: "+ $.each(types, function(i, v) { console.log("<a href='/record/type/"+ v +"'>" + v + "</a>") }) +"</div>";

		return "<div class='site'>" + html + typesHtml + commonButtons + "</div>";

	} else {
		if ((rdftype != "http://rdf.overstory.co.uk/rdf/terms/DataRecord") && (rdftype != "http://rdf.overstory.co.uk/rdf/terms/MetaRecord")) {
			var types = [];
			var label = null;
			//default build for preview
			//return html

				console.log("chce isc kurwa spac" + rdftype)
			$.each(json.results.bindings, function(i, v) {
				if (v.p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
					types.push(getTypeFromURI(v.o.value))
				}
				if (label == null) {
					if (v.p.value == "http://www.w3.org/2000/01/rdf-schema#label") {
						label = "<h3>"+ v.o.value +"</h3>";
					} else if (v.p.value == "http://purl.org/dc/terms/title") {
						label = "<h3>"+ v.o.value +"</h3>";
					} else if (v.p.value == "http://www.w3.org/2004/02/skos/core#prefLabel") {
						label = "<h3>"+ v.o.value +"</h3>";
					} else if (v.p.value == "http://xmlns.com/foaf/0.1/name") {
						label = "<h3>"+ v.o.value +"</h3>";
					}
				}
			});

			if (label == null) label = '';

			var typesHtml = "<div class='previewTypes'>RDF Type: "+ $.each(types, function(i, v) { console.log("<a href='/record/type/"+ v +"'>" + v + "</a>") }) +"</div>";

			return "<div class='resource'>" + label + typesHtml + commonButtons + "</div>";
		}

		return "";

	}
}

function buildTablePreview (identifier)
{
	var json;

	$.ajax({
		url: '/datamesh/rdf/triple/id/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + " Not Found!")
		},
		success: function(data) {
			json = data;

		},
		type: 'GET'
	});

	var html;

	for (var i = 0; i< json.results.bindings.length; i++) {
		var predicate = json.results.bindings[i].p.value;
		var object = json.results.bindings[i].o.value;

		html = html + "<tr><td>" + curieof(predicate) + "</td><td>" + curieof(object) + "</td></tr>";
	}

	return html;
}

function curieof(uri)
{
	var result = uri;

	$.each (curieMap, function (key, prefix) {
		if (uri.startsWith (key)) {
			result = prefix + ":" + uri.substring (key.length);
		}

	});

	return result
}



/*
function getRecord (identifier) {
	$.ajax({
		url: '/datamesh/rdf/triple/id/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + " Not Found!")
		},
		success: function(data) {
			return data;
		},
		type: 'GET'
	});
}
*/

function allProperties()
{
	var html = buildTablePreview (clickedIdentifier);

	d3.select("#literaltable").style("display", "block");

	//$("#literaltablebody").html();
	$("#literaltablebody").html(html);
	$("#btnShowAllProperties").remove();
}

function expandNodeOut()
{
	expandOutbound (clickedIdentifier)
}

function expandNodeIn()
{
	expandInbound (clickedIdentifier)
}

function expandOutbound (identifier)
{
	d3.select("#literals").style("display", "none");

	$.ajax({
		url: '/datamesh/rdf/triple/id/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + " Not Found!")
		},
		success: function(data) {
			buildNodesAndLinks (data, identifier);

			restart();
		},
		type: 'GET'
	});
}

// FixMe
function expandInbound (identifier)
{
	d3.select("#literals").style("display", "none");

	$.ajax({
		url: '/datamesh/rdf/triple/referenced-by/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + " Not Found!")
		},
		success: function(json) {
			var objectIndex = pushNodeIf (identifier);

			for (var i = 0; i < json.results.bindings.length; i++) {
				var refererUri = json.results.bindings[i].o.value;
				var recordUrl = '/datamesh/record/id/' + refererUri;

				$.ajax({
					type: 'GET',
					url: recordUrl,
					async: false,
					success: function(json, status){
						// alert ("CHECK: status=" + status + ", recordUrl=" + recordUrl);

						var sourceIndex = pushNodeIf (refererUri);

						// expandOutbound (refererUri)
						pushLinkIf (sourceIndex, objectIndex);
					},
					error: function(jqXHR, status, errorThrown){
						// alert ("CHECK FAIL: status=" + status + ", " + errorThrown + ", recordUrl=" + recordUrl);

					}
				});
			}

			restart();
		},
		type: 'GET'
	});
}

/*
function recordExists (identifier)
{
	var recordUrl = '/datamesh/record/id/' + identifier;

	$.ajax({
		type: 'GET',
		url: recordUrl,
		async: false,
		success: function(json, status){
			alert ("CHECK: status=" + status);

			if ("200".equals (status)) {
				var sourceIndex = pushNodeIf (refererUri);

				// expandOutbound (refererUri)
				pushLinkIf (sourceIndex, objectIndex);
			}
		},
		error: function(jqXHR, status, errorThrown){
			alert ("CHECK FAIL: status=" + status + ", " + errorThrown + ", recordUrl=" + recordUrl);

		})

}
*/


function getLabel (identifier)
{
	var label = null;

	$.ajax({
		url: '/datamesh/rdf/triple/id/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + " Not Found!")
		},
		success: function(data) {

			var fname = "", sname = "";
			$.each(data.results.bindings, function(i, v) {
				if (v.p.value == "http://www.w3.org/2006/vcard/ns#street-address") {
					label = v.o.value;
				} else if (v.p.value == "http://www.w3.org/2006/vcard/ns#street-address") {
					label = v.o.value;
				} else if (v.p.value == "http://www.w3.org/2004/02/skos/core#prefLabel") {
					label = v.o.value;
				} else if (v.p.value == "http://xmlns.com/foaf/0.1/name") {
					label = v.o.value;
				} else if (v.p.value == "http://xmlns.com/foaf/0.1/firstName") {
					fname = v.o.value;
				} else if (v.p.value == "http://xmlns.com/foaf/0.1/surname") {
					sname = v.o.value;
				} else if (v.p.value == "http://purl.org/dc/terms/title") {
					label = v.o.value;
				} else if (v.p.value == "http://www.w3.org/2000/01/rdf-schema#label") {
					label = v.o.value;
				}
			});

			if (fname != '' && sname != '' && label == null){
				label = fname + " " + sname;
			}

			if (label != null) {
				return label;
			} else {
				$.each(data.results.bindings, function(i, v) {

					if (v.p.value == "http://rdf.overstory.co.uk/rdf/terms/uri") {
						return v.o.value;
					}

				});
			}
		},
		type: 'GET'
	});

	return (label == null) ? identifier : label;
}

function getPattern (identifier)
{
	var pattern = "defaultPattern";

	$.ajax({
		type: 'GET',
		url: '/datamesh/rdf/triple/id/' + identifier,
		async: false,
		error: function() {
			console.log(identifier + " Not Found!")
		},
		success: function(data) {
			var image = findImage(data);

			if (image != null) {
				pattern = image;

				defs.append("svg:pattern")
					.attr('id', image)
					.attr("patternUnits", "userSpaceOnUse")
					.attr("x", -30)
					.attr("y", -30)
					.attr("width", 60)
					.attr("height", 60)

					.append("svg:image")
					.attr("xlink:href", image)
					.attr("x", 10)
					.attr("y", 10)
					.attr("width", 40)
					.attr("height", 40)
				;
			}
		}
	});

	return pattern;
}

function findImage (data)
{
	var image = null;

	$.each(data.results.bindings, function(i, v) {
		if (image == null) {
			if (v.p.value == "http://xmlns.com/foaf/0.1/depiction") {
				image = v.o.value;
			}

			if (v.p.value == "http://xmlns.com/foaf/0.1/mbox") {
				var email = v.o.value.trim().toLowerCase();
				var hash = CryptoJS.MD5(email);

				image = "http://www.gravatar.com/avatar/" + hash + "?d=wavatar&s=60";
			}
		}
	});

	if (image == null) {
		image = findDefaultImageForType(data);
	}
	return image;
}

function findDefaultImageForType (data)
{
	var image = null;

	$.each(data.results.bindings, function(i, v) {
		if (image == null) {
			if (v.p.value == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" && imageMap[v.o.value] !== undefined) {
				image = imageMap[v.o.value];
			}
		}
	});

	return image;
}

function getTypeFromURI (uri) {
	var n = uri.lastIndexOf('/');
	var result = uri.substring(n + 1);
	n = result.lastIndexOf('#');
	result = result.substring(n + 1);
	return result;
}

