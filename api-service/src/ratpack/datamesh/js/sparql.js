var baseEndpoint = "/datamesh";
var sparqlEndpoint = "/sparql";


$("#btnSparqlSearch").click(function () {
	$('.sparql-results').empty();

    var sparql = $('#inputSparql').val(); //"SELECT ?s ?p WHERE { ?s ?p 'Marcin'}"
    var contentType = $("#selectSparqlContentType option:selected").text();

    postSPARQL(sparql, contentType);
});


var postSPARQL = function (sparql, contentType) {
	var endpoint = baseEndpoint + sparqlEndpoint;
	var title = '<h3>Results</h3>';

	$.ajax({
        url: endpoint,
        type: 'POST',
        contentType: 'application/sparql-query',
        headers: {"Accept": contentType},
        data: sparql,
        success: function (result) {
            var prettyPrintResponse = null;
            var html = null;

            if (contentType == 'application/sparql-results+xml' || contentType == 'application/vnd.marklogic.triples+xml' || contentType == 'application/rdf+xml') {
            	prettyPrintResponse = vkbeautify.xml((new XMLSerializer()).serializeToString(result));
            	prettyPrintResponse = htmlEscape(prettyPrintResponse);

            } else if (contentType == 'application/sparql-results+json' || contentType == 'application/rdf+json') {
            	prettyPrintResponse = vkbeautify.json(result)
            } else if (contentType == 'text/html') {
            	html = result;
            } else {
            	prettyPrintResponse = result;
            	prettyPrintResponse = htmlEscape(prettyPrintResponse);
            }

            if (contentType == 'text/html') {
                $('.sparql-results').append(title);
                $('.sparql-results').append('<div id="sparql-result-table"></div>');
                $('#sparql-result-table').html(html);
            } else {
                $('.sparql-results').append(title);
                $('.sparql-results').append('<pre class="prettyprint">' + prettyPrintResponse + '</pre>');
                prettyPrint();
            }
        },
        error: function (error){
        	var container = '<pre class="prettyprint">' + htmlEscape(vkbeautify.xml(error.responseText)) + '</pre>';
        	$('.sparql-results').append(title);
            $('.sparql-results').append(container);
        	prettyPrint();
        }
    });

    $('html,body').animate({scrollTop: 600}, 'slow');
};

function htmlEscape(str) {
    return String(str)
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
}
