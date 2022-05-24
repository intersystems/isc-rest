/// Class used to represent lists of Strings (makes creation/validation of arrays of string lists easier)
/// JSON Representation is the inline (not as a separate object) contents of ..Data, through use of %pkg.isc.rest.openAPI.model.passthroughObject
Class %pkg.isc.rest.openAPI.model.stringList Extends %pkg.isc.rest.openAPI.model.passthroughObject
{

/// @Special: This Object's content
/// The String array represented by this object
Property Data As list Of %String(MAXLEN = 2000);

Storage Default
{
<Data name="StringListDefaultData">
<Subscript>"StringList"</Subscript>
<Value name="1">
<Value>Data</Value>
</Value>
</Data>
<DefaultData>StringListDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

