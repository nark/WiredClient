/*
 *  Copyright (c) 2013 Read-Write.fr. All rights reserved.
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

/** @const */
var ONE_SECOND = 1000;
/** @const */
var ONE_MINUTE = ONE_SECOND * 60;
/** @const */
var ONE_HOUR = ONE_MINUTE * 60;
/** @const */
var ONE_DAY = ONE_HOUR * 24;
/** @const */
var ONE_WEEK = ONE_DAY * 7;
/** @const */
var ONE_YEAR = ONE_DAY * 365;

function createSingularOrPlural(singular, plural, value, divisor) {
    value = Math.floor(value / divisor);

    return value < 2 ? singular : plural.replace('?', value);
}

function getPrettyTimeAgo(timeAgo) {

    if (timeAgo >= ONE_YEAR) {
        return "over a year ago";
    }

    if (timeAgo >= ONE_DAY) {
        return createSingularOrPlural("yesterday", "? days ago", timeAgo, ONE_DAY);
    }

    if (timeAgo >= ONE_HOUR) {
        return createSingularOrPlural("about 1 hour ago", "? hours ago", timeAgo, ONE_HOUR);
    }

    if (timeAgo >= ONE_MINUTE) {
        return createSingularOrPlural("about 1 minute ago", "? minutes ago", timeAgo, ONE_MINUTE);
    }

    return createSingularOrPlural("right now", "? seconds ago", timeAgo, ONE_SECOND);
}

function getMillisecondsSinceDate(dateString) {
    var rightNow = new Date();
    var then = new Date(dateString);

    // If we're using jQuery, check if we're using IE to perform a defect fix. 
    if (window.$ && window.$.browser && window.$.browser.msie) {
        then = Date.parse(dateString.replace(/( \+)/, ' UTC$1'));
    }

    return rightNow - then;
}

function timeAgo(dateString) {

    var timeDifference = getMillisecondsSinceDate(dateString);

    if (isNaN(timeDifference) || timeDifference < 0) {
        return "";
    }

    return {
        tAgo: getPrettyTimeAgo(timeDifference),
        timeCheck: timeDifference >= 2 * ONE_HOUR
    };
}