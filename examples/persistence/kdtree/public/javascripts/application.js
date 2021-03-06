var map;
var marker;
var infoWindow;

// Fits the canvas to the page
function fitMapCanvas() {
  $("#map_canvas").height($(window).height() - $("#map_menu").height() - $("#footer").height() - 50);
}

function initialize() {
  // Auto-select results count on focus
  $("#num_results").focus(function() {
    this.select();
  });

  // Bind handler to the go-to-zip button
  $("#zip_jump_button").click(function() {
    requestLocation( $("#zip_jump").val() );
  });
  
  // Resize the map canvas on window resize
  $(window).resize(fitMapCanvas);
  fitMapCanvas();

  // let's set the initial location of the map.
  var latLng = new google.maps.LatLng( 41.6326327769545, -100.1024599609375 );

  // create a Map instance.
  map = new google.maps.Map( document.getElementById( 'map_canvas' ), {
    zoom: 5,
    center: latLng,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  });

  // register a click event handler with our Map instance.
  google.maps.event.addListener( map, 'click', function(event) {
    searchZips(event.latLng.lat(), event.latLng.lng());
    return false;
  });
}

function searchZips(lat, lng) {
  // Remove the previous window so the user knows something is about to happen. 
  removeInfoWindow( );
  
  // remove the marker from the map if it exists.
  if ( marker != null ) {
    marker.setMap(null);
  }

  // create a new marker and place it on the map 
  // of the clicked location.
  placeMarker( new google.maps.LatLng( lat, lng ) ); 
  
  // show our current location
  $("#location_display").text("Location: " + lat + ", " + lng);
        
  // post an Ajax request to the server.
  requestNearest( );
}

// Makes a request for all that is closest
// the marker and displays it.
function requestNearest( ) {
  // get the values for the parameter hash.
  var markerLocation = marker.getPosition();
  var latitudeS = markerLocation.lat();
  var longitudeS = markerLocation.lng();

  // determine how many results the user wanted (modifying the text box if there's invalid input)
  var k_results = $.trim($("#num_results").val());
  var isNumber = /^\d+$/.test(k_results);
  var numValid = k_results > 1;
  if( !isNumber || !numValid ) {
    k_results = 5; // Default to this many results if input not valid
  }

  $("#num_results").val(k_results);

  // create a parameter hash.
  var params = { lat: latitudeS, lon: longitudeS, k: k_results };

  // do not let the user (or the map click handler firing spuriously) click again until we resolve the request
  disableClick = true;

  // dispatch request
  postAjaxRequest("nearest", params, function( locations ) {
    // create a new info window, open it, and extend 
    // it from the current marker on the map.
    attachInfoWindow( marker, 0, locations );
  }, 
  function() {
    // let the user click again
    disableClick = false;
  });
}

function requestLocation( zipCode ) {
  postAjaxRequest("zip_to_pos", { zip: zipCode }, function( results ) {
    if( results.length == 0 ) {
      // No such ZIP
      alert('Could not find Zip code -- sorry!');
    } else {
      // Found it!
      searchZips(results[0].latitude, results[0].longitude);
    }
  });
}

function postAjaxRequest( apiMethod, params, successCallback, alwaysExecutedCallback ) {
  host = location.hostname;
  port = location.port;
  serviceUrl = "http://" + host + ":" + port + "/" + apiMethod;

  // initiate an Ajax request to the server and store the response in 'result'.
  $.ajax({
    url: serviceUrl,
    type: 'POST',
    dataType: 'json',
    data: params,
    success: function(results) { 
      successCallback(results);
      if(alwaysExecutedCallback)
        alwaysExecutedCallback();
    },

    error: function( xhr, txtStatus ) {
      alert( "Something went wrong during API request to '/"+apiMethod+"'!  "
        + "This may be a cross-site request failure due to your browser's security policy.  "
        + "Check that the address " + host + " agrees with what is in your browser's URL bar.  "
        + "\n========\n"
        + "Details:\n" 
        + "XMLHttpRequest status: " + xhr.status + "\n"
        + "Status: " + txtStatus );
        
        alwaysExecutedCallback();
    }

  });

}

function placeMarker(location) {

  var clickedLocation = new google.maps.LatLng(location);
  marker = new google.maps.Marker({
      position: location, 
      map: map
    });

  map.setCenter(location);
  
}

// This will remove the info window if it is currently present.
function removeInfoWindow() {
  // remove the info window
  if ( infoWindow != null ) {
    infoWindow.close();    
  }
}

// Called when a zip link is clicked
function zipLinkCallback(e, lat, lng) {
  e = e || window.event; // Just in case the event comes out null (shouldn't happen)
  
  // Do the new zips search for the desired location
  searchZips(lat, lng);
  
  // Stop the event from bubbling upward in to the map (http://www.quirksmode.org/js/events_order.html)
  e.cancelBubble = true;
}

function attachInfoWindow( marker, number, locations ) {
  // By trying to remove the window again just before display, we 
  // can guarantee we won't get any leftover popups if a user (...or bug)
  // manages to fire off two queries very close together.
  removeInfoWindow();

  var markerLocation = marker.getPosition();
  var latitude = markerLocation.lat();
  var longitude = markerLocation.lng();
  
  var html  = '<div id="info_window">';
      html += '  <table class="results"> <thead> <th>ZIP</th> <th>City</th>  <th>State</th>  <th>Distance</th> </thead>';
      html += '  <tbody>';
  
  for(var idx in locations) {  
    var loc = locations[idx];
    
    // First row <td>s are 'first', after that it's 'other'; used to highlight first result
    var tdTag = '<td class="' + ( (idx == 0) ? 'first' : 'other' ) + '">'; 
    
    // Generate a zip code link they can click
    var zipCodeHtml;
    if(loc['miles'] > 0.000001)
      zipCodeHtml = '<a href="#'+loc['zipcode']+'" onclick="zipLinkCallback(event, '+loc['latitude']+', '+loc['longitude']+')">' + htmlEncode(loc['zipcode']) + '</a>';      
    else // Don't link to zip codes we're right on top of 
      zipCodeHtml = htmlEncode(loc['zipcode']);    

    html += "<tr>";
    html += tdTag + zipCodeHtml                                   + "</td>";
    html += tdTag + htmlEncode(loc['city'])                       + "</td>";
    html += tdTag + htmlEncode(loc['state'])                      + "</td>";
    html += tdTag + htmlEncode(loc['miles'].toFixed(1) + " mi")   + "</td>";
    html += "</tr>"
  }
  
  html += "</tbody> </table>";

  infoWindow = new google.maps.InfoWindow( { content: html, zIndex: number } );
  infoWindow.open( map, marker );
}

function htmlEncode(value){ 
  // http://stackoverflow.com/questions/1219860/javascript-jquery-html-encoding
  return $('<div/>').text(value+"").html(); 
} 

$(document).ready(function() {
  initialize();
});


