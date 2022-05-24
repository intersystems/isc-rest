/// A representation of the OpenAPI Specification Info Object (see http://spec.openapis.org/oas/v3.0.3#infoObject)
Class %pkg.isc.rest.openAPI.model.info Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The title of the API.
Property Title As %String(%JSONFIELDNAME = "title", MAXLEN = 2000) [ Required ];

/// @OpenAPI: A short description of the API. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 20000);

/// @OpenAPI: A URL to the Terms of Service for the API. MUST be in the format of a URL.
Property TermsOfService As %String(%JSONFIELDNAME = "termsOfService", MAXLEN = 2000);

/// @OpenAPI: The contact information for the exposed API.
Property Contact As %pkg.isc.rest.openAPI.model.contact(%JSONFIELDNAME = "contact");

/// @OpenAPI: The license information for the exposed API.
Property License As %pkg.isc.rest.openAPI.model.license(%JSONFIELDNAME = "license");

/// @OpenAPI: The version of the OpenAPI document (which is distinct from the OpenAPI Specification version or the API implementation version).
Property Version As %String(%JSONFIELDNAME = "version", MAXLEN = 2000) [ Required ];

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set tosValid = ..TermsOfService="" || $Match(..TermsOfService, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Do:'tosValid ..OnFail(fullSpecification, debug, "URL (" _ ..TermsOfService _ ") Regex mismatch", "TermsOfService")
	Return tosValid
}

Storage Default
{
<Data name="InfoDefaultData">
<Subscript>"Info"</Subscript>
<Value name="1">
<Value>Title</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>TermsOfService</Value>
</Value>
<Value name="4">
<Value>Contact</Value>
</Value>
<Value name="5">
<Value>License</Value>
</Value>
<Value name="6">
<Value>Version</Value>
</Value>
</Data>
<DefaultData>InfoDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

