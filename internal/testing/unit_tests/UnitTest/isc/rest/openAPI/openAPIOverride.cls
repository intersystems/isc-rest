Class UnitTest.isc.rest.openAPI.openAPIOverride Extends %pkg.isc.rest.openAPI
{

Property UnitTestOverrideClassName As %String [ Internal, Private ];

Property UnitTestOverrideMethodName As %String [ Internal, Private ];

Method %OnNew(className, methodName) As %Status
{
	Set ..UnitTestOverrideClassName = className
	Set ..UnitTestOverrideMethodName = methodName
	Return ##super()
}

Method GetWebApplicationInfo() [ Internal ]
{
	Do $ClassMethod(..UnitTestOverrideClassName, ..UnitTestOverrideMethodName, $This)
}

}

