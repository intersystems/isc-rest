/// A representation of the OpenAPI Specification Security Requirement Object (see http://spec.openapis.org/oas/v3.0.3#securityRequirementObject)
/// JSON Representation is the inline (not as a separate object) contents of ..Data, through use of %pkg.isc.rest.openAPI.model.passthroughObject
Class %pkg.isc.rest.openAPI.model.securityRequirement Extends %pkg.isc.rest.openAPI.model.passthroughObject
{

/// @Special: This Object's content
/// @OpenAPI: Lists the required security schemes to execute this operation. The name used for each property MUST correspond to a security scheme declared in the Security Schemes under the Components Object.
/// @OpenAPI: If the security scheme is of type "oauth2" or "openIdConnect", then the value is a list of scope names required for the execution, and the list MAY be empty if authorization does not require a specified scope. For other security scheme types, the array MUST be empty.
Property Data As array Of %pkg.isc.rest.openAPI.model.stringList;

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set keysValid = 1
	Set valuesValid = 1
	If $IsObject(..Data) {
		Set components = ..GetAllFromSpec(fullSpecification, "%pkg.isc.rest.openAPI.model.component")
		Set key = ""
		Set list = ..Data.GetNext(.key)
		While key'="" {
			Set ok = 0
			For j=1:1:components.Count() {
				Set component = components.GetAt(j)
				If $IsObject(component.SecuritySchemes) && component.SecuritySchemes.IsDefined(key) {
					Set scheme = component.SecuritySchemes.GetAt(key)
					If '$Match(scheme.Type, "oauth2|openIdConnect") {
						Set valuesValid = list.Count() = 0
					}
					Set ok = 1
					Quit
				}
			}
			If 'ok {
				Set keysValid = 0
				Do:'keysValid ..OnFail(fullSpecification, debug, "Key (" _ key _ ") does not match a defined Security Scheme key")
			}
			Set list = ..Data.GetNext(.key)
		}
	}
	Do:'valuesValid ..OnFail(fullSpecification, debug, "Value array must be empty when matching Security Scheme type is not oauth2 or openIdConnect")
}

Storage Default
{
<Data name="Data">
<Attribute>Data</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.securityRequirement.Data"</Subscript>
</Data>
<Type>%Storage.Persistent</Type>
}

}

