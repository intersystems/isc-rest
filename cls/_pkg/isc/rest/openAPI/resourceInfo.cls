Include %pkg.isc.rest.general

Class %pkg.isc.rest.openAPI.resourceInfo Extends %pkg.isc.rest.openAPI.resourceInfoStub
{

/// Whether or not resource endpoints should be generated
Property ResourceEndpointsEnabled As %Boolean [ Internal ];

/// Whether or not the CheckPermission() method for this resource allows the current user to call the Query endpoint
Property ForbidResourceQuery As %Boolean [ Internal ];

/// Whether or not the CheckPermission() method for this resource allows the current user to call the Create endpoint
Property ForbidResourceCreate As %Boolean [ Internal ];

/// Whether or not the CheckPermission() method for this resource allows the current user to call the Construct endpoint
Property ForbidResourceConstruct As %Boolean [ Internal ];

/// Whether or not the CheckPermission() method for this resource allows the current user to call the Read endpoint
Property ForbidResourceRead As %Boolean [ Internal ];

/// Whether or not the CheckPermission() method for this resource allows the current user to call the Update endpoint
Property ForbidResourceUpdate As %Boolean [ Internal ];

/// Whether or not the CheckPermission() method for this resource allows the current user to call the Delete endpoint
Property ForbidResourceDelete As %Boolean [ Internal ];

/// Whether or not the Forbid... values will *always* be true
Property ForbidUnderAllCircumstances As %Boolean [ InitialExpression = 0, Internal ];

/// The name of the class representing this resource
Property RepresentativeClassName As %String [ Internal ];

/// Whether or not the ..ClassName class is a proxy definition
Property ExternalDefinition As %Boolean [ Internal ];

/// The name of the class (if any) that the ..ClassName class is a proxy for
Property ExternalClassName As %String [ Internal ];

/// An array mapping property names to %pkg.isc.rest.openAPI.propertyInfo objects
Property Properties As array Of %pkg.isc.rest.openAPI.propertyInfo [ Internal ];

/// An OpenAPI-format schema specification for this resource in the INPUT direction
Property OpenAPIInputSchema As %pkg.isc.rest.openAPI.model.schema [ Internal, Transient ];

/// An OpenAPI-format schema specification for this resource in the OUTPUT direction
Property OpenAPIOutputSchema As %pkg.isc.rest.openAPI.model.schema [ Internal, Transient ];

/// Whether or not the ResourceInfo failed to generate
Property Invalid As %Boolean [ InitialExpression = 0, Internal ];

Method %OnNew(stub) As %Library.Status
{	
	// Copy values from the stub (TODO: come up with a nicer way to do this...)
	Set ..ClassName = $$$CLASSNAME(stub.ClassName)
	Set ..FieldName = stub.FieldName
	Set ..FieldNameOverwritten = stub.FieldNameOverwritten
	Set ..IDField = stub.IDField
	Set ..IgnoreNull = stub.IgnoreNull
	Set ..IgnoreNullOverwritten = stub.IgnoreNullOverwritten
	Set ..Include = stub.Include
	Set ..IncludeID = stub.IncludeID
	Set ..IncludeOverwritten = stub.IncludeOverwritten
	Set ..JSONMapping = stub.JSONMapping
	Set ..JSONType = stub.JSONType
	Set ..JSONTypeOverwritten = stub.JSONTypeOverwritten
	Set ..MediaType = stub.MediaType
	Set ..Null = stub.Null
	Set ..NullOverwritten = stub.NullOverwritten
	Set ..PropertiesDefaultJSONMapping = stub.PropertiesDefaultJSONMapping
	Set ..PropertiesDefaultJSONMappingOverwritten = stub.PropertiesDefaultJSONMappingOverwritten
	Set ..Reference = stub.Reference
	Set ..ReferenceOverwritten = stub.ReferenceOverwritten
	Set ..ResourceName = stub.ResourceName
	Set ..PropertiesDefaultIncludeID = stub.PropertiesDefaultIncludeID
	Set ..PropertiesDefaultIncludeIDOverwritten = stub.PropertiesDefaultIncludeIDOverwritten
	Set ..PropertiesDefaultIDField = stub.PropertiesDefaultIDField
	Set ..PropertiesDefaultIDFieldOverwritten = stub.PropertiesDefaultIDFieldOverwritten
	Set ..PropertiesDefaultReference = stub.PropertiesDefaultReference
	Set ..PropertiesDefaultReferenceOverwritten = stub.PropertiesDefaultReferenceOverwritten
	
	Return $$$OK
}

/// Get a ResourceInfo object (OpenAPI resource schema (input / output) + auxiliary information) for the given class
ClassMethod FromStub(stub As %pkg.isc.rest.openAPI.resourceInfoStub, openapi As %pkg.isc.rest.openAPI) As %pkg.isc.rest.openAPI.resourceInfo [ Internal ]
{
	
	// TODO: Swap out these references in code so this is no longer needed
	Set className = stub.ClassName
	Set resourceName = stub.ResourceName
	Set mediaType = stub.MediaType
	
	// Create and initialize the info object
	Set info = ..%New(stub)
	Set info.RepresentativeClassName = info.ClassName
	Set info.ResourceEndpointsEnabled = (info.ResourceName '= "")
	
	// Get class info
	Set classInfo = ##class(%Dictionary.CompiledClass).%OpenId(info.ClassName)
	Set classProperties = classInfo.Properties
	Set info.Description = classInfo.Description
	
	// Decide if this is an external (Proxy) schema
	Set externalDefinition = $ClassMethod(info.ClassName, "%Extends", "%pkg.isc.rest.model.proxy")
	Set info.ExternalDefinition = externalDefinition
	If info.ExternalDefinition {
		Set info.ExternalClassName = $$$CLASSNAME($Parameter(info.ClassName, "SOURCECLASS"))
		Set info.RepresentativeClassName = info.ExternalClassName
		//// Get updated info into the stub
		Set info.ClassName = info.RepresentativeClassName
		Do info.PopulateNonOverwrittenValues()
		Set info.ClassName = className
		Set classInfo = ##class(%Dictionary.CompiledClass).%OpenId(info.RepresentativeClassName)
	} Else {
		Do info.PopulateNonOverwrittenValues()
	}
	Set procInfo = info
	
	Do ..RetrieveFieldInfo(openapi,stub,info,.procInfo,className,classInfo)
	
	// Create and set-up the schema objects
	// NOTE: This includes a number of x-ISC_CLASS fields if ..HideInternalInfo is disabled
	// TODO: Document the x-ISC_* values somewhere
	Set openAPIinputSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set openAPIoutputSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set openAPIinputSchema.AutoGenerated = 1
	Set openAPIoutputSchema.AutoGenerated = 1
	Do openAPIinputSchema.SourceClasses.Insert(info.ClassName)
	Do openAPIoutputSchema.SourceClasses.Insert(info.ClassName)
	Set openAPIinputSchema.SourceStub = info
	Set openAPIoutputSchema.SourceStub = info
	Set openAPIinputSchema.SourceDirection = "input"
	Set openAPIoutputSchema.SourceDirection = "output"
	#Dim openAPIinputSchema As %pkg.isc.rest.openAPI.model.schema
	#Dim openAPIoutputSchema As %pkg.isc.rest.openAPI.model.schema
	If 'openapi.HideInternalInfo {
		Set openAPIinputSchema.Description = info.Description
		Set openAPIoutputSchema.Description = info.Description
		Do openAPIinputSchema.SetExtendedProperty("ISC_CLASS", info.ClassName)
		Do openAPIoutputSchema.SetExtendedProperty("ISC_CLASS", info.ClassName)
		If info.ExternalDefinition {
			Do openAPIinputSchema.SetExtendedProperty("ISC_PROXY", 1, "boolean")
			Do openAPIoutputSchema.SetExtendedProperty("ISC_PROXY", 1, "boolean")
			Do openAPIinputSchema.SetExtendedProperty("ISC_PROXY_FOR", info.ExternalClassName)
			Do openAPIoutputSchema.SetExtendedProperty("ISC_PROXY_FOR", info.ExternalClassName)
		}
		If info.JSONMapping'="" {
			Do openAPIinputSchema.SetExtendedProperty("ISC_JSONMAPPING", info.RepresentativeClassName _  ":" _ info.JSONMapping)
			Do openAPIoutputSchema.SetExtendedProperty("ISC_JSONMAPPING", info.RepresentativeClassName _  ":" _ info.JSONMapping)
		}
	}
	Set openAPIinputSchema.Type = stub.JSONType
	Set openAPIoutputSchema.Type = stub.JSONType
	Set openAPIinputSchema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	Set openAPIoutputSchema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	
	If info.IncludeID && (info.JSONType = "object") && (info.RepresentativeClassName '= "%Library.DynamicObject"){
		Set idFieldInfo = ##class(%pkg.isc.rest.openAPI.propertyInfo).%New()
		Set idFieldInfo.Source = "$this"
		Set idFieldInfo.Include = "outputonly"
		Set idFieldInfo.Reference = "ID"
		Set idFieldInfo.ClassName = info.RepresentativeClassName
		Set idFieldInfo.JSONType = "object"
		Set idFieldInfo.Required = 1
		Set idFieldInfo.ReferenceType = "%Library.String"
		Set idFieldInfo.ReferenceJsonType = "string"
		Do ##class(%pkg.isc.rest.openAPI.example).GetPropertyExample( , , idFieldInfo.ClassName, .idFieldInfo, idFieldInfo.Reference)
		Do info.Properties.SetAt(idFieldInfo, info.IDField)
	}
	
	// Put the schema info into the OpenAPI-format schema objects
	// TODO: Clean up / document the following section's code
	Set fieldName = ""
	Set fieldInfo = info.Properties.GetNext(.fieldName)
	While fieldName '= "" {
		If fieldInfo.ClassName = "%Library.DynamicObject" || (fieldInfo.ClassName = "%Library.DynamicArray") {
			Do openapi.Warn("Property " _ info.RepresentativeClassName _ ":" _ fieldInfo.Source _ " is a dynamic object/array, consider providing an alternate schema representation using " _ info.RepresentativeClassName _ ":ModifyOpenAPIInfo")
		}
		Set fieldSchemaInput = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
		Set fieldSchemaOutput = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
		#Dim fieldSchemaInput As %pkg.isc.rest.openAPI.model.schema
		#Dim fieldSchemaOutput As %pkg.isc.rest.openAPI.model.schema
		Set fieldSchemaInput.AutoGenerated = 1
		Set fieldSchemaOutput.AutoGenerated = 1
		Do fieldSchemaInput.SourceClasses.Insert(info.ClassName)
		Do fieldSchemaOutput.SourceClasses.Insert(info.ClassName)
		If 'openapi.HideInternalInfo {
			Set fieldSchemaInput.Description = fieldInfo.Description
			Set fieldSchemaOutput.Description = fieldInfo.Description
			If info.ExternalDefinition {
				Do fieldSchemaInput.SetExtendedProperty("ISC_CLASS", info.ExternalClassName)
				Do fieldSchemaOutput.SetExtendedProperty("ISC_CLASS", info.ExternalClassName)
			} Else {
				Do fieldSchemaInput.SetExtendedProperty("ISC_CLASS", info.ClassName)
				Do fieldSchemaOutput.SetExtendedProperty("ISC_CLASS", info.ClassName)
			}
			Do fieldSchemaInput.SetExtendedProperty("ISC_NAME", fieldInfo.Source)
			Do fieldSchemaOutput.SetExtendedProperty("ISC_NAME", fieldInfo.Source)
			// TODO this should really just use the Relationship boolean from the property...
			If fieldInfo.Cardinality '= "" {
				Do fieldSchemaInput.SetExtendedProperty("ISC_RELATIONSHIP", 1, "boolean")
				Do fieldSchemaInput.SetExtendedProperty("ISC_CARDINALITY", fieldInfo.Cardinality)
				Do fieldSchemaOutput.SetExtendedProperty("ISC_RELATIONSHIP", 1, "boolean")
				Do fieldSchemaOutput.SetExtendedProperty("ISC_CARDINALITY", fieldInfo.Cardinality)
			}
			If fieldInfo.RuntimeType = fieldInfo.ClassName {
				Do fieldSchemaInput.SetExtendedProperty("ISC_TYPE", fieldInfo.RuntimeType)
				Do fieldSchemaOutput.SetExtendedProperty("ISC_TYPE", fieldInfo.RuntimeType)
				}
			If fieldInfo.Reference'="OBJECT" && (fieldInfo.Reference '= "") {
				Do fieldSchemaInput.SetExtendedProperty("ISC_REFERENCE", fieldInfo.Reference)
				Do fieldSchemaOutput.SetExtendedProperty("ISC_REFERENCE", fieldInfo.Reference)
			}
			If fieldInfo.JSONMapping'="" {
				Do fieldSchemaInput.SetExtendedProperty("ISC_JSONMAPPING", fieldInfo.JSONMapping)
				Do fieldSchemaOutput.SetExtendedProperty("ISC_JSONMAPPING", fieldInfo.JSONMapping)
			}
		}
		Set fieldStub = fieldInfo.GetStub()
		If fieldInfo.Cardinality = "children" || (fieldInfo.Cardinality = "many") || (fieldInfo.Collection = "list") {
			// Handle arrays here!
			Set fieldSchemaInput.Type = "array"
			Set fieldSchemaOutput.Type = "array"
			If fieldInfo.Reference="OBJECT" || (fieldInfo.Reference="") {
				If fieldInfo.JSONType = "object" {
					Set fieldSchemaInput.Items = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
					Set fieldSchemaOutput.Items = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
					Do fieldSchemaInput.Items.SourceClasses.Insert(info.ClassName)
					Do fieldSchemaOutput.Items.SourceClasses.Insert(info.ClassName)
					Set fieldSchemaInput.Items.Ref = "#/components/schemas/" _ openapi.GetNiceName(fieldStub) _ "_input"
					Set fieldSchemaOutput.Items.Ref = "#/components/schemas/" _ openapi.GetNiceName(fieldStub) _ "_output"
					Do openapi.NeededClasses.Insert(fieldStub)
				} Else {
					Set fieldSchemaInput.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
					Set fieldSchemaOutput.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
					Set fieldSchemaInput.Items.AutoGenerated = 1
					Set fieldSchemaOutput.Items.AutoGenerated = 1
					Do fieldSchemaInput.Items.SourceClasses.Insert(info.ClassName)
					Do fieldSchemaOutput.Items.SourceClasses.Insert(info.ClassName)
					Do:'openapi.HideInternalInfo fieldSchemaInput.Items.SetExtendedProperty("ISC_TYPE", fieldInfo.ClassName)
					Do:'openapi.HideInternalInfo fieldSchemaOutput.Items.SetExtendedProperty("ISC_TYPE", fieldInfo.ClassName)
					Set fieldSchemaInput.Items.Type = fieldInfo.JSONType
					Set fieldSchemaOutput.Items.Type = fieldInfo.JSONType
					Set:fieldInfo.Example'="" fieldSchemaInput.Items.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.JSONType)
					Set:fieldInfo.Example'="" fieldSchemaOutput.Items.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.JSONType)
				}
			} Else {
				Set fieldSchemaInput.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
				Set fieldSchemaOutput.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
				Set fieldSchemaInput.Items.AutoGenerated = 1
				Set fieldSchemaOutput.Items.AutoGenerated = 1
				Do fieldSchemaInput.Items.SourceClasses.Insert(info.ClassName)
				Do fieldSchemaOutput.Items.SourceClasses.Insert(info.ClassName)
				Do:'openapi.HideInternalInfo fieldSchemaInput.Items.SetExtendedProperty("ISC_TYPE", fieldInfo.ClassName)
				Do:'openapi.HideInternalInfo fieldSchemaOutput.Items.SetExtendedProperty("ISC_TYPE", fieldInfo.ClassName)
				Do ##class(%pkg.isc.rest.openAPI.example).GetPropertyExample("", "", fieldInfo.ReferenceType, .fieldInfo)
				Set fieldSchemaInput.Items.Type = fieldInfo.ReferenceJsonType
				Set fieldSchemaOutput.Items.Type = fieldInfo.ReferenceJsonType
				Set:fieldInfo.Example'="" fieldSchemaInput.Items.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.ReferenceJsonType)
				Set:fieldInfo.Example'="" fieldSchemaOutput.Items.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.ReferenceJsonType)
			}
		} Else {
			If fieldInfo.Reference="OBJECT" || (fieldInfo.Reference="") { 
				If fieldInfo.JSONType = "object" {
					Set fieldSchemaInput = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
					Set fieldSchemaOutput = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
					Do fieldSchemaInput.SourceClasses.Insert(info.ClassName)
					Do fieldSchemaOutput.SourceClasses.Insert(info.ClassName)
					Set fieldSchemaInput.Ref = "#/components/schemas/" _ openapi.GetNiceName(fieldStub) _ "_input"
					Set fieldSchemaOutput.Ref = "#/components/schemas/" _ openapi.GetNiceName(fieldStub) _ "_output"
					Do openapi.NeededClasses.Insert(fieldStub)
				} Else {
					Set fieldSchemaInput.Type = fieldInfo.JSONType
					Set fieldSchemaOutput.Type = fieldInfo.JSONType
					Set:fieldInfo.Example'="" fieldSchemaInput.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.JSONType)
					Set:fieldInfo.Example'="" fieldSchemaOutput.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.JSONType)
				}
			} Else {
				Set fieldSchemaInput.Type = fieldInfo.ReferenceJsonType
				Set fieldSchemaOutput.Type = fieldInfo.ReferenceJsonType
				Set:fieldInfo.Example'="" fieldSchemaInput.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.ReferenceJsonType)
				Set:fieldInfo.Example'="" fieldSchemaOutput.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From(fieldInfo.Example, fieldInfo.ReferenceJsonType)
			}
		}
		Set fieldInfo.OpenAPIInputSchema = fieldSchemaInput
		Set fieldInfo.OpenAPIOutputSchema = fieldSchemaOutput
		Set realFieldName = $Piece(fieldName,"||")
		If fieldInfo.Include '= "none" {
			If fieldInfo.Include '= "outputonly" {
				Do openAPIinputSchema.Properties.SetAt(fieldInfo.OpenAPIInputSchema, realFieldName)
				Do:fieldInfo.Required openAPIinputSchema.Required.Insert(realFieldName)
			}
			If fieldInfo.Include '= "inputonly" {
				Do openAPIoutputSchema.Properties.SetAt(fieldInfo.OpenAPIOutputSchema, realFieldName)
				Do:fieldInfo.Required openAPIoutputSchema.Required.Insert(realFieldName)
			}
		}
		Set fieldInfo = info.Properties.GetNext(.fieldName)
	}
	
	// Set the readOnly / writeOnly schema fields
	Set openAPIinputSchema.WriteOnly = 1
	Set openAPIoutputSchema.ReadOnly = 1
	
	// Set the externalDocs field
	If 'openapi.HideInternalInfo {
		Set docs = ##class(%pkg.isc.rest.openAPI.model.externalDocumentation).%New()
		#Dim docs As %pkg.isc.rest.openAPI.model.externalDocumentation
		Set docs.URL = openapi.ClassReferenceURL _ "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY=" _ openapi.Namespace _ "&CLASSNAME=" _ info.ClassName
		Set docs.Description = info.ClassName _ " InterSystems Class Reference"
		Set openAPIinputSchema.ExternalDocumentation = docs
		Set openAPIoutputSchema.ExternalDocumentation = docs
	}
	
	If openAPIinputSchema.Required.Count() = 0 {
		Set openAPIinputSchema.Required = ""
	}
	If openAPIoutputSchema.Required.Count() = 0 {
		Set openAPIoutputSchema.Required = ""
	}
	If openAPIinputSchema.Type = "array" && ('$IsObject(openAPIinputSchema.Items)) {
		Set openAPIinputSchema.Items = ##class(%pkg.isc.rest.openAPI.model.emptyObject).%New()
	}
	If openAPIoutputSchema.Type = "array" && ('$IsObject(openAPIoutputSchema.Items)) {
		Set openAPIoutputSchema.Items = ##class(%pkg.isc.rest.openAPI.model.emptyObject).%New()
	}
	
	// Check CheckPermission() permissions for Resource methods
	// [TODO] It's not great to tie this to the current user's credentials... (note: the OpenAPI spec actually says this might be OK to do?)
	try {
		Set queryMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "QUERY", openapi.UserContext, "")
		Set createMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "CREATE", openapi.UserContext, "")
		Set readMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "READ", openapi.UserContext, "")
		Set newActionAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "ACTION:new", openapi.UserContext, "")
		Set updateMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "UPDATE", openapi.UserContext, "")
		Set deleteMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "DELETE", openapi.UserContext, "")
		Set info.ForbidResourceQuery = 'queryMethodAllowed
		Set info.ForbidResourceCreate = 'createMethodAllowed
		Set info.ForbidResourceConstruct = '(readMethodAllowed&&newActionAllowed)
		Set info.ForbidResourceRead = 'readMethodAllowed
		Set info.ForbidResourceUpdate = 'updateMethodAllowed
		Set info.ForbidResourceDelete = 'deleteMethodAllowed
		Set info.ForbidUnderAllCircumstances = ##class(%Dictionary.CompiledMethod).%OpenId(info.ClassName _ "||CheckPermission").Origin = "%pkg.isc.rest.model.resource"
	}
	catch (ex) {
		Try {
			Set queryMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "QUERY", openapi.UserContext)
			Set createMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "CREATE", openapi.UserContext)
			Set readMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "READ", openapi.UserContext)
			Set newActionAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "ACTION:new", openapi.UserContext)
			Set updateMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "UPDATE", openapi.UserContext)
			Set deleteMethodAllowed = $ClassMethod(info.ClassName, "CheckPermission", "", "DELETE", openapi.UserContext)
			Set info.ForbidResourceQuery = 'queryMethodAllowed
			Set info.ForbidResourceCreate = 'createMethodAllowed
			Set info.ForbidResourceConstruct = '(readMethodAllowed&&newActionAllowed)
			Set info.ForbidResourceRead = 'readMethodAllowed
			Set info.ForbidResourceUpdate = 'updateMethodAllowed
			Set info.ForbidResourceDelete = 'deleteMethodAllowed
			Set info.ForbidUnderAllCircumstances = ##class(%Dictionary.CompiledMethod).%OpenId(info.ClassName _ "||CheckPermission").Origin = "%pkg.isc.rest.model.resource"
		} Catch {
			Set info.ForbidUnderAllCircumstances = 1
			Set info.ForbidResourceQuery = 1
			Set info.ForbidResourceCreate = 1
			Set info.ForbidResourceConstruct = 1
			Set info.ForbidResourceRead = 1
			Set info.ForbidResourceUpdate = 1
			Set info.ForbidResourceDelete = 1
		}
	}
	
	// If this is a resource and the mediatype is unsupported, mark it as invalid
	If (info.ResourceName'="") && '$Match(info.MediaType,"application/(.*\+)?((json)|(octet-stream))") {
		Set info.Invalid = 1
		Do openapi.ErrorOnce("Class " _ info.ClassName _ " has an unsupported (non application/json or application/octet-stream) MEDIATYPE parameter value")
	}
	
	
	// Add the info object (everything we just generated) to the ResourceInfo array
	Set info.OpenAPIOutputSchema = openAPIoutputSchema
	Set info.OpenAPIInputSchema = openAPIinputSchema
	Do openapi.ResourceInfo.Insert(info)
	Return info
}

ClassMethod RetrieveFieldInfo(openapi, stub, info As %pkg.isc.rest.openAPI.resourceInfo, procInfo As %pkg.isc.rest.openAPI.resourceInfo, className, classInfo)
{
	If stub.JSONType = "object" {
		
		// Handle the case where we are reading from a JSONMapping XData block
		If info.JSONMapping '= "" {
			
			// Read the XData block
			Set mapping = ##class(%pkg.isc.rest.openAPI.util).ParseJSONMapping(info.RepresentativeClassName, info.JSONMapping, .sc)
			If $System.Status.IsError(sc) {
				
				// Warn and use the default ("") mapping if the provided mapping name is invalid
				Do openapi.WarnOnce("JSONMapping XDATA for " _ info.RepresentativeClassName _ ":" _ info.JSONMapping _ " from class " _ info.ClassName _ " doesn't exist, using the default JSON map")
				Set procInfo = info.%ConstructClone()
				Set procInfo.JSONMapping = ""
				Set procInfo.ClassName = info.RepresentativeClassName
				Do procInfo.PopulateNonOverwrittenValues()
				Set procInfo.ClassName = className
				
			} Else {
				
				// Iterate over Call elements
				If mapping.%IsA("%pkg.isc.json.mapping") {
					For i=1:1:mapping.callList.Count() {
						Set call = mapping.callList.GetAt(i)
						Set callInfo = info.%ConstructClone()
						Set callInfo.JSONMapping = call.Mapping
						Do ..RetrieveFieldInfo(openapi,stub,callInfo,callInfo,className,classInfo)
						Set key = ""
						For {
							Set property = callInfo.Properties.GetNext(.key)
							Quit:key=""
							Do info.Properties.SetAt(property,key)
						}
					}
				}
			
				// Iterate over found properties
				For i=1:1:mapping.propertyList.Count() {
					Set property = mapping.propertyList.GetAt(i)
					#Dim property As %JSON.MappingProperty
					
					Set jsonVarName = property.FieldName
					Set includeParam = property.Include
					Set referenceField = property.Reference
					Set mappingField = property.Mapping
					Set nullField = property.Null
					Set ignoreNullField = property.IgnoreNull
					Set:jsonVarName="" jsonVarName = property.Name
							
					// TODO: Comment this
					Set fieldSource = property.Name
					Set fieldInclude = $ZConvert(includeParam,"L")
					Set fieldReference = $ZConvert(referenceField,"U")
					Set:fieldReference="" fieldReference=$c(0)
					Set sourceProperty = classInfo.Properties.GetAt(classInfo.Properties.FindObject($lb(info.RepresentativeClassName_"||"_property.Name,"%Dictionary.CompiledProperty")))
					Set fieldClassName = $$$CLASSNAME(sourceProperty.Type)
					Set fieldJSONMapping = mappingField
					Set:fieldJSONMapping=""&&(info.PropertiesDefaultJSONMapping'="") fieldJSONMapping = info.PropertiesDefaultJSONMapping
							
					// Make the PropertyInfo object
					Set fieldInfo = ##class(%pkg.isc.rest.openAPI.propertyInfo).%New(fieldClassName,fieldJSONMapping,,,,,nullField,ignoreNullField,,fieldReference,fieldInclude,jsonVarName,)
					Set fieldInfo.Source = fieldSource
					Do fieldInfo.PopulateNonOverwrittenValues()
					Set:info.PropertiesDefaultIncludeID'="" fieldInfo.IncludeID = info.PropertiesDefaultIncludeID
					Set:info.PropertiesDefaultIDField'="" fieldInfo.IDField = info.PropertiesDefaultIDField
					Set:info.PropertiesDefaultReference'=""&&(property.Reference="") fieldInfo.Reference = info.PropertiesDefaultReference
					
					// Get other useful fields from the property (Cardinality, RuntimeType, Required)
					Set fieldInfo.Cardinality = sourceProperty.Cardinality
					Set fieldInfo.Collection = sourceProperty.Collection
					Set fieldInfo.RuntimeType = sourceProperty.RuntimeType
					Set fieldInfo.Required = sourceProperty.Required
					Set fieldInfo.Description = sourceProperty.Description

					Do info.FinalizeField(.fieldInfo)
					
					// Write the property info to the ResourceInfo object
					If (fieldInfo.Include = "none") {
						Do info.Properties.RemoveAt(fieldInfo,jsonVarName)
					} ElseIf (fieldInfo.Include = "outputonly") {
						Do info.Properties.SetAt(fieldInfo,jsonVarName_"||OUT")
					} ElseIf (fieldInfo.Include = "inputonly") {
						Do info.Properties.SetAt(fieldInfo,jsonVarName_"||IN")
					} Else { // inout or empty, means the same thing
						Do info.Properties.RemoveAt(fieldInfo,jsonVarName_"||OUT")
						Do info.Properties.RemoveAt(fieldInfo,jsonVarName_"||IN")
						Do info.Properties.SetAt(fieldInfo,jsonVarName)
					}
				}
			}
		}
		
		// Handle the case where we are not reading from a JSONMapping XData block
		If procInfo.JSONMapping = "" {
			
			// Iterate over the class's properties
			Set properties = classInfo.Properties
			For i=1:1:properties.Count() {
				Set property = properties.GetAt(i)
				
				// Don't continue if this is a property we should ignore
				If property.Name = "%%OID" || (property.Name = "%Concurrency") {
					Continue
				}
				
				// Get the property's name, JSON Include field, type, and JSON Mapping field
				Set fieldSource = property.Name
				Set fieldInclude = $ZConvert(property.Parameters.GetAt("%JSONINCLUDE"),"L")
				Set:'property.Parameters.IsDefined("%JSONINCLUDE") fieldInclude = $c(0)
				Set fieldClassName = $$$CLASSNAME(property.Type)
				Set fieldNull = property.Parameters.GetAt("%JSONNULL")
				Set:'property.Parameters.IsDefined("%JSONNULL") fieldNull = $c(0)
				Set fieldIgnoreNull = property.Parameters.GetAt("%JSONIGNORENULL")
				Set:'property.Parameters.GetAt("%JSONIGNORENULL") fieldIgnoreNull = $c(0)
				Set fieldReference = $ZConvert(property.Parameters.GetAt("%JSONREFERENCE"),"U")
				Set:fieldReference="" fieldReference=$c(0)
				Set fieldJSONMapping = property.Parameters.GetAt("%JSONMAPPING")
				Set:info.PropertiesDefaultJSONMapping'=""&&(fieldJSONMapping="") fieldJSONMapping = procInfo.PropertiesDefaultJSONMapping
				
				// Get the property's JSON name
				Set fieldName = property.Parameters.GetAt("%JSONFIELDNAME")
				If fieldName = "" {
					Set fieldName = fieldSource
				}
				
				// Make the PropertyInfo object
				Set fieldInfo = ##class(%pkg.isc.rest.openAPI.propertyInfo).%New(fieldClassName,fieldJSONMapping,,,,,fieldNull,fieldIgnoreNull,,fieldReference,fieldInclude,fieldName)
				Set fieldInfo.Source = fieldSource
				Do fieldInfo.PopulateNonOverwrittenValues()
				
				// Get other useful fields from the property
				Set fieldInfo.Cardinality = property.Cardinality
				Set fieldInfo.Collection = property.Collection
				Set fieldInfo.RuntimeType = property.RuntimeType
				Set fieldInfo.Required = property.Required
				If fieldInfo.Reference="" {
					Set fieldClassReferenceParameter = ##class(%Dictionary.CompiledParameter).%OpenId(fieldInfo.ClassName_"||%JSONREFERENCE")
					Set:$IsObject(fieldClassReferenceParameter) fieldInfo.Reference = $ZConvert(fieldClassReferenceParameter.Default,"U")
				}
				Set fieldInfo.Description = property.Description
				Do info.FinalizeField(.fieldInfo)
				
				// Write the property info to the ResourceInfo object
				If (fieldInfo.Include = "none") {
					Do info.Properties.RemoveAt(fieldInfo,fieldName)
				} ElseIf (fieldInfo.Include = "outputonly") {
					Do info.Properties.SetAt(fieldInfo,fieldName_"||OUT")
				} ElseIf (fieldInfo.Include = "inputonly") {
					Do info.Properties.SetAt(fieldInfo,fieldName_"||IN")
				} Else { // inout or empty, means the same thing
					Do info.Properties.RemoveAt(fieldInfo,fieldName_"||OUT")
					Do info.Properties.RemoveAt(fieldInfo,fieldName_"||IN")
					Do info.Properties.SetAt(fieldInfo,fieldName)
				} 
			}
		}
	}
}

/// Shared code to call when adding a PropertyInfo object to a ResourceInfo instance
Method FinalizeField(ByRef fieldInfo)
{
	// Handle the reference field
	If fieldInfo.Reference '= "OBJECT" && (fieldInfo.Reference '= "") {
		
		// We are referencing something that is an object by a field, set referenceType / referenceJsonType appropriately
		If fieldInfo.Reference = "ID" {
			Set fieldInfo.ReferenceType = "%Library.String"
			Set fieldInfo.ReferenceJsonType = "string"
		} ElseIf fieldInfo.Reference = "OID" {
			Set fieldInfo.ReferenceType = "%Library.ObjectIdentity"
			Set fieldInfo.ReferenceJsonType = "string"
		} ElseIf fieldInfo.Reference = "GUID" {
			Set fieldInfo.ReferenceType = "%Library.String"
			Set fieldInfo.ReferenceJsonType = "string"
		}
		
		// Get an example of the property (using the appropriate reference)
		Do ##class(%pkg.isc.rest.openAPI.example).GetPropertyExample(..RepresentativeClassName, fieldInfo.Source, fieldInfo.ClassName, .fieldInfo, fieldInfo.Reference)
		
	} Else {
		
		// Either this isn't an object, or it is an object being directly referenced
		// The referenceType / refrenceJsonType don't really matter in this instance
		Set fieldInfo.ReferenceType = fieldInfo.ClassName
		Set fieldInfo.ReferenceJsonType = "object"
		
		// Get an example of the property
		Do ##class(%pkg.isc.rest.openAPI.example).GetPropertyExample(..RepresentativeClassName, fieldInfo.Source, fieldInfo.ClassName, .fieldInfo)
	}
}

/// Returns a variant of the output schema where none of the properties are required
Method GetUpdateSchema() As %pkg.isc.rest.openAPI.model.schema [ Internal ]
{
	Set updateSchema = ..OpenAPIInputSchema.%ConstructClone(1)
	Set updateSchema.Required = ""
	Set updateSchema.SourceDirection = "update"
	Return updateSchema
}

}

