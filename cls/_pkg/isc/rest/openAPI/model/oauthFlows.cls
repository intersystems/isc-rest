/// A representation of the OpenAPI Specification OAuth Flows Object (see http://spec.openapis.org/oas/v3.0.3#oauthFlowsObject)
Class %pkg.isc.rest.openAPI.model.oauthFlows Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: Configuration for the OAuth Implicit flow
Property Implicit As %pkg.isc.rest.openAPI.model.oauthFlow(%JSONFIELDNAME = "implicit");

/// @OpenAPI: Configuration for the OAuth Resource Owner Password flow
Property Password As %pkg.isc.rest.openAPI.model.oauthFlow(%JSONFIELDNAME = "password");

/// @OpenAPI: Configuration for the OAuth Client Credentials flow. Previously called application in OpenAPI 2.0.
Property ClientCredentials As %pkg.isc.rest.openAPI.model.oauthFlow(%JSONFIELDNAME = "clientCredentials");

/// @OpenAPI: Configuration for the OAuth Authorization Code flow. Previously called accessCode in OpenAPI 2.0.
Property AuthorizationCode As %pkg.isc.rest.openAPI.model.oauthFlow(%JSONFIELDNAME = "authorizationCode");

Storage Default
{
<Data name="OAuthFlowsDefaultData">
<Subscript>"OAuthFlows"</Subscript>
<Value name="1">
<Value>Implicit</Value>
</Value>
<Value name="2">
<Value>Password</Value>
</Value>
<Value name="3">
<Value>ClientCredentials</Value>
</Value>
<Value name="4">
<Value>AuthorizationCode</Value>
</Value>
</Data>
<DefaultData>OAuthFlowsDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

