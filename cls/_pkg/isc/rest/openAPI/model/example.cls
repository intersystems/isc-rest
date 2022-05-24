/// A representation of the OpenAPI Specification Example Object (see http://spec.openapis.org/oas/v3.0.3#exampleObject)
Class %pkg.isc.rest.openAPI.model.example Extends (%pkg.isc.rest.openAPI.model.exampleOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper)
{

/// @OpenAPI: Short description for the example.
Property Summary As %String(%JSONFIELDNAME = "summary", MAXLEN = 2000);

/// @OpenAPI: Long description for the example. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: Embedded literal example. The value field and externalValue field are mutually exclusive. To represent examples of media types that cannot naturally represented in JSON or YAML, use a string value to contain the example, escaping where necessary.
Property Value As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "value");

/// @OpenAPI: A URL that points to the literal example. This provides the capability to reference examples that cannot easily be included in JSON or YAML documents. The value field and externalValue field are mutually exclusive.
Property ExternalValue As %String(%JSONFIELDNAME = "externalValue", MAXLEN = 2000);

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set urlValid = 1
	Set:..ExternalValue'="" urlValid = $Match(..ExternalValue, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Set objValid = '($IsObject(..Value) && (..ExternalValue'=""))
	Do:'urlValid ..OnFail(fullSpecification, debug, "URL (" _ ..ExternalValue _ ") Regex mismatch", "ExternalValue")
	Do:'objValid ..OnFail(fullSpecification, debug, "Only one of Value/ExternalValue should be specified")
	Return urlValid && objValid
}

Storage Default
{
<Data name="ExampleDefaultData">
<Subscript>"Example"</Subscript>
<Value name="1">
<Value>Summary</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>Value</Value>
</Value>
<Value name="4">
<Value>ExternalValue</Value>
</Value>
<Value name="5">
<Value>Example</Value>
</Value>
<Value name="6">
<Value>Reference</Value>
</Value>
</Data>
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.example.Extras"</Subscript>
</Data>
<DefaultData>ExampleDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

