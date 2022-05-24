/// Superclass to be used where either Header objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.headerOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Header objects
Parameter EXPECT = "Header";

Property Header As %pkg.isc.rest.openAPI.model.header(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

Storage Default
{
<Data name="HeaderOrReferenceDefaultData">
<Subscript>"HeaderOrReference"</Subscript>
<Value name="1">
<Value>Header</Value>
</Value>
<Value name="2">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>HeaderOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

