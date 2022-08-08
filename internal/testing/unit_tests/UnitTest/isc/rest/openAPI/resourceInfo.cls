Class UnitTest.isc.rest.openAPI.resourceInfo Extends UnitTest.isc.rest.testCase
{

Parameter CLASS1 = "UnitTest.isc.rest.openAPI.transientClass1";

Parameter CLASS2 = "UnitTest.isc.rest.openAPI.transientClass2";

/// TODO: Understand why this needs to not run in a transaction for the
/// classes to compile correctly
Parameter RunInTransaction As BOOLEAN = 0;

Method LogResourceInfo(resourceInfo)
{
	Do $$$LogMessage(".  Resource Name: " _ resourceInfo.ResourceName)
	Kill str Do resourceInfo.OpenAPIInputSchema.%JSONExportToString(.str)
	Do $$$LogMessage(".  Input Schema: " _ str)
	Kill str Do resourceInfo.OpenAPIOutputSchema.%JSONExportToString(.str)
	Do $$$LogMessage(".  Output Schema: " _ str)
}

Method SetupClassesForTest(testName)
{
	#define JSONAdaptor ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONAdaptorClass()
	#define JSONMapping ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONMappingClass()
	#define JSONBoolean ##class(UnitTest.isc.rest.openAPI.compatibility).GetBooleanClass()
	
	If $Match(testName, "SimpleTest|XISCTags") {
		Set class1Params = {
			"RESOURCENAME":"unittest-resource-proxy", 
			"MEDIATYPE":"application/json+vnd.intersystems.unittest-resource-proxy", 
			"JSONMAPPING":"MappingXData1", 
			"%JSONMAPPING":"MappingXData2"
		}
		Set class1Params.SOURCECLASS = ..#CLASS2
		Set class1Supers = ["%Library.Persistent", "%pkg.isc.rest.model.proxy"]
		Set class1RelationshipName = "sampleRelation"
		Set class1RelationshipFields = {"Inverse":"sampleRelation", "Cardinality":"many"}
		Set class1RelationshipFields.Type = ..#CLASS2
		Set class1PropName = "testProp"
		Set class1PropFields = {"Type":"%Double","InitialExpression":5.7,"Required":true}
		Set class1PropParams = {"%JSONFIELDNAME": "testprop-paramname"}
		Set class1XDatas = ["SimpleTestXData1:MappingXData1", "SimpleTestXData2:MappingXData2"]
		Set class1Methods = ["CheckPermissionAllowAll:CheckPermission"]
		Set class1Queries = []
		Set class1Description = "Description of class 1"
		// ---
		Set class2Params = {
			"RESOURCENAME":"unittest-resource", 
			"MEDIATYPE":"application/json+vnd.intersystems.unittest-resource",
			"JSONMAPPING":"MappingXData1", 
			"%JSONMAPPING":"MappingXData2"
		}
		Set class2Supers = ["%Library.Persistent", ""]
		Do class2Supers.%Set(1, $$$JSONAdaptor)
		set class2RelationshipName = "sampleRelation"
		Set class2RelationshipFields = {"Inverse":"sampleRelation", "Cardinality":"one"}
		Set class2RelationshipFields.Type = ..#CLASS1
		Set class2PropName = "testProp"
		Set class2PropFields = {"Type":"%Boolean", "Description":"testProp class2 Description"}
		Set class2PropParams = {}
		Set class2XDatas = ["SimpleTestXData3:MappingXData1", "SimpleTestXData4:MappingXData2"]
		Set class2Methods = []
		Set class2Queries = []
	}
	Kill classList
	Set classList(..#CLASS1_".CLS") = ""
	Set classList(..#CLASS2_".CLS") = ""
	If (
		'$$$AssertStatusOK(..SetupClass(..#CLASS1,class1Supers,class1Params,class1PropName,class1PropFields,class1PropParams,class1RelationshipName,class1RelationshipFields,{},class1XDatas,class1Methods,class1Queries,class1Description), "Transient class 1 setup correctly")
		|| '$$$AssertStatusOK(..SetupClass(..#CLASS2,class2Supers,class2Params,class2PropName,class2PropFields,class2PropParams,class2RelationshipName,class2RelationshipFields,{},class2XDatas,class2Methods,class2Queries), "Transient class 2 setup correctly")
		|| '$$$AssertStatusOK(..CompileClassList(.classList), "Transient Class 1 and 2 compiled")
		|| '$$$AssertStatusOK(..CompileClassList(.classList), "Transient Class 1 and 2 compiled (2nd time)")
	) {
		Throw ##class(%Exception.General).%New("Failed to set up or compile test classes")
	}
}

Method TestSimpleTest()
{
	Do ..SetupClassesForTest("SimpleTest")
	// ---
	Set class1Stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(..#CLASS1,$Parameter(..#CLASS1,"JSONMAPPING"),$Parameter(..#CLASS1,"RESOURCENAME"),$Parameter(..#CLASS1,"MEDIATYPE"))
	Do class1Stub.PopulateNonOverwrittenValues()
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Set openapi.HideInternalInfo = 0
	Set openapi.UserContext = $$$NULLOREF
	Set class1ResourceInfo = ##class(%pkg.isc.rest.openAPI.resourceInfo).FromStub(class1Stub, openapi)
	// ---
	Do $$$LogMessage("Checking the status of TransientClass1")
	Do $$$AssertTrue(openapi.Warnings.Count() = 0, ".  No warnings were raised in FromClass() call")
	For i=1:1:openapi.Warnings.Count() {
		 Do $$$LogMessage(".    Warning: " _ openapi.Warnings.GetAt(i))
	}
	Do $$$AssertTrue(openapi.NeededClasses.Count() > 0, ".  At least one additional class has been marked for creation")
	Do $$$AssertEquals(class1ResourceInfo.ResourceEndpointsEnabled, 1, ".  Resource endpoints were enabled")
	Do $$$AssertEquals(class1ResourceInfo.ForbidResourceQuery, 0, ".  Resource query wasn't forbidden")
	Do $$$AssertEquals(class1ResourceInfo.ForbidResourceCreate, 0, ".  Resource create wasn't forbidden")
	Do $$$AssertEquals(class1ResourceInfo.ForbidResourceConstruct, 0, ".  Resource construct wasn't forbidden")
	Do $$$AssertEquals(class1ResourceInfo.ForbidResourceRead, 0, ".  Resource read wasn't forbidden")
	Do $$$AssertEquals(class1ResourceInfo.ForbidResourceUpdate, 0, ".  Resource update wasn't forbidden")
	Do $$$AssertEquals(class1ResourceInfo.ForbidResourceDelete, 0, ".  Resource delete wasn't forbidden")
	Do $$$AssertEquals(class1ResourceInfo.ResourceName, "unittest-resource-proxy", ".  Resource name was parsed correctly")
	Do $$$AssertEquals(class1ResourceInfo.MediaType, "application/json+vnd.intersystems.unittest-resource-proxy", ".  Resource mediatype was parsed correctly")
	// ---
	Set inputString = "" 
	Do class1ResourceInfo.OpenAPIInputSchema.%JSONExportToString(.inputString) 
	Set inputSchemaJSON = {}.%FromJSON(inputString)
	Set outputString = "" 
	Do class1ResourceInfo.OpenAPIOutputSchema.%JSONExportToString(.outputString) 
	Set outputSchemaJSON = {}.%FromJSON(outputString)
	Set refTestStub = class1Stub.%ConstructClone()
	Set refTestStub.JSONMapping = "MappingXData2"
	Do refTestStub.PopulateNonOverwrittenValues()
	// ---
	Do ..VerifyJSON(inputSchemaJSON, {}.%FromJSON("{""x-ISC_CLASS"":"""_..#CLASS1_""",""x-ISC_JSONMAPPING"":"""_..#CLASS2_":MappingXData1"",""x-ISC_PROXY"":true,""x-ISC_PROXY_FOR"":"""_..#CLASS2_"""}"), ".  FromClass("_..#CLASS1_") Input Schema Extended Properties are correct")
	Do ..VerifyJSON(inputSchemaJSON, {
			"type": "object",
			"description": "Description of class 1",
			"properties": {
				"xdata3-property":{
					"type": "boolean",
					"description": "testProp class2 Description" //for now, property descriptions come from source class.
				},
				"xdata3-relationship": {
					"$ref": ("#/components/schemas/" _ openapi.GetNiceName(refTestStub) _ "_input")
				}
			}
		}, 
		".  FromClass("_..#CLASS1_") Input Schema Property Data is correct")
	Do ..VerifyJSON(inputSchemaJSON, {}.%FromJSON("{""writeOnly"":true,""externalDocs"":{""description"":"""_..#CLASS1_" InterSystems Class Reference"",""url"":""%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY=&CLASSNAME="_..#CLASS1_"""}}"), ".  FromClass("_..#CLASS1_") Input Schema Class Data is correct")
	// ---
	Do ..VerifyJSON(outputSchemaJSON, {}.%FromJSON("{""x-ISC_CLASS"":"""_..#CLASS1_""",""x-ISC_JSONMAPPING"":"""_..#CLASS2_":MappingXData1"",""x-ISC_PROXY"":true,""x-ISC_PROXY_FOR"":"""_..#CLASS2_"""}"), ".  FromClass("_..#CLASS1_") Output Schema Extended Properties are correct")
	Do ..VerifyJSON(outputSchemaJSON, {
			"type": "object",
			"description": "Description of class 1",
			"required": [
				"_id"
			],
			"properties": {
				"_id": {
					"type": "string"
				},
				"xdata3-property": {
					"type": "boolean",
					"description": "testProp class2 Description"
				},
				"xdata3-relationship": {
					"$ref": ("#/components/schemas/" _ openapi.GetNiceName(refTestStub) _ "_output")
				}
			}
		}, 
		".  FromClass("_..#CLASS1_") Output Schema Property Data is correct")
	Do ..VerifyJSON(outputSchemaJSON, {}.%FromJSON("{""readOnly"":true,""externalDocs"":{""description"":"""_..#CLASS1_" InterSystems Class Reference"",""url"":""%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY=&CLASSNAME="_..#CLASS1_"""}}"), ".  FromClass("_..#CLASS1_") Output Schema Class Data is correct")
	// ---
	Do ..TeardownClass(..#CLASS1)
	Do ..TeardownClass(..#CLASS2)
}

Method TestXISCTags()
{
	// Check the following tags:
	// 	schema: ISC_CLASS
	// 	schema: ISC_PROXY
	// 	schema: ISC_PROXY_FOR
	// 	schema: ISC_JSONMAPPING
	// 	property: ISC_CLASS (correct in both proxy + not) *
	// 	property: ISC_NAME *
	// 	property: ISC_RELATIONSHIP *
	// 	property: ISC_CARDINALITY *
	// 	property: ISC_TYPE *
	// 	property: ISC_REFERENCE *
	// 	property: ISC_JSONMAPPING *
	// 	property items: ISC_TYPE *
	// *: not allowed on references
	
	Do ..SetupClassesForTest("XISCTags")
	// ---
	Set class1Stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(..#CLASS1,$Parameter(..#CLASS1,"JSONMAPPING"),$Parameter(..#CLASS1,"RESOURCENAME"),$Parameter(..#CLASS1,"MEDIATYPE"))
	Do class1Stub.PopulateNonOverwrittenValues()
	Set openapi = ##class(%pkg.isc.rest.openAPI).%New()
	Set openapi.HideInternalInfo = 0
	Set openapi.UserContext = $$$NULLOREF
	Set class1ResourceInfo = ##class(%pkg.isc.rest.openAPI.resourceInfo).FromStub(class1Stub, openapi)
	// ---
	Do $$$AssertTrue(openapi.Warnings.Count() = 0, ".  No warnings were raised in FromClass() call")
	For i=1:1:openapi.Warnings.Count() {
		 Do $$$LogMessage(".    Warning: " _ openapi.Warnings.GetAt(i))
	}
	// ---
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.IsExtendedPropertySet("ISC_CLASS"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.IsExtendedPropertySet("ISC_PROXY"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.IsExtendedPropertySet("ISC_PROXY_FOR"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.IsExtendedPropertySet("ISC_JSONMAPPING"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_CLASS"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_NAME"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_TYPE"))
	Do $$$AssertTrue(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_JSONMAPPING"))
	Do $$$AssertTrue('class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_RELATIONSHIP"))
	Do $$$AssertTrue('class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_CARDINALITY"))
	Do $$$AssertTrue('class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").IsExtendedPropertySet("ISC_REFERENCE"))
	// Note: Cannot check the relationship for ISC values here, because it can't hold them (its a reference)
	// ---
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.GetExtendedProperty("ISC_CLASS", .type), ..#CLASS1)
	Do $$$AssertTrue($Match(type, "|string"))
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.GetExtendedProperty("ISC_PROXY", .type), 1)
	Do $$$AssertEquals(type, "boolean")
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.GetExtendedProperty("ISC_PROXY_FOR", .type), ..#CLASS2)
	Do $$$AssertTrue($Match(type, "|string"))
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.GetExtendedProperty("ISC_JSONMAPPING", .type), ..#CLASS2_":MappingXData1")
	Do $$$AssertTrue($Match(type, "|string"))
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").GetExtendedProperty("ISC_CLASS", .type), ..#CLASS2)
	Do $$$AssertTrue($Match(type, "|string"))
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").GetExtendedProperty("ISC_NAME", .type), "testProp")
	Do $$$AssertTrue($Match(type, "|string"))
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").GetExtendedProperty("ISC_TYPE", .type), "%Library.Boolean")
	Do $$$AssertTrue($Match(type, "|string"))
	Do $$$AssertEquals(class1ResourceInfo.OpenAPIInputSchema.Properties.GetAt("xdata3-property").GetExtendedProperty("ISC_JSONMAPPING", .type), "MappingXData2")
	Do $$$AssertTrue($Match(type, "|string"))
	// ---
	// TODO: Check non-proxy example
	// TODO: Check reference
	// ---
	Do ..TeardownClass(..#CLASS1)
	Do ..TeardownClass(..#CLASS2)
}

/// Methods
ClassMethod CheckPermissionAllowAll(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return 1
}

XData SimpleTestXData1 [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/json/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/_pkg/isc/json/jsonmapping" Mapping="MappingXData4" Reference="OID">
<Property Name="testProp" FieldName="xdata1-property"/>
<Property Name="sampleRelation" FieldName="xdata1-relationship"/>
</Mapping>
}

/// JSON maps
XData SimpleTestXData2 [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/json/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/_pkg/isc/json/jsonmapping" Mapping="MappingXData3" Reference="ID">
<Property Name="testProp" FieldName="xdata2-property"/>
<Property Name="sampleRelation" FieldName="xdata2-relationship"/>
</Mapping>
}

XData SimpleTestXData3 [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping" Mapping="MappingXData2">
<Property Name="testProp" FieldName="xdata3-property"/>
<Property Name="sampleRelation" FieldName="xdata3-relationship"/>
</Mapping>
}

XData SimpleTestXData4 [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping" Mapping="MappingXData1">
<Property Name="testProp" FieldName="xdata4-property"/>
<Property Name="sampleRelation" FieldName="xdata4-relationship"/>
</Mapping>
}

}

