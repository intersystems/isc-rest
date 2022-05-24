/// A representation of the OpenAPI Specification Contact Object (see http://spec.openapis.org/oas/v3.0.3#contactObject)
Class %pkg.isc.rest.openAPI.model.contact Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The identifying name of the contact person/organization.
Property Name As %String(%JSONFIELDNAME = "name", MAXLEN = 2000);

/// @OpenAPI: The URL pointing to the contact information. MUST be in the format of a URL.
Property URL As %String(%JSONFIELDNAME = "url", MAXLEN = 2000);

/// @OpenAPI: The email address of the contact person/organization. MUST be in the format of an email address.
Property Email As %String(%JSONFIELDNAME = "email", MAXLEN = 2000);

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set urlValid = ..URL="" || $Match(..URL, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Set emailValid = ..Email="" || $Match(..Email, ##class(%pkg.isc.rest.openAPI.util).#EMAILREGEX)
	Do:'urlValid ..OnFail(fullSpecification, debug, "URL (" _ ..URL _ ") Regex mismatch", "URL")
	Do:'emailValid ..OnFail(fullSpecification, debug, "Email (" _ ..Email _ ")Regex mismatch", "Email")
	Return urlValid && emailValid
}

Storage Default
{
<Data name="ContactDefaultData">
<Subscript>"Contact"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>URL</Value>
</Value>
<Value name="3">
<Value>Email</Value>
</Value>
</Data>
<DefaultData>ContactDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

