/// Model Super-class, provides utility/verification methods
Class %pkg.isc.rest.openAPI.model.super Extends (%Persistent, %pkg.isc.rest.openAPI.customizableJSONAdaptor) [ DependsOn = %pkg.isc.rest.openAPI.model.superUtils ]
{

/// Structure:
/// RefMap(0,<internal path>)=<oref>
/// RefMap(1,<oref>)=<internal path>
Property RefMap(%JSONINCLUDE = "none") [ Internal, MultiDimensional, Transient ];

Parameter %JSONINCLUDEID = 0;

Parameter DEFAULTGLOBAL As STRING = "^pkg.isc.rest.oas.model.super";

/// @Override: Whether or not this object allows extended properties
Method AllowsExtendedProperties() As %Boolean
{
	Return 0
}

/// Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, debug = 0) As %Boolean
{
	Return 1
}

/// Report a validation failure
Method OnFail(fullSpecification, debug, description, property = "")
{
	If property '= "" {
		Set properties = ##class(%Dictionary.CompiledClass).%OpenId($ClassName($This)).Properties
		Set property = properties.GetAt(properties.FindObjectId($ClassName($This)_"||"_property)).Parameters.GetAt("%JSONFIELDNAME")
	}
	Write:debug *27,"[54mFail:",*27,"[0m " _ description _ " ",*27,"[59m[" _ ..GetReference(fullSpecification, $This)  _ $Select(property'="":"/" _ property,1:"")_"]",*27,"[0m", !
}

Method GenerateRefKeys() [ CodeMode = objectgenerator, Internal ]
{
	#define GENERATE(%line) Do %code.WriteLine(" "_%line)
	$$$GENERATE("#define SetRefMap(%object,%key) Set i%RefMap(0,%key) = %object Set:+%object i%RefMap(1,%object) = %key")
	$$$GENERATE("#define MergeRefMap(%source,%prefix) Do %source.GenerateRefKeys() Set mergeKey = """" For { Set mergeKey = $Order(%source.RefMap(0,mergeKey),1,val) Quit:mergeKey=""""  $$$SetRefMap(val,%prefix_mergeKey) }")
	$$$GENERATE("Kill i%RefMap")
	Set properties = %compiledclass.Properties
	For i=1:1:properties.Count() {
		Set property = properties.GetAt(i)
		If ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends(property.Type, "%pkg.isc.rest.openAPI.model.super") {
			Continue:property.Parameters.GetAt("%JSONINCLUDE")="none"
			Set propertyJSONName = $c(0) _ property.Parameters.GetAt("%JSONFIELDNAME")
			If propertyJSONName=$c(0) {
				Continue:property.Name'="Data"
				Set propertyJSONName = $c(1)
			}
			$$$GENERATE("Set object = .."_property.Name)
			$$$GENERATE("Set propertyJSONName = "_$$Quote^%qcr(propertyJSONName))
			$$$GENERATE("If $IsObject(object) {")
			If property.RuntimeType [ ".ListOfObj" {
				$$$GENERATE("For j=1:1:object.Count() {")
				$$$GENERATE("	Set objj = object.GetAt(j)")
				$$$GENERATE("	$$$SetRefMap(objj, propertyJSONName _ $c(0) _ (j-1))")
				$$$GENERATE("	$$$MergeRefMap(objj, propertyJSONName _ $c(0) _ (j-1))")
				$$$GENERATE("}")
			} ElseIf property.RuntimeType [ ".ArrayOfObj" {
				$$$GENERATE("Set key = """"")
				$$$GENERATE("Set value = object.GetNext(.key)")
				$$$GENERATE("While key'="""" {")
				$$$GENERATE("	$$$SetRefMap(value, propertyJSONName _ $c(0) _ key)")
				$$$GENERATE("	$$$MergeRefMap(value, propertyJSONName _ $c(0) _ key)")
				$$$GENERATE("	Set value = object.GetNext(.key)")
				$$$GENERATE("}")
			} Else {
				$$$GENERATE("$$$SetRefMap(object, propertyJSONName)")
				$$$GENERATE("$$$MergeRefMap(object, propertyJSONName)")
			}
			$$$GENERATE("}")
		}
	}
}

ClassMethod DeleteExtent() [ Final ]
{
	If $ClassName() '= "%pkg.isc.rest.openAPI.model.super" {
		Write "Will not run DeleteExtent() from this class, call it on %pkg.isc.rest.openAPI.model.super to delete all model class extents.",!
		Return
	}
	Set classes = ##class(%SQL.Statement).%ExecDirect(, "select Name,ID from %Dictionary.CompiledClass where Name %MATCHES 'isc\.rest\.openAPI\.model\.*'")
	While classes.%Next() {
		Try {
			Do $ClassMethod(classes.Name,"%DeleteExtent")
		} Catch {}
	}
}

ClassMethod KillExtent() [ Final ]
{
	If $ClassName() '= "%pkg.isc.rest.openAPI.model.super" {
		Write "Will not run DeleteExtent() from this class, call it on %pkg.isc.rest.openAPI.model.super to delete all model class extents.",!
		Return
	}
	Set classes = ##class(%SQL.Statement).%ExecDirect(, "select Name,ID from %Dictionary.CompiledClass where Name %MATCHES 'isc\.rest\.documentation\.openAPI\.model\.*'")
	While classes.%Next() {
		Try {
			Do $ClassMethod(classes.Name,"%DeleteExtent")
		} Catch {}
	}
}

Method Delete() As %Status [ CodeMode = objectgenerator ]
{
	Set properties = %compiledclass.Properties
	For i=1:1:properties.Count() {
		Set property = properties.GetAt(i)
		If ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends(property.Type, "%pkg.isc.rest.openAPI.model.super") {
			Do %code.WriteLine(" Set object = .."_property.Name)
			Do %code.WriteLine(" If $IsObject(object) {")
			If property.RuntimeType [ ".ListOfObj" {
				Do %code.WriteLine(" For j=1:1:object.Count() {")
				Do %code.WriteLine(" 	Set objj = object.GetAt(j)")
				Do %code.WriteLine(" 	If $IsObject(objj) {")
				Do %code.WriteLine(" 		Set sc = objj.Delete()")
				Do %code.WriteLine(" 		Return:$system.Status.IsError(sc) sc")
				Do %code.WriteLine(" 	}")
				Do %code.WriteLine(" }")
			} ElseIf property.RuntimeType [ ".ArrayOfObj" {
				Do %code.WriteLine(" Set key = """"")
				Do %code.WriteLine(" Set value = object.GetNext(.key)")
				Do %code.WriteLine(" While key'="""" {")
				Do %code.WriteLine(" 	If $IsObject(value) {")
				Do %code.WriteLine(" 		Set sc = value.Delete()")
				Do %code.WriteLine(" 		Return:$system.Status.IsError(sc) sc")
				Do %code.WriteLine(" 	}")
				Do %code.WriteLine(" 	Set value = object.GetNext(.key)")
				Do %code.WriteLine(" }")
			} Else {
				Do %code.WriteLine(" Set sc = object.Delete()")
				Do %code.WriteLine(" Return:$system.Status.IsError(sc) sc")
			}
			Do %code.WriteLine(" }")
		}
	}
	Do %code.WriteLine(" If ..%Id()'="""" {")
	Do %code.WriteLine(" 	Set sc = ..%DeleteId(..%Id())")
	Do %code.WriteLine(" 	Return sc")
	Do %code.WriteLine(" }")
	Return $$$OK
}

Method GetSaveableInstance(expect = "") As %pkg.isc.rest.openAPI.model.super [ CodeMode = objectgenerator ]
{
	#define GENERATE(%line) Do %code.WriteLine($c(9)_%line)
	$$$GENERATE("Set clone = ..%ConstructClone()")
	Set properties = %compiledclass.Properties
	For i=1:1:properties.Count() {
		Set property = properties.GetAt(i)
		If (property.Name = "%%OID") {
		} ElseIf property.Transient {
			$$$GENERATE("Set clone."_property.Name_"= """"")
		} ElseIf ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends(property.Type, "%pkg.isc.rest.openAPI.model.super") {
			$$$GENERATE("Set propExpect = ##class("_property.Type_").#EXPECT")
			$$$GENERATE("Set object = clone."_property.Name)
			$$$GENERATE("If $IsObject(object) {")
			$$$GENERATE("Set object = object.%ConstructClone()")
			If property.RuntimeType [ ".ListOfObj" {
				$$$GENERATE("For j=1:1:object.Count() {")
				$$$GENERATE("	Set objj = object.GetAt(j)")
				$$$GENERATE("	If $IsObject(objj) {")
				$$$GENERATE("		Do object.SetAt(objj.GetSaveableInstance(propExpect), j)")
				$$$GENERATE("	}")
				$$$GENERATE("}")
			} ElseIf property.RuntimeType [ ".ArrayOfObj" {
				$$$GENERATE("Set key = """"")
				$$$GENERATE("Set value = object.GetNext(.key)")
				$$$GENERATE("While key'="""" {")
				$$$GENERATE("	If $IsObject(value) {")
				$$$GENERATE("		Do object.SetAt(value.GetSaveableInstance(propExpect), key)")
				$$$GENERATE("	}")
				$$$GENERATE("	Set value = object.GetNext(.key)")
				$$$GENERATE("}")
			} Else {
				$$$GENERATE("Set object = object.GetSaveableInstance(propExpect)")
			}
			$$$GENERATE("Set clone."_property.Name_" = object")
			$$$GENERATE("}")
		}
	}
	$$$GENERATE("Return clone")
}

Method GetUnsaveableInstance() As %pkg.isc.rest.openAPI.model.super
{
	// TODO: Implement this!
	Return ""
}

/// @Special: Override the JSONExport behavior defined by %pkg.isc.json, in order to return a JSON representation of
///           ..? or ..Reference instead of this object, for instances of ?OrReference classes
Method JSONExportOverride(write As %Boolean) As %Status
{
	// Figure out if we need to run the override at all
	Set expect = $Parameter($This, "EXPECT")
	Throw:expect="" 0
	Set subclass = ##class(%Dictionary.CompiledParameter).%OpenId($ClassName($This)_"||EXPECT").Origin'=$ClassName($This)
	Throw:subclass 0
	// Box the ? / Ref in a GenericObject to avoid needing to duplicate JSON Export logic here
	Set obj = $Property($This, expect)
	Set:'$IsObject(obj) obj = $Property($This, "Reference")
	Set:'$IsObject(obj) obj = ##class(%pkg.isc.rest.openAPI.model.emptyObject).%New()
	Set boxedObj = ##class(%pkg.isc.rest.openAPI.model.genericObject).%New()
	Set boxedObj.Data = obj
	Return boxedObj.JSONExportOverride(write)
}

/// Gets a reference string for the super object within the specified OpenAPI specification (returns the input string on failure)
ClassMethod GetReference(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, super As %pkg.isc.rest.openAPI.model.super, internal = 0) As %String
{
	Quit:super=fullSpecification "#"
	If $Data(fullSpecification.RefMap(1,super),key)#2 {
		Return:internal "#" _ key
		Return "#"_$Translate(key, $c(0,1), "/")
	}
	Return super
}

/// Resolves a reference string to an object within the specified OpenAPI specification (returns the empty-string on failure)
Method ResolveReference(reference As %String, fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, internal = 0) As %pkg.isc.rest.openAPI.model.super
{
	If internal {
		Return $Get(fullSpecification.RefMap(0,$Extract(reference,2,*)))
	}
	Set path = $ListFromString(reference,"/")
	Return:$ListLength(path)<2 ""
	Set key=""
	For {
		Set key = $order(fullSpecification.RefMap(0,key),1,obj)
		Quit:key=""
		Return:$Translate(key,$c(0,1),"/")=$Extract(reference,2,*) obj
	}
	Return ""
}

/// Returns true if the current object is a reference.
Method IsReference() As %Boolean
{
	return ..%Extends("%pkg.isc.rest.openAPI.model.reference")
}

/// Gets the objct containing $This within the specified OpenAPI specification
Method GetContainingObject(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI) As %pkg.isc.rest.openAPI.model.super
{
	Set reference = ..GetReference(fullSpecification, $This, 1)
	Set superRef = $Piece(reference,$c(0),1,*-1)
	If $Extract(superRef,*)=$c(1) {
		Set superRef = $Piece(superRef,$c(0),1,*-1)
	}
	Return ..ResolveReference(superRef, fullSpecification, 1)
}

/// Gets the defined (property) type of $This within the specified OpenAPI specification
Method GetDefinedType(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI)
{
	Set super = ..GetContainingObject(fullSpecification)
	Return:'$IsObject(super) ""
	If '$ClassMethod($ClassName(super), "%Extends", "%pkg.isc.rest.openAPI.model.super") {
		Set super = ..ResolveReference($Piece(..GetReference(fullSpecification, $This),"/",1,*-2), fullSpecification)
		Set:'$IsObject(super) super = fullSpecification
	}
	Set properties = ##class(%Dictionary.CompiledClass).%OpenId($ClassName(super)).Properties
	For i=1:1:properties.Count() {
		Set property = properties.GetAt(i)
		If $ClassMethod(property.Type, "%Extends", "%pkg.isc.rest.openAPI.model.super") {
			Try {
				Set object = $Property(super, property.Name)
				Quit:$Parameter(object,"%JSONINCLUDE")="none"
				If property.RuntimeType [ ".ListOfObj" {
					For j=1:1:object.Count() {
						Return:object.GetAt(j)=$This property.Type
					}
				} ElseIf property.RuntimeType [ ".ArrayOfObj" {
					Set key = ""
					Set value = object.GetNext(.key)
					While key'="" {
						Return:value=$This property.Type
						Set value = object.GetNext(.key)
					}
				} Else {
					Return:object=$This property.Type
				}
			} Catch {}
		}
	}
	Return ""
}

Method GetAll(className As %String) As %ListOfObjects [ CodeMode = objectgenerator, ForceGenerate, Internal ]
{
	Do %code.WriteLine("	Set ret = ##class(%ListOfObjects).%New()")
	Set properties = %compiledclass.Properties
	set searchList = $listbuild("schema","reference","schemaOrReference","")
	For j=1:1:$ListLength(searchList) {
		Set optimizedName = $ListGet(searchList, j)
		If optimizedName="" {
			Set optimizedName = "className"
			Set isOptimized = 0
		} Else {
			Set optimizedName = """%pkg.isc.rest.openAPI.model." _ optimizedName _ """"
			Set isOptimized = 1
		}
		If isOptimized {
			Do %code.WriteLine("	If className = " _ optimizedName _ " {")
		} Else {
			Do %code.WriteLine("	Else {")
		}
		For i=1:1:properties.Count() {
			Set optimizedMatch = -1
			Set property = properties.GetAt(i)
			If ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends(property.Type, "%pkg.isc.rest.openAPI.model.super") && (property.Parameters.GetAt("%JSONINCLUDE") '= "none") {
				Do %code.WriteLine("	Set object = .." _ property.Name)
				If 'isOptimized {
					Do %code.WriteLine("	Set classMatches = (""" _ property.Type _ """ = className) || ($IsObject(object) && object.%Extends(className))")
				} Else {
					If ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends(property.Type, $Extract(optimizedName,2,*-1)) {
						Set optimizedMatch = 1
					} ElseIf ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends($Extract(optimizedName,2,*-1), property.Type) {
						Do %code.WriteLine("	Set classMatches = ($IsObject(object) && object.%Extends(className))")
					} Else {
						Set optimizedMatch = 0
					}
				}
				If property.RuntimeType [ ".ListOfObj" {
					Do %code.WriteLine("	For j=1:1:object.Count() {")
					Do %code.WriteLine("		Set item = object.GetAt(j)")
					If optimizedMatch '= 0 {
						If optimizedMatch = -1 {
							Do %code.WriteLine("		Set itemMatches = ($IsObject(item) && item.%Extends(className))")
							Do %code.WriteLine("		Do:itemMatches ret.Insert(item)")
						} Else {
							Do %code.WriteLine("		Do:item'="""" ret.Insert(item)")
						}
					}
					Do %code.WriteLine("		If $IsObject(item) && item.%Extends(""%pkg.isc.rest.openAPI.model.super"") {")
					Do %code.WriteLine("			Set otherlist = item.GetAll(className)")
					Do %code.WriteLine("			For k=1:1:otherlist.Count() {")
					Do %code.WriteLine("				Set otherObj = otherlist.GetAt(k)")
					Do %code.WriteLine("				Do:$IsObject(otherObj) ret.Insert(otherObj)")
					Do %code.WriteLine("			}")
					Do %code.WriteLine("		}")
					Do %code.WriteLine("	}")
				} ElseIf property.RuntimeType [ ".ArrayOfObj" {
					Do %code.WriteLine("	Set key = """"")
					Do %code.WriteLine("	Set value = object.GetNext(.key)")
					Do %code.WriteLine("	While key'="""" {")
					If optimizedMatch '= 0 {
						If optimizedMatch = -1 {
							Do %code.WriteLine("		Set itemMatches = ($IsObject(value) && value.%Extends(className))")
							Do %code.WriteLine("		Do:itemMatches ret.Insert(value)")
						} Else {
							Do %code.WriteLine("		Do:value'="""" ret.Insert(value)")
						}
					}
					Do %code.WriteLine("		If $IsObject(value) && value.%Extends(""%pkg.isc.rest.openAPI.model.super"") {")
					Do %code.WriteLine("			Set otherlist = value.GetAll(className)")
					Do %code.WriteLine("			For k=1:1:otherlist.Count() {")
					Do %code.WriteLine("				Set otherObj = otherlist.GetAt(k)")
					Do %code.WriteLine("				Do ret.Insert(otherObj)")
					Do %code.WriteLine("			}")
					Do %code.WriteLine("		}")
					Do %code.WriteLine("		Set value = object.GetNext(.key)")
					Do %code.WriteLine("	}")
				} Else {
					If 'isOptimized {
						Do %code.WriteLine("	Do:object'=""""&&classMatches ret.Insert(object)")
					} ElseIf optimizedMatch = 1 {
						Do %code.WriteLine("	Do:object'="""" ret.Insert(object)")
					}
					Do %code.WriteLine("	If $IsObject(object) && object.%Extends(""%pkg.isc.rest.openAPI.model.super"") {")
					Do %code.WriteLine("		Set otherlist = object.GetAll(className)")
					Do %code.WriteLine("		For k=1:1:otherlist.Count() {")
					Do %code.WriteLine("			Set otherObj = otherlist.GetAt(k)")
					Do %code.WriteLine("			Do ret.Insert(otherObj)")
					Do %code.WriteLine("		}")
					Do %code.WriteLine("	}")
				}
			}
		}
		Do %code.WriteLine("	}")
	}
	Do %code.WriteLine("	Quit ret")
}

/// Returns a list of all instances of the given class found within the specified OpenAPI specification
ClassMethod GetAllFromSpec(super As %pkg.isc.rest.openAPI.model.super, className) As %ListOfObjects
{
	Return super.GetAll(className)
}

/// Validates a component within a specified OpenAPI specification (override ..Validate() in place of this in sub-classes!)
Method ValidateComponent(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, debug = 0) As %Boolean
{
	Set objectValid = ..%ValidateObject()
	Set componentsValid = ..ValidateComponents(fullSpecification, debug)
	Set extraValidation = ..Validate(fullSpecification, debug)
	Do:'objectValid ..OnFail(fullSpecification, debug, $System.Status.GetErrorText(objectValid))
	Return objectValid && extraValidation && componentsValid
}

/// Validates the sub-components of this object
Method ValidateComponents(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, debug = 0) [ CodeMode = objectgenerator ]
{
	#define GENERATE(%line) Do %code.WriteLine($c(9)_%line)
	$$$GENERATE("Set validMaster = 1")
	Set properties = %compiledclass.Properties
	For i=1:1:properties.Count() {
		Set property = properties.GetAt(i)
		Continue:property.Parameters.GetAt("%JSONINCLUDE")="none"
		If ##class(%pkg.isc.rest.openAPI.model.superUtils).Extends(property.Type, "%pkg.isc.rest.openAPI.model.super") {
			$$$GENERATE("Try {")
			$$$GENERATE("	Set object = .."_property.Name)
			$$$GENERATE("	Quit:'$IsObject(object)")
			If property.RuntimeType [ ".ListOfObj" {
				$$$GENERATE("		For j=1:1:object.Count() {")
				$$$GENERATE("			If '$ClassMethod($ClassName(object.GetAt(j)), ""%Extends"", "_$$$QUOTE(property.Type)_") {")
				$$$GENERATE("				Set validMaster = 0")
				$$$GENERATE("				Do ..OnFail(fullSpecification, debug, ""Object type ("" _ $ClassName(object.GetAt(j)) _ "") at index ("" _ j _ "") is not a(n) "_property.Type_""","_ $$$QUOTE(property.Name)_")")
				$$$GENERATE("				Return:'debug 0")
				$$$GENERATE("				Continue")
				$$$GENERATE("			}")
				$$$GENERATE("			Set valid = $Method(object.GetAt(j), ""ValidateComponent"", fullSpecification, debug)")
				$$$GENERATE("			If 'valid {")
				$$$GENERATE("				Set validMaster = 0")
				$$$GENERATE("				Return:'debug 0")
				$$$GENERATE("			} Else {")
				$$$GENERATE("				Write:(debug=1)&&($ClassName(object.GetAt(j))'=""%pkg.isc.rest.openAPI.model.genericObject"") ..GetReference(fullSpecification, object.GetAt(j)) _ "" is valid..."",!")
				$$$GENERATE("			}")
				$$$GENERATE("		}")
			} ElseIf property.RuntimeType [ ".ArrayOfObj" {
				$$$GENERATE("		Set key = """"")
				$$$GENERATE("		Set value = object.GetNext(.key)")
				$$$GENERATE("		While key'="""" {")
				$$$GENERATE("			If '$ClassMethod($ClassName(value), ""%Extends"", "_$$$QUOTE(property.Type)_") {")
				$$$GENERATE("				Set validMaster = 0")
				$$$GENERATE("				Do ..OnFail(fullSpecification, debug, ""Object type ("" _ $ClassName(value) _ "") at key ("" _ key _ "") is not a(n) " _ property.Type_ ""","_$$$QUOTE(property.Name)_")")
				$$$GENERATE("				Return:'debug 0")
				$$$GENERATE("				Set value = object.GetNext(.key)")
				$$$GENERATE("				Continue")
				$$$GENERATE("			}")
				$$$GENERATE("			Set valid = $Method(value, ""ValidateComponent"", fullSpecification, debug)")
				$$$GENERATE("			If 'valid {")
				$$$GENERATE("				Set validMaster = 0")
				$$$GENERATE("				Return:'debug 0")
				$$$GENERATE("			} Else {")
				$$$GENERATE("				Write:(debug=1)&&($ClassName(value)'=""%pkg.isc.rest.openAPI.model.genericObject"") ..GetReference(fullSpecification, value) _ "" is valid..."",!")
				$$$GENERATE("			}")
				$$$GENERATE("			Set value = object.GetNext(.key)")
				$$$GENERATE("		}")
			} Else {
				$$$GENERATE("		If '$ClassMethod($ClassName(object), ""%Extends"", "_$$$QUOTE(property.Type)_") {")
				$$$GENERATE("			Set validMaster = 0")
				$$$GENERATE("			Do ..OnFail(fullSpecification, debug, ""Object type ("" _ $ClassName(object) _ "") is not a(n) " _ property.Type _ ""","_$$$QUOTE(property.Name)_")")
				$$$GENERATE("			Return:'debug 0")
				$$$GENERATE("			Quit")
				$$$GENERATE("		}")
				$$$GENERATE("		Set valid = $Method(object, ""ValidateComponent"", fullSpecification, debug)")
				$$$GENERATE("		If 'valid {")
				$$$GENERATE("			Set validMaster = 0")
				$$$GENERATE("			Return:'debug 0")
				$$$GENERATE("		} Else {")
				$$$GENERATE("			Write:(debug=1)&&($ClassName(object)'=""%pkg.isc.rest.openAPI.model.genericObject"") ..GetReference(fullSpecification, object) _ "" is valid..."",!")
				$$$GENERATE("		}")
			}
			$$$GENERATE("} Catch ex {")
			$$$GENERATE("	Set message = $System.Status.GetErrorText(ex.AsStatus())")
			$$$GENERATE("	Do ..OnFail(fullSpecification, debug, message, "_$$$QUOTE(property.Name)_")")
			$$$GENERATE("	Return 0")
			$$$GENERATE("}")
		}
	}
	$$$GENERATE("Return validMaster")
}

Storage Default
{
<Data name="superDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^pkg.isc.rest.oas.model.superD</DataLocation>
<DefaultData>superDefaultData</DefaultData>
<IdLocation>^pkg.isc.rest.oas.model.superD</IdLocation>
<IndexLocation>^pkg.isc.rest.oas.model.superI</IndexLocation>
<StreamLocation>^pkg.isc.rest.oas.model.superS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

