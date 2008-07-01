<cfcomponent displayname="Combine" output="false" hint="provides javascript and css file merge and compress functionality, to reduce the overhead caused by file sizes & multiple requests">
	
	<cffunction name="init" access="public" returntype="Combine" output="false">
		<cfargument name="basePath" type="string" required="true" hint="the path where the files' relative urls are based. allows us to convert relative urls to file paths" />
		<cfargument name="enableCache" type="boolean" required="true" />
		<cfargument name="cachePath" type="string" required="true" />
		<cfargument name="enableETags" type="boolean" required="true" />
		<cfargument name="enableJSMin" type="boolean" required="true" hint="compress JS using JSMin?" />
		<cfargument name="enableYuiCSS" type="boolean" required="true" hint="compress CSS using the YUI css compressor?" />
		<!--- optional args --->
		<cfargument name="outputSeperator" type="string" required="false" default="#chr(13)#" hint="seperates the output of different file content" />
		<cfargument name="skipMissingFiles" type="boolean" required="false" default="true" hint="skip files that don't exists? If false, non-existent files will cause an error" />
		<cfargument name="getFileModifiedMethod" type="string" required="false" default="java" hint="java or com. Which technique to use to get the last modified times for files." />
		
		<cfscript>
		variables.sCachePath = arguments.cachePath;
		// enable caching
		variables.bCache = arguments.enableCache;
		// enable etags - browsers use this hash to decide if their cached version is up to date
		variables.bEtags = arguments.enableETags;
		// enable jsmin compression of javascript
		variables.bJsMin = arguments.enableJSMin;
		// enable yui css compression
		variables.bYuiCss = arguments.enableYuiCSS;
		// text used to delimit the merged files in the final output
		variables.sOutputDelimiter = arguments.outputSeperator;
		// the path where the files' relative urls are based. allows us to convert relative urls to file paths
		variables.sBaseFilePath = arguments.basePath;
		// skip files that don't exists? If false, non-existent files will cause an error
		variables.bSkipMissingFiles = arguments.skipMissingFiles;
		
		// -----------------------------------------------------------------------
		variables.jOutputStream = createObject("java","java.io.ByteArrayOutputStream");
		variables.jStringReader = createObject("java","java.io.StringReader");
		if(variables.bJsMin)
		{
			variables.jJSMin = createObject("java","com.magnoliabox.jsmin.JSMin");
		}
		if(variables.bYuiCss)
		{
			variables.jStringWriter = createObject("java","java.io.StringWriter");
			variables.jYuiCssCompressor = createObject("java","com.yahoo.platform.yui.compressor.CssCompressor");
		}
		
		// determine which method to use for getting the file last modified dates
		if(arguments.getFileModifiedMethod eq 'com')
		{
			variables.fso = CreateObject("COM", "Scripting.FileSystemObject");
			// calls to getFileDateLastModified() are handled by getFileDateLastModified_com()
			variables.getFileDateLastModified = variables.getFileDateLastModified_com;
		}
		else
		{
			variables.jFile = CreateObject("java", "java.io.File");
			// calls to getFileDateLastModified() are handled by getFileDateLastModified_java()
			variables.getFileDateLastModified = variables.getFileDateLastModified_java;
		}
		</cfscript>
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="combine" access="public" returntype="void" output="true" hint="combines a list js or css files into a single file, which is output, and cached if caching is enabled">
		<cfargument name="files" type="string" required="true" hint="a delimited list of jss or css paths to combine" />
		<cfargument name="type" type="string" required="false" hint="js,css" />
		<cfargument name="delimiter" type="string" required="false" default="," hint="the delimiter used in the provided paths string" />
		
		<cfscript>
		var sType = '';
		var lastModified = 0;
		var sFilePath = '';
		var sCorrectedFilePaths = '';
		var i = 0;
		var sDelimiter = arguments.delimiter;
		
		var etag = '';
		var sCacheFile = '';
		var sOutput = '';
		var sFileContent = '';
		
		var filePaths = convertToAbsolutePaths(files, delimiter);
		
		// determine what file type we are dealing with
		if( structkeyExists(arguments, 'type') )
		{
			sType = arguments.type;
		}
		if(not listFindNoCase('js,css', sType))
		{
			sType = listLast( listFirst(filePaths, sDelimiter) , '.');
		}
		</cfscript>

		<!--- get the latest last modified date --->
		<cfset sCorrectedFilePaths = '' />
		<cfloop from="1" to="#listLen(filePaths, sDelimiter)#" index="i">
			
			<cfset sFilePath = listGetAt(filePaths, i, sDelimiter) />
			
			<cfif fileExists( sFilePath )>
			
				<cfset lastModified = max(lastModified, getFileDateLastModified( sFilePath )) />
				<cfset sCorrectedFilePaths = listAppend(sCorrectedFilePaths, sFilePath, sDelimiter) />
				
			<cfelseif not variables.bSkipMissingFiles>
				<cfthrow type="combine.missingFileException" message="A file specified in the combine (#sType#) path doesn't exist." detail="file: #sFilePath#" extendedinfo="full combine path list: #filePaths#" />
			</cfif>
			
		</cfloop>

		<cfset filePaths = sCorrectedFilePaths />	
		
		<!--- create a string to be used as an Etag - in the response header --->
		<cfset etag = lastModified & '-' & hash(filePaths) />
		
		<!--- 
			output the etag, this allows the browser to make conditional requests
			(i.e. browser says to server: only return me the file if your eTag is different to mine)
		--->
		<cfif variables.bEtags>
			<cfheader name="ETag" value="""#etag#""">
		</cfif>
		
		<!--- 
			if the browser is doing a conditional request, then only send it the file if the browser's
			etag doesn't match the server's etag (i.e. the browser's file is different to the server's)
		 --->
		<cfif (structKeyExists(cgi, 'HTTP_IF_NONE_MATCH') and cgi.HTTP_IF_NONE_MATCH contains eTag) and variables.bEtags>
			<!--- nothing has changed, return nothing --->
			<cfheader statuscode="304" statustext="Not Modified">
			<cfheader name="Content-Length" value="0">
			<cfreturn />
		<cfelse>
			<!--- first time visit, or files have changed --->
			
			<cfif variables.bCache>
				
				<!--- try to return a cached version of the file --->		
				<cfset sCacheFile = variables.sCachePath & '\' & etag & '.' & sType />
				<cfif fileExists(sCacheFile)>
					<cffile action="read" file="#sCacheFile#" variable="sOutput" />
					<!--- output contents --->
					<cfset outputContent(sOutput, sType) />
					<cfreturn />
				</cfif>
				
			</cfif>
			
			<!--- combine the file contents into 1 string --->
			<cfset sOutput = '' />
			<cfloop from="1" to="#listLen(filePaths, sDelimiter)#" index="i">
				<cffile action="read" variable="sFileContent" file="#listGetAt(filePaths,i,sDelimiter)#" />
				<cfset sOutput = sOutput & variables.sOutputDelimiter & sFileContent />
			</cfloop>
			
			<cfscript>
			// 'Minify' the javascript with jsmin
			if(variables.bJsMin and sType eq 'js')
			{
				sOutput = compressJsWithJSMin(sOutput);
			}
			else if(variables.bYuiCss and sType eq 'css')
			{
				sOutput = compressCssWithYUI(sOutput);
			}
			
			//output contents
			outputContent(sOutput, sType);
			</cfscript>
			
			<!--- write the cache file --->
			<cfif variables.bCache>
				<cffile action="write" file="#sCacheFile#" output="#sOutput#" />
			</cfif>
			
		</cfif>
		
	</cffunction>
	
	
	<cffunction name="outputContent" access="private" returnType="void" output="true">
		<cfargument name="sOut" type="string" required="true" />
		<cfargument name="sType" type="string" required="true" />
	
		<cfcontent type="text/#arguments.sType#">
		<cfoutput>#arguments.sOut#</cfoutput>
		
	</cffunction>
	
	
	<!--- uses 'Scripting.FileSystemObject' com object --->
	<cffunction name="getFileDateLastModified_com" access="private" returnType="string">
		<cfargument name="path" type="string" required="true" />
		<cfset var file = variables.fso.GetFile(arguments.path) />
		<cfreturn file.DateLastModified />
	</cffunction>
	<!--- uses 'java.io.file'. Recommended --->
	<cffunction name="getFileDateLastModified_java" access="private" returnType="string">
		<cfargument name="path" type="string" required="true" />
		<cfset var file = variables.jFile.init(arguments.path) />
		<cfreturn file.lastModified() />
	</cffunction>
	
	
	<cffunction name="compressJsWithJSMin" access="private" returnType="string" hint="takes a javascript string and returns a compressed version, using JSMin">
		<cfargument name="sInput" type="string" required="true" />
		<cfscript>
		var sOut = arguments.sInput;
			
		var joOutput = variables.jOutputStream.init();
		var joInput = variables.jStringReader.init(sOut);
		var joJSMin = variables.jJSMin.init(joInput, joOutput);
		
		joJSMin.jsmin();
		joInput.close();
		sOut = joOutput.toString();
		joOutput.close();
		
		return sOut;
		</cfscript>
	</cffunction>
	
	
	<cffunction name="compressCssWithYUI" access="private" returnType="string" hint="takes a css string and returns a compressed version, using the YUI css compressor">
		<cfargument name="sInput" type="string" required="true" />
		<cfscript>
		var sOut = arguments.sInput;
			
		var joInput = variables.jStringReader.init(sOut);
		var joOutput = variables.jStringWriter.init();
		var joYUI = variables.jYuiCssCompressor.init(joInput);
		
		joYUI.compress(joOutput, javaCast('int',-1));
		joInput.close();
		sOut = joOutput.toString();
		joOutput.close();
		
		return sOut;
		</cfscript>
	</cffunction>
	
	
	<cffunction name="convertToAbsolutePaths" access="private" returnType="string" hint="takes a list of relative paths and makes them absolute, based on variables.sBaseFilePath">
		<cfargument name="relativePaths" type="string" required="true" hint="commar delimited list of relative paths" />
		<cfargument name="delimiter" type="string" required="false" default="," hint="the delimiter used in the provided paths string" />
		<cfscript>
		// convert the relative web paths into full file paths
		var absReplace = '#arguments.delimiter##variables.sBaseFilePath#\';
		var filePaths = reReplaceNoCase(arguments.relativePaths, '/', '\', 'all');
		filePaths = reReplaceNoCase(filePaths, '#arguments.delimiter#\\|^\\', absReplace, 'all');
		// remove url params e.g. scriptaculous.js?load=effects ==> scriptaculous.js
		filePaths = reReplaceNoCase(filePaths, '[\?|\&][^\#arguments.delimiter#]*', '', 'all');
		return filePaths;
		</cfscript>
	</cffunction>
	
</cfcomponent>
