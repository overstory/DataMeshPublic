var propertyPredicates =[ "foaf:name", "foaf:firstName", "foaf:surname", "foaf:mbox", "foaf:phone", "ost:workPhone", "ost:mobilePhone", "ost:twitter", "ost:facebook", "ost:linkedin", "ost:skype"];

var resourceTypes = [ "ost:Address", "foaf:Group", "org:Organization", "foaf:Person", "org:Site" ];

var dummyUris = [ "urn:overstory.co.uk:id:person:test1","urn:overstory.co.uk:id:person:test2","urn:overstory.co.uk:id:person:test3","urn:overstory.co.uk:id:person:test4","urn:overstory.co.uk:id:person:test5","urn:overstory.co.uk:id:person:test6" ]

var elementNameIdentifierPrefix = "urn:overstory.co.uk:id:rdf-element:";

//Back button
$(document).ready(function () {
    $('#back-btn').click(function () {
        parent.history.back();
        return false;
    });
});

//Copy to clipboard
$(document).ready(function () {
    var clip = new ZeroClipboard($("#copy_button"), {
        moviePath: "/web/js/ZeroClipboard.swf"
    });
});


//Top Left corner search
$("#search").click(function () {
    var terms = $('#search-input').val();
    var base = "/datamesh/record?terms="

    if ($('#inputSearchAll').prop('checked')){
    	var selectAll = "&search-all=true"
    	console.log("select-all=" + selectAll)
    	var fullUri = base + terms + selectAll
    } else {
   		var fullUri = base + terms
    }

    $(location).attr('href', fullUri);
});

//Add prefix functionality
$("#add-prefix").click(function () {
    var prefixName = $('#inputPrefix').val();
    var prefixUri = String($('#inputUri').val());

    var endpoint = "/datamesh/rdf/prefix/" + prefixName;

    $.ajax({
        url: endpoint,
        type: 'PUT',
        data: prefixUri,
        contentType: 'text/plain',
        success: function (result) {
        	location.reload();
        },
        error: function (xhr, ajaxOptions, thrownError) {
	        if (xhr.status == 409) {
	        	var prefixAlert = '<div class="alert alert-danger prefix-alert" role="alert">Prefix '+ prefixName +' already exists.</div>';
				$('.add-prefix-modal').append(prefixAlert);
	        }
	    }
    });
});

$("#boxclose").click(function(){
    $("#literals").css("display", "none");;
});

$(".button-diagram").click(function () {
    console.log("test button diagram");

    var identifier = $("#xml-edit-id").val();

    $.ajax({
        url: '/datamesh/rdf/triple/id/' + identifier,
        async:false,
        error: function() {
            console.log(identifier + " Not Found!")
        },
        success: function(data) {
            console.log("all good data is: ", data)
            buildDiagram (identifier, data)
        },
        type: 'GET'
    });

});


//Delete prefix functionality
$(".delete-prefix").click(function () {
    //window.confirm('Delete this record?')
    var prefixName = $(this).parent().prev().prev('.prefixname').children().text();
    var msg = "Are you sure you want to remove " + prefixName + " prefix?"
    var success = confirm(msg);

	var ETag = getPrefixETag(prefixName);

    if (success) {
        var endpoint = String("/datamesh/rdf/prefix/" + prefixName);

        $.ajax({
            url: endpoint,
            headers: {"ETag": ETag},
            type: 'DELETE',
            success: function (result) {
                location.reload();
            },
            error: function (xhr, ajaxOptions, thrownError) {
		        if (xhr.status == 409) {
		        	alert("409 - Conflict - ETag mismatch");
		        }
		    }
        });
    }

    //window.location.reload();
});

//Edit prefix functionality obsolete
$(".modify-prefix").click(function () {
    var prefixName = $(this).parent().prev().prev('.prefixname').children().text();
    var prefixUri = String($(this).parent().prev('.prefixuri').children().text());
    var endpoint = "/datamesh/rdf/prefix/" + prefixName;

    $('#editInputPrefix').val(prefixName);
    $('#editInputUri').val(prefixUri);

    /*,
    error: function (request, status, error) {
    console.log(request.responseText);
    }*/
});

//Edit prefix functionality
$("#edit-prefix").click(function () {

    var prefixName = $('#editInputPrefix').val();
    var prefixUri = String($('#editInputUri').val());
    var endpoint = "/datamesh/rdf/prefix/" + prefixName;

    var ETag = getPrefixETag(prefixName);

    $.ajax({
        url: endpoint,
        headers: {"ETag": ETag},
        type: 'PUT',
        data: prefixUri,
        contentType: 'text/plain',
        success: function (result) {
            location.reload();
        },
        error: function (xhr, ajaxOptions, thrownError) {
	        if (xhr.status == 409) {
	        	alert("409 - Conflict - ETag mismatch");
	        }
	    }
    });

    $('#editPrefixModal').modal('hide');
});

//Edit XML functionality
$("#xml-update-submit").click(function() {

    var recordId = $('#xml-edit-id').val();
    var xmlText = String($('#xml-edit-text').val());
    var recordType = String($('#xml-edit-record-type').val());
    var endpoint = "/datamesh/" + recordType + "/id/" + recordId;

    var ETag = getRecordETag(recordId);

	console.log(ETag)

    $.ajax({
        url: endpoint,
        type: 'PUT',
        headers: {"ETag": ETag},
        data: xmlText,
        contentType: 'application/xml',
        success: function (result) {
            location.reload();
        },
        error: function (jqXHR, textStatus, errorThrown) {
            alert ("AJAX call failed: status=" + textStatus + ", error=" + errorThrown);
        }
    });
});


//Load predicates into add property
$('#property-modal').click(function () {

    if ($('#inputPredicateProperty option').length == 0) {
        $.ajax({
        headers: {"Accept": "application/json"},
        url: '/datamesh/record/type/ost:RdfElementMap?search-all=true',
        type: 'GET',
        data: {'ipp':1000},
        success: function(data) {
            var html = '';
            var len = propertyPredicates.length;

            $.each(data.feed.entry, function(key, value) {
                var optionValue = value.content["osc:rdf-element-map"]["osc:rdf-type"].content;
                html += '<option value="' + optionValue + '">' + optionValue + '</option>';
            });
            $('#inputPredicateProperty').append(html);

            var nsInitialElementName = data.feed.entry[0].content["osc:rdf-element-map"]["osc:element-qname"].content;
            var initialRdfType = data.feed.entry[0].content["osc:rdf-element-map"]["osc:rdf-type"].content;
            var initialElementName = nsInitialElementName.split(':')[1];
            var initialElementLabel = data.feed.entry[0].content["osc:rdf-element-map"]["osc:label"].content;

            var initialElementIcon;
			if ( data.feed.entry[0].content["osc:rdf-element-map"]["osc:icon"] != undefined) {
            	initialElementIcon = data.feed.entry[0].content["osc:rdf-element-map"]["osc:icon"].content;
            } else {
            	initialElementIcon = "no-icon";
            }

            $('#inputElementNameProperty').val(initialElementName);
            $('#inputElementNameProperty').attr("disabled", true);
            $('#inputElementLabelProperty').val(initialElementLabel);
            $('#inputElementLabelProperty').attr("disabled", true);
            $('#inputElementIconProperty option[value="'+initialElementIcon+'"]').prop("selected", true);
            $('#inputElementIconProperty').attr("disabled", true);
        },
        error: function(e) {

        }
      });

    }
});

//On Select of inputPredicateProperty change value of Element Name
$('#inputPredicateProperty').on('change', function() {
	var rdfType = this.value;
	var identifier = elementNameIdentifierPrefix + rdfType;
	var record = getRecord(identifier,"application/json")
	var nsElementName = record["osc:rdf-element-map"]["osc:element-qname"].content;
	var elementName = nsElementName.split(':')[1];
	var elementLabel = record["osc:rdf-element-map"]["osc:label"].content;

	var elementIcon;
	if ( record["osc:rdf-element-map"]["osc:icon"] != undefined) {
	    elementIcon = record["osc:rdf-element-map"]["osc:icon"].content;
	} else {
	    elementIcon = "no-icon";
	}

	$('#inputElementIconProperty option[value="'+elementIcon+'"]').prop("selected", true);
	$('#inputElementNameProperty').val(elementName);
	$('#inputElementLabelProperty').val(elementLabel);
});

//Add simple property (text) functionality
$("#put-property").click(function () {
    $('.missing-alert').remove();
    $('.prefix-alert').remove();
    $('.triple-exists').remove();

    var subject = $(".subject-uri").text();
    var predicate;
    var description;

    //SELECT VALUES FOR PROPERTY
    if ($("#inputPredicateProperty").val()){
        predicate = $("#inputPredicateProperty option:selected").text();
    }
    //CUSTOM PROPERTY
    else if ($("#inputPredicateTextProperty").length)
    {
        //IF PROPERTY IS EMPTY THROW ERROR
        if ($("#inputPredicateTextProperty").val() == null || $("#inputPredicateTextProperty").val() == ''){
            var propertyAlert = '<div class="alert alert-danger prefix-alert" role="alert">Predicate must be provided, please correct the Predicate field.</div>';
            $('.add-property-form').append(propertyAlert);
        }
        //ELSE PREDICATE IS PROVIDED
        else {

            //VALIDATE PREFIX
            var prefix = $("#inputPredicateTextProperty").val().substr(0, $("#inputPredicateTextProperty").val().indexOf(':'));
            var prefixValidation = validatePrefix(prefix);

            //IF VALID PREFIX
            if (prefixValidation == true){

                //CHECK IF PROPERTY EXISTS
               var elementMapExists = rdfElementMapExists($("#inputPredicateTextProperty").val());

               //IF PROPERTY EXISTS
               if (elementMapExists == true){
                   var propertyAlert = '<div class="alert alert-danger prefix-alert" role="alert">Property '+ $("#inputPredicateTextProperty").val() +' already exists. Please use the default list to add this property.</div>';
                   $('.add-property-form').append(propertyAlert);
               }
               //IF PROPERTY DOES NOT EXIST
               else {
                   predicate = $("#inputPredicateTextProperty").val();
               }
           }

           //IF INVALID PREFIX
           else {
                var prefixAlert = '<div class="alert alert-danger prefix-alert" role="alert">Prefix '+ prefix +' could not be found, please try again.</div>';
                $('.add-property-form').append(prefixAlert);
           }

        }

    }

    if ($("#inputObjectProperty").val() == null || $("#inputObjectProperty").val() == '') {
        var objectAlert = '<div class="alert alert-danger prefix-alert" role="alert">Value must be provided, please correct the Value field.</div>';
        $('.add-property-form').append(objectAlert);
    }
    else if ($("#inputObjectProperty").val())
    {
        var object = $("#inputObjectProperty").val();
    }

    if (predicate != null && object != ""){

        if ($("#inputDescriptionProperty").val() == $("#inputObjectProperty").val()){
            description == '';
        }
        else {
            description = $("#inputDescriptionProperty").val();
        }

        var elementName = $('#inputElementNameProperty').val();
        var elementNamePrefixed;
        if (elementName == null || elementName == '') {
            elementNamePrefixed = "osc:property";
        }
        else {
            elementNamePrefixed = 'osc:'+elementName
        }

        var predicateValue;
        if ($("#inputPredicateProperty").val()){
        predicateValue = $("#inputPredicateProperty option:selected").text();
        } else {
            predicateValue = $("#inputPredicateTextProperty").val();
        }

        if ( $("#inputElementNameProperty").attr("disabled") != true && $("#inputElementLabelProperty").attr("disabled") != true ){
        	var elementLabel = $("#inputElementLabelProperty").val();
        	var elementIcon = $("#inputElementIconProperty").val();
       		//PUT ELEMENTNAME MAPPING
        	putElementNameMapping(predicateValue, elementNamePrefixed, elementLabel, elementIcon);
        }

        //PUT TRIPLE
        var response = putTriple(subject,predicate,object,description);
        if (response == true) {
        	location.reload();
        } else {
        	var tripleExistsAlert = '<div class="alert alert-danger triple-exists" role="alert">Provided triple already exists.</div>';
        	$('.add-property-form').append(tripleExistsAlert);
        }
    }

});

//Add RDF type

$("#type-modal").click(function () {
	/*var inputKnownTypes = $("#inputKnownTypes").text();
	var customRdfType = $("#inputCustomRdfType").text();*/
	console.log("hey type modal")
	//Populate select input
    if ($('#inputKnownTypes option').length == 0) {
    	console.log("hey inside")
        $.ajax({
        url: '/datamesh/rdf/record/type?ipp=200',
        type: 'GET',
        dataType: 'json',
	    accepts: {
	        json: 'application/json',
	        text: 'text/plain'
	    },
        success: function(data) {
            var html = '';

            $.each(data.feed.entry, function(key, value) {
                var optionValue = value["osc:type-curie"];

                html += '<option value="' + optionValue + '">' + optionValue + '</option>';
            });
            $('#inputKnownTypes').append(html);

        },
        error: function(e) {
        }
      });

    }

    //$('#inputKnownTypes').append(html);

	//console.log("known types json: ", knownTypes);
});

$(document).on('click', "#btnCustomRdfType", function() {
	$('.prefix-alert').remove();
	$('.exists-alert').remove();
	console.log("switch to custom types")
    $('.known-types').remove();
    var html = '<div class="form-group custom-types"><label for="inputCustomRdfType" class="col-sm-2 control-label">Custom RDF Type</label><div class="col-sm-8"><input type="input" class="form-control element-name-property" id="inputCustomRdfType" placeholder="RDF Type..."></input><button type="button" class="btn btn-success known-rdf-type" id="btnKnownRdfType">Known RDF Types</button></div></div>'
    $('.add-rdf-type-form').append(html);
});

$(document).on('click', "#btnKnownRdfType", function() {
	$('.prefix-alert').remove();
	$('.exists-alert').remove();
    console.log("switch to known types")
    $('.custom-types').remove();
    var html = '<div class="form-group known-types"><label for="inputKnownTypes" class="col-sm-2 control-label">Known Types</label><div class="col-sm-8 predicate-container" id="divKnownTypes"><select class="form-control" id="inputKnownTypes" placeholder="Types..."></select><button type="button" class="btn btn-success custom-rdf-type" id="btnCustomRdfType">Custom RDF Type</button></div></div>'
    $('.add-rdf-type-form').append(html);

    if ($('#inputKnownTypes option').length == 0) {
    	console.log("hey inside")
        $.ajax({
        url: '/datamesh/rdf/record/type?ipp=200',
        type: 'GET',
        dataType: 'json',
	    accepts: {
	        json: 'application/json',
	        text: 'text/plain'
	    },
        success: function(data) {
            var html = '';

            $.each(data.feed.entry, function(key, value) {
                var optionValue = value["osc:type-curie"];

                html += '<option value="' + optionValue + '">' + optionValue + '</option>';
            });
            $('#inputKnownTypes').append(html);

        },
        error: function(e) {
        }
      });
    }
});

//PUT RDF Type into record
$(".put-rdf-type").click(function () {
	console.log("PUT RDF TYPE")

	$('.prefix-alert').remove();
	$('.exists-alert').remove();

	var rdfType;

	if ($('#inputCustomRdfType').val()){
		console.log("there is a value for custom type")
		rdfType = $('#inputCustomRdfType').val();

	} else {
		console.log("there is a value for known type")
		rdfType = $( "#inputKnownTypes option:selected" ).text();
	}

	var prefix = rdfType.substr(0, rdfType.indexOf(':'));
    var prefixValidation = validatePrefix(prefix);

    //IF VALID PREFIX
    if (prefixValidation == true){

    	var subject = $(".subject-uri").text();
    	var predicate = "rdf:type"
    	var object = rdfType

		var responsePut = putTriple(subject,predicate,object,"");

		if (responsePut == true)
		{
			location.reload();
		} else {
			var existsAlert = '<div class="alert alert-danger exists-alert" role="alert">RDF Type '+ rdfType +' already exists for this record.</div>';
        	$('.add-rdf-type-form').append(existsAlert);
		}

    	console.log("subject ", subject);


    } else {
        var prefixAlert = '<div class="alert alert-danger prefix-alert" role="alert">Prefix '+ prefix +' could not be found, please try again.</div>';
        $('.add-rdf-type-form').append(prefixAlert);
   }

	console.log("selected rdf type is: ", rdfType)

});


//Remove triple
$(".delete-triple").click(function () {
    var endpoint = "/datamesh/rdf/triple";
    var subject = $(".subject-uri").text();
    var predicate = $(this).parent().prev().prev().attr('property');
    var object = $(this).parent().prev().attr('object');

    var msg = "Are you sure you want to remove triple " + subject + " - " + predicate + " - " + object + "?";
    var success = confirm(msg);

    if (success) {
        $.ajax({
            url: endpoint+"?subject="+subject+"&predicate="+predicate+"&object="+object,
            type: 'DELETE',
            /*data: { "subject": subject, "predicate": predicate, "object": object },*/
            success: function (result) {
                location.reload();
            }
        });
    }
});

//Modify triple load modal
$(".modify-triple").click(function () {
	$('.edit-property-description-group').remove();
	var subject = $(".subject-uri").text();
	var predicate = $(this).parent().prev().prev().attr('property');
	var object = $(this).parent().prev().attr('object');
	var description = $(this).parent().prev().attr('description');

	$("#inputSubject").val(subject);
	$("#inputPredicate").val(predicate);
	$("#inputObject").val(object);
	$("#inputInitialObject").val(object);

	if (description) {
		var descriptionInput = '<div class="form-group edit-property-description-group">'
								+'<label for="inputDescription" class="col-sm-2 control-label">Description</label>'
									+'<div class="col-sm-8">'
									+'	<input type="input" class="form-control edit-property-description" id="inputDescription" value="' + description + '"></input>'
									+'</div>'
								+'</div>';
		$('.edit-property-form').append(descriptionInput);
	}
});

//Modify triple - PUT
$(".put-edit-property").click(function () {
	var subject = $("#inputSubject").val();
	var predicate = $("#inputPredicate").val();
	var initialObject = $("#inputInitialObject").val();
	var object = $("#inputObject").val();
	var description = $("#inputDescription").val();

	//Delete old triple
	var responseDelete = deleteTriple(subject,predicate,initialObject)

	//Add new triple
	var responsePut = putTriple(subject,predicate,object,description);

	if (responsePut == true)
	{
		location.reload();
	}

});


//Custom Predicate
$('#btnCustomPredicateProperty').click(function () {
    $('#inputPredicateProperty').remove();
    $('#btnCustomPredicateProperty').remove();
    $('#divPredicateContainerProperty').append('<input type="input" class="form-control predicate-property" id="inputPredicateTextProperty" placeholder="Predicate..."></input>');
    $('#inputElementNameProperty').val('');
    $('#inputElementNameProperty').attr("disabled", false);
    $('#inputElementLabelProperty').val('');
    $('#inputElementLabelProperty').attr("disabled", false);
    $('#inputElementIconProperty option[value="no-icon"]').prop("selected", true);
    $('#inputElementIconProperty').attr("disabled", false);
});

//Copy text from Value to Description on typing or PASTE
$("#inputObjectProperty").bind('input', function () {
    var stt = $(this).val();
    $("#inputDescriptionProperty").val(stt);
});

//Enter on search
$('#search-input').keypress(function (e) {
    if (e.which == 13) {
        $('#search').click();
        return false; //<---- Add this line
    }
});


//Toggle XML show/hide section
$(".xml-content").hide();
$(".show_hide").show();

$('.show_hide').click(function () {
    $(".xml-content").slideToggle();
});

//Toggle XML Edit show/hide section
$(".edit-xml-content").hide();
$(".edit-show_hide").show();

$('.edit-show_hide').click(function () {
    $(".edit-xml-content").slideToggle();
});

//Load predicates and resource types into add resource reference
$('.add-resource').click(function () {
    if ($('#inputResourceType option').length == 0) {
        var html = '';
        var len = resourceTypes.length;
        for (var i = 0; i < len; i++) {
            html += '<option value="' + resourceTypes[i] + '">' + resourceTypes[i] + '</option>';
        }
        $('#inputResourceType').append(html);
    }
    if ($('.resource-predicate option').length == 0) {
        var html = '';
        var len = propertyPredicates.length;
        for (var i = 0; i < len; i++) {
            html += '<option value="' + propertyPredicates[i] + '">' + propertyPredicates[i] + '</option>';
        }
        $('.resource-predicate').append(html);
    }
});

//On Click call NK to get a list of resources of a selected type
$('.btn-resource').click(function () {
    var resourceType = $( ".resource-type option:selected" ).text();
    var endpoint = "/datamesh/record"

    $.ajax({
        url: endpoint,
        type: 'GET',
        data: {'ipp':100, 'type':resourceType},
        success: function(data) {

          var selectHtml = '<select multiple="" class="form-control resource-list"></select>';
          $(".display-resources").append(selectHtml);

          //todo: get all ids from the json response from NK
          var html = '';
          var len = dummyUris.length;
          for (var i = 0; i < len; i++) {
            html += '<option value="' + dummyUris[i] + '">' + dummyUris[i] + '</option>';
          }
          $('.resource-list').append(html);

        },
        error: function(e) {
          //called when there is an error
        }
      });

});

//Submit resource ref to NK
/*$('#put-resource').click(function () {
    var subject = "?subject="+$(".subject-uri").text();
    var predicate = "&predicate="+$( "#inputPredicateResource option:selected" ).text();
    var object = "&object="+$( ".resource-list option:selected" ).text();

    putTriple(subject,predicate,object);

});*/

$('.edit-xml').click(function () {
    $('#xml-edit-text').autoResize();
});



//ADD RECORD
$('.add-record-btn').click(function () {
    $('#add-record-xml').autoResize();
    $('#add-record-xml').css({"width":"100%","height":"100px"});
});

$('#put-record').click(function () {
    var identifier = $('#inputIdentifier').val();
    var xml = $('#add-record-xml').val();
    var endpoint = '/datamesh/record/id/'+identifier;

    var badIdentifier = '<div class="alert alert-danger bad-identifier" role="alert">Please provide correct identifier</div>';
    var notMatchingIdentifier = '<div class="alert alert-danger identifier-mismatch-alert" role="alert">Provided identifier and the identifier in the XML do not match.</div>';
    var xmlIdentifierError = '<div class="alert alert-danger identifier-xml-error-alert" role="alert">Identifiers in provided XML record do not match (osc:uri and @about).</div>';
    var badXml = '<div class="alert alert-danger xml-body-alert" role="alert">Please provide correct XML body</div>';
    var success = '<div class="alert alert-success put-record-success" role="alert">Success! Record Created.</div>';
    var recordExists = '<div class="alert alert-danger record-exists" role="alert">Record ' + identifier + ' already exists.</div>';

    $(".bad-identifier").remove();
    $(".identifier-mismatch-alert").remove();
    $(".identifier-xml-error-alert").remove();
    $(".xml-body-alert").remove();
    $(".put-record-success").remove();
    $(".record-exists").remove();

    if (identifier == null || identifier == ''){
        $('.body-add-record').append(badIdentifier);
    } else if (xml == null || xml == '') {
        $('.body-add-record').append(badXml);
    } else {

        function nsResolver(prefix) {
            switch (prefix) {
                case 'osc':
                    return 'http://ns.overstory.co.uk/namespaces/datamesh/content';
            }
        }

        var identifierInOscUri = document.evaluate('//osc:uri', jQuery.parseXML(xml), nsResolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null ).singleNodeValue.innerHTML;
        var identifierInAbout = document.evaluate('/*/@about', jQuery.parseXML(xml), nsResolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null ).singleNodeValue.value;

        if (identifierInOscUri != identifierInAbout) {
            $('.body-add-record').append(xmlIdentifierError);
        } else if (identifierInOscUri != identifier) {
            $('.body-add-record').append(notMatchingIdentifier)
        } else {
            $.ajax({
                url: endpoint,
                type: 'PUT',
                contentType: 'application/xml',
                data: String(xml),
                success: function (result) {
                    $('.body-add-record').append(success);
                },
                error: function (xhr, ajaxOptions, thrownError) {
			        if (xhr.status == 409) {
			        	$('.body-add-record').append(recordExists);
			        }
			    }
            });
        }

    }

});



/* FUNCTIONS */

//PUT TRIPLE
var putTriple = function(subject, predicate, object, description) {
    var endpoint = "/datamesh/rdf/triple";
	var response;
    /*console.log("subject: ", subject);
    console.log("predicate: ", predicate);
    console.log("object: ", object);
    console.log("description: ", description);*/

    var url;

    if (description == null){
        url = endpoint + "?subject=" + subject + "&predicate=" + predicate + "&object=" + object;
    }
    else {
        url = endpoint + "?subject=" + subject + "&predicate=" + predicate + "&object=" + object + "&description=" + description;
    }

    $.ajax({
        url: url,
        type: 'PUT',
        async: false,
        success: function (result) {
            response=true;
            //todo: add response msg
        },
        error: function (xhr) {
        	if (xhr.status==409){
                response=false;
            }
        }
    });
    return response;
};

var deleteTriple = function(subject,predicate,object) {
	var endpoint = "/datamesh/rdf/triple";
	var response;

	$.ajax({
        url: endpoint+"?subject=" + subject + "&predicate=" + predicate + "&object=" + object,
        type: 'DELETE',
        async: false,
        success: function (result) {
            response=true;
            //todo: add response msg
        },
        error: function (xhr) {
            response=false;
        }
    });
    return response
};


//PUT ELEMENT NAME MAPPING
var putElementNameMapping = function(predicate, elementName, elementLabel, elementIcon){
    var identifier = 'urn:overstory.co.uk:id:rdf-element:' + predicate;
    var endpoint = '/datamesh/record/id/' + identifier;
    var label;
    var icon;

    if (elementLabel != ''){
    	label = "<osc:label property='ost:label'>"+elementLabel+"</osc:label>"
    } else {
    	label = "";
    }
    if (elementIcon != '' && elementIcon != 'no-icon'){
    	icon = "<osc:icon property='ost:icon'>"+elementIcon+"</osc:icon>"
    } else {
    	icon = "";
    }

    var recordXml =
    '<osc:rdf-element-map prefix="ost: http://rdf.overstory.co.uk/rdf/terms/ foaf: http://xmlns.com/foaf/0.1/ dc: http://purl.org/dc/terms/" typeof="ost:RdfElementMap" about="' + identifier + '" xmlns:osc="http://ns.overstory.co.uk/namespaces/datamesh/content">'
       + '<osc:uri property="dc:identifier osc:uri">' + identifier + '</osc:uri>'
       + '<osc:rdf-type property="ost:rdfType">' + predicate + '</osc:rdf-type>'
       + '<osc:element-qname property="ost:elementQName">' + elementName + '</osc:element-qname>'
       + label
       + icon
       + '<osc:properties>'
       +    '<osc:searchable property="ost:searchable">false</osc:searchable>'
       + '</osc:properties>'
  + '</osc:rdf-element-map>';

    $.ajax({
        url: endpoint,
        type: 'PUT',
        contentType: 'application/xml',
        data: String(recordXml),
        success: function (result) {
            //console.log('element name added');
        },
        error: function (){
        	//409 should never happen because of the JS form validation
        }
    });

};

//GET RECORD BY ID
var getRecord = function(id, contentType) {
    var endpoint = "/datamesh/record/id/"+id;
    var resp;
    $.ajax({
        headers: {"Accept": contentType},
        url: endpoint,
        type: 'GET',
        async: false,
        success: function(data) {
            resp=data;
        }
    });
    return resp;
};

//VALIDATE PREFIX
var validatePrefix = function(prefix) {
  var response;
  var endpoint = "/datamesh/rdf/prefix/"+prefix;
  $.ajax({
        url: endpoint,
        type: 'GET',
        async: false,
        success: function(data) {
            response=true;
        },
        error: function(xhr, ajaxOptions, thrownError) {
            if (xhr.status==404){
                response=false;
            }
        }
    });
    return response;
};

//GET TYPES
var getRDFTypes = function() {
    var endpoint = "/datamesh/rdf/record/type?ipp=1000";
    var resp;
    $.ajax({
        headers: {"Accept": "application/json"},
        url: endpoint,
        type: 'GET',
        async: false,
        success: function(data) {
            resp=data;
        }
    });
    return resp;
};

var rdfElementMapExists = function(property) {
    var response;
    var identifier = "urn:overstory.co.uk:id:rdf-element:" + property;
    var endpoint = "/datamesh/record/id/" + identifier;

    $.ajax({
        url: endpoint,
        type: 'GET',
        async: false,
        success: function(data) {
            response=true;
        },
        error: function(xhr, ajaxOptions, thrownError) {
            if (xhr.status==404){
                response=false;
            }
        }
    });
    return response;
};

var getRecordETag = function(id) {
	var ETag;
	var endpoint = "/datamesh/record/id/" + id

	$.ajax({
        url: endpoint,
        async: false,
        type: 'GET',
        success: function(data, status, xhr) {
        	ETag = xhr.getResponseHeader("ETag");
        }
    });

    return ETag;
};

var getPrefixETag = function(prefix) {
	var ETag;
	var endpoint = "/datamesh/rdf/prefix/" + prefix

	$.ajax({
        url: endpoint,
        async: false,
        type: 'GET',
        success: function(data, status, xhr) {
        	ETag = xhr.getResponseHeader("ETag");
        }
    });

    return ETag;
};














