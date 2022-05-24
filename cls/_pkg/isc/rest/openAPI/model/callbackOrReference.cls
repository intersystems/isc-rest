/// Superclass to be used where either Callback objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.callbackOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Callback objects
Parameter EXPECT = "Callback";

Property Callback As %pkg.isc.rest.openAPI.model.callback(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

Storage Default
{
<Data name="CallbackOrReferenceDefaultData">
<Subscript>"CallbackOrReference"</Subscript>
<Value name="1">
<Value>Callback</Value>
</Value>
<Value name="2">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>CallbackOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

