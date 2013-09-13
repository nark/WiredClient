
/*  Copyright (c) 2013 Read-Write.fr. All rights reserved.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


/*
 * README
 * ======
 *
 * This script is powered by an Objective-C controller that provides
 * a data source interface to let JS access to objects shared by the
 * application. 
 * 
 * The data source API mainly returns JSON string representations of
 * Cocoa objects. The following functions are available from this script:
 *
 *		## return the number of objects in the data source
 * 		integer 		numberOfObjects();
 *
 *		## return all data source objects as an array of JSON strings
 * 		array			JSONObjects();
 *		
 *		## return paged data source objects as an array of JSON strings
 *		array			JSONObjectsFromOffsetWithLimit(integer offset, integer limit);
 *
 *		## return one data source object as a JSON string
 *		string 			JSONObjectAtIndex(integer index);
 *
 */


/***************
 * GLOBALS
 ***************/
var PAGE_SIZE 		= 10;

var PAGE_OFFSET 	= 0;
var PAGE_LIMIT 		= 0;


/***************
 * PUBLIC API 
 * 
 * Functions described here are public and designed to be called by
 * Objective-C controllers in order to update the view, passing data 
 * and settings.
 ***************/

/* Print a message in JSON format. Usualy called by Objective-C to append
 * a new message to the view. (DO NOT REMOVE THIS FUNCTON !!!) */
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
	// format the message object to a HTML string
	var html = _formatMessageAsHTHML(message);

	// append element to wrapper element
	$('#messages-content').append(html);
}


/* Prepend a message object to the DOM */
function _prependMessage(message) {
	// format the message object to a HTML string
	var html = _formatMessageAsHTHML(message);

	// append element to wrapper element
	$('#messages-content').prepend(html);
}


/* Format a message object to a HTML string  */
function _formatMessageAsHTHML(message) {
	// CSS class that defines if message is "from" or "to"
	var directionClass = (message["direction"] == 0) ? 
								  "from" : 
								  "to";
	// date formatting
	var date 	= timeAgo(message["date"]).tAgo;
	var server 	= (typeof message["server"] === 'undefined') ? "Not Connected" : message["server"];

	// return a HTML string
	return '<div class="messagewrapper">' +
		'<div class="message ' + directionClass + '">' +
			'<div class="messageheader">' +
				'<div class="icon">' +
					'<img src="data:image/tiff;base64,' + message["icon"] + '" width="32" height="32" alt="" />' +
				'</div>' +
				'<div class="messageinfo">' +
					'<span class="nick">' + message["nick"] + '</span>' +
					'<span class="time">' + date + '</span>' +
					'<span class="server">' + server + '</span>' +
					'<img src="data:image/tiff;base64,' + message["unread"] + '" />' +
				'</div>' +
			'</div>' +
			'<div class="messagebody">' +
				'<div class="messagecontent">' + message["message"] + '</div>' +
			'</div>' +
		'</div>' +
	'</div>';
}


/* Scroll to the bottom of the HTML document */
function _scrollToBottom() {
	window.scrollTo(0,document.body.scrollHeight);
}



/***************
 * WINDOW 
 ***************/

$(window).scroll(function() {
	if($(window).height() < $(document).height() && $(window).scrollTop() == 0) {
	    var controller 			= window.Controller;
	    var numberOfMessages	= controller.numberOfObjects();
	    var oldHeight			= document.body.scrollHeight;

	    if(PAGE_OFFSET == 0 && PAGE_LIMIT == 0)
	    	return;

		PAGE_OFFSET	= (PAGE_OFFSET < PAGE_SIZE) ? 0 : (PAGE_OFFSET - PAGE_SIZE);
		PAGE_LIMIT 	= (PAGE_OFFSET - PAGE_SIZE < 0) ? 
						 PAGE_SIZE - (PAGE_SIZE - PAGE_OFFSET) : 
						 ((numberOfMessages > PAGE_SIZE) ? PAGE_SIZE : numberOfMessages);

		console.log(PAGE_OFFSET, "PAGE_OFFSET");
		console.log(PAGE_LIMIT, "PAGE_LIMIT");

	    var messages			= eval(controller.JSONObjectsFromOffsetWithLimit(PAGE_OFFSET, PAGE_LIMIT)); // test offset & limit

	    $('#messages-content').prepend('<div class="messagestatus">'+PAGE_OFFSET+','+PAGE_LIMIT+'</div>');

	    // prepend all messages to the view
		for (var i in messages) {
			_prependMessage(messages[i]);
		}
		var newHeight 			= document.body.scrollHeight;
		window.scrollTo(0,(newHeight-oldHeight));
	}
});





/***************
 * DOCUMENT 
 ***************/

/* Ready? ... Go! */
$(document).ready(function(){
	// find messages from Obj-C controller (window.Controller)
    var controller			= window.Controller;
    var numberOfMessages	= controller.numberOfObjects();
   	PAGE_OFFSET 			= (numberOfMessages > PAGE_SIZE) ? (numberOfMessages - PAGE_SIZE) : 0;
   	PAGE_LIMIT				= (numberOfMessages > PAGE_SIZE) ? PAGE_SIZE : numberOfMessages;
	var messages 			= eval(controller.JSONObjectsFromOffsetWithLimit(PAGE_OFFSET, PAGE_LIMIT));

    // append all messages to the view
	for (var i in messages) {
		_appendMessage(messages[i]);
	}

	// and scroll to bottom of the view
	_scrollToBottom();
});


window.onload = function() {
	// load all images on queue
	// var imgs 	= $("img");

	// imgs.each(index, function() {
	// 	var src 		= imgs[index].attr('rel');
	// 	var image 		= new Image();
	// 	image.onload 	= function() {
	// 		_scrollToBottom();
	// 	};
	// 	image.src 		= src;
	// });
};


/* %99$ bottle$... */