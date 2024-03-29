Include %pkg.isc.rest.general

Class %pkg.isc.rest.openAPI.schema
{

/// Gets an OpenAPI-format schema from the given className (does *NOT* generate object schemas, just points to their references and adds them to neededClasses to be generated later if need-be)
ClassMethod GetSchema(stub As %pkg.isc.rest.openAPI.resourceInfoStub, jsonType = "", direction, ByRef neededClasses, openapi, autogenerated = 0) As %pkg.isc.rest.openAPI.model.schemaOrReference [ Internal ]
{
	Set className = $$$CLASSNAME(stub.ClassName)
	Set ret = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set:jsonType=""&&(stub.ResourceName'="") jsonType = stub.JSONType
	Set:jsonType="" jsonType = "object"
	Set ret.Type = jsonType
	If jsonType = "object" {
		If className'="" {
			Set ret = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
			Set ret.Ref = "#/components/schemas/" _ openapi.GetNiceName(stub) _ "_" _ direction
			Do:$Data(neededClasses) neededClasses.Insert(stub)
		}
	} ElseIf jsonType = "array" {
		Set ret.Items = ..GetSchema(stub, , direction, .neededClasses, openapi, autogenerated)
	}
	Set ret.AutoGenerated = autogenerated
	Return ret
}

ClassMethod GenerateSchemaFromSQL(sqlQueryString As %String, openapi As %pkg.isc.rest.openAPI, autogenerated = 0) As %pkg.isc.rest.openAPI.model.schema [ Internal ]
{
	// Get a schema for the query's result type(s)
	Set querySchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set querySchema.AutoGenerated = autogenerated
	Set querySchema.Type = "array"
	Set querySchema.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set querySchema.Items.AutoGenerated = autogenerated
	Set querySchema.Items.Type = "object"
	Set statement = ##class(%SQL.Statement).%New()
	$$$ThrowOnError(statement.%Prepare(sqlQueryString))
	Set statementColumns = statement.%Metadata.columns
	For k=1:1:statementColumns.Count() {
		Set column = statementColumns.GetAt(k)
		Set resultColumnName = column.label
		Set resultColumnClass = column.typeClass.Name
		Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(resultColumnClass, $Parameter(resultColumnClass,"%JSONMAPPING"))
		Do stub.PopulateNonOverwrittenValues()
		Do querySchema.Items.Properties.SetAt(..GetSchema(stub,,"output",openapi.NeededClasses,openapi,autogenerated), resultColumnName)
	}
	Return querySchema
}

/// Returns an OpenAPI-format schema representing the JSON value written by a given ClassMethod *ONLY* if it is NOT as-defined in %pkg.isc.rest.model.dbMappedResource
ClassMethod GenerateSchemaIfOverwritten(className, methodName, autogenerated = 0) As %pkg.isc.rest.openAPI.model.schema [ Internal ]
{
	Try {
		Set className = $$$CLASSNAME(className)
		If ##class(%Dictionary.CompiledMethod).%OpenId(className _ "||" _ methodName).Origin = "%pkg.isc.rest.model.dbMappedResource" {
			Return ""
		}
		Return ..GenerateSchemaFromMethodOutput(className, methodName, autogenerated)
	} Catch ex {
		Return ""
	}
}

/// Returns an OpenAPI-format schema representing the JSON value written by a given ClassMethod
ClassMethod GenerateSchemaFromMethodOutput(className, methodName, autogenerated = 0) As %pkg.isc.rest.openAPI.model.schema
{
	TStart
	Set className = $$$CLASSNAME(className)
	Set str = ##class(%pkg.isc.rest.openAPI.util).ReadClassMethodOutput(className, methodName)
	TRollback 1
	Try {
		Set json = {}.%FromJSON(str)
		Return ..GenerateSchemaFromJSONExample(json, autogenerated)
	} Catch ex {
		Return ..GenerateSchemaFromJSONExample(str, autogenerated)
	}
}

/// Returns an OpenAPI-format schema representing the JSON value returned by a given ClassMethod
ClassMethod GenerateSchemaFromMethodReturn(className, methodName, autogenerated) As %pkg.isc.rest.openAPI.model.schema
{
	TStart
	Set className = $$$CLASSNAME(className)
	Set str = $ClassMethod(className, methodName)
	TRollback 1
	Try {
		Set json = {}.%FromJSON(str)
		Return ..GenerateSchemaFromJSONExample(json, autogenerated)
	} Catch ex {
		Return ..GenerateSchemaFromJSONExample(str, autogenerated)
	}
}

/// Converts a JSON object into an OpenAPI-format specification that it fits
ClassMethod GenerateSchemaFromJSONExample(json, autogenerated = 0) As %pkg.isc.rest.openAPI.model.schema
{
	If '$IsObject(json) {
		// Handle JSON primitives
		Set json2 = {}
		Set json2.a = json
		Set obj = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
		Set obj.AutoGenerated = autogenerated
		Set obj.Type = json2.%GetTypeOf("a")
		Set obj.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(json, obj.Type)
		Return obj
	} Else {
		Set iterator = json.%GetIterator()
		If $ClassName(json) = "%Library.DynamicObject" {
			Set obj = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set obj.AutoGenerated = autogenerated
			Set obj.Type = "object"
			While iterator.%GetNext(.key, .value) {
				Set type = json.%GetTypeOf(key)
				If type = "object" || (type = "array"){
					Set property = ..GenerateSchemaFromJSONExample(value, autogenerated)
				} Else {
					Set property = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
					Set property.AutoGenerated = autogenerated
					Set property.Type = type
					Set property.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(value, property.Type)
				}
				Do obj.Properties.SetAt(property, key)
			}
			Set obj.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(json)
			Return obj
		} Else {
			Set obj = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set obj.AutoGenerated = autogenerated
			Set obj.Type = "array"
			While iterator.%GetNext(.key, .value) {
				Set valueSchema = ..GenerateSchemaFromJSONExample(value, autogenerated)
				If obj.Items = "" {
					Set obj.Items = valueSchema
				} Else {
					Do ..MergeSchemas(obj.Items, valueSchema, .mergedSchema, .success, autogenerated)
					If 'success {
						// Error!
						Return ""
					} Else {
						Set obj.Items = mergedSchema
					}
				}
			}
			Set obj.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(json)
			Return obj
		}
	}
}

/// Attempts to merge two partial OpenAPI-format schemas with each other (combining properties, etc)
ClassMethod MergeSchemas(schema1 As %pkg.isc.rest.openAPI.model.schema, schema2 As %pkg.isc.rest.openAPI.model.schema, Output outputSchema As %pkg.isc.rest.openAPI.model.schema, Output success As %Boolean, autogenerated = 0) [ Internal ]
{
	If $IsObject(schema1)'=$IsObject(schema2) {
		Set success = 0
		Return
	}
	If '$IsObject(schema1) {
		Set success = 1
		Set outputSchema = schema1.%ConstructClone(1)
	} Else {
		If schema1.Type '= schema2.Type {
			Set success = 0
			Return
		}
		If schema1.Type = "array" {
			Set obj = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set obj.Type = "array"
			Set obj.AutoGenerated = autogenerated
			Do ..MergeSchemas(schema1.Items, schema2.Items, .mergedItem, .resolved, autogenerated)
			If 'resolved {
				Set success = 0
				Return
			}
			Set obj.Items = mergedItem
			Set obj.Items.AutoGenerated = autogenerated
			Set success = 1
			Set outputSchema = obj
		} ElseIf schema1.Type = "object" {
			Set obj = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set obj.Type = "object"
			Set obj.AutoGenerated = autogenerated
			For i=1:1:schema1.SourceClasses.Count() {
				Do obj.SourceClasses.Insert(schema1.SourceClasses.GetAt(i))
			}
			For i=1:1:schema2.SourceClasses.Count() {
				Do:obj.SourceClasses.Find(schema2.SourceClasses.GetAt(i))="" obj.SourceClasses.Insert(schema2.SourceClasses.GetAt(i))
			}
			Set key="", value = schema1.Properties.GetNext(.key)
			While key'="" {
				Set value.AutoGenerated = autogenerated
				Do obj.Properties.SetAt(value, key)
				Set value = schema1.Properties.GetNext(.key)
			}
			Set key="", value = schema2.Properties.GetNext(.key)
			While key'="" {
				If 'obj.Properties.IsDefined(key) {
					Set value.AutoGenerated = autogenerated
					Do obj.Properties.SetAt(value, key)
				} Else {
					Set success2 = 1
					Do ..MergeSchemas(value, obj.Properties.GetAt(key), .merged, .success2, autogenerated)
					If 'success2 {
						Set success = 0
						Return
					}
					Set merged.AutoGenerated = autogenerated
					Do obj.Properties.SetAt(merged, key)
				}
				Set value = schema2.Properties.GetNext(.key)
			}
			Set success = 1
			Set outputSchema = obj
		} Else {
			Set success = 1
			Set outputSchema = schema1
			Return
		}
	}
	For i=1:1:schema1.SourceClasses.Count() {
		Do outputSchema.SourceClasses.Insert(schema1.SourceClasses.GetAt(i))
	}
	For i=1:1:schema2.SourceClasses.Count() {
		Do:outputSchema.SourceClasses.Find(schema2.SourceClasses.GetAt(i))="" outputSchema.SourceClasses.Insert(schema2.SourceClasses.GetAt(i))
	}
}

/// Attempts to reconcile an expected OpenAPI-style resource schema with a found resource schema
ClassMethod ReconcileFoundMethodSchema(initialSchema As %pkg.isc.rest.openAPI.model.schema, foundSchema As %pkg.isc.rest.openAPI.model.schema, Output reconciledSchema As %pkg.isc.rest.openAPI.model.schema, Output mismatchSeverity As %Integer, autogenerated = 0) [ Internal ]
{
	If '$IsObject(foundSchema) {
		Set mismatchSeverity = 0
		Set reconciledSchema = initialSchema
		Return
	}
	If initialSchema.Type '= foundSchema.Type {
		Set mismatchSeverity = 2
		If initialSchema.Type = "array" {
			Set inner = initialSchema.Items
			Do ..ReconcileFoundMethodSchema(inner, foundSchema, .reconciledSchema, .mismatchSeverity)
			Set:mismatchSeverity=0 mismatchSeverity = 1
			Return
		}
		If foundSchema.Type = "array" {
			Set inner = foundSchema.Items
			Do ..ReconcileFoundMethodSchema(initialSchema, inner, .reconciledSchema, .mismatchSeverity)
			Set:mismatchSeverity=0 mismatchSeverity = 1
			Return
		}
	}
	If initialSchema.Type = "array" {
		Set initialInner = initialSchema.Items
		Set foundInner = foundSchema.Items
		// TODO: This... won't return the proper reconciled schema at all :/
		Do ..ReconcileFoundMethodSchema(initialInner, foundInner, .reconciledSchema, .mismatchSeverity)
		Return
	}
	If initialSchema.Properties.Count() = 0 {
		If foundSchema.Properties.Count() = 0 {
			Set reconciledSchema = initialSchema
			Set mismatchSeverity = 0
			Return
		}
		Set reconciledSchema = foundSchema
		Set mismatchSeverity = 2
		Return
	}
	Set key = "", value = foundSchema.Properties.GetNext(.key)
	Set reconciledSchema = initialSchema
	While key'="" {
		If 'initialSchema.Properties.IsDefined(key) {
			Set reconciledSchema = foundSchema
			Set mismatchSeverity = 2
			Return
		} Else {
			// This should remain commented out to avoid (potentially) leaking data
			// Set:(schema.Properties.GetAt(key).Example="" && $IsObject(value) && (value.Example'="")) schema.Properties.GetAt(key).Example = value.Example
		}
		Set value = foundSchema.Properties.GetNext(.key)
	}
	Set mismatchSeverity = 0
	Return
}

}

