/// A representation of the OpenAPI Specification Tag Object (see http://spec.openapis.org/oas/v3.0.3#tagObject)
Class %pkg.isc.rest.openAPI.model.tag Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The name of the tag.
Property Name As %String(%JSONFIELDNAME = "name", MAXLEN = 2000) [ Required ];

/// @OpenAPI: A short description for the tag. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: Additional external documentation for this tag.
Property ExternalDocumentation As %pkg.isc.rest.openAPI.model.externalDocumentation(%JSONFIELDNAME = "externalDocs");

Storage Default
{
<Data name="TagDefaultData">
<Subscript>"Tag"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>ExternalDocumentation</Value>
</Value>
</Data>
<DefaultData>TagDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

