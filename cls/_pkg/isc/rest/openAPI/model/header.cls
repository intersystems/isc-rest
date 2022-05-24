/// A representation of the OpenAPI Specification Header Object (see http://spec.openapis.org/oas/v3.0.3#headerObject)
Class %pkg.isc.rest.openAPI.model.header Extends (%pkg.isc.rest.openAPI.model.headerOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper)
{

/// @OpenAPI: A brief description of the [header]. This could contain examples of use. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: Determines whether this [header] is mandatory. [...]
Property Required As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "required");

/// @OpenAPI: Specifies that a [header] is deprecated and SHOULD be transitioned out of usage. Default value is false.
Property Deprecated As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "deprecated");

/// @OpenAPI: Sets the ability to pass empty-valued [header]s. This [...] allows sending a <header> with an empty value. Default value is false. If style is used, and if behavior is n/a (cannot be serialized), the value of allowEmptyValue SHALL be ignored. Use of this property is NOT RECOMMENDED, as it is likely to be removed in a later revision.
Property AllowEmptyValue As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "allowEmptyValue");

/// @OpenAPI: Describes how the [header] value will be serialized [...]
Property Style As %String(%JSONFIELDNAME = "style", MAXLEN = 2000);

/// @OpenAPI: When this is true, [header] values [...] generate separate [header]s for each value of the array or key-value pair of the map.
Property Explode As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "explode");

/// @OpenAPI: Determines whether the [header] value SHOULD allow reserved characters, as defined by RFC3986 :/?#[]@!$&'()*+,;= to be included without percent-encoding. [...]
Property AllowReserved As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "allowReserved");

/// @OpenAPI: The schema defining the type used for the [header].
Property Schema As %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "schema");

/// @OpenAPI: Example of the [header]’s potential value. The example SHOULD match the specified schema and encoding properties if present. The example field is mutually exclusive of the examples field. Furthermore, if referencing a schema that contains an example, the example value SHALL override the example provided by the schema. To represent examples of media types that cannot naturally be represented in JSON or YAML, a string value can contain the example with escaping where necessary.
Property Example As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "example");

/// @OpenAPI: Examples of the [header]’s potential value. Each example SHOULD contain a value in the correct format as specified in the parameter encoding. The examples field is mutually exclusive of the example field. Furthermore, if referencing a schema that contains an example, the examples value SHALL override the example provided by the schema.
Property Examples As array Of %pkg.isc.rest.openAPI.model.exampleOrReference(%JSONFIELDNAME = "examples");

/// @OpenAPI: A map containing the representations for the [header]. The key is the media type and the value describes it. The map MUST only contain one entry.
Property Content As array Of %pkg.isc.rest.openAPI.model.mediaType;

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set contentValid = (..Content.Count() <= 1)
	Set exampleValid = '((..Examples.Count() > 0) && (..Example'=""))
	Do:'contentValid ..OnFail(fullSpecification, debug, "Invalid number of objects", "Content")
	Do:'exampleValid ..OnFail(fullSpecification, debug, "Only one of Example/Examples should be specified")
	Return contentValid && exampleValid
}

Storage Default
{
<Data name="Content">
<Attribute>Content</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.header.Content"</Subscript>
</Data>
<Data name="Examples">
<Attribute>Examples</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.header.Examples"</Subscript>
</Data>
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.header.Extras"</Subscript>
</Data>
<Data name="HeaderDefaultData">
<Subscript>"Header"</Subscript>
<Value name="1">
<Value>Description</Value>
</Value>
<Value name="2">
<Value>Required</Value>
</Value>
<Value name="3">
<Value>Deprecated</Value>
</Value>
<Value name="4">
<Value>AllowEmptyValue</Value>
</Value>
<Value name="5">
<Value>Style</Value>
</Value>
<Value name="6">
<Value>Explode</Value>
</Value>
<Value name="7">
<Value>AllowReserved</Value>
</Value>
<Value name="8">
<Value>Schema</Value>
</Value>
<Value name="9">
<Value>Example</Value>
</Value>
<Value name="10">
<Value>Header</Value>
</Value>
<Value name="11">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>HeaderDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

