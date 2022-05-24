/// A representation of the OpenAPI Specification Encoding Object (see http://spec.openapis.org/oas/v3.0.3#encodingObject)
Class %pkg.isc.rest.openAPI.model.encoding Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: The Content-Type for encoding a specific property. Default value depends on the property type: for string with format being binary – application/octet-stream; for other primitive types – text/plain; for object - application/json; for array – the default is defined based on the inner type. The value can be a specific media type (e.g. application/json), a wildcard media type (e.g. image/*), or a comma-separated list of the two types.
Property ContentType As %String(%JSONFIELDNAME = "contentType", MAXLEN = 2000);

/// @OpenAPI: A map allowing additional information to be provided as headers, for example Content-Disposition. Content-Type is described separately and SHALL be ignored in this section. This property SHALL be ignored if the request body media type is not a multipart.
Property Headers As array Of %pkg.isc.rest.openAPI.model.headerOrReference(%JSONFIELDNAME = "headers");

/// @OpenAPI: Describes how a specific property value will be serialized depending on its type. See Parameter Object for details on the style property. The behavior follows the same values as query parameters, including default values. This property SHALL be ignored if the request body media type is not application/x-www-form-urlencoded.
Property Style As %String(%JSONFIELDNAME = "style", MAXLEN = 2000);

/// @OpenAPI: When this is true, property values of type array or object generate separate parameters for each value of the array, or key-value-pair of the map. For other types of properties this property has no effect. When style is form, the default value is true. For all other styles, the default value is false. This property SHALL be ignored if the request body media type is not application/x-www-form-urlencoded.
Property Explode As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "explode");

/// @OpenAPI: Determines whether the parameter value SHOULD allow reserved characters, as defined by RFC3986 :/?#[]@!$&'()*+,;= to be included without percent-encoding. The default value is false. This property SHALL be ignored if the request body media type is not application/x-www-form-urlencoded.
Property AllowReserved As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "allowReserved");

// TODO: Validation against AllowReserved would be nice

Storage Default
{
<Data name="EncodingDefaultData">
<Subscript>"Encoding"</Subscript>
<Value name="1">
<Value>ContentType</Value>
</Value>
<Value name="2">
<Value>Style</Value>
</Value>
<Value name="3">
<Value>Explode</Value>
</Value>
<Value name="4">
<Value>AllowReserved</Value>
</Value>
</Data>
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.encoding.Headers"</Subscript>
</Data>
<DefaultData>EncodingDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

