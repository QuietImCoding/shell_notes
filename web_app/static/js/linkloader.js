var loadnote = function(e) {
    link = e.target;
    e.preventDefault();
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
	if (this.readyState == 4 && this.status == 200) {
	    document.getElementById("notes-container").innerHTML = xhttp.responseText;
	}
    };
    xhttp.open("GET", link.href, true);
    xhttp.send();
}

links=document.getElementsByTagName("a");
for ( var i = 2; i < links.length; i++ ) {
    if (links[i].href.search('#') == -1) {
	links[i].onclick = loadnote;
    }
}
