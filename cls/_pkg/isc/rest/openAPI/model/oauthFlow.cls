/// A representation of the OpenAPI Specification OAuth Flow Object (see http://spec.openapis.org/oas/v3.0.3#oauthFlowObject)
Class %pkg.isc.rest.openAPI.model.oauthFlow Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The authorization URL to be used for this flow. This MUST be in the form of a URL.
Property AuthorizationURL As %String(%JSONFIELDNAME = "authorizationUrl", MAXLEN = 2000) [ Required ];

/// @OpenAPI: The token URL to be used for this flow. This MUST be in the form of a URL.
Property TokenURL As %String(%JSONFIELDNAME = "tokenUrl", MAXLEN = 2000) [ Required ];

/// @OpenAPI: The URL to be used for obtaining refresh tokens. This MUST be in the form of a URL.
Property RefreshURL As %String(%JSONFIELDNAME = "refreshUrl", MAXLEN = 2000);

/// @OpenAPI: The available scopes for the OAuth2 security scheme. A map between the scope name and a short description for it. The map MAY be empty.
Property Scopes As array Of %String(%JSONFIELDNAME = "scopes", MAXLEN = 2000) [ Required ];

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set authURLValid = 1, tokenURLValid = 1, refreshURLValid = 1
	Set:..AuthorizationURL'="" authURLValid = $Match(..AuthorizationURL, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Set:..TokenURL'="" tokenURLValid = $Match(..TokenURL, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Set:..RefreshURL'="" refreshURLValid = $Match(..RefreshURL, ##class(%pkg.isc.rest.openAPI.util).#URLREGEX)
	Do:'authURLValid ..OnFail(fullSpecification, debug, "URL (" _ ..AuthorizationURL _ ") Regex mismatch", "AuthorizationURL")
	Do:'tokenURLValid ..OnFail(fullSpecification, debug, "URL (" _ ..TokenURL _ ") Regex mismatch", "TokenURL")
	Do:'refreshURLValid ..OnFail(fullSpecification, debug, "URL (" _ ..RefreshURL _ ") Regex mismatch", "RefreshURL")
	Return authURLValid && tokenURLValid && refreshURLValid
}

Storage Default
{
<Data name="OAuthFlowDefaultData">
<Subscript>"OAuthFlow"</Subscript>
<Value name="1">
<Value>AuthorizationURL</Value>
</Value>
<Value name="2">
<Value>TokenURL</Value>
</Value>
<Value name="3">
<Value>RefreshURL</Value>
</Value>
</Data>
<Data name="Scopes">
<Attribute>Scopes</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.oauthFlow.Scopes"</Subscript>
</Data>
<DefaultData>OAuthFlowDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

