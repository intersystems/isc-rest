/// A representation of the OpenAPI Specification Response Object (see http://spec.openapis.org/oas/v3.0.3#responseObject)
Class %pkg.isc.rest.openAPI.model.response Extends (%pkg.isc.rest.openAPI.model.responseOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper)
{

/// Acceptible key regex (see http://spec.openapis.org/oas/v3.0.3#responseObject and http://spec.openapis.org/oas/v3.0.3#componentsObject)
Parameter KEYREGEX = "^[a-zA-Z0-9\.\-_]+$";

/// @OpenAPI: A short description of the response. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000) [ Required ];

/// @OpenAPI: Maps a header name to its definition. RFC7230 states header names are case insensitive. If a response header is defined with the name "Content-Type", it SHALL be ignored.
Property Headers As array Of %pkg.isc.rest.openAPI.model.headerOrReference(%JSONFIELDNAME = "headers");

/// @OpenAPI: A map containing descriptions of potential response payloads. The key is a media type or [media type range]appendix-D) and the value describes it. For responses that match multiple keys, only the most specific key is applicable. e.g. text/plain overrides text/*
Property Content As array Of %pkg.isc.rest.openAPI.model.mediaType(%JSONFIELDNAME = "content");

/// @OpenAPI: A map of operations links that can be followed from the response. The key of the map is a short name for the link, following the naming constraints of the names for Component Objects.
Property Links As array Of %pkg.isc.rest.openAPI.model.linkOrReference(%JSONFIELDNAME = "links");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set keysValid = 1
	If $IsObject(..Links) {
		Set key = ""
		Do ..Links.GetNext(.key)
		While key'="" {
			If '$Match(key, ..#KEYREGEX) {
				Set keysValid = 0
				Do ..OnFail(fullSpecification, debug, "Array key (" _ key _ ") contains invalid characters", "Links")
				Quit:'debug
			}
			Do ..Links.GetNext(.key)
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
	
	Set key="", val = ..Content.GetAt(.key)
	While key'="" {
		Do val.RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..Content.RemoveAt(key)
			Set key = ""
		}
		Set val = ..Content.GetAt(.key)
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="Content">
<Attribute>Content</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.response.Content"</Subscript>
</Data>
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.response.Extras"</Subscript>
</Data>
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.response.Headers"</Subscript>
</Data>
<Data name="Links">
<Attribute>Links</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.response.Links"</Subscript>
</Data>
<Data name="ResponseDefaultData">
<Subscript>"Response"</Subscript>
<Value name="1">
<Value>Description</Value>
</Value>
</Data>
<DefaultData>ResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

