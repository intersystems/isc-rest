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

}

