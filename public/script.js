var es = new EventSource('/refresh');
es.onmessage = function(e) {
	window.location.reload(true);  
}
