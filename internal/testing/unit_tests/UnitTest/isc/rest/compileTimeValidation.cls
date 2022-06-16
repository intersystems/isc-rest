Class UnitTest.isc.rest.compileTimeValidation Extends UnitTest.isc.rest.openAPI.testCase
{

Method TestRequiredHandlerMethods()
{
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["CheckResourcePermitted","AuthenticationStrategy"])
	do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.handler")
	do $$$AssertStatusOK(compileStatus, "REST Handler compiled without error.")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["CheckResourcePermitted"])
	do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.handler",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "REST Handler compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Method AuthenticationStrategy must be defined for class zUnitTest.isc.rest.handler")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["AuthenticationStrategy"])
	do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.handler",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "REST Handler compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Method CheckResourcePermitted must be defined for class zUnitTest.isc.rest.handler")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext")
	do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.handler",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "REST Handler compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Method AuthenticationStrategy must be defined for class zUnitTest.isc.rest.handler")
	do $$$AssertEquals(errorLog(2,"param",1),"Method CheckResourcePermitted must be defined for class zUnitTest.isc.rest.handler")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestRequiredResourceParameters()
{
	do ..TeardownClass("zUnitTest.isc.rest.resource")
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%pkg.isc.rest.model.resource"],
		{"RESOURCENAME":"unittest-resource"}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(compileStatus, "Resource class compiled without error.")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%pkg.isc.rest.model.resource"],, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter RESOURCENAME must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
}

Method TestRequiredDBMappedResourceParameters()
{
	do ..TeardownClass("zUnitTest.isc.rest.resource")
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"],
		{"SOURCECLASS":"zUnitTest.isc.rest.resource"}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter RESOURCENAME must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"],
		{"RESOURCENAME":"unittest-resource"}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter SOURCECLASS must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%pkg.isc.rest.model.dbMappedResource"],, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter RESOURCENAME must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertEquals(errorLog(2,"param",1),"Parameter SOURCECLASS must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
}

Method TestRequiredProxyParameters()
{
	do ..TeardownClass("zUnitTest.isc.rest.resource")
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%Persistent","%pkg.isc.rest.model.proxy"],
		{"SOURCECLASS":"zUnitTest.isc.rest.resource"}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter RESOURCENAME must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%Persistent","%pkg.isc.rest.model.proxy"],
		{"RESOURCENAME":"unittest-resource"}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter SOURCECLASS must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%pkg.isc.rest.model.proxy"],, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter RESOURCENAME must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertEquals(errorLog(2,"param",1),"Parameter SOURCECLASS must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
}

Method TestRequiredAdaptorParameters()
{
	do ..TeardownClass("zUnitTest.isc.rest.resource")
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%Persistent","%pkg.isc.rest.model.adaptor"],
		{"RESOURCENAME":"unittest-resource"}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusOK(compileStatus, "Resource class compiled without error.")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
	
	set sc = ..SetupClass("zUnitTest.isc.rest.resource", ["%pkg.isc.rest.model.adaptor"],, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"Parameter RESOURCENAME must be defined for class zUnitTest.isc.rest.resource")
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource"))
}

Method TestMultiDefaultResources()
{
	do ..TeardownClass("zUnitTest.isc.rest.handler")
	do ..TeardownClass("zUnitTest.isc.rest.resource1")
	do ..TeardownClass("zUnitTest.isc.rest.resource2")
	
	set sc = ..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, "UserContext",,, ,,, , 
		["CheckResourcePermitted","AuthenticationStrategy"])
	do $$$AssertStatusOK(sc, "REST Handler was set-up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.handler")
	do $$$AssertStatusOK(compileStatus, "REST Handler compiled without error.")
		
	set sc = ..SetupClass("zUnitTest.isc.rest.resource1", ["%Persistent","%pkg.isc.rest.model.adaptor"],
		{"RESOURCENAME":"unittest-resource","DEFAULT":1}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource1")
	do $$$AssertStatusOK(compileStatus, "Resource class compiled without error.")
		
	set sc = ..SetupClass("zUnitTest.isc.rest.resource2", ["%Persistent","%pkg.isc.rest.model.adaptor"],
		{"RESOURCENAME":"unittest-resource","DEFAULT":1}, "TestProperty")
	do $$$AssertStatusOK(sc, "Resource class was set up correctly")
	set compileStatus = ..CompileClass("zUnitTest.isc.rest.resource2",.errorLog)
	do $$$AssertStatusNotOK(compileStatus, "Resource class compiled with error.")
	do $$$AssertEquals(errorLog(1,"param",1),"zUnitTest.isc.rest.resource1 is already registered as the default resource for name unittest-resource in dispatch class zUnitTest.isc.rest.handler")
	
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource1"))
	do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.resource2"))
}

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    quit ##class(%pkg.isc.rest.authentication.platformBased).%ClassName(1)
}

ClassMethod CheckResourcePermitted(resourceClass As %Dictionary.Classname) As %Boolean
{
	quit $Piece(resourceClass,".",1,3) = "zUnitTest.isc.rest"
}

}

