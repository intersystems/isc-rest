Class UnitTest.isc.rest.sample.handler Extends %pkg.isc.rest.handler
{

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit "%pkg.isc.rest.authentication.platformBased"
}

ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As UnitTest.isc.rest.sample.userContext
{
	Quit ##class(UnitTest.isc.rest.sample.userContext).%New()
}

/// Subclasses MUST override this method to specify which resource classes are allowed
/// as part of the API.
ClassMethod CheckResourcePermitted(resourceClass As %Dictionary.Classname) As %Boolean
{
	Quit $Piece(resourceClass,".",1,4) = "UnitTest.isc.rest.sample"
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
	If (pEndpoint = "/auth/logout") {
		Return 0
	}
	Return 1
}

}

