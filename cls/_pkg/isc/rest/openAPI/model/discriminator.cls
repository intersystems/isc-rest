/// A representation of the OpenAPI Specification Discriminator Object (see http://spec.openapis.org/oas/v3.0.3#discriminatorObject)
Class %pkg.isc.rest.openAPI.model.discriminator Extends %pkg.isc.rest.openAPI.model.super
{

/// @OpenAPI: The name of the property in the payload that will hold the discriminator value.
Property PropertyName As %String(%JSONFIELDNAME = "propertyName", MAXLEN = 2000) [ Required ];

/// @OpenAPI: An object to hold mappings between payload values and schema names or references.
Property Mapping As array Of %String(%JSONFIELDNAME = "mapping", MAXLEN = 2000);

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	// TODO: Validate that Mappings point to existing schema names / references
	Set locationValid = 0
	Set superObject = ..GetContainingObject(fullSpecification)
	#dim superObject as %pkg.isc.rest.openAPI.model.schema
	If $IsObject(superObject) {
		Set locationValid = locationValid || (superObject.OneOf'="")
		Set locationValid = locationValid || (superObject.AnyOf'="")
		Set locationValid = locationValid || (superObject.AllOf'="")
	}
	Do:'locationValid ..OnFail(fullSpecification, debug, "Containing schema doesn't define at least one of OneOf/AnyOf/AllOf")
	Do:'nameSpecified ..OnFail(fullSpecification, debug, "Required field unspecified", "PropertyName")
	Return locationValid
}

Storage Default
{
<Data name="DiscriminatorDefaultData">
<Subscript>"Discriminator"</Subscript>
<Value name="1">
<Value>PropertyName</Value>
</Value>
</Data>
<Data name="Mapping">
<Attribute>Mapping</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.discriminator.Mapping"</Subscript>
</Data>
<DefaultData>DiscriminatorDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

