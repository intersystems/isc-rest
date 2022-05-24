/// A representation of the OpenAPI Specification Request Body Object (see http://spec.openapis.org/oas/v3.0.3#requestBodyObject)
Class %pkg.isc.rest.openAPI.model.requestBody Extends (%pkg.isc.rest.openAPI.model.requestBodyOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper)
{

/// @OpenAPI: A brief description of the request body. This could contain examples of use. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: The content of the request body. The key is a media type or [media type range]appendix-D) and the value describes it. For requests that match multiple keys, only the most specific key is applicable. e.g. text/plain overrides text/*
Property Content As array Of %pkg.isc.rest.openAPI.model.mediaType(%JSONFIELDNAME = "content") [ Required ];

/// @OpenAPI: Determines if the request body is required in the request. Defaults to false.
Property Required As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "required");

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	Set key="", val = ..Content.GetNext(.key)
	While key'="" {
		Do val.RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..Content.RemoveAt(key)
			Set key = ""
		}
		Set val = ..Content.GetNext(.key)
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="Content">
<Attribute>Content</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.requestBody.Content"</Subscript>
</Data>
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.requestBody.Extras"</Subscript>
</Data>
<Data name="RequestBodyDefaultData">
<Subscript>"RequestBody"</Subscript>
<Value name="1">
<Value>Description</Value>
</Value>
<Value name="2">
<Value>Required</Value>
</Value>
</Data>
<DefaultData>RequestBodyDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

