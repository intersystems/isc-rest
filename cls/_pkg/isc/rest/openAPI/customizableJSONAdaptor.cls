/// JSON Adaptor that supports custom JSON generation / addition methods
Class %pkg.isc.rest.openAPI.customizableJSONAdaptor [ Abstract, PropertyClass = %pkg.isc.rest.openAPI.customizableJSONAdaptorProperties, System = 3 ]
{

Parameter %JSONINCLUDEID = 1;

Parameter %JSONFIELDNAME = "_id";

/// Writes the JSON representation of this object
Method %JSONExport(mapping = "") As %Status
{
	Set sc = ..%JSONExportToString(.str, mapping)
	Return:$System.Status.IsError(sc) sc
	Write str
	Return $$$OK
}

/// Writes the JSON representation of this object to a string
Method %JSONExportToString(ByRef str, mapping = "") As %Status
{
	Try {
		New %export
		Set %export = ""
		Do $Method($This, "JSONExportOverride", 0)
		Set str = %export
		Return $$$OK
	} Catch {}
	Set str = "{"
	Try {
		Set str = str _ $Method($This,"JSONExportAdditional")
	} Catch {}
	If ..#%JSONINCLUDEID {
		Set str = str _ """" _ ..#%JSONFIELDNAME _ """:" _ $Method($This,"%Id") _ ","
	}
	Try {
		Set selfStub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New($ClassName($This), mapping)
		Do selfStub.PopulateNonOverwrittenValues()
		Set def = ##class(%Dictionary.CompiledClass).%OpenId($ClassName($This))
		Set first = 1
		For i=1:1:def.Properties.Count() {
			Set property = def.Properties.GetAt(i)
			#Dim property As %Dictionary.CompiledProperty
			Continue:$Match(property.Parameters.GetAt("%JSONINCLUDE"),"none|inputonly")
			Continue:$Property($This,property.Name)=""||(property.Name="%Concurrency")||(property.Name="%%OID")
			Set fieldName = property.Parameters.GetAt("%JSONFIELDNAME")
			Set:fieldName="" fieldName = property.Name
			Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(property.Type, selfStub.PropertiesDefaultJSONMapping,,,,,,,,,, fieldName)
			Do stub.PopulateNonOverwrittenValues(selfStub.PropertiesDefaultReference, selfStub.PropertiesDefaultIncludeID, selfStub.PropertiesDefaultIDField)
			Set jsonObj = ##class(%pkg.isc.rest.openAPI.util).FromJSON($Property($This,property.Name), $Case(stub.JSONType,"object":"",:stub.JSONType), stub.JSONMapping)
			If '$Match(jsonObj,"|\{\}|\[\]") {
				Set str = str _ $Case(first,1:"",:",") _ """"_fieldName_""":" _ jsonObj
				Set first = 0
			}
		}
		Set str = str _ "}"
		Return $$$OK
	} Catch ex {
		Return ex.AsStatus()
	}
}

}

