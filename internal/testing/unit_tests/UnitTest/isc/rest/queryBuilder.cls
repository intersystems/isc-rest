Class UnitTest.isc.rest.queryBuilder Extends %UnitTest.TestCase
{

Method TestCompiling()
{
	Do $$$AssertStatusOK($System.OBJ.Compile("UnitTest.isc.rest.samplePersistentAdapted","ck/nomulticompile"))
}

Method TestValidEverything()
{
	Set p("someField[noteq]",1) = 2 // someField is the JSON alias for 'Foo'
	Set p("Bar[isnull]",1) = ""
	Do ..GetQueryWrapper(.p,.query,.params,.prepareStatus,.exception)
	If $$$AssertEquals($Data(exception),0) {
		Do $$$AssertEquals(query,"select ID from UnitTest_isc_rest.samplePersistentAdapted where 1=1 and Bar is null and not FOO_NAME = ?")
		Do $$$AssertEquals(params,1)
		Do $$$AssertEquals(params(1),2)
		Do $$$AssertStatusOK(prepareStatus)
	} Else {
		Do $$$AssertFailure("Exception occured: "_exception.DisplayString())
	}
}

Method TestIllegalColumnExpression()
{
	Set p("Baz union all select 1 -- [eq]",1) = "42"
	Do ..GetQueryWrapper(.p,.query,.params,.prepareStatus,.exception)
	If $$$AssertEquals($Data(exception),1) {
		Do $$$AssertEquals($classname(exception),"%pkg.isc.rest.exception.invalidColumnException")
	} Else {
		Do $$$AssertFailure("Exception should have been thrown.")
	}
}

Method TestInvalidColumnName()
{
	// For now, a runtime error preparing the query.
	Set p("Qux[eq]",1) = "42"
	Do ..GetQueryWrapper(.p,.query,.params,.prepareStatus,.exception)
	If $$$AssertEquals($Data(exception),1) {
		Do $$$AssertEquals($classname(exception),"%pkg.isc.rest.exception.invalidColumnException")
	} Else {
		Do $$$AssertFailure("Exception should have been thrown.")
	}
}

Method TestInvalidOrderBy()
{
	Set p("$orderBy",1) = "baz union all select 1"
	Do ..GetQueryWrapper(.p,.query,.params,.prepareStatus,.exception)
	If $$$AssertEquals($Data(exception),1) {
		Do $$$AssertEquals($classname(exception),"%pkg.isc.rest.exception.invalidColumnException")
	} Else {
		Do $$$AssertFailure("Exception should have been thrown.")
	}
}

Method GetQueryWrapper(ByRef URLParams, Output query As %String, Output queryParams, Output prepareStatus As %Status, Output exception As %Exception.AbstractException)
{
	Kill query, queryParams, prepareStatus, exception
	Try {
		Set query = ##class(%pkg.isc.rest.queryGenerator).GetQuery(
			"UnitTest.isc.rest.samplePersistentAdapted",
			##class(UnitTest.isc.rest.samplePersistentAdapted).GetProxyColumnList(),
			##class(UnitTest.isc.rest.samplePersistentAdapted).#IndexToUse,
			.URLParams,
			.queryParams)
	} Catch exception {
		Return
	}
	
	Set tStatement = ##class(%SQL.Statement).%New()
	Set prepareStatus = tStatement.%Prepare(query)
}

}

