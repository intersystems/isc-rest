Class UnitTest.isc.rest.model.paginatedQueryResult Extends HSTools.UnitTest.Mock.TestCase [ CompileAfter = UnitTest.isc.rest.samplePersistentAdapted, DependsOn = UnitTest.isc.rest.samplePersistentAdapted ]
{

Property GUID1 As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

Property GUID2 As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

Method OnBeforeOneTest() As %Status
{
	do ..DeleteAll()
	for i=0:1:19{
		for foo=..GUID1,..GUID2 {
			set entry = ##class(UnitTest.isc.rest.samplePersistentAdapted).%New()
			set entry.Foo = foo
			set entry.Bar = i
			$$$ThrowOnError(entry.%Save())
		}
	}
	return ##super()
}

Method OnAfterOneTest() As %Status
{
	do ..DeleteAll()
	return ##super()
}

Method DeleteAll()
{
	set rs = ##class(%SQL.Statement).%ExecDirect(,"delete from UnitTest_isc_rest.samplePersistentAdapted where FOO_NAME in (?, ?)",..GUID1,..GUID2)
	throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
}

Method TestClassQuery()
{
	set page1 = ##class(%pkg.isc.rest.model.paginatedQueryResult).FromClassQuery("UnitTest.isc.rest.samplePersistentAdapted",..%ClassName(1),"SampleClassQuery",10,,..GUID1)
	do $$$AssertNotTrue(page1.Done)
	do $$$AssertStatusOK(page1.JSONExportToString(.json1))
	do $$$LogMessage(json1)
	set array = [].%FromJSON(json1)
	do $$$AssertEquals(array.%Size(),10)
	for i=0:1:9 {
		do $$$AssertEquals(array.%Get(i).someField,..GUID1)
		do $$$AssertEquals(array.%Get(i).Bar,i)
	}
	set page2 = ##class(%pkg.isc.rest.model.paginatedQueryResult).FromClassQuery("UnitTest.isc.rest.samplePersistentAdapted",..%ClassName(1),"SampleClassQuery",5,10,..GUID1)
	do $$$AssertNotTrue(page2.Done)
	do $$$AssertStatusOK(page2.JSONExportToString(.json2))
	do $$$LogMessage(json2)
	set array = [].%FromJSON(json2)
	do $$$AssertEquals(array.%Size(),5)
	for i=0:1:4 {
		do $$$AssertEquals(array.%Get(i).someField,..GUID1)
		do $$$AssertEquals(array.%Get(i).Bar,i+10)
	}
	set page3 = ##class(%pkg.isc.rest.model.paginatedQueryResult).FromClassQuery("UnitTest.isc.rest.samplePersistentAdapted",..%ClassName(1),"SampleClassQuery",10,15,..GUID1)
	do $$$AssertTrue(page3.Done)
	do $$$AssertStatusOK(page3.JSONExportToString(.json3))
	do $$$LogMessage(json3)
	set array = [].%FromJSON(json3)
	do $$$AssertEquals(array.%Size(),5)
	for i=0:1:4 {
		do $$$AssertEquals(array.%Get(i).someField,..GUID1)
		do $$$AssertEquals(array.%Get(i).Bar,i+15)
	}
}

Method AnswerBadExecute(pCall As HSTools.UnitTest.Mock.MethodCall, pArguments...) As %Status
{
	set pCall.Instance.%SQLCODE = -1
	set pCall.Instance.%Message = "unit test bad execute"
	return $$$OK
}

Method TestResultSetQueryFailure()
{
	try {
		set resultset = ..mock("%Library.ResultSet")
		do ..when(resultset.%Execute(..GUID1)).thenAnswer(..withMethod($this,"AnswerBadExecute"))
		set page = ##class(%pkg.isc.rest.model.paginatedQueryResult).FromResultSet("UnitTest.isc.rest.samplePersistentAdapted",resultset,,,..GUID1)
		do $$$AssertFailure("FromClassQuery should have thrown error")
	} catch err {
		do $$$LogMessage(err.DisplayString())
		do $$$AssertTrue(err.DisplayString()["unit test bad execute")
	}
}

Method TestClassQueryNoLimit()
{
	set page1 = ##class(%pkg.isc.rest.model.paginatedQueryResult).FromClassQuery("UnitTest.isc.rest.samplePersistentAdapted",..%ClassName(1),"SampleClassQuery",,,..GUID1)
	do $$$AssertTrue(page1.Done)
	do $$$AssertStatusOK(page1.JSONExportToString(.json1))
	do $$$LogMessage(json1)
	set array = [].%FromJSON(json1)
	do $$$AssertEquals(array.%Size(),20)
	for i=0:1:19 {
		do $$$AssertEquals(array.%Get(i).someField,..GUID1)
		do $$$AssertEquals(array.%Get(i).Bar,i)
	}
}

Method TestClassQueryOffsetNoLimit()
{
	set page1 = ##class(%pkg.isc.rest.model.paginatedQueryResult).FromClassQuery("UnitTest.isc.rest.samplePersistentAdapted",..%ClassName(1),"SampleClassQuery",,5,..GUID1)
	do $$$AssertTrue(page1.Done)
	do $$$AssertStatusOK(page1.JSONExportToString(.json1))
	do $$$LogMessage(json1)
	set array = [].%FromJSON(json1)
	do $$$AssertEquals(array.%Size(),15)
	for i=0:1:14 {
		do $$$AssertEquals(array.%Get(i).someField,..GUID1)
		do $$$AssertEquals(array.%Get(i).Bar,i+5)
	}
}

Query SampleClassQuery(pFoo As %String) As %SQLQuery
{
SELECT ID,FOO_NAME,Bar FROM UnitTest_isc_rest.samplePersistentAdapted WHERE FOO_NAME = :pFoo ORDER BY Id
}

}

