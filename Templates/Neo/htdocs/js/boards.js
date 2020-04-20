
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
function printPost(json) {
	var post = eval(json);

	// TODO: handle error properly
	if(!post)
		return;

	// Append the message to the DOM and scroll to bottom of the view
	_appendPost(post);
}



/***************
 * PRIVATE API 
 ***************/

/* Append a post object to the DOM */
function _appendPost(post) {
	// format the post object to a HTML string
	var html = _formatPostAsHTHML(post);

	// append element to wrapper element
	$('#thread-content').append(html);
}


/* Prepend a post object to the DOM */
function _prependPost(post) {
	// format the post object to a HTML string
	var html = _formatPostAsHTHML(post);

	// append element to wrapper element
	$('#thread-content').prepend(html);
}


/* Format a post object to a HTML string  */
function _formatPostAsHTHML(post) {
	console.log(post);

	var replyDisabled 	= post["replyDisabled"] == "true" ? "disabled": "";
	var quoteDisabled 	= post["quoteDisabled"] == "true" ? "disabled": "";
	var editDisabled 	= post["editDisabled"] == "true" ? "disabled": "";
	var deleteDisabled 	= post["deleteDisabled"] == "true" ? "disabled": "";

	// return a HTML string
	return  '<a class="anchor" name="' + post["postID"] + '"></a>' +
			'<div class="post">' +
				'<div class="postheader">' +
					'<div class="posticon">' +
						'<img src="data:image/tiff;base64,' + post["icon"] + '" width="32" height="32" alt="icon" />' +
					'</div>' +
					'<div class="postinfo">' +
						'<span class="postfrom">' + post["from"] + '</span>' + 
						'<div class="postattributes">' +
                            '<span class="postpostdatestring">' + post["postDateString"] + '</span>' +
                            '<span class="postpostdate"> ' + post["postDate"] + '</span>' +
                        '</div>' +
                        '<div class="postattributes">' +
                            '<span class="posteditdatestring ">' + post["editDateString"] + '</span>' +
                            '<span class="posteditdate"> ' + post["editDate"] + '</span>' +
						'</div>' +
					'</div>' +
					'<span class="postunread"></span>' +
					'<div class="postbuttons">' +
						'<form action="">' +
							'<input '+ replyDisabled +' class="'+ replyDisabled +' replybutton postbutton" type="button" ' +
									'onclick=window.Controller.replyToThread(); ' +
									'title="' + post["replyButtonString"] + '" />' +
							'<input '+ quoteDisabled +' class="'+ quoteDisabled +' quotebutton postbutton" type="button" ' +
									'onclick=window.Controller.replyToPostWithID_("' + post["postID"] + '"); ' +
									'title="' + post["quoteButtonString"] + '" />' +
							'<input '+ editDisabled +' class="'+ editDisabled +' editbutton postbutton" type="button" ' +
									'onclick=window.Controller.editPostWithID_("' + post["postID"] + '"); ' +
									'title="' + post["editButtonString"] + '" />' +
							'<input '+ deleteDisabled +' class="'+ deleteDisabled +' deletebutton postbutton" type="button"  ' +
									'onclick=window.Controller.deletePostWithID_("' + post["postID"] + '"); ' +
									'title="' + post["deleteButtonString"] + '" />' +
						'</form>' +
					'</div>' +
				'</div>' +
				'<div class="postbody">' + post["postContent"] + '</div>' +
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
	// if($(window).height() < $(document).height() && $(window).scrollTop() == 0) {
	// 	_addPage();	
	// }
});





/***************
 * DOCUMENT 
 ***************/

/* Ready? ... Go! */
$(document).ready(function(){
	$('#thread-content').hide();

	var controller	= window.Controller;
	var posts 		= eval(controller.JSONObjects());

	for (var i in posts) {
		_appendPost(posts[i]);
		_scrollToBottom();
	}

	$("img").load(function() {
        _scrollToBottom();
        $('#thread-content').fadeIn();
    });
});



/* %99$ bottle$... */
