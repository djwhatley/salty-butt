var blueButton = document.getElementById("betbuttonblue");
var redButton = document.getElementById("betbuttonred");
var selectedPlayer = document.getElementById("selectedplayer");
blueButton.onclick = function () {
    selectedPlayer.value = "1";
};
redButton.onclick = function () {
    selectedPlayer.value = "0";
};

var es = new EventSource('/refresh');
es.onmessage = function() {
	window.location.reload(true);  
};
