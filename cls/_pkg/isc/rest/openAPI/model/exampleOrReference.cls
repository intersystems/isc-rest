/// Superclass to be used where either Example objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.exampleOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Example objects
Parameter EXPECT = "Example";

Property Example As %pkg.isc.rest.openAPI.model.example(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

Storage Default
{
<Data name="ExampleOrReferenceDefaultData">
<Subscript>"ExampleOrReference"</Subscript>
<Value name="1">
<Value>Example</Value>
</Value>
<Value name="2">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>ExampleOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

