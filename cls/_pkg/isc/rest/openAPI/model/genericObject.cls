/// An object that can hold any type of data (primitive, object, or DynamicObject/Array)
/// JSON Representation is the inline (not as a separate object) contents of ..Data, through use of %pkg.isc.rest.openAPI.model.passthroughObject
Class %pkg.isc.rest.openAPI.model.genericObject Extends %pkg.isc.rest.openAPI.model.passthroughObject
{

/// @Special: The object that is being stored
Property Data(MAXLEN = 2000);

/// @Special: The JSON Type (if specified) that should be used when returning this object's JSON representation
Property JSONType;

/// Constructs a GenericObject from the given object and (if specified) JSON type
/// Note: A JSONType of "raw" will pass through obj unchanged (as direct JSON) to output.
ClassMethod From(obj, jsonType = "") As %pkg.isc.rest.openAPI.model.genericObject
{
	Set ret = ..%New()
	Set ret.Data = obj
	Set ret.JSONType = jsonType
	Return ret
}

/// @Override: This object should not be validated
Method ValidateComponent(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, debug = 0) As %Boolean
{
	Return 1
}

/// @Override: This object's properties should not be validated
Method ValidateComponents(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, debug = 0)
{
	Return 1
}

/// @Override: Never save the object stored in ..Data, only its JSON representation
Method GetSaveableInstance(expect = "", removeTransient = 1) As %pkg.isc.rest.openAPI.model.super
{
	Do ..%JSONExportToString(.str)
	Return ..From(str, "raw")
}

Storage Default
{
<Data name="GenericObjectDefaultData">
<Subscript>"GenericObject"</Subscript>
<Value name="1">
<Value>Data</Value>
</Value>
<Value name="2">
<Value>JSONType</Value>
</Value>
</Data>
<DefaultData>GenericObjectDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

