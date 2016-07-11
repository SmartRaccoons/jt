install :
	npm install
upgrade :
	ncu -a

compile :
	grunt compile

production :
	uglifycss public/d/css/screen.css > public/d/c.css
	cat bower_components/jquery/dist/jquery.js \
	public/d/js/plugins/primus.js \
	node_modules/lodash/index.js \
	node_modules/backbone/backbone.js \
	public/d/js/backbone-patch.js \
    bower_components/babylonjs/dist/babylon.2.2.js \
    node_modules/Order/index.js \
	public/d/js/init.js \
	public/d/locale/en.js \
	game/index.js \
	game/client.js \
	public/d/js/objects.js \
	public/d/js/rooms.js \
	public/d/js/router.js \
	public/d/js/run.js \
> public/d/all.js
	uglifyjs --beautify "indent-level=0" public/d/all.js -o public/d/j.js
	rm public/d/all.js


