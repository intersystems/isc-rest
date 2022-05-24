/// A representation of the OpenAPI Specification Callback Object (see http://spec.openapis.org/oas/v3.0.3#callbackObject)
/// JSON Representation is the inline (not as a separate object) contents of ..Data, through use of %pkg.isc.rest.openAPI.model.passthroughObject
Class %pkg.isc.rest.openAPI.model.callback Extends (%pkg.isc.rest.openAPI.model.callbackOrReference, %pkg.isc.rest.openAPI.model.passthroughObject)
{

/// @Override: Per the OpenAPI Specification, this object may be extended with "x-*" properties.
Parameter EXTENSIBLE = 1;

/// @Special: This Object's content
/// @OpenAPI: Each value in the map is a Path Item Object that describes a set of requests that may be initiated by the API provider and the expected responses.
/// @OpenAPI: The key value used to identify the path item object is an expression, evaluated at runtime, that identifies a URL to use for the callback operation.
Property Data As array Of %pkg.isc.rest.openAPI.model.pathItem;

Storage Default
{
<Data name="CallbackDefaultData">
<Subscript>"Callback"</Subscript>
<Value name="1">
<Value>Callback</Value>
</Value>
<Value name="2">
<Value>Reference</Value>
</Value>
</Data>
<Data name="Data">
<Attribute>Data</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.callback.Data"</Subscript>
</Data>
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.callback.Extras"</Subscript>
</Data>
<DefaultData>CallbackDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

