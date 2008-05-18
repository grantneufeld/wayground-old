// based on http://railscasts.com/episodes/77
// Should be called from ruby views like:
// link_to_function "confirm_destroy(this, '#{url}', 'msg')", :href=>'noscript url'
function confirm_destroy(element, action, msg, token) {
	if (confirm(msg)) {
		var f = document.createElement('form');
		f.style.display = 'none';
		element.parentNode.appendChild(f);
		f.method = 'POST';
		f.action = action;
		var m = document.createElement('input');
		m.setAttribute('type', 'hidden');
		m.setAttribute('name', '_method');
		m.setAttribute('value', 'delete');
		f.appendChild(m);
		var t = document.createElement('input');
		t.setAttribute('type', 'hidden');
		t.setAttribute('name', 'authenticity_token');
		t.setAttribute('value', token);
		f.appendChild(t);
		f.submit();
	}
	return false;
}