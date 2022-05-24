/// A representation of the OpenAPI Specification License Object (see http://spec.openapis.org/oas/v3.0.3#licenseObject)
Class %pkg.isc.rest.openAPI.model.license Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The license name used for the API.
Property Name As %String(%JSONFIELDNAME = "name", MAXLEN = 2000) [ Required ];

/// @OpenAPI: A URL to the license used for the API. MUST be in the format of a URL.
Property URL As %String(%JSONFIELDNAME = "url", MAXLEN = 2000);

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set urlValid = ..URL="" || $Match(..URL, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Do:'urlValid ..OnFail(fullSpecification, debug, "URL (" _ ..URL _ ") Regex mismatch", "URL")
	Return urlValid
}

Storage Default
{
<Data name="LicenseDefaultData">
<Subscript>"License"</Subscript>
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>URL</Value>
</Value>
</Data>
<DefaultData>LicenseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

