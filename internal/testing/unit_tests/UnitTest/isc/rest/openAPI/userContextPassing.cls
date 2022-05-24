Class UnitTest.isc.rest.openAPI.userContextPassing Extends UnitTest.isc.rest.openAPI.testCase
{

Method OnBeforeOneTest() As %Status
{
	kill ^pkg.isc.rest.documentation.parameters
	Kill ^pkg.isc.rest.documentation.stage
	return $$$OK
}

Method OnAfterOneTest() As %Status
{
	Set classname = ""
	Do ..ClassTracker.GetNext(.classname)
	While classname '= "" {
		Do ..TeardownClass(classname)
		Do ..ClassTracker.GetNext(.classname)
	}
	Return ##super()
}

/// The current user context needs to be passed between processes to kick off an asynchronous build using the build-documentation endpoint
/// This test ensures that the user context is passed correctly in a number of different conditions
/// Note that the actual documentation building will error out as the %CSP.Request in use does not have its Application property set;
///   this does not affect whether or not the user context is passed properly, which is what this unit test is checking for
Method TestUserContextPersistentInDB()
{
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["AuthenticationStrategy","CheckPermissionHandlerAllowAll:CheckPermission"])
	Do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"), "REST Handler was compiled correctly")
	
	// Test
    Set userContext = ##class(UnitTest.isc.rest.openAPI.nonTransientResource).%New()
    Set userContext.TestProperty = "test string value 1"
    Do userContext.%Save()
	do $classmethod("zUnitTest.isc.rest.handler","BuildDocumentationInternal",1, 0, "/test/application", "", userContext.%Id(), $classname(userContext))
	// Verify
	Set userContextVerbose = $Get(^pkg.isc.rest.documentation.parameters("Build","userContext","verbose"))
	Do $$$LogMessage("Job recieved userContext " _ userContextVerbose)
	set expected = userContext.%Id() _ "@UnitTest.isc.rest.openAPI.nonTransientResource: {""TestProperty"":""test string value 1""}" 
	Do $$$AssertEquals(expected, userContextVerbose, "Persistent serializable class (saved to the database) was passed correctly to the documentation build job")
	Do ##class(UnitTest.isc.rest.openAPI.nonTransientResource).%DeleteExtent()
}

/// Test #2: User context is an instance of a persistent serializable class (not saved to the database)
Method TestUserContextPersistentNotInDB()
{
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["AuthenticationStrategy","CheckPermissionHandlerAllowAll:CheckPermission"])
	Do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"), "REST Handler was compiled correctly")

	// Test
    Set userContext = ##class(UnitTest.isc.rest.openAPI.nonTransientResource).%New()
    Set userContext.TestProperty = "test string value 1"
	do $classmethod("zUnitTest.isc.rest.handler","BuildDocumentationInternal",1, 0, "/test/application", "{""TestProperty"":""test string value 2""}", , $classname(userContext))
	// Verify
	Set userContextVerbose = $Get(^pkg.isc.rest.documentation.parameters("Build","userContext","verbose"))
	Do $$$LogMessage("Job recieved userContext " _ userContextVerbose)
	set expected = "UnitTest.isc.rest.openAPI.nonTransientResource: {""TestProperty"":""test string value 2""}"
	Do $$$AssertEquals(expected, userContextVerbose, "Persistent serializable class (NOT saved to the database) was passed correctly to the documentation build job")
}

/// Test #3: User context is an instance of a non-persistent serializable class
Method TestUserContextNotPersistent()
{
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["AuthenticationStrategy","CheckPermissionHandlerAllowAll:CheckPermission"])
	Do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"), "REST Handler was compiled correctly")

	// Setup
	set sc = ..SetupClass("zUnitTest.isc.rest.transientClass1", ["%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource"}, "TestProperty")
	Do $$$AssertStatusOK(sc, "Transient serializable class was set-up correctly")
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.transientClass1"), "Transient serializable class was compiled correctly")
	// Test
    Set userContext = $ClassMethod("zUnitTest.isc.rest.transientClass1", "%New")
    Set userContext.TestProperty = "test string value 3"
	do $classmethod("zUnitTest.isc.rest.handler","BuildDocumentationInternal",1, 0, "/test/application", "{""TestProperty"":""test string value 3""}", , $classname(userContext))
	// Verify
	Set userContextVerbose = $Get(^pkg.isc.rest.documentation.parameters("Build","userContext","verbose"))
	Do $$$LogMessage("Job recieved userContext " _ userContextVerbose)
	set expected = "zUnitTest.isc.rest.transientClass1: {""TestProperty"":""test string value 3""}"
	Do $$$AssertEquals(expected, userContextVerbose, "Non-persistent serializable class was passed correctly to the documentation build job")

	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.transientClass1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit ##class(%pkg.isc.rest.authentication.platformBased).%ClassName(1)
}

ClassMethod CheckPermissionHandlerAllowAll(pEndpoint As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return 1
}

}

