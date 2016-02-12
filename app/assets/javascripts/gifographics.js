function set_data_src_to_src(tag) {
	$(tag).data('srcOriginal', tag.src);
}

function set_src_to_data_src(tag) {
	tag.src = $(tag).data().srcOriginal;
}

function is_gif_image(i) {
	return /^(?!data:).*\.gif/i.test(i.src);
}

function freeze_gif(i) {
	var c = document.createElement('canvas');
	var w = c.width = i.width;
	var h = c.height = i.height;
	c.getContext('2d').drawImage(i, 0, 0, w, h);
	try {
		i.src = c.toDataURL("image/gif"); // if possible, retain all css aspects
	} catch(e) { // cross-domain -- mimic original with all its tag attributes
		for (var j = 0, a; a = i.attributes[j]; j++)
			c.setAttribute(a.name, a.value);
		i.parentNode.replaceChild(c, i);
	}
}

function play_gif(image) {
	set_src_to_data_src(image);
}

function setup_gifographic(image) {
	set_data_src_to_src(image);
  freeze_gif(image);

	$(image).hover(
		function() {
			play_gif(image);
		}, function() {
			freeze_gif(image);
	});
}

function setup_gifographics() {
  $('.js-setup-gifographics')
    .imagesLoaded()
    .progress( function() {
      var image = this[0];
      if (is_gif_image(image)) setup_gifographic(image);
    });
}