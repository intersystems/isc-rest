Class UnitTest.isc.rest.authorization.permission Extends %UnitTest.TestCase
{

Method TestCompile()
{
	Do $$$AssertStatusOK($System.OBJ.Compile("UnitTest.isc.rest.authorization.permission.samplePermission","ck-d/nomulticompile"))
}

Method TestPermissions()
{
	New %ROWID
	Do ##class(UnitTest.isc.rest.authorization.permission.samplePermission).%KillExtent()
	
	&sql(insert into UnitTest_isc_rest_authorization_permission.samplePermission
		(ResourceClass,Context,Operation) values
		('UnitTest.isc.rest.authorization.permission.samplePermission','SampleContext','CREATE'))
	Set instId = %ROWID
	Set instance = ##class(UnitTest.isc.rest.authorization.permission.samplePermission).%OpenId(%ROWID,,.sc)
	$$$ThrowOnError(sc)
	
	Set grantedResult = ##class(UnitTest.isc.rest.authorization.permission.samplePermission).ListGrantedPermissionsFunc("SampleContext")
	Do $$$AssertTrue(grantedResult.%Next(.sc))
	Do $$$AssertStatusOK(sc)
	#dim result As UnitTest.isc.rest.authorization.permission.samplePermission
	
	For test = $This,grantedResult {
		Set result = ##class(UnitTest.isc.rest.authorization.permission.samplePermission).GetModelFromResultRow(test)
		Do $$$AssertEquals(result.MediaType,"application/json")
		Do $$$AssertEquals(result.ResourceName,"unit-test-permission")
		Do $$$AssertEquals(result.ResourceClass,"UnitTest.isc.rest.authorization.permission.samplePermission")
		Do $$$AssertEquals(result.Granted,1)
		Do $$$AssertEquals(result.Context,"SampleContext")
		Do $$$AssertEquals(result.Operation,"CREATE")
	}
}

Method %Get(pColName As %String) As %String
{
	Quit %ROWID
}

}

