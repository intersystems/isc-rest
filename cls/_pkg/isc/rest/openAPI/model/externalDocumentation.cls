/// A representation of the OpenAPI Specification External Documentation Object (see http://spec.openapis.org/oas/v3.0.3#externalDocumentationObject)
Class %pkg.isc.rest.openAPI.model.externalDocumentation Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: A short description of the target documentation. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: The URL for the target documentation. Value MUST be in the format of a URL.
Property URL As %String(%JSONFIELDNAME = "url", MAXLEN = 2000) [ Required ];

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set urlValid = 1
	Set:..URL'="" urlValid = $Match(..URL, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Do:'urlValid ..OnFail(fullSpecification, debug, "URL (" _ ..URL _ ") Regex mismatch", "URL")
	Return urlValid
}

Storage Default
{
<Data name="ExternalDocumentationDefaultData">
<Subscript>"ExternalDocumentation"</Subscript>
<Value name="1">
<Value>Description</Value>
</Value>
<Value name="2">
<Value>URL</Value>
</Value>
</Data>
<DefaultData>ExternalDocumentationDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

