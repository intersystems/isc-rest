/// A representation of the OpenAPI Specification Responses Object (see http://spec.openapis.org/oas/v3.0.3#responsesObject)
/// JSON Representation is the inline (not as a separate object) contents of ..Data, through use of %pkg.isc.rest.openAPI.model.passthroughObject
Class %pkg.isc.rest.openAPI.model.responses Extends %pkg.isc.rest.openAPI.model.passthroughObject
{

/// @Override: Per the OpenAPI Specification, this object may be extended with "x-*" properties.
Parameter EXTENSIBLE = 1;

/// Acceptible key regex (from description at http://spec.openapis.org/oas/v3.0.3#responsesObject)
Parameter KEYREGEX = "default|[1-5](XX|[0-9]{2})";

/// @Special: This Object's content
/// @OpenAPI: A container for the expected responses of an operation. The container maps a HTTP response code to the expected response.
/// @OpenAPI: The default [array key] MAY be used as a default response object for all HTTP codes that are not covered individually by the specification.
Property Data As array Of %pkg.isc.rest.openAPI.model.responseOrReference;

/// Used to track the class(es) that caused this object to be generated
Property SourceClasses As list Of %String(%JSONINCLUDE = "none");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set keysValid = 1
	If $IsObject(..Data) {
		Set key = ""
		Do ..Data.GetNext(.key)
		While key'="" {
			If '$Match(key, ..#KEYREGEX) {
				Set keysValid = 0
				Do ..OnFail(fullSpecification, debug, "Array (" _ key _ ") key contains invalid characters")
				Quit:'debug
			}
			Do ..Data.GetNext(.key)
		}
	}
	Return keysValid
}

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	Set key = "", obj = ..Data.GetNext(.key)
	While key'="" {
		Do obj.RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..RemoveAt(key)
			Set key = ""
		}
		Set obj = ..Data.GetNext(.key)
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="Data">
<Attribute>Data</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.responses.Data"</Subscript>
</Data>
<Data name="ResponsesDefaultData">
<Subscript>"Responses"</Subscript>
<Value name="1">
<Value>SourceClasses</Value>
</Value>
</Data>
<DefaultData>ResponsesDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

