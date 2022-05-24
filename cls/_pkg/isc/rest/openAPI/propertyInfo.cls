Class %pkg.isc.rest.openAPI.propertyInfo Extends %pkg.isc.rest.openAPI.resourceInfoStub
{

/// Name of the class containing this property
Property Source As %String [ Internal ];

/// Cardinality (if any) of the property... ie. its Relationship-type
Property Cardinality As %String [ Internal ];

/// The type class being used to store the property... will differ from ..Type for some reference types
Property RuntimeType As %String [ Internal ];

/// Whether or not this is a required property
Property Required As %Boolean [ Internal ];

/// Type class of the property when used as a reference, ie. ID --> %Library.String
Property ReferenceType As %String [ Internal ];

/// JSON type of the property when used as a reference, ie. ID --> string
Property ReferenceJsonType As %String [ Internal ];

/// The JSON representation of a value this property could take on
Property Example As %String [ Internal ];

/// Collection type ('array' or 'list')
Property Collection As %String(VALUELIST = ",array,list") [ Internal ];

/// An OpenAPI-format schema specification for this property in the INPUT direction
Property OpenAPIInputSchema As %pkg.isc.rest.openAPI.model.schema [ Internal ];

/// An OpenAPI-format schema specification for this property in the OUTPUT direction
Property OpenAPIOutputSchema As %pkg.isc.rest.openAPI.model.schema [ Internal ];

/// TODO: Remove from use
Method GetStub()
{
	Return $This
}

}

