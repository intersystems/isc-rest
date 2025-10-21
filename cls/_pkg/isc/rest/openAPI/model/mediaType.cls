/// A representation of the OpenAPI Specification Media Type Object (see http://spec.openapis.org/oas/v3.0.3#mediaTypeObject)
Class %pkg.isc.rest.openAPI.model.mediaType Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The schema defining the content of the request, response, or parameter.
Property Schema As %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "schema");

/// @OpenAPI: Example of the media type. The example object SHOULD be in the correct format as specified by the media type. The example field is mutually exclusive of the examples field. Furthermore, if referencing a schema which contains an example, the example value SHALL override the example provided by the schema.
Property Example As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "example");

/// @OpenAPI: Examples of the media type. Each example object SHOULD match the media type and specified schema if present. The examples field is mutually exclusive of the example field. Furthermore, if referencing a schema which contains an example, the examples value SHALL override the example provided by the schema.
Property Examples As array Of %pkg.isc.rest.openAPI.model.exampleOrReference(%JSONFIELDNAME = "examples");

/// @OpenAPI: A map between a property name and its encoding information. The key, being the property name, MUST exist in the schema as a property. The encoding object SHALL only apply to requestBody objects when the media type is multipart or application/x-www-form-urlencoded.
Property Encoding As array Of %pkg.isc.rest.openAPI.model.encoding(%JSONFIELDNAME = "encoding");

/// Used to track the class(es) that caused this object to be generated.
/// MAXLEN to match <class>%Dictionary.Classname</class>. MUST use %String or else
/// cannot save due to lack of Normalize() method in %Dictionary.Classname.
Property SourceClasses As list Of %String(%JSONINCLUDE = "none", MAXLEN = 220);

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set objValid = '($IsObject(..Examples) && $IsObject(..Example))
	Do:'objValid ..OnFail(fullSpecification, debug, "Only one of Example/Examples should be specified")
	Return objValid
}

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
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
<Data name="Encoding">
<Attribute>Encoding</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.mediaType.Encoding"</Subscript>
</Data>
<Data name="Examples">
<Attribute>Examples</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.mediaType.Examples"</Subscript>
</Data>
<Data name="MediaTypeDefaultData">
<Subscript>"MediaType"</Subscript>
<Value name="1">
<Value>Schema</Value>
</Value>
<Value name="2">
<Value>Example</Value>
</Value>
<Value name="3">
<Value>SourceClasses</Value>
</Value>
</Data>
<DefaultData>MediaTypeDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

