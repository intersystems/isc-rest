Include (%occErrors, %pkg.isc.rest.openAPI, %pkg.isc.rest.general)

/// Base REST handler for APIs built on %pkg.isc.rest.
/// Consumers should extend this, override <method>GetUserResource</method> and <method>AuthenticationStrategy</method> appropriately, and
/// should *NOT* override the UrlMap XData block.
Class %pkg.isc.rest.handler Extends %CSP.REST [ Abstract, System = 4 ]
{

/// Determines what mode queries using this REST handler will be run in.  Defaults to 0 (Logical Mode).
/// Overwrite in a subclass as 1 (ODBC Mode) or 2 (Display Mode).
Parameter QuerySelectMode As INTEGER = 0;

/// Subclasses may override this method to provide information about the logged-in user.
/// <ul>
/// <li> pFullUserInfo: dynamic object with full user info provided by the authentication strategy
/// <ul>
ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As %pkg.isc.rest.model.iSerializable
{
	Quit $$$NULLOREF
}

ClassMethod GetLoginResource(pLoginInfo As %DynamicObject) As %pkg.isc.rest.model.iSerializable
{
	Quit $$$NULLOREF
}

/// Subclasses MUST override this method to specify which resource classes are allowed
/// as part of the API.
ClassMethod CheckResourcePermitted(resourceClass As %Dictionary.Classname) As %Boolean
{
	Quit 0
}

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET = "utf-8";

/// Specifies if input %request.Content or %request.MimeData values are converted from their
/// original character set on input. By default (0) we do not modify these and receive them
/// as a binary stream which may need to be converted manually later. If 1 then if there
/// is a 'charset' value in the request Content-Type or mime section we will convert from this
/// charset when the input data is text based. For either json or xml data with no charset
/// this will convert from utf-8 or honor the BOM if one is present.
Parameter CONVERTINPUTSTREAM = 1;

/// Version of this API to be used in OpenAPI documentation
/// Formatting follows Semantic Versioning (https://semver.org/)
Parameter APIVersion = "0.1.0";

/// Endpoints for which <method>Supports</method> is called. Take a look at
/// the method documentation to see how this parameter is used.
Parameter SupportsCheckEndpoints [ Final ] = {$LISTBUILD("/auth/status:GET","/auth/logout:POST","/build-documentation:POST","/build-documentation:GET","/openapi.json:GET")};

/// Regex for the isc.rest supported media types.
Parameter AllowedMediaTypeRegex As STRING [ Final, Internal ] = "application/(.*\+)?json";

Projection HandlerProjection As %pkg.isc.rest.handlerProjection;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!-- Authentication routes -->
<Route Url="/auth/status" Method="GET" Call="GetUserInfo" />
<Route Url="/auth/login" Method="POST" Call="AuthLogin" />
<Route Url="/auth/logout" Method="POST" Call="LogOut" />

<!-- Documentation methods -->
<Route Url="/build-documentation" Method="POST" Call="BuildDocumentationEndpoint" />
<Route Url="/build-documentation" Method="GET" Call="GetDocumentationBuildStatus" />
<Route Url="/openapi.json" Method="GET" Call="GetOpenAPISpecification" />

<!-- Resource "class methods" -->
<Route Url="/:resource" Method="GET" Call="CollectionQuery" />
<Route Url="/:resource" Method="POST" Call="Create" />
<Route Url="/:resource/\$new" Method="GET" Call="Construct" />

<!-- "class actions" (GET/PUT/POST/DELETE/PATCH) -->
<Route Url="/:resource/\$(.+)" Method="GET" Call="DispatchClassAction" />
<Route Url="/:resource/\$(.+)" Method="PUT" Call="DispatchClassAction" />
<Route Url="/:resource/\$(.+)" Method="POST" Call="DispatchClassAction" />
<Route Url="/:resource/\$(.+)" Method="DELETE" Call="DispatchClassAction" />
<Route Url="/:resource/\$(.+)" Method="PATCH" Call="DispatchClassAction" />

<!-- Resource "instance methods" -->
<Route Url="/:resource/:id" Method="GET" Call="Retrieve" />
<Route Url="/:resource/:id" Method="PUT" Call="Update" />
<Route Url="/:resource/:id" Method="DELETE" Call="Delete" />

<!-- "instance actions" (GET/PUT/POST/DELETE/PATCH) -->
<Route Url="/:resource/:id/\$(.+)" Method="GET" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$(.+)" Method="PUT" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$(.+)" Method="POST" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$(.+)" Method="DELETE" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$(.+)" Method="PATCH" Call="DispatchInstanceAction" />
</Routes>
}

/// Ensures all required parameters are overridden in non-abstract subclasses.
ClassMethod "%%CheckClassValidity"() [ CodeMode = objectgenerator, GenerateAfter = SupportedVerbs, Internal, Private ]
{
	// Require non-abstract CheckResourcePermitted and AuthenticationStrategy methods
	Set overrides = $LISTBUILD("m:AuthenticationStrategy","m:CheckResourcePermitted")
	Return ##class(%pkg.isc.rest.compileTimeCheck).RequireOverrides(overrides,"%pkg.isc.rest.handler")
}

/// Endpoint call to get the OpenAPI specification saved to disk, and write it to the page as JSON
ClassMethod GetOpenAPISpecification() As %Status [ Final ]
{
	Kill params
	Merge params = %request.Data
	Set userContext = ..GetUserContext()
	If '..CheckPermission("/openapi.json", userContext, .params) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: endpoint /openapi.json"))
		Return $$$OK
	}
	Set result = ##class(%SQL.Statement).%ExecDirect(,
		"select top 1 ID from %pkg_isc_rest_openAPI_model.openAPI where DispatchClass = ?",
		$CLASSNAME())
	#Dim result As %SQL.StatementResult
	If result.%SQLCODE = 0 {
		Set %response.ContentType = "application/json"
		If 'result.%Next() {
			Set %response.Status = ..#HTTP204NOCONTENT
		} Else {
			Set specification = ##class(%pkg.isc.rest.openAPI.model.openAPI).%OpenId(result.ID)
			Do specification.%JSONExport()
		}
	} Else {
		Set %response.Status = ..#HTTP204NOCONTENT
	}
	Return $$$OK
}

/// Builds OpenAPI documentation from the console (no use of %request / %response)
/// apiPath is the application path of the form "/your/application/"
/// debug / internal are the same as the query parameters defined in BuildDocumentationEndpoint()
/// response will be set to the generated OpenAPI specification
ClassMethod ConsoleBuildOpenAPIDocumentation(apiPath, debug = 0, internal = 0, Output response As %pkg.isc.rest.openAPI.model.openAPI, endpointOverride As %String = "") As %Status [ Final ]
{
	Try {
		Set buildLock = $SYSTEM.AutoLock.Lock($NAME($$$DocLocksBuildGbl),"E",1)
		If '$ISOBJECT(buildLock) {
			Return $$$ERROR(8222, "Failed to acquire BuildDocumentation lock (another build is already in progress)")
		}
		Set $$$DocLocksBuildGbl = 2
		Set $$$DocTimingBuildStartGbl = $ZDATETIME($HOROLOG, -2)
		Kill $$$DocTimingBuildFinishGbl
		Set $$$DocParameterBuildDebugGbl = debug
		Set $$$DocParameterBuildInternalGbl = internal
		Set status = ##class(%pkg.isc.rest.openAPI).GetSpecification(.response,, apiPath, debug, internal, 1, endpointOverride)
		Set $$$DocStageBuildOpenAPIGbl = "Save specification..."
		Set result = ##class(%SQL.Statement).%ExecDirect(,
			"select ID from %pkg_isc_rest_openAPI_model.openAPI where DispatchClass = ?",$CLASSNAME())
		#Dim result As %SQL.StatementResult
		If result.%SQLCODE = 0 {
			While result.%Next() {
				Do ##class(%pkg.isc.rest.openAPI.model.openAPI).%OpenId(result.ID).Delete()
			}
		}
		Set saveableResponse = response.GetSaveableInstance()
		Set status2 = saveableResponse.%Save()
		Set $$$DocTimingBuildFinishGbl = $ZDATETIME($HOROLOG, -2)
		Set $$$DocLocksBuildGbl = 0
		If 'status {
			Set $$$DocStageBuildOpenAPIGbl = "Build failed: GetSpecification() returned false; saved anyway (console builds always save)"
			Return $$$ERROR($$$GeneralError, "OpenAPI Specification Generation Error")
		}
		If $SYSTEM.Status.IsError(status2) {
			Set $$$DocStageBuildOpenAPIGbl = "Build failed: " _ $SYSTEM.Status.GetErrorText(status2) _ "; saved anyway (console builds always save)"
			Return status2
		}
		Set $$$DocStageBuildOpenAPIGbl = "Finished"
		Return $$$OK
	} Catch e {
		Set $$$DocTimingBuildFinishGbl = $ZDATETIME($HOROLOG, -2)
		Set $$$DocLocksBuildGbl = 0
		Set $$$DocStageBuildOpenAPIGbl = "Build failed: " _ $SYSTEM.Status.GetErrorText(e.AsStatus()) _ "; saved anyway (console builds always save)"
		Return e.AsStatus()
	}
}

/// Reports on the status of either the currently building documentation, or the last built documentation
ClassMethod GetDocumentationBuildStatus() As %Status [ Final ]
{
	Kill params
	Merge params = %request.Data
	Set userContext = ..GetUserContext()
	If '..CheckPermission("/build-documentation", userContext, .params) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: endpoint /build-documentation"))
		Return $$$OK
	}
	Set %response.ContentType = "application/json"
	Set buildStage = $GET($$$DocLocksBuildGbl, 0)
	Set status = {}
	Do status.%Set("buildInProgress", $CASE(buildStage,0:0,:1), "boolean")
	Set status.buildStartedTime = $GET($$$DocTimingBuildStartGbl,0)
	Set status.buildFinishedTime = $GET($$$DocTimingBuildFinishGbl,0)
	Set buildProgress = {}
	Set status.buildProgress = buildProgress
	Set buildProgress.buildStage = buildStage
	Set documentationType = $ORDER($$$DocStageBuildDocTypeGbl(""))
	While documentationType '= "" {
		Set documentationStatus = $$$DocStageBuildDocTypeGbl(documentationType)
		Do buildProgress.%Set(documentationType, documentationStatus)
		Set documentationType = $ORDER($$$DocStageBuildDocTypeGbl(documentationType))
	}
	Set buildParameters = {}
	Set status.buildParameters = buildParameters
	Do buildParameters.%Set("debug", $GET($$$DocParameterBuildDebugGbl,0), "number")
	Do buildParameters.%Set("internal", $GET($$$DocParameterBuildInternalGbl,0), "number")
	Try {
		Set buildParameters.userContext = {}.%FromJSON($GET($$$DocParameterBuildUserGbl,""))
	} Catch {
		Set buildParameters.userContext = $GET($$$DocParameterBuildUserGbl,"")
	}
	Do status.%ToJSON()
	Return $$$OK
}

/// Endpoint call to build all REST documentation types
/// Query parameters are:
///   debug (defaults to 0): Whether or not to run documentation generators in debug mode
///   internal (defaults to 0): Whether or not to generate documentation appropriate for users with source code access
ClassMethod BuildDocumentationEndpoint() As %Status [ Final ]
{
	Kill params
	Merge params = %request.Data
	Set userContext = ..GetUserContext()
	Set userContextString = "", userContextClassName = "", userContextID = ""
	If $ISOBJECT(userContext) {
		Try {
			Do userContext.JSONExportToString(.userContextString)
		}
		Catch {}
		Try {
			Set userContextID = userContext.%Id()
		}
		Catch {}
		Set userContextClassName = $CLASSNAME(userContext)
	}
	If '..CheckPermission("/build-documentation", userContext, .params) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: endpoint /build-documentation"))
		Return $$$OK
	}
	Set buildLock = $SYSTEM.AutoLock.Lock($NAME($$$DocLocksBuildGbl),"E",1)
	If '$ISOBJECT(buildLock) || $GET($$$DocLocksBuildGbl) {
		Do ..ReportHttpStatusCode(..#HTTP423LOCKED)
		Set %response.ContentType = "application/json"
		Set status = {"statusUrl":"/build-documentation","statusMethod":"GET","buildStarted":false}
		Do status.%ToJSON()
		Return $$$OK
	}
	Set $$$DocLocksBuildGbl = 1
	Set debug = $GET(params("debug",1), 0)
	Set internal = $GET(params("internal",1), 0)
	Set $$$DocParameterBuildDebugGbl = debug
	Set $$$DocParameterBuildInternalGbl = internal
	Job ..BuildDocumentationInternal(debug, internal, %request.AppMatch, userContextString, userContextID, userContextClassName):():2
	Set %response.ContentType = "application/json"
	Set status = {"statusUrl":"/build-documentation","statusMethod":"GET"} 
	Do status.%Set("buildStarted", $TEST, "boolean")
	Do status.%ToJSON()
	Return $$$OK
}

/// Long-running method to generate all REST documentation types
/// Updates $$$DocLocksBuildGbl to track over-all progress
/// Individual documentation generators should update $$$DocStageBuildDocTypeGbl( typeOfDocumentation) with their individual progress
/// debug / internal are the same as the query parameters in BuildDocumentationEndpoint()
/// application is equal to %request.Application
ClassMethod BuildDocumentationInternal(debug, internal, application, userContextString, userContextID, userContextClass) [ Final, Internal ]
{
	// Init
	Set buildLock = $SYSTEM.AutoLock.Lock($NAME($$$DocLocksBuildGbl),"E",1)
	// OpenAPI
	Set $$$DocLocksBuildGbl = 2
	Set $$$DocTimingBuildStartGbl = $ZDATETIME($HOROLOG, -2)
	Kill $$$DocTimingBuildFinishGbl
	Try
	{
		Set $$$DocStageBuildOpenAPIGbl = "Calling GetSpecification()"
		Try {
			Set userContext = $CLASSMETHOD(userContextClass, "%OpenId", userContextID, , .sc)
			$$$ThrowOnError(sc)
			Set sc = userContext.JSONImport(userContextString)
			Set jsonID = {}
			Do jsonID.%Set("_id", userContextID)
			Set $$$DocParameterBuildUserGbl = jsonID.%ToJSON()
			Do userContext.JSONExportToString(.importedJSON)
			Set $$$DocParameterBuildUserVerboseGbl = userContextID _ "@" _ userContextClass _ ": " _ importedJSON
		} Catch {
			Set jsonID = {}
			Try {
				Set userContext = $CLASSMETHOD(userContextClass, "%New")
				Set sc = userContext.JSONImport(userContextString)
				$$$ThrowOnError(sc)
				Do jsonID.%Set("_id", "N/A")
				Do userContext.JSONExportToString(.importedJSON)
				Set $$$DocParameterBuildUserVerboseGbl = userContextClass _ ": " _ importedJSON
			} Catch {
				Do jsonID.%Set("_id", "")
				Set userContext = $$$NULLOREF
				Set $$$DocParameterBuildUserVerboseGbl = "null"
			}
			Set $$$DocParameterBuildUserGbl = jsonID.%ToJSON()
		}
		Set status = ##class(%pkg.isc.rest.openAPI).GetSpecification(.response, userContext, application, debug, internal, 1)
		#Dim response As %pkg.isc.rest.openAPI.model.openAPI
		Set getSpecificationFailed = 'status
		If 'getSpecificationFailed || debug {
			Set $$$DocStageBuildOpenAPIGbl = "Removing old specification(s) from the database"
			Set result = ##class(%SQL.Statement).%ExecDirect(,"select ID from %pkg_isc_rest_openAPI_model.openAPI")
			#Dim result As %SQL.StatementResult
			If result.%SQLCODE = 0 {
				While result.%Next() {
					Do ##class(%pkg.isc.rest.openAPI.model.openAPI).%OpenId(result.ID).Delete()
				}
			}
			Set $$$DocStageBuildOpenAPIGbl = "Getting a saveable version of the generated specification"
			Set saveableResponse = response.GetSaveableInstance()
			Set $$$DocStageBuildOpenAPIGbl = "Saving specification"
			Set status = saveableResponse.%Save()
			Set $$$DocStageBuildOpenAPIGbl = "Finished"
		}
		If getSpecificationFailed {
			If debug {
				Set $$$DocStageBuildOpenAPIGbl = "Warning: GetSpecification() returned false; saved due to debug = " _ debug
			} Else {
				Set $$$DocStageBuildOpenAPIGbl = "Failed: GetSpecification() returned false"
			}
		}
		If 'status && ('getSpecificationFailed || debug) {
			Set $$$DocStageBuildOpenAPIGbl = "Failed: " _ $SYSTEM.Status.GetErrorText(status)
		}
	} Catch ex {
		Set $$$DocStageBuildOpenAPIGbl = "Failed: " _ $SYSTEM.Status.GetErrorText(ex.AsStatus())
	}
	
	// Additional documentation types go here!
	
	// Finish
	Set $$$DocTimingBuildFinishGbl = $ZDATETIME($HOROLOG, -2)
	Set $$$DocLocksBuildGbl = 0
}

/// Used to modify a generated OpenAPI specification before it is finalized, implement any custom-changes you want to make to
///   the OpenAPI specification as a whole here.
/// If you want to modify something class-specific (resource/action endpoints, schemas generated for classes), consider using the
///   ModifyOpenAPISpecification() ClassMethod of the class in question instead.
ClassMethod ModifyOpenAPISpecification(ByRef specification As %pkg.isc.rest.openAPI.model.openAPI)
{
}

/// Checks the user's permission for a documentation-related endpoint.
/// <var>pEndpoint</var> may be one of:
/// <ul>
/// 	<li>/build-documentation</li>
/// 	<li>/openapi.json</li>
/// </ul>
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>.
ClassMethod CheckPermission(pEndpoint As %String, pUserContext As %RegisteredObject, ByRef pURLParams) As %Boolean
{
	Quit 0
}

/// Checks if the endpoint provided is supported for the current dispatch class.
/// If the method returns 0 for a given endpoint, requests to the endpoint will
/// get a 404 and the endpoint will be excluded from the Open API specification. <br />
/// Default behavior is to return 1 for all endpoints. <br />
/// <var>pEndpoint</var> can be one of the endpoint-http verb combinations present
/// in <parameter>SupportsCheckEndpoints</parameter>. <br />
/// <var>pHTTPVerb</var> is the HTTP verb for the endpoint. <br />
/// <var>pRequest</var> is the request object in an HTTP context. <br />
ClassMethod Supports(pEndpoint As %String, pHTTPVerb As %String, pRequest As %CSP.Request = {$$$NULLOREF}) As %Boolean
{
	Return 1
}

/// Check whether a given operation is supported for the resource.
/// Returns 0 if the operation is not supported and sets the response status
/// to 404 Not Found. <br />
ClassMethod CheckSupports(pResourceClass As %Dictionary.Classname, pOperation As %String, pType As %String) As %Boolean [ Final, Internal, Private ]
{
	// Wrap with $Get() on %request in case this is called during Open API generation
	// and %request is not available.
	Return $CLASSMETHOD(pResourceClass, "Supports", pOperation, pType, $GET(%request))
}

/// Checks both strategy- and resource-level permissions
ClassMethod CheckAllPermissions(pResourceClass As %Dictionary.Classname, pID As %String, pOperation As %String, pUserContext As %String, ByRef pURLParams) As %Boolean [ Final ]
{
	Return +..ExecuteAuthenticationStrategyMethod("CheckPermission", pResourceClass, pOperation, pUserContext)
		&& $CLASSMETHOD(pResourceClass, "CheckPermission", pID, pOperation, pUserContext, .pURLParams)
}

/// Subclasses must override this to define a custom authentication strategy class.
ClassMethod AuthenticationStrategy() As %Dictionary.Classname [ Abstract ]
{
}

ClassMethod ExecuteAuthenticationStrategyMethod(pMethodName As %String, pArgs...) As %Status [ Internal, Private ]
{
	Set strategyClass = ..AuthenticationStrategy()
	// Check if WithDispatch equivalent exists first and execute if it does
	If $SYSTEM.CLS.IsMthd(strategyClass, pMethodName_"WithDispatch") {
		Return $CLASSMETHOD(strategyClass, pMethodName_"WithDispatch", ..%ClassName(1), pArgs...)
	}
	// WithDispatch did not exist so call without dispatch class
	If $SYSTEM.CLS.IsMthd(strategyClass, pMethodName) {
		Return $CLASSMETHOD(strategyClass, pMethodName, pArgs...)
	}
	// Just return ok as a no-op
	Return $$$OK
}

/// This method Gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. If this case it's the
/// responsibility of the user to return a response.
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	#dim %response As %CSP.Response
	Set sc = $$$OK
	Set endpointList = ..#SupportsCheckEndpoints
	Set ptr = 0
	Set supports = 1
	While $LISTNEXT(endpointList,ptr,endpoint) {
		Set url = $PIECE(endpoint, ":", 1)
		Set method = $PIECE(endpoint, ":", 2)
		If (pUrl = url) && (pMethod = method) {
			Set supports = ..Supports(url, method, %request)
			Quit
		}
	}
	If ('supports) {
		// If not supported, return 404
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	If pMethod '= "OPTIONS" { // OPTIONS requests are never authenticated
		Set sc = ..ExecuteAuthenticationStrategyMethod("Authenticate",pUrl,.pContinue)
		Set pContinue = 1
	}
	Do:'pContinue ..OnHandleCorsRequest(pUrl)
	If (pMethod = "GET") && $ISOBJECT($GET(%session)) {
		// Permit concurrent GET requests
		Do %session.Unlock()
	}
	Quit sc
}

ClassMethod GetUserInfo() As %Status [ Final ]
{
	#dim %response As %CSP.Response
	Set userContext = ..GetUserContext()
	If $ISOBJECT(userContext) {
		Set %response.ContentType = userContext.#MEDIATYPE
		$$$ThrowOnError(userContext.JSONExport())
	} Else {
		Set %response.Status = ..#HTTP204NOCONTENT
	}
	Quit $$$OK
}

ClassMethod GetUserContext() As %pkg.isc.rest.model.resource [ Final ]
{
	$$$ThrowOnError(..ExecuteAuthenticationStrategyMethod("UserInfo",.userInfo))
	Quit ..GetUserResource(.userInfo)
}

ClassMethod AuthLogin() As %Status [ Final ]
{
	#dim %response As %CSP.Response
	$$$ThrowOnError(..ExecuteAuthenticationStrategyMethod("Login",.loginInfo))
	If %response.Status '= ..#HTTP200OK {
		Quit $$$OK
	}
	If loginInfo'="" {
		Set loginResource = ..GetLoginResource(.loginInfo)
		Set %response.ContentType = loginResource.#MEDIATYPE
		$$$ThrowOnError(loginResource.JSONExport())
	} Else {
		Set %response.Status = ..#HTTP204NOCONTENT
	}
	Quit $$$OK
}

ClassMethod LogOut() As %Status [ Final ]
{
	Quit ..ExecuteAuthenticationStrategyMethod("Logout")
}

/// Creates a new instance of the resource (handling a POST request to the resource's endpoint)
ClassMethod Create(resourceName As %String) As %Status [ Final ]
{
	Set operation = $$$OperationCreate

	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	// Get proxy class based on the request's content type header and the resource
	Set resourceClass = ..FindContentClass(resourceName)
	If (resourceClass = "") {
		Return $$$OK
	}

	// First check if endpoint is supported before checking permissions
	Set supported = ..CheckSupportsCreate(resourceClass)
	If ('supported) {
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	
	Set userContext = ..GetUserContext()
	If '..CheckAllPermissions(resourceClass, "", operation, userContext) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", "_operation))
		Return $$$OK
	}
	
	// Grab the json body from the incoming reqeust
	Set json = {}.%FromJSON(%request.Content)
	// Instantiate a proxy without passing an id; this will give us an empty one
	#dim resourceToUse As %pkg.isc.rest.model.resource
	Set resourceToUse = $CLASSMETHOD(resourceClass, "GetModelInstance")
	$$$ThrowOnError(resourceToUse.JSONImport(json))
	Do resourceToUse.SaveModelInstance(userContext)
	
	// Respond with a json block representing the newly posted resource
	Set %response.Status = ..#HTTP201CREATED
	Set %response.ContentType = $PARAMETER(resourceClass, "MEDIATYPE")
	Set sc = resourceToUse.JSONExport()
	$$$ThrowOnError(sc)

	Return $$$OK
}

/// Wrapper around <method>Supports</method> for the <method>Create</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsCreate(pResourceClass As %Dictionary.Classname) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationCreate, $$$TypeOperationClass)
}

ClassMethod CollectionQuery(resourceName As %String) As %Status [ Final ]
{
	Set operation = $$$OperationQuery

	// Grab the parameters that define the filters for the query
	// These come in as URL parameters via the request
	Kill params
	Merge params = %request.Data
	
	// Use the request's content type and resource name to determine which proxy class to use
	Set resourceClass = ..FindAcceptedClass(resourceName)
	If (resourceClass = "") {
		Return $$$OK
	}

	// First check if endpoint is supported before checking permissions
	Set supported = ..CheckSupportsCollectionQuery(resourceClass)
	If ('supported) {
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	
	Set userContext = ..GetUserContext()
	Set authorized = ..CheckAllPermissions(resourceClass, "", operation, userContext, .params)
	If 'authorized {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", "_operation))
		Return $$$OK
	}
	
	Set %response.ContentType = $PARAMETER(resourceClass, "MEDIATYPE")
	
	Try {
		Do $CLASSMETHOD(resourceClass, "GetCollection", .params, ..#QuerySelectMode)
	} Catch e {
		// For well-defined exception types, report appropriately.
		If e.%IsA("%pkg.isc.rest.exception.queryGenerationException") {
			Do ..ReportHttpStatusCode(e.ErrorStatus, $$$ERROR($$$GeneralError,e.DisplayString()))
			Quit
		}
		// Otherwise, re-throw.
		Throw e
	}
	
	Return $$$OK
}

/// Wrapper around <method>Supports</method> for the <method>CollectionQuery</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsCollectionQuery(pResourceClass As %Dictionary.Classname) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationQuery, $$$TypeOperationClass)
}

ClassMethod Retrieve(resourceName As %String, id As %String) As %Status [ Final ]
{
	Set operation = $$$OperationRead

	#dim %response As %CSP.Response
	#dim resource As %pkg.isc.rest.model.resource
	
	Set resourceClass = ..FindAcceptedClass(resourceName)
	If (resourceClass = "") {
		Return 1
	}

	// First check if endpoint is supported before checking permissions
	Set supported = ..CheckSupportsRetrieve(resourceClass)
	If ('supported) {
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	
	If '..CheckAllPermissions(resourceClass, id, operation, ..GetUserContext()) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ID: "_id_", "_operation))
		Return 1
	}
	
	Set %response.ContentType = $PARAMETER(resourceClass, "MEDIATYPE")
	Set resource = $CLASSMETHOD(resourceClass, "GetModelInstance", id)
	Quit resource.JSONExport()
}

/// Wrapper around <method>Supports</method> for the <method>Retrieve</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsRetrieve(pResourceClass As %Dictionary.Classname) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationRead, $$$TypeOperationInstance)
}

ClassMethod Construct(resourceName As %String) As %Status [ Final ]
{
	Set operation = $$$OperationActionNew

	#dim %response As %CSP.Response
	#dim resource As %pkg.isc.rest.model.resource
	
	Set resourceClass = ..FindAcceptedClass(resourceName)
	If (resourceClass = "") {
		Return 1
	}

	// $$$OperationRead with no ID, or $$$OperationActionNew, is usable as validation for this special case.

	// First check if endpoint is supported before checking permissions
	Set supported = ..CheckSupportsConstruct(resourceClass)
	If ('supported) {
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	
	Set userContext = ..GetUserContext()
	If '(..CheckAllPermissions(resourceClass, "", $$$OperationRead, userContext)
		|| ..CheckAllPermissions(resourceClass, "", operation, userContext)) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", "_operation))
		Return 1
	}
	
	Set %response.ContentType = $PARAMETER(resourceClass,"MEDIATYPE")
	Set resource = $CLASSMETHOD(resourceClass, "GetModelInstance")
	Quit resource.JSONExport()
}

/// Wrapper around <method>Supports</method> for the <method>Construct</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
/// $$$OperationRead with no ID, or $$$OperationActionNew, is usable as validation for this special case.
ClassMethod CheckSupportsConstruct(pResourceClass As %Dictionary.Classname) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationRead, $$$TypeOperationClass) ||
..CheckSupports(pResourceClass, $$$OperationActionNew, $$$TypeOperationClass)
}

ClassMethod Update(resourceName As %String, id As %String) As %Status [ Final ]
{
	Set operation = $$$OperationUpdate

	#dim resourceToUse As %pkg.isc.rest.model.resource
	
	// Get proxy class based on the request's content type header and the resource
	Set resourceClass = ..FindContentClass(resourceName)
	If (resourceClass = "") {
		Return $$$OK
	}

	// First check if endpoint is supported before checking permissions
	Set supported = ..CheckSupportsUpdate(resourceClass)
	If ('supported) {
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	
	Set userContext = ..GetUserContext()
	If '..CheckAllPermissions(resourceClass, id, operation, userContext) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ID "_id_", "_operation))
		Return $$$OK
	}
	
	// Grab the json body from the incoming reqeust
	Set json = {}.%FromJSON(%request.Content)
	Set resourceToUse = $CLASSMETHOD(resourceClass, "GetModelInstance", id)
	$$$ThrowOnError(resourceToUse.JSONImport(json))
	Do resourceToUse.SaveModelInstance(userContext)
	
	Set %response.ContentType = $PARAMETER(resourceClass,"MEDIATYPE")
	Set sc = resourceToUse.JSONExport()
	$$$ThrowOnError(sc)
	
	Return $$$OK
}

/// Wrapper around <method>Supports</method> for the <method>Update</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsUpdate(pResourceClass As %Dictionary.Classname) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationUpdate, $$$TypeOperationInstance)
}

ClassMethod Delete(resourceName As %String, id As %String) As %Status [ Final ]
{
	Set operation = $$$OperationDelete

	#dim %response As %CSP.Response
	#dim resource As %pkg.isc.rest.model.resource
	
	Set resourceClass = ..FindContentClass(resourceName)
	If (resourceClass = "") {
		Return 1
	}

	// First check if endpoint is supported before checking permissions
	Set supported = ..CheckSupportsDelete(resourceClass)
	If ('supported) {
		Set %response.Status = ..#HTTP404NOTFOUND
		Return $$$OK
	}
	
	If '..CheckAllPermissions(resourceClass, id, operation, ..GetUserContext()) {
		Set %response.Status = ..#HTTP403FORBIDDEN
		Return $$$OK
	}
	
	Set deleted = $CLASSMETHOD(resourceClass, "DeleteModelInstance", id)
	If deleted {
		Set %response.Status = ..#HTTP204NOCONTENT
	} Else {
		Set %response.Status = ..#HTTP404NOTFOUND
	}
	Quit $$$OK
}

/// Wrapper around <method>Supports</method> for the <method>Delete</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsDelete(pResourceClass As %Dictionary.Classname) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationDelete, $$$TypeOperationInstance)
}

ClassMethod DispatchClassAction(resourceName As %String, action As %String) As %Status [ Final ]
{
	Set operation = $$$OperationAction(action)

	#dim %response As %CSP.Response
	#dim resource As %pkg.isc.rest.model.resource

	Try {
		Kill params
		Merge params = %request.Data
		
		Set actionClass = ..FindActionClass(resourceName, action, "class", .resourceClass)
		If (actionClass = "") {
			Quit
		}

		// First check if endpoint is supported before checking permissions
		Set supported = ..CheckSupportsDispatchClassAction(resourceClass, action)
		If ('supported) {
			Set %response.Status = ..#HTTP404NOTFOUND
			Quit
		}
		
		Set userContext = ..GetUserContext()
		If '..CheckAllPermissions(resourceClass, "", operation, userContext, .params) {
			Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", "_operation))
			Quit
		}
		Do $CLASSMETHOD(actionClass,"HandleInvokeClassAction", %request.Method, action, userContext)
	} Catch err {
		If err.%IsA("%pkg.isc.rest.exception.httpStatusException") {
			Do ..ReportHttpStatusCode(err.StatusCode)
		} Else {
			Throw err
		}
	}
	
	Return $$$OK
}

/// Wrapper around <method>Supports</method> for the <method>DispatchClassAction</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsDispatchClassAction(pResourceClass As %Dictionary.Classname, pAction As %String) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationAction(pAction), $$$TypeOperationClass)
}

ClassMethod DispatchInstanceAction(resourceName As %String, id As %String, action As %String) As %Status [ Final ]
{
	Set operation = $$$OperationAction(action)

	#dim %response As %CSP.Response
	#dim resource As %pkg.isc.rest.model.resource
	Try {	
		Kill params
		Merge params = %request.Data
		
		Set actionClass = ..FindActionClass(resourceName, action, "instance", .resourceClass)
		If (actionClass = "") {
			Quit
		}

		// First check if endpoint is supported before checking permissions
		Set supported = ..CheckSupportsDispatchInstanceAction(resourceClass, action)
		If ('supported) {
			Set %response.Status = ..#HTTP404NOTFOUND
			Quit
		}
		
		Set userContext = ..GetUserContext()
		If '..CheckAllPermissions(resourceClass, id, operation, userContext, .params) {
			Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ID "_id_", "_operation))
			Quit
		}
		
		Set resourceInstance = $CLASSMETHOD(resourceClass, "GetModelInstance", id)
		Do $CLASSMETHOD(actionClass,"HandleInvokeInstanceAction", %request.Method, resourceInstance, action, userContext)
	} Catch err {
		If err.%IsA("%pkg.isc.rest.exception.httpStatusException") {
			Do ..ReportHttpStatusCode(err.StatusCode)
		} Else {
			Throw err
		}
	}
	
	Return $$$OK
}

/// Wrapper around <method>Supports</method> for the <method>DispatchInstanceAction</method>
/// operation. Use this wrapper so it can be invoked from Open API generation.
ClassMethod CheckSupportsDispatchInstanceAction(pResourceClass As %Dictionary.Classname, pAction As %String) [ CodeMode = expression, Final, Internal ]
{
..CheckSupports(pResourceClass, $$$OperationAction(pAction), $$$TypeOperationInstance)
}

ClassMethod FindActionClass(pResource As %String, pAction As %String, pTarget As %String, Output pResourceClass As %Dictionary.Classname) As %Dictionary.Classname [ Final, Private ]
{
	#dim %response As %CSP.Response
	#dim %request As %CSP.Request
	
	Set acceptsList = ..GetMediaTypeListFromAcceptHeader()
	Set contentType = ..GetMediaTypeFromContentType()
	
	Set contentTypeList = $LISTBUILD(contentType, $CHAR(0))

	#dim map As %pkg.isc.rest.actionMap
	Set map = ##class(%pkg.isc.rest.actionMap).FindActionForRequest(
		$CLASSNAME(),
		pResource,
		pTarget,
		acceptsList,
		contentTypeList,
		%request.Method,
		pAction,
		.hasMatchedAction,
		.supportedHttpVerbs
	)
	If $ISOBJECT(map) {
		// Success
		Set pResourceClass = map.ResourceClass
		Return map.ImplementationClass
	}
	// Naive approach: complain about media type.
	If hasMatchedAction {
		// If matched action but not method as well, then complain about invalid method
		Set %response.Status = ..#HTTP405METHODNOTALLOWED
		Set %response.ContentType = ..#CONTENTTYPEJSON
		Set result = { "supportedHttpVerbs": (supportedHttpVerbs) }
		Do result.%ToJSON()
	} Else {
		Set supportedTypesArr = ##class(%pkg.isc.rest.actionMap).FindSupportedMediaTypesForRequest(
			$CLASSNAME(),
			pResource,
			pTarget,
			%request.Method,
			pAction,
			.resourceFound,
			.actionFound
		)
		If ('resourceFound) {
			// No resource found so return 404
			Do ..ReportHttpStatusCode(..#HTTP404NOTFOUND, $$$ERROR($$$GeneralError,"No resource found"))
		} ElseIf ('actionFound) {
			// No action found so return 404
			Do ..ReportHttpStatusCode(..#HTTP404NOTFOUND, $$$ERROR($$$GeneralError,"No action found"))
		} Else {
			// Descriptive info about media types available for the specified resource/action
			Set httpStatus = ..#HTTP406NOTACCEPTABLE
			If (contentType '= "") && (%request.Content.Size > 0) {
				// Naive approach: complain about media type if it is non-empty
				Set httpStatus = ..#HTTP415UNSUPPORTEDMEDIATYPE
			}
			Set %response.Status = httpStatus
			Set %response.ContentType = ..#CONTENTTYPEJSON
			Set result = {
				"supportedTypes": (supportedTypesArr)
			}
			Do result.%ToJSON()
		}
	}
	Return ""
}

ClassMethod FindAcceptedClass(pResource As %String) As %Dictionary.Classname [ Final, Private ]
{
	#dim %request As %CSP.Request
	Quit ..FindClass(..GetMediaTypeListFromAcceptHeader(),pResource,..#HTTP406NOTACCEPTABLE,1)
}

ClassMethod FindContentClass(pResource As %String) As %Dictionary.Classname [ Final, Private ]
{
	#dim %request As %CSP.Request
	Quit ..FindClass($LISTBUILD(..GetMediaTypeFromContentType()),pResource,..#HTTP415UNSUPPORTEDMEDIATYPE)
}

ClassMethod FindClass(pMediaTypeList As %Library.List, pResource As %String, pStatusWhenInvalid As %String, pLookForDefault As %Boolean = 0) As %Dictionary.Classname [ Final, Private ]
{
	Set pointer = 0
	Set resourceClass = ""
	Set foundJSON = 0
	While $LISTNEXT(pMediaTypeList,pointer,type) {
		If '$MATCH(type,..#AllowedMediaTypeRegex) {
			Continue
		}
		Set foundJSON = 1
		
		If ##class(%pkg.isc.rest.resourceMap).UniqueByContextExists($CLASSNAME(),pResource,type,.id) {
			Set resourceClass = ##class(%pkg.isc.rest.resourceMap).ResourceClassGetStored(id)
			Quit
		}
	}
	
	If pLookForDefault && (resourceClass = "") {
		Set resourceClass = ##class(%pkg.isc.rest.resourceMap).FindDefaultResourceForRequest($CLASSNAME(), pResource, pMediaTypeList)
	}
	
	If (resourceClass = "") {
		// Look for resource and all of its available media types
		#dim resultSet As %SQL.StatementResult
		Set query = "SELECT DISTINCT MediaType FROM %pkg_isc_rest.resourceMap "_
			"WHERE DispatchClass = ? AND ResourceName = ?"
		Set resultSet = ##class(%SQL.Statement).%ExecDirect(, query, $CLASSNAME(), pResource)
		$$$ThrowSQLIfError(resultSet.%SQLCODE,resultSet.%Message)
		Set count = 0
		#dim mediaTypeArr As %DynamicArray
		Set mediaTypeArr = []
		While (resultSet.%Next(.sc)) {
			$$$ThrowOnError(sc)
			Do $INCREMENT(count)
			Do mediaTypeArr.%Push($$$lcase(resultSet.%Get("MediaType")))
		}
		$$$ThrowOnError(sc)
		If (count = 0) {
			// No resources found matching name
			Do ..ReportHttpStatusCode(..#HTTP404NOTFOUND, $$$ERROR($$$GeneralError,"No resource found"))
		} Else {
			Set %response.Status = pStatusWhenInvalid
			Set %response.ContentType = ..#CONTENTTYPEJSON
			Set errorText = $CASE(foundJSON, 
				1: "Failed to find matching resource class.",
				 : "Only JSON is supported."
			)
			Set result = {
				"error": (errorText),
				"supportedMediaTypes": (mediaTypeArr)
			}
			Do result.%ToJSON()
		}
	}
	
	Return resourceClass
}

ClassMethod OrderMediaTypeList(pList As %List) As %List [ Final, Internal ]
{
	Set pointer = 0
	While $LISTNEXT(pList,pointer,item) {
		Set order = $LENGTH(item,"*")
		Set array(order,$INCREMENT(array(order))) = item
	}
	Set orderedList = ""
	For order=1:1:3 {
		For i=1:1:$GET(array(order)) {
			Set orderedList = orderedList_$LISTBUILD(array(order,i))
		}
	}
	Quit orderedList
}

ClassMethod GetMediaTypeFromContentType() As %String [ Final, Internal ]
{
	// Strip away charset/boundary: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type
	// Strip away leading and trailing white space
	Return $ZSTRIP($PIECE(%request.ContentType, ";", 1), "<>W")
}

ClassMethod GetMediaTypeListFromAcceptHeader() As %Library.List [ Final, Internal ]
{
	// Order media types based on q-factor:
	// https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept
	Set types = $LISTFROMSTRING(%request.GetCgiEnv("HTTP_ACCEPT"),",")
	Kill qFactorToTypeArray
	Set typePtr = 0
	While $LISTNEXT(types,typePtr,type) {
		// Strip leading and trailing white space
		Set resolvedType = $ZSTRIP($PIECE(type,";", 1), "<>W")
		// Strip remaining type since stuff other than q factor could be in there. If so, we ignore
		// it and only handle the q factor
		Set remainingTypeList = $LISTFROMSTRING($ZSTRIP($PIECE(type,";", 2, *), "<>W"),";")
		Set remTypePtr = 0
		// Default is 1
		Set qFactorValue = 1
		While $LISTNEXT(remainingTypeList,remTypePtr,remType) {
			Set remTypeValue = $PIECE(remType, "=", 2)
			If $MATCH(remType, "q=.*") && $ISVALIDDOUBLE(remTypeValue,3,0,1) {
				Set qFactorValue = remTypeValue
			}
		}
		// Multiply by 1000 to get correct ordering with no decimals in subscripts
		Set qFactorValue = qFactorValue * 1000 
		Set qFactorToTypeArray(qFactorValue) = $GET(qFactorToTypeArray(qFactorValue)) _ $LISTBUILD(resolvedType)
	}
	// Iterate array in reverse order
	Set list = ""
	Set key = ""
	While 1 {
		Set key = $ORDER(qFactorToTypeArray(key), -1, value)
		If (key = "") {
			Quit
		}
		If ($LISTLENGTH(value) = 1) {
			// Directly append
			Set list = list _ value
		} Else {
			// TODO: Order based on specificity when multiple values with same q-factor - 
			// https://developer.mozilla.org/en-US/docs/Glossary/Quality_values
			// For now, directly append
			Set list = list _ value
		}
	}
	If (list = "") {
		Set list = $LISTBUILD($CHAR(0),"*/*")
	}
	If $LISTFIND(list,"*/*") {
		Set list = list _ $LISTBUILD($CHAR(0))
	}
	Return list
}

/// Errors are logged to the application error log, which is time- and space-intensive; use with care in production environments.
/// Possible values for pLogLevel:
/// <ul>
/// <li>0 (default): Log no errors</li>
/// <li>1: Log system errors only</li>
/// <li>2: Log all errors</li>
/// </ul>
ClassMethod SetLogLevel(pLogLevel As %Integer = 0)
{
	Set $$$RESTErrorLogConfigGbl($CLASSNAME()) = +pLogLevel
}

/// Subclasses may override to customize logging. <br />
/// To suppress error logging, set ^Config("isc","rest","suppressLogging") = 1
ClassMethod LogErrorStatus(pStatus As %Status)
{
	Set isSystemError = $SYSTEM.Status.GetErrorCodes(pStatus) [ $$$CacheError
	Set logLevel = $GET($$$RESTErrorLogConfigGbl($CLASSNAME()),0)
	If (isSystemError && logLevel) || (logLevel > 1) {
		Set e = ##class(%Exception.StatusException).CreateFromStatus(pStatus)
		// Don't log <EXTERNAL INTERRUPT> as it doesn't indicate an application error
		If (e.Name '= "<EXTERNAL INTERRUPT>") {
			Do e.Log()
		}
	}
}

/// Issue an 'Http' error
ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}) As %Status
{
	#dim %request As %CSP.Request
	If $$$ISERR(pSC) {
		Do ..LogErrorStatus(pSC)
	}
	
	// If a default HTTP status is supplied, try to be more descriptive.
	If (pHttpStatus = ..#HTTP500INTERNALSERVERERROR) {
		// Special cases for pSC:
		If $SYSTEM.Status.Equals(pSC,$$$AccessDenied) {
			// $$$AccessDenied -> 403 Forbidden
			Set %response.Status = ..#HTTP403FORBIDDEN
			Quit $$$OK
		} ElseIf $SYSTEM.Status.Equals(pSC,$$$GeneralException) {
			// JSON parsing exception
			Set %response.Status = ..#HTTP400BADREQUEST
			Quit $$$OK
		} ElseIf $SYSTEM.Status.Equals(pSC,$$$LoadObjectNotFound)
			|| $SYSTEM.Status.Equals(pSC,$$$KeyValueNotFoundOpen) {
			// $$$LoadObjectNotFound -> 404 (GET or anything else) or 409 (PUT)
			If (%request.Method = "PUT") {
				Quit ##super(..#HTTP409CONFLICT,pSC)
			} Else {
				Quit ##super(..#HTTP404NOTFOUND,pSC)
			}
		} ElseIf $SYSTEM.Status.Equals(pSC,$$$NotImplemented) {
			// Not implemented means doesn't exist so respond with 404
			Quit ##super(..#HTTP404NOTFOUND,pSC)
		}
	} ElseIf (pHttpStatus = ..#HTTP403FORBIDDEN) && $$$ISERR(pSC) {
		// Don't be too descriptive, though full details of the violation are logged.
		Set %response.Status = ..#HTTP403FORBIDDEN
		Quit $$$OK
	}
    Quit ##super(pHttpStatus,pSC)
}

/// Overridden to use StatusToJSON() for proper escaping
ClassMethod outputStatus(pSC As %Status) As %Status [ Internal ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        #dim tJSON As %ZEN.proxyObject
        If ..AcceptsContentType("application/json") {
            Set %response.ContentType = ..#CONTENTTYPEJSON
            // Convert the exception to a status and render to JSON
            Set tSC = ..StatusToJSON(pSC, .tJSON)
            If $$$ISERR(tSC) Quit
            // Write the JSON to the output device
           	Do tJSON.%ToJSON()
        } Else {
            // Set plain text
            Set %response.ContentType = ..#CONTENTTYPETEXT
            // Write out a simple text message
            Do ##class(%Exception.StatusException).CreateFromStatus(pSC).OutputToDevice()
        }
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    Quit $$$OK
}

}

