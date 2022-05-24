/// Superclass to be used where either Schema objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.schemaOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Schema objects
Parameter EXPECT = "Schema";

Property Schema As %pkg.isc.rest.openAPI.model.schema(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

/// Used to track the class(es) that caused this object to be generated
Property SourceClasses As list Of %Dictionary.CacheClassname(%JSONINCLUDE = "none");

/// Whether or not this schema was auto-generated (anything overriding default behavior should leave this = 0)
Property AutoGenerated As %Boolean(%JSONINCLUDE = "none") [ InitialExpression = 0, Internal ];

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="SchemaOrReferenceDefaultData">
<Subscript>"SchemaOrReference"</Subscript>
<Value name="1">
<Value>SourceClasses</Value>
</Value>
<Value name="2">
<Value>ClassName</Value>
</Value>
<Value name="3">
<Value>SubclassName</Value>
</Value>
<Value name="4">
<Value>SubclassID</Value>
</Value>
<Value name="5">
<Value>Schema</Value>
</Value>
<Value name="6">
<Value>Reference</Value>
</Value>
<Value name="7">
<Value>AutoGenerated</Value>
</Value>
</Data>
<DefaultData>SchemaOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
