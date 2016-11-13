/**
 PhantomJS file to parse given JSON file for targets.
 Load targets.
 Remove unnecessary components.
 Screen capture after delay.
 @author Robert Brisita <robert.brisita@gmail.com>
 **/

var DATE = '20140421';
var VERSION = '0.2.0';

var system = require('system');
var webpage = require('webpage');

var _arrFileTypes = ['gif', 'jpg', 'jpeg', 'png', 'pdf'];
var _defaultFileType = 'png';
var _defaultDelay = 200;

if(system.args.length === 1)
{
	console.log('Usage: capture.js <URL | JSON file containing URLs> [', _arrFileTypes.join(', '), ']');
	console.log('JSON file format: {"target":"URL" [, "delay":number]}');
	phantom.exit(1);
}

listenToPhantomErrors(phantom);

// Check for filename.
var arrTargets = null;
var fs = require('fs');
var target = system.args[1];
if(fs.isReadable(target))
{
	target = fs.read(target);
}

try // Try to parse file contents or JSON string
{
	arrTargets = JSON.parse(target);
}
catch(e) // Maybe a URL was given?
{
	arrTargets = [{target: target, delay: _defaultDelay}];
}

// Check for file type to save each target as.
var _fileType = system.args[2];
if(-1 === _arrFileTypes.indexOf(_fileType))
{
	console.log("Capture.js: '", _fileType, "' not an available file format. Using", _defaultFileType);
	_fileType = _defaultFileType;
}

// Loop through targets.
phantom.app_mon_total = arrTargets.length;
arrTargets.forEach(function(obj, index, array)
{
	console.log("Capture.js: Capturing", obj.target);
	loadPage(webpage, obj);
});


/* METHODS */
function listenToPhantomErrors(phantom)
{
	phantom.onError = function(msg, trace)
	{
		var msgStack = ['PHANTOM ERROR: ' + msg];
		if(trace && trace.length)
		{
			msgStack.push('TRACE:');
			trace.forEach(function(t)
			{
				msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function + ')' : ''));
			});
		}
		console.error(msgStack.join('\n'));
		console.log(msgStack.join('\n'));
		phantom.exit(1);
	};
}

function loadPage(webpage, obj)
{
	var page = createPage(webpage);
	monitorResources(page, obj);

	// Load given URL
	page.app_mon_delay = obj.delay | _defaultDelay;
	page.app_mon_time = Date.now();
	page.open(obj.target, function(status)
	{
		if(status === 'fail')
		{
			console.log('ERROR: Failed to load:', page.url);
			// TODO: LARAVEL TASK to save failed page load
			page.close();
			return;
		}

		page.app_mon_time = Date.now() - page.app_mon_time;
		console.log('Total load time:', page.app_mon_time, 'ms for', page.url);

		// TODO: LARAVEL TASK Check load time > obj.loadTime

		page.injectJs('hideElements.js');

		var filename = getFilenameFromPage(page);
		filename += '.' + _fileType;
		setTimeout(function()
		{
			var obj = getDateObj();
			console.log('Created file:', obj + '/' + filename);

			page.render(obj + '/' + filename);
			page.close();

			checkToExit(phantom);
		}, page.app_mon_delay);
	});
}

function createPage(webpage)
{
	var page = webpage.create();

	page.viewportSize =
	{
		width: 800,
		height: 600
	};

	page.settings.userAgent = "Phantom.js Application Monitor Bot";

	page.onConsoleMessage = function(msg, lineNum, sourceId)
	{
		console.log('CONSOLE: ', page.url + ': ' + msg + ' (from line #' + lineNum + ' in "' + sourceId + '")');
	};

	page.onError = function(msg, trace)
	{
		console.log('Error: ' + page.url, "'" + msg + "'");
		trace.forEach(function(item)
		{
			console.log('\t', item.file, ' : #', item.line);
		});
	};

	return page;
}

function monitorResources(page, obj)
{
	page.onResourceRequested = function(request)
	{
//			console.log('Request', request.method, request.url);
//			console.log('Request ' + JSON.stringify(request, undefined, 2));
	};

	page.onResourceReceived = function(response)
	{
		if(resourceError(response)
		&& lastStage(response))
		{
			// ^app[\.*\w*]*\.js$
			var resource = getResourceFromURI(response.url);
			var arr = obj.resources;
			arr.forEach(function(elem, index, array)
			{
				if(elem === resource)
				{
					// TODO: LARAVEL TASK resource error
					console.log('Resource', resource);
				}
			});
		}

//			console.log('Receive', response.stage, response.status, response.statusText, response.url);
//			console.log('Receive ' + JSON.stringify(response, undefined, 2));
	};

	page.onResourceError = function(resourceError)
	{
		console.log('Unable to load resource (#' + resourceError.id + ' URL: ' + resourceError.url + ')');
		console.log('Error code: ' + resourceError.errorCode + '. Description: ' + resourceError.errorString);

		// ^app[\.*\w*]*\.js$
		var resource = getResourceFromURI(resourceError.url);
		var arr = obj.resources;
		arr.forEach(function(elem, index, array)
		{
			if(elem === resource)
			{
				// TODO: LARAVEL TASK resource error
				console.log('Resource', resource);
			}
		});
	};
}

function resourceError(response)
{
	return response.status < 200 || response.status >= 400;
}

function lastStage(response)
{
	return response.stage === 'end';
}

function getResourceFromURI(uri)
{
	var endSlash = uri.lastIndexOf('/');
	var filename = uri.substr(endSlash + 1, uri.length);
	return filename;
}

function getFilenameFromPage(page)
{
	// Possible URL query parameters have to be stripped out
	var filename = page.url.replace(':/', '');
	var endSlash = filename.lastIndexOf('/');
	if((endSlash + 1) === filename.length) // End of str?
	{
		filename = filename.substr(0, endSlash);	// Copy everything but the slash.
//				filename = filename.slice(0, -1);
	}

	return filename;
}

function getDateObj(date)
{
	var obj = {};
	var d = (date) ? new Date(date) : new Date();

	obj.yyyy = d.getUTCFullYear();
	obj.mm = d.getUTCMonth();
	obj.dd = d.getUTCDate();

	obj.toString = function()
	{
		return obj.yyyy + '/' + formatUnit(obj.mm + 1) + '/' + formatUnit(obj.dd);
	};

	return obj;
}

function formatUnit(u)
{
	return (u < 10) ? '0' + u : u;
}

function checkToExit(phantom)
{
	// KLUDGE: Don't like this, could be cleaner
	phantom.app_mon_total--;
	if(!phantom.app_mon_total)
	{
		phantom.exit(0);
	}
}
