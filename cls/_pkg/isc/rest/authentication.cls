/// Interface for authentication methods used in subclasses of <class>%pkg.isc.rest.handler</class>
Class %pkg.isc.rest.authentication Extends %RegisteredObject [ Abstract ]
{

/// Implement to define custom authentication logic that will be run OnPreDispatch.
/// If pContinue is set to false, the request will not be dispatched.
ClassMethod Authenticate(pUrl As %String, ByRef pContinue As %Boolean) As %Status [ Abstract ]
{
}

/// Returns authenticated user information for the request or session
ClassMethod UserInfo(Output pUserInfo As %DynamicObject) As %Status [ Abstract ]
{
}

ClassMethod Logout() As %Status [ Abstract ]
{
}

/// Allows centralized control over permission checking,
/// which is applied *in addition* to resource-level permission checks.
/// If unimplemented, only resource-level checks are used.
/// For a granular permission-based scheme, see <class>%pkg.isc.rest.authorization.permission</class>.
ClassMethod CheckPermission(pResourceClassName As %Dictionary.CacheClassname, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean [ Abstract ]
{
}

}

