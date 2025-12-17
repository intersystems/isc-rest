/// Superclass to be used where either Parameter objects or Reference objects may be accepted
Class %pkg.isc.rest.openAPI.model.parameterOrReference Extends %pkg.isc.rest.openAPI.model.super
{

/// @Special: Marks Reference object validation to only accept Parameter objects
Parameter EXPECT = "Parameter";

Property Parameter As %pkg.isc.rest.openAPI.model.parameter(%JSONINCLUDE = "none") [ Internal ];

Property Reference As %pkg.isc.rest.openAPI.model.reference(%JSONINCLUDE = "none") [ Internal ];

/// Used to track the class(es) that caused this object to be generated.
/// MAXLEN to match <class>%Dictionary.Classname</class>. MUST use %String or else
/// cannot save due to lack of Normalize() method in %Dictionary.Classname.
Property SourceClasses As list Of %String(%JSONINCLUDE = "none", MAXLEN = 220);

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
<Data name="ParameterOrReferenceDefaultData">
<Subscript>"ParameterOrReference"</Subscript>
<Value name="1">
<Value>SourceClasses</Value>
</Value>
<Value name="2">
<Value>Parameter</Value>
</Value>
<Value name="3">
<Value>Reference</Value>
</Value>
</Data>
<DefaultData>ParameterOrReferenceDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

