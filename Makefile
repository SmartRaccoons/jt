install :
	npm install
upgrade :
	ncu -a

run :
	coffee app.coffee

admin-compile :
	coffee express-admin/custom.json.coffee
	coffee express-admin/config.json.coffee
	coffee express-admin/js/config.coffee

admin :
	node node_modules/express-admin/app.js express-admin

compile :
	make admin-compile
	grunt compile

production :
	uglifycss public/d/css/screen.css > public/d/c.css
	cat public/d/js/redirect.js \
	public/d/js/social.js \
> public/d/all.js
	uglifyjs --beautify "indent-level=0" public/d/all.js -o public/d/j.js
	rm public/d/all.js


