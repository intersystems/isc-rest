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
		// handles export override only for string, not stream.
		New %export
		Set %export = ""
		Do $Method($This, "JSONExportOverride", 0)
		Set str = %export
		Return $$$OK
	} Catch {}
	Try {
		Set stream = ##class(%Stream.TmpCharacter).%New()
		// re-use export to stream and convert to string
		Set sc = ..%JSONExportCustom(.stream, mapping)
		Set str = stream.Read()		
		Return $$$OK
	} Catch ex {
		Return ex.AsStatus()
	}
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.<br>
/// mappingName is the name of the mapping to use for the export.  The base mapping is represened by "" and is the default.
Method %JSONExportToStream(
	ByRef export As %Stream.Object,
	mapping As %String = "") As %Status
{
	// Save current device
	Set io=$io
	
	Try {
		// Always output to %FileCharacterStream
		If $get(export)="" {
			Set export=##class(%FileCharacterStream).%New()
			// JSON is always UTF-8
			Set export.TranslateTable="UTF8"
			Set filestream=1
		} Else {
			Set filestream = ($zobjclass(export)="%Library.FileCharacterStream")
		}
		If filestream {
			Set stream=export
		} Else {
			Set stream=##class(%FileCharacterStream).%New()
			Set stream.TranslateTable="UTF8"
		}
		
		// Force stream's file to open
		Set sc=stream.Write("")
		
		// Export JSON to the stream
		If $$$ISOK(sc) {
			Set file=stream.Filename ; get filename and make current device
			Use file:(/NOXY)
			Set sc=..%JSONExportCustom(.stream, mapping)
			// Don't Close file to leave stream positioned
			Use io
		}
		
		// Need to ensdure that LineTerminator is correct for the platform
		If $$$ISOK(sc) Set stream.LineTerminator=$select($$$isUNIX:$char(10),1:$char(13,10))

		// If we created the stream and caller passed in stream, then copy it to the caller's stream
		If 'filestream,$$$ISOK(sc) {	
			Set sc=export.CopyFrom(stream)
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	Quit sc
}

// Internal Method to write to stream as custom export.

Method %JSONExportCustom(
	ByRef stream As %Stream.Object,
	mapping As %String = "")
{
	$$$ThrowOnError(stream.Rewind())
	$$$ThrowOnError(stream.Write("{"))
	Try {
		Set str = $Method($This,"JSONExportAdditional")
		If (str '= "") {
			$$$ThrowOnError(stream.Write(str))
		}
	} Catch {}
	If ..#%JSONINCLUDEID {
		Set str = """" _ ..#%JSONFIELDNAME _ """:" _ $Method($This,"%Id") _ ","
		$$$ThrowOnError(stream.Write(str))
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
				Set str = $Case(first,1:"",:",") _ """"_fieldName_""":" _ jsonObj
				$$$ThrowOnError(stream.Write(str))
				Set first = 0
			}
		}
		$$$ThrowOnError(stream.Write("}")) 
		Return $$$OK
	} Catch ex {
		Return ex.AsStatus()
	}
}

}
