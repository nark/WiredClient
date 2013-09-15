
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
				'</div>' +
			'</div>' +
			'<div class="messagebody">' +
				'<div class="messagecontent">' + message["message"] + '</div>' +
			'</div>' +
		'</div>' +
	'</div>';
}

function _formatDateAsHTML() {
	$('#messages-content').prepend('<div class="messagestatus">'+timeAgo(OLD_MESSAGE_DATE).tAgo+'</div>');
}


/* Scroll to the bottom of the HTML document */
function _scrollToBottom() {
	window.scrollTo(0,document.body.scrollHeight);
}

function _addPage(bFirst) {

	bFirst = (typeof bFirst != 'boolean' ? false : bFirst );

	var controller		= window.Controller;
	var messages 		= eval(controller.JSONObjectsUntilDateWithLimit(OLD_MESSAGE_DATE, PAGE_SIZE));
	var messagesLength 	= messages.length;

	if(!bFirst) {
		var oldHeight		= document.body.scrollHeight;
		var newHeight 		= 0;

		if(messagesLength > 0) {
			_formatDateAsHTML();
		}
	}
    
   

     // append all messages to the view
	for (var i in messages) {
		_prependMessage(messages[i]);

		if(i == messagesLength - 1) {
			OLD_MESSAGE_DATE = messages[i].date;
		}
	}



	if(bFirst) {
		// and scroll to bottom of the view
		_scrollToBottom();
	} else {
		newHeight 			= document.body.scrollHeight;
		window.scrollTo(0,(newHeight-oldHeight));
	}


}

function _appendLoader() {
	$('body').prepend($('<div>', {'class': 'loaderWrapper'}));
	_animeLoaderToBottom();
}

function _animeLoaderToBottom() {
	$('div.loaderWrapper').animate({
		top: 0
	}, 500, function() {
		setTimeout(function() {
			_animateLoaderToTop();
		}, 500);
	});
}

function _animateLoaderToTop() {
	$('div.loaderWrapper').animate({
		top: '-50px'
	}, 500, function() {
		_addPage();
		removeLoader();
	});
}

function removeLoader() {
	//$('div.loaderWrapper').remove();
}



/***************
 * WINDOW 
 ***************/

$(window).scroll(function() {
	if($(window).height() < $(document).height() && $(window).scrollTop() == 0) {
		_appendLoader();	
	}
});





/***************
 * DOCUMENT 
 ***************/

/* Ready? ... Go! */
$(document).ready(function(){

	if(!window.Controller.loadScriptWithName("tweenjs")) {
		console.log("Error loading script: tweenjs");
	}

	_addPage(true);
});



/* %99$ bottle$... */