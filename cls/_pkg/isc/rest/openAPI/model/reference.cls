/// A representation of the OpenAPI Specification Reference Object (see http://spec.openapis.org/oas/v3.0.3#referenceObject)
Class %pkg.isc.rest.openAPI.model.reference Extends %pkg.isc.rest.openAPI.model.super
{

/// @OpenAPI: The reference string.
Property Ref As %String(%JSONFIELDNAME = "$ref", MAXLEN = 2000) [ Required ];

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set resolved = ..ResolveReference(..Ref, fullSpecification)
	Set refValid = $IsObject(resolved)
	Set type = ..GetDefinedType(fullSpecification)
	Set expect = ""
	If type [ "OrReference" {
		Set expect = $Parameter(type,"EXPECT")
		Set refValid = refValid && ($ClassName(resolved) = ("%pkg.isc.rest.openAPI.model."_expect))
	}
	Do:'refValid ..OnFail(fullSpecification, debug, "Reference (" _ ..Ref _ ") is invalid" _ $Select(expect="":"",1:" or does not point to a(n) "_expect_" object"), "Ref")
	Return refValid
}

Storage Default
{
<Data name="ReferenceDefaultData">
<Subscript>"Reference"</Subscript>
<Value name="1">
<Value>Ref</Value>
</Value>
</Data>
<DefaultData>ReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

