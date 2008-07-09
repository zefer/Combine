Combine.CFC
-----------

Combine multiple javascript or CSS files into a single, compressed, HTTP request.

Allows you to change this:

	<script src='file1.js' type='text/javascript'></script>
	<script src='file2.js' type='text/javascript'></script>
	<script src='file3.js' type='text/javascript'></script>
	
To this:

	<script src='combine.cfm?files=file1.js,file2.js,file3.js' type='text/javascript'></script>

...combining and compressing multiple javascript or css files into one http request.


How do I use it?
----------------
- Place combine.cfm and Combine.cfc somewhere under your webserver
- Modify the combine.cfm with your preferred combine options, and error handling if required.
- Update your <script> and <link> urls for JS and CSS respectively, e.g:
  - <script src="combine.cfm?type=js&files=monkey.js,jungle.js" type="text/javascript"></script>
  - <link href="combine.cfm?type=css&files=monkey.css,jungle.css" type="text/css" rel="stylesheet" media="screen" />
- [optional] If you want to use the CSS or Javascript compression, you need to add the required Java to your classpath. See "How to add the Java to your classpath" below...


How to add the Java to your classpath [required for css and js compression]
---------------------------------------------------------------------------
1. Determine where you will place your Java, it must go in a directory in your Coldfusion class path. This could either be cf_install_dir\lib, or a custom directory path which has been added to the Coldfusion class path (through Coldfusion's admin/config)
2. Add the code to the class_path_dir as determined in step 1, using one of the following 2 methods:
  a. copy combine.jar (archive) to your class_path_dir; or
  b. copy the 'com' directory and contents to your class_path_dir (directory structure must not change).
3. Restart Coldfusion


Why?
----
- Reduces the number of HTTP requests required to load your page. All your javascript files can be combined into a single <script> request in your html file.
- Compressing the CSS/JS reduces the filesize, therefore reduces the bandwidth overhead
- Keep seperate CSS and JS files for easier development


How does it work?
-----------------
- [optional] Uses the dependable JSMin method to reduce redundancy from the JavaScript, without obfuscation. In my experience, it's very dependable.
- [optional] Uses the YUI CSS compressor to reduce redundancy from the CSS, not just white-space removal, see http://developer.yahoo.com/yui/compressor/
- [optional] Caches merged files to local machine to avoid having to rebuild on each request
- [optional] Uses Etags (file hash/fingerprints) to allow browsers to make conditional requests. E.g. browser says to server, only give me the javascript to download if your etag is different to mine (i.e. only if it has changed since my last visit). Otherwise, browser uses it's locally cached version.


More
----
- You are likely to also see benefits from enabling gzip compression on your webserver. Compressing something twice is generally pointless (ever tried zipping a JPEG?). However, combine.cfc strips out white space, comments, etc, Gzip is lossless; therefore the combination of the 2 can be quite effective.
- YSlow is a great Firefox extension which can help you determine what optimisations you can make to imporve your site's performance (requires Firebug)
- Yahoo's best practices document (linked to from YSlow) is worth a read if you are serious about optimisation: http://developer.yahoo.com/performance/rules.html
- Firebug - It's pains me to think of the days I spent as a web developer without this Firefox extension!
- The following post contains useful information about the Java class path: http://weblogs.macromedia.com/cantrell/archives/2004/07/the_definitive.html


Contact
-------
Please feel free to contact me with any issues, ideas and experiences you have with Combine.cfc. jroberts1{at}gmail{dot}com


Credits
-------
All I have done here is pulled together some other peoples' clever work, into a workable solution for Coldfusion apps. So loads of credit to the following:

- Combine.php
  - A lot of ideas came from this project. Ed Eliot (www.ejeliot.com), Thanks!
- JSMin:
  - Originally written by Douglas Crockford www.crockford.com
  - Ported to Java by John Reilly http://www.inconspicuous.org/projects/jsmin/JSMin.java
- YUI CSS Compressor:
  - Part of the impressive YUI Compressor library http://developer.yahoo.com/yui/compressor/