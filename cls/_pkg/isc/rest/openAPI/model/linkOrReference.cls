/// Superclass to be used where either Link objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.linkOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Link objects
Parameter EXPECT = "Link";

Property Link As %pkg.isc.rest.openAPI.model.link(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

Storage Default
{
<Data name="LinkOrReferenceDefaultData">
<Subscript>"LinkOrReference"</Subscript>
<Value name="1">
<Value>ClassName</Value>
</Value>
<Value name="2">
<Value>Link</Value>
</Value>
<Value name="3">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>LinkOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

