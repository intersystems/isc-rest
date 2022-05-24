/// A representation of the OpenAPI Specification Server Object (see http://spec.openapis.org/oas/v3.0.3#serverObject)
Class %pkg.isc.rest.openAPI.model.server Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: A URL to the target host. This URL supports Server Variables and MAY be relative, to indicate that the host location is relative to the location where the OpenAPI document is being served. Variable substitutions will be made when a variable is named in {brackets}.
Property URL As %String(%JSONFIELDNAME = "url", MAXLEN = 2000) [ Required ];

/// @OpenAPI: An optional string describing the host designated by the URL. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: A map between a variable name and its value. The value is used for substitution in the server’s URL template.
Property Variables As array Of %pkg.isc.rest.openAPI.model.serverVariable(%JSONFIELDNAME = "variables");

// TODO: Validation that when the enum values are substituted in, this is a valid url?

Storage Default
{
<Data name="ServerDefaultData">
<Subscript>"Server"</Subscript>
<Value name="1">
<Value>URL</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
</Data>
<Data name="Variables">
<Attribute>Variables</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.server.Variables"</Subscript>
</Data>
<DefaultData>ServerDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

