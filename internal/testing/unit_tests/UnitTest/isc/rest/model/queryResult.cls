Class UnitTest.isc.rest.model.queryResult Extends %UnitTest.TestCase
{

Property GUID1 As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

Property GUID2 As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

Method OnBeforeAllTests() As %Status
{
	set sql = "insert into UnitTest_isc_rest.samplePersistentAdapted (FOO_NAME, Bar) Values (?, ?)"
	for i=0,1,2 {
		set rs = ##class(%SQL.Statement).%ExecDirect(,sql,..GUID1,i)
		throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
	}
	for i=0,1,2 {
		set rs = ##class(%SQL.Statement).%ExecDirect(,sql,..GUID2,i)
		throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
	}
	return ##super()
}

Method OnAfterAllTests() As %Status
{
	set rs = ##class(%SQL.Statement).%ExecDirect(,"delete from UnitTest_isc_rest.samplePersistentAdapted where FOO_NAME in (?, ?)",..GUID1,..GUID2)
	throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
	return ##super()
}

Method TestClassQuery()
{
	set model = ##class(%pkg.isc.rest.model.queryResult).FromClassQuery("UnitTest.isc.rest.samplePersistentAdapted",..%ClassName(1),"SampleClassQuery",..GUID1)
	do $$$AssertStatusOK(model.JSONExportToString(.json))
	set array = [].%FromJSON(json)
	do $$$AssertEquals(array.%Size(),3)
	do $$$AssertEquals(array.%Get(0).someField,..GUID1)
	do $$$AssertEquals(array.%Get(0).Bar,0)
	do $$$AssertEquals(array.%Get(1).someField,..GUID1)
	do $$$AssertEquals(array.%Get(1).Bar,1)
	do $$$AssertEquals(array.%Get(2).someField,..GUID1)
	do $$$AssertEquals(array.%Get(2).Bar,2)
}

Method TestHugeResult()
{
	set $ZStorage = 2 * $ZStorage // need extra buffer space for this large test
	set size = 100000
	set model = ##class(%pkg.isc.rest.model.queryResult).%New()
	set bar = ""
	for i=1:1:500 set bar = bar _ "a"
	for i=1:1:size {
		set row = ##class(UnitTest.isc.rest.samplePersistentAdapted).%New()
		set row.Foo = i
		set row.Bar = bar
		do model.rows.Insert(row)
		kill row // kill local variable after each iteration to prevent <STORE> error by freeing up $Storage
	}
	do $$$AssertStatusOK(model.JSONExportToStream(.stream))
	#dim array As %Library.DynamicArray
	set array = [].%FromJSON(stream)
	do $$$AssertEquals(array.%Size(),size)
	for i=1:1:size {
		if array.%Get(i-1).someField '= i {
			do $$$AssertEquals(array.%Get(i-1).Foo, i)
			quit
		}
		if array.%Get(i-1).Bar '= bar {
			do $$$AssertEquals(array.%Get(i-1).Bar, bar)
			quit
		}
	}
}

Query SampleClassQuery(pFoo As %String) As %SQLQuery
{
SELECT ID,FOO_NAME,Bar FROM UnitTest_isc_rest.samplePersistentAdapted WHERE FOO_NAME = :pFoo ORDER BY Bar
}

}

