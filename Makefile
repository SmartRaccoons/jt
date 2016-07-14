install :
	npm install
upgrade :
	ncu -a

compile :
	grunt compile

production :
	uglifycss public/d/css/screen.css > public/d/c.css
	cat public/d/js/redirect.js \
	public/d/js/social.js \
> public/d/all.js
	uglifyjs --beautify "indent-level=0" public/d/all.js -o public/d/j.js
	rm public/d/all.js


