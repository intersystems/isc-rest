/// A representation of the OpenAPI Specification XML Object (see http://spec.openapis.org/oas/v3.0.3#xmlObject)
Class %pkg.isc.rest.openAPI.model.xml Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: Replaces the name of the element/attribute used for the described schema property. When defined within items, it will affect the name of the individual XML elements within the list. When defined alongside type being array (outside the items), it will affect the wrapping element and only if wrapped is true. If wrapped is false, it will be ignored.
Property Name As %String(%JSONFIELDNAME = "name", MAXLEN = 2000);

/// @OpenAPI: The URI of the namespace definition. Value MUST be in the form of an absolute URI.
Property Namespace As %String(%JSONFIELDNAME = "namespace", MAXLEN = 2000);

/// @OpenAPI: The prefix to be used for the name.
Property Prefix As %String(%JSONFIELDNAME = "prefix", MAXLEN = 2000);

/// @OpenAPI: Declares whether the property definition translates to an attribute instead of an element. Default value is false.
Property Attribute As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "attribute");

/// @OpenAPI: MAY be used only for an array definition. Signifies whether the array is wrapped (for example, <books><book/><book/></books>) or unwrapped (<book/><book/>). Default value is false. The definition takes effect only when defined alongside type being array (outside the items).
Property Wrapped As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "wrapped");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set namespaceValid = ..Namespace="" || $Match(..Namespace, ##class(%pkg.isc.rest.openAPI.util).#URIREGEX)
	Do:'namespaceValid ..OnFail(fullSpecification, debug, "URI (" _ ..Namespace _ ") Regex mismatch", "Namespace")
	Return namespaceValid
}

Storage Default
{
<Data name="XMLDefaultData">
<Subscript>"XML"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Namespace</Value>
</Value>
<Value name="3">
<Value>Prefix</Value>
</Value>
<Value name="4">
<Value>Attribute</Value>
</Value>
<Value name="5">
<Value>Wrapped</Value>
</Value>
</Data>
<DefaultData>XMLDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

