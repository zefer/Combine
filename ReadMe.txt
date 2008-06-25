Combine.CFC
-----------

Combine multiple javascript or CSS files into a single, compressed, HTTP request from the browser

Allows you to change this:

	<script src="file1.js" type="text/javascript"></script>
	<script src="file2.js" type="text/javascript"></script>
	<script src="file3.js" type="text/javascript"></script>
	
To this:

	<script src="combine/index.cfm?files=file1.js,file2.js,file3.js" type="text/javascript"></script>


How do I use it?
----------------
- Place index.cfm and Combine.cfc somewhere under your webserver
- Modify the index.cfm with your preferred combine options, and error handling if required.
- Update your <script> and <link> urls for JS and CSS respectively, e.g:
  - <script src="combine/index.cfm?type=js&files=monkey.js,jungle.js" type="text/javascript"></script>
  - <link href="combine/index.cfm?type=css&files=monkey.css,jungle.css" type="text/css" rel="stylesheet" media="screen" />
- [optional] add the java class files to your class path - required if you want to use the CSS or Javascript compression


Why?
----
- Reduces the number of HTTP requests required to load your page. All your javascript files can be combined into a single <script> request in your html file.
- Compressing the CSS/JS reduces the filesize, therefore reduces the bandwidth overhead
- Keep seperate CSS and JS files for easier development


How does it work?
-----------------
- [optional] Uses the dependable JSMin method to reduce redundancy from the JavaScript, without obfuscation. In my experience, it's dependable.
- [optional] Uses the YUI CSS compressor to reduce redundancy from the CSS, not just white0space removal, see http://developer.yahoo.com/yui/compressor/
- [optional] Caches merged files to local machine to avoid having to rebuild on each request
- [optional] Uses Etags (file hash/fingerprints) to allow browsers to make conditional requests. E.g. browser says to server, only give me the javascript to download if your etag is different to mine (i.e. only if it has changed since my last visit). Otherwise, browser uses it's locally cached version.


More
----
- You may also see benefits from enabling gzip compression on your webserver. You may find with gzip enabled, the compression of CSS and JS files via combine.cfc is of no additional benefit (have you ever tried zipping a jpeg?). Experimentation should help you make this call.
- YSlow is a great Firefox extension which can help you determine what optimisations you can make to imporve your site's performance (requires Firebug)
- Firebug - It's pains me to think of the days I spent as a web developer without this Firefox extension!


Credits
-------

All I have done here is pulled together some other peoples clever work, into a workable solution for Coldfusion apps. So loads of credit to the following (and not very much to me!):

- Combine.php
  - I pretty much copied this idea, my code is very similar! Ed Eliot (www.ejeliot.com), Thanks!
- JSMin:
  - Originally written by Douglas Crockford www.crockford.com
  - Ported to Java by John Reilly http://www.inconspicuous.org/projects/jsmin/JSMin.java
- YUI CSS Compressor:
  - Part of the impressive YUI Compressor library http://developer.yahoo.com/yui/compressor/