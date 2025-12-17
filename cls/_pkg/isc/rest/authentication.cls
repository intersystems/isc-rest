/// Interface for authentication methods used in subclasses of <class>%pkg.isc.rest.handler</class>
/// NOTE: All methods have *WithDispatch equivalents. If the WithDispatch equivalents are implemented,
/// they are executed instead. These provide the callback with an additional argument of the dispatch 
/// class.
Class %pkg.isc.rest.authentication Extends %RegisteredObject [ Abstract ]
{

/// Implement to define custom authentication logic that will be run OnPreDispatch.
/// If pContinue is set to false, the request will not be dispatched.
ClassMethod Authenticate(pUrl As %String, ByRef pContinue As %Boolean) As %Status [ Abstract ]
{
}

/// Equivalent to <method>Authenticate</method> with additional argument <var>DispatchClass</var>
/// of the calling dispatch class.
ClassMethod AuthenticateWithDispatch(pDispatchClass As %Dictionary.Classname, pUrl As %String, ByRef pContinue As %Boolean) As %Status [ Abstract ]
{
}

/// Returns authenticated user information for the request or session
ClassMethod UserInfo(Output pUserInfo As %DynamicObject) As %Status [ Abstract ]
{
}

/// Equivalent to <method>UserInfo</method> with additional argument <var>DispatchClass</var>
/// of the calling dispatch class.
ClassMethod UserInfoWithDispatch(pDispatchClass As %Dictionary.Classname, Output pUserInfo As %DynamicObject) As %Status [ Abstract ]
{
}

/// Invoked when /auth/login is called.
ClassMethod Login(Output pLoginInfo As %DynamicObject) As %Status [ Abstract ]
{
}

/// Equivalent to <method>Login</method> with additional argument <var>DispatchClass</var>
/// of the calling dispatch class.
ClassMethod LoginWithDispatch(pDispatchClass As %Dictionary.Classname, Output pLoginInfo As %DynamicObject) As %Status [ Abstract ]
{
}

/// Invoked when /auth/logout is called.
ClassMethod Logout() As %Status [ Abstract ]
{
}

/// Equivalent to <method>Logout</method> with additional argument <var>DispatchClass</var>
/// of the calling dispatch class.
ClassMethod LogoutWithDispatch(pDispatchClass As %Dictionary.Classname) As %Status [ Abstract ]
{
}

/// Allows centralized control over permission checking,
/// which is applied *in addition* to resource-level permission checks.
/// If unimplemented, only resource-level checks are used.
/// For a granular permission-based scheme, see <class>%pkg.isc.rest.authorization.permission</class>.
ClassMethod CheckPermission(pResourceClassName As %Dictionary.Classname, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean [ Abstract ]
{
}

/// Equivalent to <method>CheckPermission</method> with additional argument <var>DispatchClass</var>
/// of the calling dispatch class.
ClassMethod CheckPermissionWithDispatch(pDispatchClass As %Dictionary.Classname, pResourceClassName As %Dictionary.Classname, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean [ Abstract ]
{
}

}

