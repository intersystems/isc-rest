/// Variant of the Model Super-class that allows specification of extended "x-*" properties.
Class %pkg.isc.rest.openAPI.model.extensibleSuper Extends %pkg.isc.rest.openAPI.model.super
{

/// Array of name->value mappings for extended "x-*" properties
Property Extras As array Of %pkg.isc.rest.openAPI.model.genericObject(%JSONINCLUDE = "none") [ Private ];

/// @Override: Whether or not this object allows extended properties
Method AllowsExtendedProperties() As %Boolean
{
	Return 1
}

/// Sets an extended "x-*" property
Method SetExtendedProperty(name As %String, value, jsonType = "")
{
	Set obj = ##class(%pkg.isc.rest.openAPI.model.genericObject).%New()
	Set obj.Data = value
	Set obj.JSONType = jsonType
	Do ..Extras.SetAt(obj, "x-" _ name)
}

/// Un-sets an extended "x-*" property
Method RemoveExtendedProperty(name As %String) As %Boolean
{
	Do ..Extras.RemoveAt("x-" _ name)
}

/// Gets the value of an "x-*" property
Method GetExtendedProperty(name As %String, Output type)
{
	Set type = ..Extras.GetAt("x-" _ name).JSONType
	Return ..Extras.GetAt("x-" _ name).Data
}

/// Returns whether or not an "x-*" property is set
Method IsExtendedPropertySet(name As %String) As %Boolean
{
	Return ..Extras.IsDefined("x-" _ name)
}

/// @Special: Additional information to be included in this class' JSON representation.
Method JSONExportAdditional() As %String
{
	Set json = {}
	Set setSomething = 0
	Try {
		Set key = ""
		Set val = ..Extras.GetNext(.key)
		While key'="" {
			Set setSomething = 1
			If val.JSONType '= "" {
				Do json.%Set(key, ##class(%pkg.isc.rest.openAPI.util).GetJSON(val.Data), val.JSONType)
			} Else {
				Do json.%Set(key, ##class(%pkg.isc.rest.openAPI.util).GetJSON(val.Data))
			}
			Set val = ..Extras.GetNext(.key)
		}
		Set str = json.%ToJSON()
		Return $Extract(str,2,*-1) _ $Select(setSomething:",",1:"")
	} Catch {
		Return $system.Error.%New("Class " _ $ClassName($this) _ " is a subclass of %pkg.isc.rest.openAPI.model.extensibleSuper, but is of a non-object type.")
	}
}

Storage Default
{
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.extensibleSuper.Extras"</Subscript>
</Data>
<Type>%Storage.Persistent</Type>
}

}

