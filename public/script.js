var source = new EventSource('pull');
source.addEventListener('message', function(e) {
	console.log(e.data);
}, false);