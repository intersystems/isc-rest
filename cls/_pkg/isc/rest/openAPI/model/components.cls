/// A representation of the OpenAPI Specification Component Object (see http://spec.openapis.org/oas/v3.0.3#componentsObject)
Class %pkg.isc.rest.openAPI.model.components Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// Acceptible key regex (see http://spec.openapis.org/oas/v3.0.3#componentsObject)
Parameter KEYREGEX = "^[a-zA-Z0-9\.\-_]+$";

/// @OpenAPI: An object to hold reusable Schema Objects.
Property Schemas As array Of %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "schemas");

/// @OpenAPI: An object to hold reusable Response Objects.
Property Responses As %pkg.isc.rest.openAPI.model.responses(%JSONFIELDNAME = "responses");

/// @OpenAPI: An object to hold reusable Parameter Objects.
Property Parameters As array Of %pkg.isc.rest.openAPI.model.parameterOrReference(%JSONFIELDNAME = "parameters");

/// @OpenAPI: An object to hold reusable Example Objects.
Property Examples As array Of %pkg.isc.rest.openAPI.model.exampleOrReference(%JSONFIELDNAME = "examples");

/// @OpenAPI: An object to hold reusable Request Body Objects.
Property RequestBodies As array Of %pkg.isc.rest.openAPI.model.requestBodyOrReference(%JSONFIELDNAME = "requestBodies");

/// @OpenAPI: An object to hold reusable Header Objects.
Property Headers As array Of %pkg.isc.rest.openAPI.model.headerOrReference(%JSONFIELDNAME = "headers");

/// @OpenAPI: An object to hold reusable Security Scheme Objects.
Property SecuritySchemes As array Of %pkg.isc.rest.openAPI.model.securitySchemeOrReference(%JSONFIELDNAME = "securitySchemes");

/// @OpenAPI: An object to hold reusable Link Objects.
Property Links As array Of %pkg.isc.rest.openAPI.model.linkOrReference(%JSONFIELDNAME = "links");

/// @OpenAPI: An object to hold reusable Callback Objects.
Property Callbacks As array Of %pkg.isc.rest.openAPI.model.callbackOrReference(%JSONFIELDNAME = "callbacks");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set valid = 1
	Set arrays = ##class(%ArrayOfObjects).%New()
	Do arrays.SetAt(..Schemas,"Schemas")
	Do arrays.SetAt(..Responses,"Responses")
	Do arrays.SetAt(..Parameters,"Parameters")
	Do arrays.SetAt(..Examples,"Examples")
	Do arrays.SetAt(..RequestBodies,"RequestBodies")
	Do arrays.SetAt(..Headers,"Headers")
	Do arrays.SetAt(..SecuritySchemes,"SecuritySchemes")
	Do arrays.SetAt(..Links,"Links")
	Do arrays.SetAt(..Callbacks,"Callbacks")
	Set propertyName = ""
	Set array = arrays.GetNext(.propertyName)
	While propertyName '= "" {
		If $IsObject(array) {
			Set key = ""
			Do array.GetNext(.key)
			While key'="" {
				If '$Match(key, ..#KEYREGEX) {
					Set valid = 0
					Do ..OnFail(fullSpecification, debug, "Array key (" _ key _ ") contains invalid characters", propertyName)
					Quit:'debug
				}
				Do array.GetNext(.key)
			}
		}
		Set array = arrays.GetNext(.propertyName)
	}
	Return valid
}

Storage Default
{
<Data name="Callbacks">
<Attribute>Callbacks</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.Callbacks"</Subscript>
</Data>
<Data name="ComponentsDefaultData">
<Subscript>"Components"</Subscript>
<Value name="1">
<Value>Responses</Value>
</Value>
</Data>
<Data name="Examples">
<Attribute>Examples</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.Examples"</Subscript>
</Data>
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.Headers"</Subscript>
</Data>
<Data name="Links">
<Attribute>Links</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.Links"</Subscript>
</Data>
<Data name="Parameters">
<Attribute>Parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.Parameters"</Subscript>
</Data>
<Data name="RequestBodies">
<Attribute>RequestBodies</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.RequestBodies"</Subscript>
</Data>
<Data name="Schemas">
<Attribute>Schemas</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.Schemas"</Subscript>
</Data>
<Data name="SecuritySchemes">
<Attribute>SecuritySchemes</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.components.SecuritySchemes"</Subscript>
</Data>
<DefaultData>ComponentsDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

