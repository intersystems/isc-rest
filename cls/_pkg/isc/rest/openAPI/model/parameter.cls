/// A representation of the OpenAPI Specification Parameter Object (see http://spec.openapis.org/oas/v3.0.3#parameterObject)
Class %pkg.isc.rest.openAPI.model.parameter Extends (%pkg.isc.rest.openAPI.model.parameterOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper)
{

/// @OpenAPI: The name of the parameter. Parameter names are case sensitive. 
/// @OpenAPI: - If in is "path", the name field MUST correspond to a template expression occurring within the path field in the Paths Object. See Path Templating for further information.
/// @OpenAPI: - If in is "header" and the name field is "Accept", "Content-Type" or "Authorization", the parameter definition SHALL be ignored.
/// @OpenAPI: - For all other cases, the name corresponds to the parameter name used by the in property.
Property Name As %String(%JSONFIELDNAME = "name", MAXLEN = 2000) [ Required ];

/// @OpenAPI: The location of the parameter. Possible values are "query", "header", "path" or "cookie".
Property In As %EnumString(%JSONFIELDNAME = "in", VALUELIST = "|query|header|path|cookie") [ Required ];

/// @OpenAPI: A brief description of the parameter. This could contain examples of use. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: Determines whether this parameter is mandatory. If the parameter location is "path", this property is REQUIRED and its value MUST be true. Otherwise, the property MAY be included and its default value is false.
Property Required As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "required");

/// @OpenAPI: Specifies that a parameter is deprecated and SHOULD be transitioned out of usage. Default value is false.
Property Deprecated As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "deprecated");

/// @OpenAPI: Sets the ability to pass empty-valued parameters. This is valid only for query parameters and allows sending a parameter with an empty value. Default value is false. If style is used, and if behavior is n/a (cannot be serialized), the value of allowEmptyValue SHALL be ignored. Use of this property is NOT RECOMMENDED, as it is likely to be removed in a later revision.
Property AllowEmptyValue As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "allowEmptyValue");

/// @OpenAPI: Describes how the parameter value will be serialized depending on the type of the parameter value. Default values (based on value of in): for query - form; for path - simple; for header - simple; for cookie - form.
Property Style As %String(%JSONFIELDNAME = "style", MAXLEN = 2000);

/// @OpenAPI: When this is true, parameter values of type array or object generate separate parameters for each value of the array or key-value pair of the map. For other types of parameters this property has no effect. When style is form, the default value is true. For all other styles, the default value is false.
Property Explode As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "explode");

/// @OpenAPI: Determines whether the parameter value SHOULD allow reserved characters, as defined by RFC3986 :/?#[]@!$&'()*+,;= to be included without percent-encoding. This property only applies to parameters with an in value of query. The default value is false.
Property AllowReserved As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "allowReserved");

/// @OpenAPI: The schema defining the type used for the parameter.
Property Schema As %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "schema");

/// @OpenAPI: Example of the parameter’s potential value. The example SHOULD match the specified schema and encoding properties if present. The example field is mutually exclusive of the examples field. Furthermore, if referencing a schema that contains an example, the example value SHALL override the example provided by the schema. To represent examples of media types that cannot naturally be represented in JSON or YAML, a string value can contain the example with escaping where necessary.
Property Example As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "example");

/// @OpenAPI: Examples of the parameter’s potential value. Each example SHOULD contain a value in the correct format as specified in the parameter encoding. The examples field is mutually exclusive of the example field. Furthermore, if referencing a schema that contains an example, the examples value SHALL override the example provided by the schema.
Property Examples As array Of %pkg.isc.rest.openAPI.model.exampleOrReference(%JSONFIELDNAME = "examples");

/// @OpenAPI: A map containing the representations for the parameter. The key is the media type and the value describes it. The map MUST only contain one entry.
Property Content As array Of %pkg.isc.rest.openAPI.model.mediaType(%JSONFIELDNAME = "content");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set requiredValid = 1
	If ..In = "path" {
		Set requiredValid = ..Required
	}
	Do:'requiredValid ..OnFail(fullSpecification, debug, "Required must be true when In = 'path'", "Required")
	Return requiredValid
}

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	Set key = "", content = ..Content.GetNext(.key)
	While key'="" {
		Do content.RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..Content.RemoveAt(key)
			Set key = ""
		}
		Set content = ..Content.GetNext(.key)
	}
	
	If $IsObject(..Schema) {
		Do ..Schema.RemoveAllFromSource(className, .keep)
		Set:'keep ..Schema = ""
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="Content">
<Attribute>Content</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.parameter.Content"</Subscript>
</Data>
<Data name="Examples">
<Attribute>Examples</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.parameter.Examples"</Subscript>
</Data>
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.parameter.Extras"</Subscript>
</Data>
<Data name="ParameterDefaultData">
<Subscript>"Parameter"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>In</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Required</Value>
</Value>
<Value name="5">
<Value>Deprecated</Value>
</Value>
<Value name="6">
<Value>AllowEmptyValue</Value>
</Value>
<Value name="7">
<Value>Style</Value>
</Value>
<Value name="8">
<Value>Explode</Value>
</Value>
<Value name="9">
<Value>AllowReserved</Value>
</Value>
<Value name="10">
<Value>Schema</Value>
</Value>
<Value name="11">
<Value>Example</Value>
</Value>
</Data>
<DefaultData>ParameterDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

