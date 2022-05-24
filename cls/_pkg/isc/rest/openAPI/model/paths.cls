/// A representation of the OpenAPI Specification Paths Object (see http://spec.openapis.org/oas/v3.0.3#pathsObject)
/// JSON Representation is the inline (not as a separate object) contents of ..Data, through use of %pkg.isc.rest.openAPI.model.passthroughObject
Class %pkg.isc.rest.openAPI.model.paths Extends %pkg.isc.rest.openAPI.model.passthroughObject
{

/// @Override: Per the OpenAPI Specification, this object may be extended with "x-*" properties.
Parameter EXTENSIBLE = 1;

/// @Special: This Object's content
/// @OpenAPI: A relative path to an individual endpoint. The field name MUST begin with a forward slash (/). The path is appended (no relative URL resolution) to the expanded URL from the Server Object's url field in order to construct the full URL. Path templating is allowed. When matching URLs, concrete (non-templated) paths would be matched before their templated counterparts. Templated paths with the same hierarchy but different templated names MUST NOT exist as they are identical. In case of ambiguous matching, it’s up to the tooling to decide which one to use.
Property Data As array Of %pkg.isc.rest.openAPI.model.pathItem;

/// Used to track which (external) class is making use of this object
Property UserMethodClass As %String(%JSONINCLUDE = "none");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set pathsValid = 1
	Set key = "", value = ..GetNext(.key)
	While key '= "" {
		If $Extract(key,1) '= "/" {
			Set pathsValid = 0
			Quit
		}
		Set value = ..GetNext(.key)
	}
	Do:'pathsValid ..OnFail(fullSpecification, debug, "Path does not begin with a leading '/'")
	Return pathsValid
}

Method RemoveUnreachableOperations(permissionsRegex)
{
	Set key = "", value = ..GetNext(.key)
	While key '= "" {
		#Dim value As %pkg.isc.rest.openAPI.model.pathItem
		Do value.RemoveUnreachableOperations(permissionsRegex, ..UserMethodClass)
		If (value.Get="") && (value.Delete="") && (value.Head="") && (value.Options="") && (value.Patch="") && (value.Post="") && (value.Put="") && (value.Trace="") {
			Do ..RemoveAt(key)
			Set key = ""
		}
		Set value = ..GetNext(.key)
	}
}

Storage Default
{
<Data name="Data">
<Attribute>Data</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.paths.Data"</Subscript>
</Data>
<Data name="PathsDefaultData">
<Subscript>"Paths"</Subscript>
<Value name="1">
<Value>UserMethodClass</Value>
</Value>
</Data>
<DefaultData>PathsDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

