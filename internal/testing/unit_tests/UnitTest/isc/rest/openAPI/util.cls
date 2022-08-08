Class UnitTest.isc.rest.openAPI.util Extends UnitTest.isc.rest.testCase
{

Method TestFormatString()
{
	#Define FormatString ##class(%pkg.isc.rest.openAPI.util).FormatString
	Do $$$AssertEquals($$$FormatString("test with spaces"), "test-with-spaces", "Spaces are handled properly in lower-case")
	Do $$$AssertEquals($$$FormatString("Test With Spaces and Title Case"), "test-with-spaces-and-title-case", "Spaces are handled properly in title-case")
	Do $$$AssertEquals($$$FormatString("singletest"), "singletest", "Single lowercase word is handled properly")
	Do $$$AssertEquals($$$FormatString("Singletest"), "singletest", "Single titlecase word is handled properly")
	Do $$$AssertEquals($$$FormatString("SINGLETEST"), "singletest", "Single uppercase word is handled properly")
	Do $$$AssertEquals($$$FormatString("SingleTest"), "single-test", "Simple camelcase is handled properly")
	Do $$$AssertEquals($$$FormatString("ISCTest"), "isc-test", "Complex camelcase is handled properly")
	Do $$$AssertEquals($$$FormatString("AppS"), "apps", "Single capital letter is handled properly")
	Do $$$AssertEquals($$$FormatString("    te   st  "), "te-st", "Extra whitespace is handled properly")
	Do $$$AssertEquals($$$FormatString("a B  cCDhJK Rq  "), "a-b-c-c-dh-jk-rq", "Complex camelcase with spaces is handled properly")
	Do $$$AssertEquals($$$FormatString("a.b,c:d""e'f/g?h>i<j\k|l}]{[-_+=)m~n`o"), "a-b-c-d-e-f-g-h-i-j-k-l-m-n-o", "Punctuation is handled properly")
	Do $$$AssertEquals($$$FormatString("a B a.B  a  B aa bB Aa BB a.b A.b a.B A.B A..B A.B? ?"), "a-b-a-b-a-b-aa-bb-aa-bb-a-b-a-b-a-b-a-b-a-b-a-b", "Punctuation with spaces is handled properly")
	Do $$$AssertEquals($$$FormatString("UnitTest.isc.rest.openAPI.util"), "unit-test-isc-rest-open-api-util", "Class name test is handled properly")
}

Method TestGetJSON()
{
	#define JSONAdaptor ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONAdaptorClass()
	#define JSONMapping ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONMappingClass()
	#define JSONBoolean ##class(UnitTest.isc.rest.openAPI.compatibility).GetBooleanClass()
	#Define GetJSON ##class(%pkg.isc.rest.openAPI.util).GetJSON
	
	$$$ThrowOnError(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent", ($$$JSONAdaptor)],, "Property1", {"Type":($$$JSONBoolean)}, {"JSONTYPE":"boolean", "%JSONFIELDNAME":"prop1"}))
	$$$ThrowOnError(..CompileClass("zUnitTest.isc.rest.class1"))
	
	Do $$$AssertEquals($$$GetJSON(1), 1)
	Do $$$AssertEquals($$$GetJSON(1, "boolean"), 1)
	Do $$$AssertEquals($$$GetJSON("test"), "test")
	Do $$$AssertEquals($$$GetJSON({"a":2}).a, 2)
	Set inst = ##class(zUnitTest.isc.rest.class1).%New()
	Set inst.Property1 = 0
	Do $$$AssertEquals($$$GetJSON(inst).%Get("prop1"), 0)
	Do $$$AssertEquals($$$GetJSON(inst).%GetTypeOf("prop1"), "boolean")
	
	Do ..TeardownClass("zUnitTest.isc.rest.class1")
}

Method TestFromJSON()
{
	#define JSONAdaptor ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONAdaptorClass()
	#define JSONMapping ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONMappingClass()
	#define JSONBoolean ##class(UnitTest.isc.rest.openAPI.compatibility).GetBooleanClass()
	#Define FromJSON ##class(%pkg.isc.rest.openAPI.util).FromJSON
	
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent", ($$$JSONAdaptor)],, "Property1", {"Type":($$$JSONBoolean)}, {"JSONTYPE":"boolean", "%JSONFIELDNAME":"prop1"}))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	
	Do $$$AssertEquals($$$FromJSON(1), "1")
	Do $$$AssertEquals($$$FromJSON(1, "boolean"), "true")
	Do $$$AssertEquals($$$FromJSON("test"), """test""")
	Do $$$AssertEquals($$$FromJSON({"a":2}), "{""a"":2}")
	Set inst = ##class(zUnitTest.isc.rest.class1).%New()
	Set inst.Property1 = 0
	Do $$$AssertEquals($$$FromJSON(inst), "{""prop1"":false}")
	
	Do ..TeardownClass("zUnitTest.isc.rest.class1")
}

Method TestReadClassMethodOutput()
{
	#Define ReadOutput ##class(%pkg.isc.rest.openAPI.util).ReadClassMethodOutput
	Do $$$AssertEquals($$$ReadOutput("zUnitTest.isc.rest.nonExistantClass", "SomeMethod"), "", "Reading the output of a non-existant class's method returns the empty string")
	Do $$$AssertEquals($$$ReadOutput($ClassName($This), "NonexistantMethod"), "", "Reading the output of a non-existant classmethod returns the empty string")
	Do $$$AssertEquals($$$ReadOutput($ClassName($This), "SampleMethod"), "This is a test!", "Reading the output of an existent classmethod worked as-expected")
}

ClassMethod SampleMethod()
{
	Write "This is a test!"
}

}

