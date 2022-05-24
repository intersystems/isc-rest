/// Superclass to be used where either Security Scheme objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.securitySchemeOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Security Scheme objects
Parameter EXPECT = "SecurityScheme";

Property SecurityScheme As %pkg.isc.rest.openAPI.model.securityScheme(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

Storage Default
{
<Data name="SecuritySchemeOrReferenceDefaultData">
<Subscript>"SecuritySchemeOrReference"</Subscript>
<Value name="1">
<Value>ClassName</Value>
</Value>
<Value name="2">
<Value>SecurityScheme</Value>
</Value>
<Value name="3">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>SecuritySchemeOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

