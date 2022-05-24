Class %pkg.isc.rest.openAPI.example
{

/// Get an example (in JSON form) of the propertyName property from the className class
/// TODO: Document the optional GetExampleInstance() ClassMethod for resources somewhere
ClassMethod GetPropertyExample(className, propertyName, propertyType, ByRef jsonOutputObj = "", reference = "") [ Internal ]
{
	// Setup
	Set reference = $ZConvert(reference,"U")
	Set referenceMethod = $Select(reference="ID":"%Id",reference="OID":"%Oid",reference="GUID":"%GUID",1:"")
	Set exampleProp = ""
	TStart
	Set buffer = ##class(%pkg.isc.json.util.buffer).%New()
	Do buffer.BeginCaptureOutput()
	// There are a number of ways to generate an example, try them one-by-one, returning the first one that works
	For attempt=1:1:8 {
		Set sc = $$$OK
		Set objs = 1
		Try {
			If attempt = 1 {
				// Attempt #1: If the class provides a method called GetExampleInstance(), use it!
				Set exampleProp = $Property($ClassMethod(className, "GetExampleInstance"), propertyName)
				Do:$IsObject(exampleProp) ##class(%pkg.isc.rest.openAPI.util).AttemptToMakeObjectSaveable(.exampleProp, propertyName)
				Do:$IsObject(exampleProp) exampleProp.%Save()
			} ElseIf attempt = 2 {
				// Attempt #2: Populate the containing class, then get the property in question
				Do $ClassMethod(className, "Populate", 1, , , .objs, , 1)
				Set obj = objs(1)
				Do:$IsObject(obj) ##class(%pkg.isc.rest.openAPI.util).AttemptToMakeObjectSaveable(.obj, propertyName)
				Set:$IsObject(obj) sc = obj.%Save()
				Set exampleProp = $Property(obj, propertyName)
			} ElseIf attempt = 3 {
				// Attempt #3: If the property's type class provices a method called GetExampleInstance(), use it!
				Set exampleProp = $ClassMethod(propertyType, "GetExampleInstance")
				Do:$IsObject(exampleProp) exampleProp.%Save()
			} ElseIf attempt = 4 {
				// Attempt #4: Populate an instance of the property's type class, then use that
				Do $ClassMethod(propertyType, "Populate", 1, , , .objs, , 1)
				Set:$IsObject(objs(1)) sc = objs(1).%Save()
				Set exampleProp = objs(1)
			} ElseIf attempt = 5 {
				// Attempt #5: Use the GetModelInstance() method to get an instance of the containing class, then get the property in question
				Set exampleProp = $Property($ClassMethod(className, "GetModelInstance"), propertyName)
				Set:$IsObject(exampleProp) sc = exampleProp.%Save()
			} ElseIf attempt = 6 {
				// Attempt #6: Use the GetModelInstance() method to get an instance of the property's type class, then use that
				Set exampleProp = $ClassMethod(propertyType, "GetModelInstance")
				Set:$IsObject(exampleProp) sc = exampleProp.%Save()
			} ElseIf attempt = 7 {
				// Attempt #7: Create a new instance of the containing class, then get the property in question
				Set exampleProp = $Property($ClassMethod(className, "%New"), propertyName)
				Set:$IsObject(exampleProp) sc = exampleProp.%Save()
			} ElseIf attempt = 8 {
				// Attempt #8: Create a new instance of the property's type class, then use that
				Set exampleProp = $ClassMethod(propertyType, "%New")
				Set:$IsObject(exampleProp) sc = exampleProp.%Save()
			}
			// Attempt to get the example in the proper form, and return it so long as that was possible
			Try {
				$$$ThrowOnError(sc)
				Set:reference'="" exampleProp = $Method(exampleProp, referenceMethod)
				Set examplePropJson = ##class(%pkg.isc.rest.openAPI.util).GetJSON(exampleProp)
				Set:$IsObject(jsonOutputObj) jsonOutputObj.Example = examplePropJson
				Do buffer.EndCaptureOutput()
				Trollback 1
				Return examplePropJson
			} Catch ex2 {}
		} Catch ex {}
	}
	// Fail.
	Do buffer.EndCaptureOutput()
	Trollback 1
	Return ""
}

/// Attempts to get an example JSON object for the specified schema
ClassMethod GetSchemaExample(openAPIresourceSchema As %pkg.isc.rest.openAPI.model.schemaOrReference, openapi As %pkg.isc.rest.openAPI = "") As %pkg.isc.rest.openAPI.model.genericObject [ Internal ]
{
	// TODO: It would be nice to use a single instance of the object in question if possible, but falling-back to the current behavior is OK
	Set ret = ""
	Try {
		Try {
			Return:$IsObject(openAPIresourceSchema.Example) openAPIresourceSchema.Example
		} Catch {}
		If ($IsObject(openAPIresourceSchema) && openAPIresourceSchema.IsReference()) {
			Set openAPIresourceSchema = openAPIresourceSchema.ResolveReference(openAPIresourceSchema.Ref, openapi.Specification)
		}
		If openAPIresourceSchema.Type = "object" {
			Set ret = ##class(%pkg.isc.rest.openAPI.model.genericObject).From({})
			Set propertyName = "", propertyInfo = openAPIresourceSchema.Properties.GetNext(.propertyName)
			While propertyName '= "" {
				Set propertyExample = ""
				If $IsObject(openAPIresourceSchema.SourceStub) {
					Set properties = ##class(%Dictionary.CompiledClass).%OpenId(openAPIresourceSchema.SourceStub.ClassName).Properties
					Set propertyParams = ##class(%pkg.isc.rest.openAPI.util).FieldNameReverseLookup(openAPIresourceSchema.SourceStub, propertyName)
					If $IsObject(propertyParams) {
						If ($IsObject(propertyInfo) && propertyInfo.IsReference()) {
							Set propertyInfo = propertyInfo.ResolveReference(propertyInfo.Ref, openapi.Specification)
						}
						Set propertyExample = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(..GetPropertyExample(openAPIresourceSchema.SourceStub.ClassName, propertyParams.Name, propertyParams.Type,, propertyParams.%JSONREFERENCE), propertyParams.%JSONTYPE)
						Do propertyExample.%JSONExport()
					}
				} Else {
					Set propertyExample = ..GetSchemaExample(propertyInfo, openapi)
				}
				If $IsObject(propertyExample) {
					If propertyExample.JSONType = "" {
						Do ret.Data.%Set(propertyName, propertyExample.Data)
					} Else {
						Do ret.Data.%Set(propertyName, propertyExample.Data, propertyExample.JSONType)
					}
				}
				Set propertyInfo = openAPIresourceSchema.Properties.GetNext(.propertyName)
			}
		} ElseIf openAPIresourceSchema.Type = "array" {
			Set ret = ##class(%pkg.isc.rest.openAPI.model.genericObject).From([])
			Set items = openAPIresourceSchema.Items
			If ($IsObject(items) && items.IsReference()) {
				Set items = items.ResolveReference(items.Ref, openapi.Specification)
			}
			Set itemsExample = ..GetSchemaExample(items, openapi)
			Do:$IsObject(itemsExample) ret.Data.%Push(itemsExample.Data)
		} ElseIf $IsObject(openAPIresourceSchema.SourceStub) {
			Set ret = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(..GetPropertyExample(,, openAPIresourceSchema.SourceStub.ClassName,, openAPIresourceSchema.SourceStub.Reference), ##class(%pkg.isc.rest.openAPI.util).GetJSONType(openAPIresourceSchema.SourceStub.ClassName))
		}
	} Catch ex {}
	Return ret
}

}

