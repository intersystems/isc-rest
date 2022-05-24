/// Super-class that allows its sub-classes' ..Data property to be represented as JSON in place of them.
/// Note that this data property may be a primitive (a string, an integer, etc)
Class %pkg.isc.rest.openAPI.model.passthroughObject Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @Override: Whether or not this object allows the use of extended "x-*" properties (defaults to false)
Parameter EXTENSIBLE = 0;

/// @Override: Whether or not this object allows extended properties
Method AllowsExtendedProperties() As %Boolean
{
	Return ..#EXTENSIBLE
}

/// Pass-through calls to ..SetAt to the object's Data property
/// Throws an error if the object does not exist or have a SetAt method defined
Method SetAt(obj, key)
{
	Do ..Data().SetAt(obj, key)
}

/// Pass-through calls to ..Insert to the object's Data property
/// Throws an error if the object does not exist or have a Insert method defined
Method Insert(obj)
{
	Do ..Data().Insert(obj)
}

/// Pass-through calls to ..GetAt to the object's Data property
/// Throws an error if the object does not exist or have a GetAt method defined
Method GetAt(key)
{
	Return ..Data().GetAt(key)
}

/// Pass-through calls to ..RemoveAt to the object's Data property
/// Throws an error if the object does not exist or have a GetAt method defined
Method RemoveAt(key)
{
	Return ..Data().RemoveAt(key)
}

/// Pass-through calls to ..Count to the object's Data property
/// Throws an error if the object does not exist or have a Count method defined
Method Count() As %Integer
{
	Return ..Data().Count()
}

/// Pass-through calls to ..GetNext to the object's Data proeprty
/// Throws an error if the object does not exist or have a GetNext method defined
Method GetNext(ByRef key)
{
	Return ..Data().GetNext(.key)
}

/// Pass-through calls to ..IsDefined to the object's Data property
/// Throws an error if the object does not exist or have a IsDefined method defined
Method IsDefined(key)
{
	Return ..Data().IsDefined(key)
}

/// @Special: Override the JSONExport behavior defined by %pkg.isc.json, in order to return a JSON representation of ..Data instead of this object
Method JSONExportOverride(write As %Boolean) As %Status
{
	Return:$IsObject(..Data())&&($ClassName(..Data())[".ArrayOf") ..ExportArray(write)
	Return:$IsObject(..Data())&&($ClassName(..Data())[".ListOf") ..ExportList(write)
	Return ..ExportValue(write)
}

/// Handles exporting ..Data as JSON when it is a single object/primitive
Method ExportValue(doWrite As %Boolean)
{
	Try {
		Set str = $Case(..GetJSONType(),"raw":..Data(),:##class(%pkg.isc.rest.openAPI.util).FromJSON(..Data(), ..GetJSONType()))
		If ..#EXTENSIBLE {
			Try {
				Set str = "{" _ ..JSONExportAdditional() _ {}.%FromJSON($Extract({}.%FromJSON(str).%ToJSON(),2,*-1) _ "}")
			} Catch {
				Return $system.Error.%New("Class " _ $ClassName($this) _ " is marked as EXTENSIBLE, but was set to a non-object type.")
			}
		}
	} Catch ex {
		Return ex
	}
	Write:doWrite str
	Set:'doWrite %export = %export _ str
	Return $$$OK
}

/// Handles exporting ..Data as JSON when it is a list
Method ExportList(doWrite As %Boolean)
{
	Return:..#EXTENSIBLE $system.Error.%New("Class " _ $ClassName($this) _ " is marked as EXTENSIBLE, but was set to a non-object type.")
	Try {
		Set obj = []
		For i=1:1:..Data().Count() {
			If ..GetJSONType()'="" {
				Do obj.%Push(##class(%pkg.isc.rest.openAPI.util).GetJSON(..Data().GetAt(i)), ..GetJSONType())
			} Else {
				Do obj.%Push(##class(%pkg.isc.rest.openAPI.util).GetJSON(..Data().GetAt(i)))
			}
		}
	} Catch ex {
		Return ex
	}
	Set str = obj.%ToJSON()
	Write:doWrite str
	Set:'doWrite %export = %export _ str
	Return $$$OK
}

/// Handles exporting ..Data as JSON when it is an array
Method ExportArray(doWrite As %Boolean)
{
	Set obj = {}
	Set key = ""
	Try {
		Set data = ..Data()
		Set val = data.GetNext(.key)
		While key '= "" {
			If ..GetJSONType()'="" {
				Do obj.%Set(key, ##class(%pkg.isc.rest.openAPI.util).GetJSON(val), ..GetJSONType())
			} Else {
				Do obj.%Set(key, ##class(%pkg.isc.rest.openAPI.util).GetJSON(val))
			}
			Set val = data.GetNext(.key)
		}
		If ..#EXTENSIBLE {
			Set obj = {}.%FromJSON("{" _ ..JSONExportAdditional() _ $Extract(obj.%ToJSON(),2,*))
		}
	} Catch ex {
		Return ex.AsStatus()
	}
	Set str = obj.%ToJSON()
	Write:doWrite str
	Set:'doWrite %export = %export _ str
	Return $$$OK
}

/// Returns the value of the ..Data property for this object
Method Data()
{
	Return $Property($this,"Data")
}

/// Returns the value of the ..JSONType property for this object (or the empty string if not JSONType is defined)
Method GetJSONType()
{
	Try {
		Return $Property($this,"JSONType")
	} Catch ex {
		Return ""
	}
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}

