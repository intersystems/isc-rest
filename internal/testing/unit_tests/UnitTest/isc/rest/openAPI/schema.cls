Class UnitTest.isc.rest.openAPI.schema Extends (UnitTest.isc.rest.openAPI.testCase, %pkg.isc.rest.openAPI.schema)
{

Method OnAfterOneTest() As %Status
{
	Do ..TeardownClass("UnitTest.isc.rest.openAPI.schema.transientClass1")
	Return ##super()
}

Method TestGetSchema()
{
	
	Do $$$LogMessage("*** Check input: %Integer input")
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Set neededClasses = ##class(%Library.ListOfObjects).%New()
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("%Integer")
	Do stub.PopulateNonOverwrittenValues()
	Set schema = ..GetSchema(stub,, "input", neededClasses, openapi)
	Do $$$AssertTrue($IsObject(schema), "GetSchema returned an object")
	Do $$$AssertTrue(schema.ValidateComponents(), "GetSchema returned an object whose components validated properly")
	Do $$$AssertEquals(openapi.Warnings.Count(), 0, "GetSchema didn't raise any warnings")
	Do $$$AssertEquals(openapi.Errors.Count(), 0, "GetSchema didn't raise any errors")
	Do $$$AssertEquals(openapi.NeededClasses.Count(), 0, "GetSchema doesn't use the OpenAPI object's NeededClasses list in place of the NeededClasses parameter")
	Do $$$AssertEquals(neededClasses.Count(), 1, "GetSchema added an entry to the NeededClasses list")
	Do $$$AssertEquals(neededClasses.GetAt(1).AsString(), stub.AsString(), "GetSchema added the correct entry to the NeededClasses list")
	Do $$$AssertEquals(schema.Ref, "#/components/schemas/" _ openapi.GetNiceName(stub) _ "_input", "GetSchema returned a correct schema")
	Do $$$AssertEquals(schema.SourceClasses.Count(), 0, "Schema has no source classes set")
	
	Do $$$LogMessage("*** Check input: %Library.Boolean array output")
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Do neededClasses.Clear()
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("%Library.Boolean")
	Do stub.PopulateNonOverwrittenValues()
	Set schema = ..GetSchema(stub, "array", "output", neededClasses, openapi)
	Do $$$AssertTrue($IsObject(schema), "GetSchema returned an object")
	Do $$$AssertEquals(schema.Type, "array", "GetSchema returned an array schema")
	Do $$$AssertTrue($IsObject(schema.Items), "GetSchema returned a schema with Items set")
	Do $$$AssertEquals(schema.Items.Ref, "#/components/schemas/" _ openapi.GetNiceName(stub) _ "_output", "GetSchema returned a correct schema")
	Do $$$AssertEquals(schema.SourceClasses.Count(), 0, "Schema has no source classes set")
	Do $$$AssertEquals(schema.Items.SourceClasses.Count(), 0, "Schema Items has no source classes set")
	
	Do $$$LogMessage("*** Check input: UnitTest.isc.rest.openAPI.schema.transientClass1 collection")
	Do $$$AssertStatusOK(..SetupClass("UnitTest.isc.rest.openAPI.schema.transientClass1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittes-resource-openapi-schema","SOURCECLASS":"UnitTest.isc.rest.openAPI.schema.transientClass1"}), "Class setup was successful")
	Do $$$AssertStatusOK(..CompileClass("UnitTest.isc.rest.openAPI.schema.transientClass1"), "Class compile was successful")
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Do neededClasses.Clear()
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("UnitTest.isc.rest.openAPI.schema.transientClass1", "TestMapping", "unittest-resource-openapi-schema", "application/vnd.intersystems.unittest.not.a.real.mediatype+json", 0, "unused", 1, 1, "TestMapping2", "GUID", "outputonly", "fieldName", "object", 0, "unused2", "OID")
	Do stub.PopulateNonOverwrittenValues()
	Set schema = ..GetSchema(stub, , "collection", neededClasses, openapi)
	Do $$$AssertTrue($IsObject(schema), "GetSchema returned an object")
	Do $$$AssertEquals(schema.Ref, "#/components/schemas/" _ openapi.GetNiceName(stub) _ "_collection", "GetSchema returned a correct schema")
}

Method TestGenerateSchemaFromSQL()
{
	// Setup
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Do $$$AssertStatusOK(..SetupClass("UnitTest.isc.rest.openAPI.schema.transientClass1",["%Persistent"],,"Self",{"Type":"UnitTest.isc.rest.openAPI.schema.transientClass1"}), "Class setup was successful")
	Do $$$AssertStatusOK(..CompileClass("UnitTest.isc.rest.openAPI.schema.transientClass1"), "Class compile was successful")
	Set sqlQueryString = "Select count(*), 'test' As str, self, CAST(2.3 As Numeric) As dbl from UnitTest_isc_rest_openAPI_schema.transientClass1"
	Do $$$LogMessage("Test using SQL Query: " _ sqlQueryString)
	
	// Method call
	Set schema = ..GenerateSchemaFromSQL(sqlQueryString, openapi)
	
	// Check the output
	Do $$$AssertEquals(openapi.Warnings.Count(), 0, "No warnings were raised")
	Do $$$AssertEquals(openapi.Errors.Count(), 0, "No errors were raised")
	Do $$$AssertTrue($IsObject(schema), "A schema object was returned")
	Do $$$AssertEquals(schema.Type, "array", "Schema is an array type")
	
	// Check that (only) the expected properties exist
	Do $$$AssertEquals(schema.Items.Properties.Count(), 4, "Schema array items have 4 properties")
	Set schemaItemsJSON = ""
	Do schema.Items.%JSONExportToString(.schemaItemsJSON)
	Set schemaItemsJSONObj = {}.%FromJSON(schemaItemsJSON)
	Do ..VerifyJSON(schemaItemsJSONObj, {"properties":{"Aggregate_1":{},"str":{},"Self":{},"dbl":{}}}, "Schema array property names were correct")
	
	// Make sure the object's schema was marked for creation
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("UnitTest.isc.rest.openAPI.schema.transientClass1")
	Do stub.PopulateNonOverwrittenValues()
	Set found = 0
	For i=1:1:openapi.NeededClasses.Count() {
		If openapi.NeededClasses.GetAt(i).AsString() = stub.AsString() {
			Set found = 1
			Quit
		}
	}
	Do $$$AssertTrue(found, "NeededClasses has the object's entry in it")
	
	// Check each of the array items properties' types
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Set prop = schema.Items.Properties.GetAt("Aggregate_1")
	Set stubBigInt = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("%BigInt")
	Set stubInt = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("%Integer")
	Do stubBigInt.PopulateNonOverwrittenValues()
	Do stubInt.PopulateNonOverwrittenValues()
	If (prop.%Extends("%pkg.isc.rest.openAPI.model.reference")) {
		// Depending on version, SQL count() might return either INT or BIGINT.
		do $$$LogMessage(prop.Ref)
		Do $$$AssertTrue((prop.Ref = ("#/components/schemas/" _ openapi.GetNiceName(stubBigInt) _ "_output")) || (prop.Ref = ("#/components/schemas/" _ openapi.GetNiceName(stubInt) _ "_output")))
	} Else {
		Do $$$AssertEquals(prop.Type, "integer")
	}
	Set prop = schema.Items.Properties.GetAt("str")
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("%String")
	Do stub.PopulateNonOverwrittenValues()
	Do $$$AssertTrue($Case($ClassMethod($ClassName(prop),"%Extends","%pkg.isc.rest.openAPI.model.reference"),1:prop.Ref = ("#/components/schemas/" _ openapi.GetNiceName(stub) _ "_output"),:prop.Type = "string"), "Schema array str type OR reference was correct")
	Set prop = schema.Items.Properties.GetAt("dbl")
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("%Numeric")
	Do stub.PopulateNonOverwrittenValues()
	Do $$$AssertTrue($Case($ClassMethod($ClassName(prop),"%Extends","%pkg.isc.rest.openAPI.model.reference"),1:prop.Ref = ("#/components/schemas/" _ openapi.GetNiceName(stub) _ "_output"),:prop.Type = "number"), "Schema array dbl type OR reference was correct")
	Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New("UnitTest.isc.rest.openAPI.schema.transientClass1")
	Do stub.PopulateNonOverwrittenValues()
	Do $$$AssertEquals(schema.Items.Properties.GetAt("Self").Ref, "#/components/schemas/" _ openapi.GetNiceName(stub) _ "_output", "Schema array Self property reference was correct")
}

Method TestGenerateSchemaIfOverwritten()
{
}

Method TestGenerateSchemaFromMethodOutput()
{
}

Method TestGenerateSchemaFromJSONExample()
{
	#Def1Arg Gen(%arg) $Xecute("(%farg) Set schema = ##class(%pkg.isc.rest.openAPI.schema).GenerateSchemaFromJSONExample(%farg) Do schema.%JSONExportToString(.json) Quit {}.%FromJSON(json)", %arg)
	Do ..VerifyJSON($$$Gen(1), {"type":"number"}, "Integer test")
	Do ..VerifyJSON($$$Gen("test"), {"type":"string"}, "String test")
	Do ..VerifyJSON($$$Gen({"test":1}), {"type":"object","properties":{"test":{"type":"number"}}}, "Object with single integer property test")
	Do ..VerifyJSON($$$Gen({"test":1, "test2":false}), {"type":"object","properties":{"test":{"type":"number"},"test2":{"type":"boolean"}}}, "Object with integer property + boolean property test")
	Do ..VerifyJSON($$$Gen(["test1", "test2"]), {"type":"array","items":{"type":"string"}}, "Array of strings test")
	Do ..VerifyJSON($$$Gen([{"a":1},{"a":2}]), {"type":"array","items":{"type":"object","properties":{"a":{"type":"number"}}}}, "Array of equivalent objects test")
	Do ..VerifyJSON($$$Gen([{"a":1},{"b":false}]), {"type":"array","items":{"type":"object","properties":{"a":{"type":"number"},"b":{"type":"boolean"}}}}, "Array of compatible objects test")
	Do $$$AssertTrue('$IsObject(##class(%pkg.isc.rest.openAPI.schema).GenerateSchemaFromJSONExample([{"a":1},{"a":false}])), "Array of incompatible object test (should fail to generate)")
}

Method TestMergeSchemas()
{
	#Define Verify(%test, %expectedJSON, %succeeded) Do ..MergeSchemas(schema1,schema2,.output,.success),$$$AssertEquals(success,%succeeded,%test_" merging was a "_$select(%succeeded:"success",1:"failure")) if%succeeded { do output.%JSONExportToString(.outputJSON),..VerifyJSON({}.%FromJSON(outputJSON),%expectedJSON,%test_" merged properly") }
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "number"
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "number"
	$$$Verify("two single-number schemas", {"type":"number"}, 1)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "number"
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "string"
	$$$Verify("a number + a string",, 0)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "number"
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "object"
	$$$Verify("a number + an object",, 0)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "object"
	Set schema1sub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1sub1.Type = "number"
	Do schema1.Properties.SetAt(schema1sub1, "sub1")
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "object"
	Set expectedJSON = {"type":"object","properties":{"sub1":{"type":"number"}}}
	$$$Verify("an object with a number property + an empty object", expectedJSON, 1)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "array"
	Set schema1sub = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1sub.Type = "string"
	Set schema1.Items = schema1sub
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "string"
	$$$Verify("an array of strings + a string",, 0)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "object"
	Set schema1sub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1sub1.Type = "number"
	Do schema1.Properties.SetAt(schema1sub1, "sub1")
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "object"
	Set schema2sub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2sub1.Type = "number"
	Do schema2.Properties.SetAt(schema2sub1, "sub1")
	Set expectedJSON = {"type":"object","properties":{"sub1":{"type":"number"}}}
	$$$Verify("two objects with a single shared number property", expectedJSON, 1)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "object"
	Set schema1sub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1sub1.Type = "number"
	Do schema1.Properties.SetAt(schema1sub1, "sub1")
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "object"
	Set schema2sub2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2sub2.Type = "number"
	Do schema2.Properties.SetAt(schema2sub2, "sub2")
	Set expectedJSON = {"type":"object","properties":{"sub1":{"type":"number"},"sub2":{"type":"number"}}}
	$$$Verify("two objects with single non-shared number properties", expectedJSON, 1)
	
	Set schema1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1.Type = "object"
	Set schema1sub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema1sub1.Type = "number"
	Do schema1.Properties.SetAt(schema1sub1, "sub1")
	Set schema2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2.Type = "object"
	Set schema2sub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New(), schema2sub1.Type = "boolean"
	Do schema2.Properties.SetAt(schema2sub1, "sub1")
	$$$Verify("two objects with a conflicting property type",, 0)
}

Method TestReconcileFoundMethodSchema()
{
}

}

