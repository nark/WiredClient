
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
var PAGE_SIZE 			= 20;

var PAGE_OFFSET 		= 0;
var PAGE_LIMIT 			= 0;
var OLD_MESSAGE_DATE 	= null;


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

function printEvent(json) {
	var event = eval(json);

	// TODO: handle error properly
	if(!event)
		return;

	// Append the event to the DOM and scroll to bottom of the view
	_appendEvent(event);
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
	$('#chat-content').append(html);

	$('img').load(function() {
	    _scrollToBottom();
	});
}

function _appendEvent(event) {
	// format the event object to a HTML string
	var html = _formatEventAsHTHML(event);

	// append element to wrapper element
	$('#chat-content').append(html);

	$('img').load(function() {
	    _scrollToBottom();
	});
}

/* Format a message object to a HTML string  */
function _formatMessageAsHTHML(message) {
	var separator = (!message["action"]) ? ": " : " ";

	return  '<div class="chat-message">' +
            	'<span class="timestamp">' + message["timestamp"] + '</span>' +
            	'<span class="nick">' + message["nick"] + '</span>' +
            	'<span class="separator">' + separator + '</span>' +
            	'<span class="message">' + message["message"] + '</span>' +
			'<div>';
}

function _formatEventAsHTHML(event) {
	return  '<div class="chat-event">' +
				'<span class="timestamp">' + event["timestamp"] + '</span>' +
				'<span class="message">' + event["message"] + '</span>' +
			'</div>';
}

function _formatDateAsHTML() {
	$('#messages-content').prepend('<div class="messagestatus">'+timeAgo(OLD_MESSAGE_DATE).tAgo+'</div>');
}


/* Scroll to the bottom of the HTML document */
function _scrollToBottom() {
	window.scrollTo(0,document.body.scrollHeight);
}





/***************
 * WINDOW 
 ***************/

$(window).scroll(function() {
//	if($(window).height() < $(document).height() && $(window).scrollTop() == 0) {
//		_addPage();	
//	}
});





/***************
 * DOCUMENT 
 ***************/

/* Ready? ... Go! */
$(document).ready(function(){
	$('img').load(function() {
		console.log("image finish loading");
	    _scrollToBottom();
	});
});



/* %99$ bottle$... */