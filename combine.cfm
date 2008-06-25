<cfsetting showdebugoutput="false" />
<cfscript>
/*
	Create the combine object, or use the cached version

	@basePath:					allows combine.cfc to convert the relative (remote) include paths into absolute (local) file paths
	@enableCache:				true: cache combined/compressed files locally, false: re-combine on each request
	@cachePath:					where should the cached combined files be stored?
	@enableETags:				should we return etags in the headers? Etags allow the browser to do conditional requests, i.e. only give me the file if the etag is different.
	@enableJSMin:				compress Javascript using JSMin?
	@enableYuiCSS:				compress CSS using YUI CSS compressor
	@skipMissingFiles:		true: ignore file-not-found errors, false: throw errors when a requested file cannot be found
	@getFileModifiedMethod:	'java' or 'com'. Which method to use to obtain the last modified dates of local files. Java is the recommended and default option
*/
variables.sKey = 'combine_#hash(getCurrentTemplatePath())#';
if((not structKeyExists(application, variables.sKey)) or structKeyExists(url, 'reinit'))
{
	application[variables.sKey] = createObject("component", "combine").init(
		basePath: 'C:\webroot\myapp\www',
		enableCache: true,
		cachePath: 'c:\webroot\myapp\cache',
		enableETags: true,
		enableJSMin: true,
		enableYuiCSS: true,
		skipMissingFiles: false
	);
}
variables.oCombine = application[variables.sKey];

/*	Make sure we have the required paths (files to combine) in the url */
if(not structKeyExists(url, 'files'))
	return;

/*	Combine the files, and handle any errors in an appropriate way for the current app */
try
{
	variables.oCombine.combine(files: url.files);
}
catch(any e)
{
	handleError(e);
}
</cfscript>

<cffunction name="handleError" access="public" returntype="void" output="false">
	<cfargument name="cfcatch" type="any" required="true" />
	
	<!--- Put any custom error handling here e.g. --->
	<cfdump var="#cfcatch#" />
	<cflog file="combine" text="Fault caught by 'combine'">
	<cfabort />

</cffunction>