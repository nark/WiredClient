
/***************
 * PUBLIC API 
 * 
 * Functions described here are public and designed to be called by
 * Objective-C controllers in order to update the view, passing data 
 * and settings.
 ***************/

/* Print a message in JSON format. Usualy called by Objective-C to append
 * a new message to the view. */
function printMessage(json) {
	var message = eval(json);

	// TODO: handle error properly
	if(!message)
		return;

	// Append the message to the DOM and scroll to bottom of the view
	_appendMessage(message);
	_scrollToBottom();
}



/***************
 * PRIVATE API 
 ***************/

/* Append a message object to the DOM */
function _appendMessage(message) {
	var directionClass = (message["direction"] == 0) ? 
								  "from" : 
								  "to";

	var date = new Date(message["date"]);

	var html = 
	'<div class="messagewrapper">' +
		'<div class="message ' + directionClass + '">' +
			'<div class="messageheader">' +
				'<div class="icon">' +
					'<img src="data:image/tiff;base64,' + message["icon"] + '" width="32" height="32" alt="" />' +
				'</div>' +
				'<div class="messageinfo">' +
					'<span class="nick">' + message["nick"] + '</span>' +
					'<span class="time">' + date + '</span>' +
					'<span class="server">' + message["server"] + '</span>' +
				'</div>' +
			'</div>' +
			'<div class="messagebody">' +
				'<div class="messagecontent">' + message["message"] + '</div>' +
			'</div>' +
		'</div>' +
	'</div>';

	$('#messages-content').append(html);
}

/* Scroll to the bottom of the HTML document */
function _scrollToBottom() {
	window.scrollTo(0,document.body.scrollHeight);
}




/***************
 * DOCUMENT 
 ***************/

/* Ready? ... Go! */
$(document).ready(function(){
	// find messages from Obj-C controller (window.Conversation)
    var conversation 		= window.Conversation;
    var messages			= eval(conversation.JSONMessages());

    // append all messages to the view
	for (var i in messages) {
		_appendMessage(messages[i]);
	}
	// and scroll to bottom of the view
	_scrollToBottom();
});

/* %99$ bottle$... */