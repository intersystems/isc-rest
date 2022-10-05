Include %pkg.isc.rest.general

Class %pkg.isc.rest.openAPI.util
{

/// Sematic Versioning 2.0.0 Regex (see https://semver.org/spec/v2.0.0.html)
Parameter SEMVERREGEX As %String = "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$";

/// Matches a http(s)/(s)ftp URL
Parameter URLREGEX = "(?i)(\b(https?|s?ftp)://[-A-Z0-9+&@#/%?=~_|!:,.;]*[-A-Z0-9+&@#/%=~_|])";

/// Matches a URI
Parameter URIREGEX = "\w+:(\/?\/?)[^\s]+";

/// Matches an email address (this regex could be made a lot more restrictive)
Parameter EMAILREGEX = "\b[^@\s]+@[^@\s]+";

/// Formats a String for use in a JSON object name
ClassMethod FormatString(str) As %String [ Internal ]
{
	// Strip leading, trailing, and repeating non-alphanumeric characters
	// Strip leading numeric characters
	Set str = $ZStrip($ZStrip(str,"<=>PCW"),"<N")
	
	// Replace all non-alphanumeric characters with hyphens
	For i=1:1:$Length(str) {
		Set c = $Extract(str,i), ca = $A($ZConvert(c,"L"))
		Set:(ca<$A("a")||(ca>$A("z")))&&(c'=+c) str = $Replace(str,c,"-")
	}
	
	// Remove all repeated hyphens
	Set str = $ZStrip(str,"=","-")
	
	// Setup
	Set strl = $ZConvert(str,"L")
	Set ret = ""
	
	// Iterate over the string
	For i=1:1:$Length(str) {
		
		// Get the current character + its lowercase form
		Set c = $Extract(str, i), lc = $Extract(strl, i)
		// Get the previous character + its lowercase form
		Set:i>1 pc = $Extract(str,i-1), pcl = $Extract(strl, i-1)
		// Get the next character + its lowercase form + its ASCII representation
		Set:i<$L(str) nc = $Extract(str,i+1), ncl = $Extract(strl,i+1), nca = $ASCII(nc)
		
		// Do not use a hyphen if the current character is lowercase
		Set d = c'=lc
		// Do not use a hyphen for the first character of the string under any condition
		// Example: $x
		Set d = d && (i>1)
		// Do not use a hyphen if both the previous character is NOT an uppercase alphabetic character AND the following character is a lowercase alphabetic character
		// Example: axb
		Set d = d && (pc=pcl||(i<$L(str)&&(nca>=$A("a")&&(nca<=$A("z")))))
		// Do not use a hyphen if the last written character was a hypen
		// Example: -xb
		Set d = d && ($E(ret,$L(ret))'="-")
		// Do not use a hyphen in cases like AppS, so it becomes "apps" instead of "app-s"
		// Example: aX?
		Set d = d && ('((c'=lc)&&(i=$L(str)||(($A(ncl)<$A("a")||($A(ncl)>$A("z")))&&(nc'=+nc)))&&(pc=pcl)))
		
		// Write the character (possibly preceeded by a hyphen)
		Set ret = ret _ $Select(d:"-",1:"") _ lc
	}
	
	// And return
	Return ret
}

/// Attempts to get EITHER a %DynamicObject OR a JSON-allowed primitive (ie. a String) from the given object
ClassMethod GetJSON(obj, type = "", mapping = "") [ Internal ]
{
	Set type = $Select(type="integer":"number",1:type)
	
	try {
		// Attempt #1: If the %ToJSON() method works, return obj as a %DynamicObject
		Return {}.%FromJSON(obj.%ToJSON())
	} catch (ex) {}
	
	try {
		// Attempt #2: If the object can be used as a JSON property (ie: a String), return it
		Set tmpobj = {}
		If type '= "" {
			Do tmpobj.%Set("a",obj,type)
		} Else {
			Do tmpobj.%Set("a",obj)
		}
		Set tmpobjJson = tmpobj.%ToJSON()
		Return obj
	} catch (ex) {}
	
	try {
		// Attempt #3: If the %JSONExportToString() method works, return obj as a %DynamicObject
		Do obj.%JSONExportToString(.str, mapping)
		Return {}.%FromJSON(str)
	} catch (ex) {}
	
	try {
		// Attempt #4: If the object's %JSONExportToString() return can be used as a JSON property (ie: a String), return it
		Set tmpobj = {}
		Do obj.%JSONExportToString(.str, mapping)
		If type '= "" {
			Do tmpobj.%Set("a",str,type)
		} Else {
			Do tmpobj.%Set("a",str)
		}
		Set tmpobjJson = tmpobj.%ToJSON()
		Return str
	} catch (ex) {}
	
	try {
		// Attempt #5: If the object is an Array, handle it!
		If $ClassName(obj) [ ".ArrayOf" {
			Set json = {}
			Set key = ""
			Set val = obj.GetNext(.key)
			While (key '= "") {
				If type '= "" {
					Do json.%Set(key, ..GetJSON(val, type, mapping), type)
				} Else {
					Do json.%Set(key, ..GetJSON(val,,mapping))
				}
				Set val = obj.GetNext(.key)
			}
			Return json
		}
	} catch (ex) { }
	
	try {
		// Attempt #6: If the object is a List, handle it!
		If $ClassName(obj) [ ".ListOf" {
			Set json = []
			For i=1:1:obj.Count() {
				If type '= "" {
					Do json.%Push(..GetJSON(obj.GetAt(i), type, mapping), type)
				} Else {
					Do json.%Push(..GetJSON(obj.GetAt(i),,mapping))
				}
			}
			Return json
		}
	} catch (ex) { }
	
	// Fail.
	Throw ##class(%Exception.General).%New("JSON Get Failed for """ _ obj _ """ with type """ _ type _ """ and mapping """ _ mapping _ """")
}

/// Attempts to get a JSON-style value from an object
ClassMethod FromJSON(a, type = "", mapping = "") [ Internal ]
{
	Set type = $Select(type="integer":"number",1:type)
	
	try {
		// Attempt #1: If the %ToJSON() method works, return a.%ToJSON()
		Return a.%ToJSON()
	} catch ex {}
	try {
		// Attempt #2: If the %JSONExportToString() method works, return a.%JSONExportToString()
		Do a.%JSONExportToString(.str, mapping)
		Return str
	} catch ex {}
	try {
		// Attempt #3: If the object is an Array, handle it!
		If $ClassName(a) [ ".ArrayOf" {
			Set str = "{"
			Set key = ""
			Set val = a.GetNext(.key)
			Set first = 1
			While (key '= "") {
				Set str = str _ $Select(first:"",1:",")
				Set first = 0
				If type '= "" {
					Set str = str _ """" _ key _ """:" _ ..FromJSON(val, type, mapping)
				} Else {
					Set str = str _ """" _ key _ """:" _ ..FromJSON(val,,mapping)
				}
				Set val = a.GetNext(.key)
			}
			Return str _ "}"
		}
	} catch (ex) {}
	try {
		// Attempt #4: If the object is a List, handle it!
		If $ClassName(a) [ ".ListOf" {
			Set str = "["
			For i=1:1:a.Count() {
				Set:i'=1 str = str _ ","
				If type '= "" {
					Set str = str _ ..FromJSON(a.GetAt(i), type, mapping)
				} Else {
					Set str = str _ ..FromJSON(a.GetAt(i),,mapping)
				}
			}
			Return str _ "]"
		}
	} catch (ex) {}
	try {
		// Attempt #5: If the object can be used as a JSON property (ie: a String), return that representation of it
		Set tmpobj = {}
		If type '= "" {
			Do tmpobj.%Set("a", a, type)
		} Else {
			Do tmpobj.%Set("a", a)
		}
		Return $Extract(tmpobj.%ToJSON(),6,*-1)
	} catch ex {}
	// Fail.
	Throw ##class(%Exception.General).%New("From JSON Failed for """ _ a _ """ with type """ _ type _ """ and mapping """ _ mapping _ """")
}

/// Parses a JSONMapping XData block
ClassMethod ParseJSONMapping(className As %String, mapName As %String, Output status As %Status)
{
	Set obj = ..ParseXData(className, mapName, "%JSON.Mapping", .status)
	Return:$System.Status.IsOK(status) obj
	Return ..ParseXData(className, mapName, "%pkg.isc.json.mapping", .status)
}

/// Parses an arbitrary XData block
ClassMethod ParseXData(className As %String, mapName As %String, desiredClass As %String, Output status As %Status)
{
	Try {
		// Setup
		Set xdata = ##class(%Dictionary.CompiledXData).%OpenId(className _ "||" _ mapName).Data
		Set reader = ##class(%XML.Reader).%New()
		Set obj = $ClassMethod(desiredClass, "%New")
		
		// Open the reader
		Do reader.CorrelateRoot(desiredClass)
		Set status = reader.OpenStream(xdata)
		Return:$System.Status.IsError(status) ""
		
		// Read the mapping
		Do reader.Next(.obj, .status)
		Do reader.Close()
		Return:$System.Status.IsError(status) ""
		
		// Validate + return
		Set status = obj.%ValidateObject()
		Return obj
		
	} Catch ex {
		Set status = ex.AsStatus()
		Return ""
	}
}

/// Gets the JSON Type of a class (make sure you check to see if this is being overwritten first if the class is being used as a property!)
ClassMethod GetJSONType(className As %String) As %String
{
	Set className = $$$CLASSNAME(className)
	Set jsonType = $Parameter(className, "JSONTYPE")
	Set:jsonType="" jsonType = $Parameter(className, "%JSONTYPE")
	If jsonType = "" {
		// Workaround for Cache
		Set xsdType = $Parameter(className, "XSDTYPE")
		If className = "%Library.Double" {
			Set jsonType = "double"
		} ElseIf $ClassMethod(className, "%Extends", "%Stream.Object") {
			// TODO: Support binary streams as NOT strings...
			Set jsonType = "string"
		} ElseIf (xsdType '= "") {
			Set jsonType = $Select(xsdType="long":"integer",xsdType="boolean":"boolean",$Match(xsdType,"decimal|double|short|byte"):"number",1:"string")
		} ElseIf ($$$comClassKeyGet(className,$$$cCLASSclasstype) = $$$cCLASSCLASSTYPEDATATYPE) {
			Set jsonType = "string"
		} Else {
			Set jsonType = "object"
		}
	}
	Set:className="%Library.DynamicArray" jsonType = "array"
	Return jsonType
}

/// Used in example generation
/// Returns Type,%JSONTYPE,%JSONREFERENCE,Name
ClassMethod FieldNameReverseLookup(stub As %pkg.isc.rest.openAPI.resourceInfoStub, fieldName As %String) As %DynamicObject [ Internal ]
{
	If stub.JSONMapping="" {
		Set classDef = ##class(%Dictionary.CompiledClass).%OpenId(stub.ClassName)
		For i=1:1:classDef.Properties.Count() {
			Set property = classDef.Properties.GetAt(i)
			If property.Parameters.GetAt("%JSONFIELDNAME") = fieldName {
				Set ret = {}
				Do ret.%Set("Type",property.Type)
				Do ret.%Set("Name",property.Name)
				Set jsonType = property.Parameters.GetAt("%JSONTYPE")
				Set:jsonType="" jsonType = ..GetJSONType(property.Type)
				Do ret.%Set("%JSONTYPE",jsonType)
				Do ret.%Set("%JSONREFERENCE",property.Parameters.GetAt("%JSONREFERENCE"))
				Return ret
			}
		}
	} Else {
		Set mapping = ..ParseJSONMapping(stub.ClassName, stub.JSONMapping, .sc)
		Return:$System.Status.IsError(sc) ""
		For i=1:1:mapping.propertyList.Count() {
			Set property = mapping.propertyList.GetAt(i)
			#Dim property As %pkg.isc.json.mappingProperty
			If property.FieldName = fieldName {
				Set ret = {}
				Set propertyDef = ##class(%Dictionary.CompiledProperty).%OpenId(stub.ClassName_"||"_property.Name)
				Do ret.%Set("Type",propertyDef.Type)
				Do ret.%Set("Name",property.Name)
				Set jsonType = propertyDef.Parameters.GetAt("%JSONTYPE")
				Set:jsonType="" jsonType = ..GetJSONType(propertyDef.Type)
				Do ret.%Set("%JSONTYPE",jsonType)
				Do ret.%Set("%JSONREFERENCE",property.Reference)
				Return ret
			}
		}
	}
	Return ""
}

/// Attempts to fix save errors that might happen on a generated object by instantiating missing required properties
ClassMethod AttemptToMakeObjectSaveable(ByRef obj, propertyToNotTouch) [ Internal ]
{
	Set properties = ##class(%Dictionary.CompiledClass).%OpenId($ClassName(obj)).Properties
	For i=1:1:properties.Count() {
		Set property = properties.GetAt(i)
		Continue:'property.Required
		If $Property(obj,property.Name)="" && (property.Name '= propertyToNotTouch) {
			Try { Set $Property(obj,property.Name) = $ClassMethod(property.Type,"%New") } catch (ex) {}
		}
	}
}

/// Utility method to get the "write" output of a ClassMethod
/// Uses %pkg.isc.json.util.buffer
ClassMethod ReadClassMethodOutput(className, methodName) As %String [ Internal ]
{
	Set buffer = ##class(%pkg.isc.json.util.buffer).%New()
	Try {
		Set str=""
		$$$ThrowOnError(buffer.BeginCaptureOutput())
		Do $ClassMethod(className, methodName)
		$$$ThrowOnError(buffer.EndCaptureOutput(.str))
	} Catch ex {
		Set str = ""
	}
	Return str
}

}
