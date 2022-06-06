Class isc.sample.rest.phonebook.rest.Handler Extends %pkg.isc.rest.handler
{

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit ##class(%pkg.isc.rest.authentication.platformBased).%ClassName(1)
}

ClassMethod CheckResourcePermitted(resourceClass As %Dictionary.Classname) As %Boolean
{
	Quit $Piece(resourceClass,".",1,4) = "isc.sample.rest.phonebook"
}


ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As %pkg.isc.rest.authentication.platformUser
{
    Quit ##class(%pkg.isc.rest.authentication.platformUser).%New()
}

}
