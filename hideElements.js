// Hide elements that change out of the developer's control.

hideElements();

function hideElements()
{
	var elems = ['#comments', '.cubeAd', '.fullBanner', '#masthead', '#footer', '.right'];

	$.each(elems, function(i, elem)
	{
		var el = $(elem);
		if(el.length)
		{
			// el.hide();
			el.css('visibility', 'hidden'); // Keep structure.
		}
	});
}
