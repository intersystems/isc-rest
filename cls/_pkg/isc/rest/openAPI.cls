Include %pkg.isc.rest.openAPI

/// Class responsible for creating OpenAPI specifications from %pkg.isc.rest configurations.
Class %pkg.isc.rest.openAPI Extends %RegisteredObject
{

/// The version of the OpenAPI specification that is being used
Parameter OpenAPIVersion As STRING = "3.0.3";

/// Debugging level; see the description for the debug parameter in GetSpecification()
Property DEBUG As %Boolean;

/// Whether or not to include endpoints with no reachable HTTP 200 response
Property IncludeForbiddenEndpoints As %Boolean [ InitialExpression = 0 ];

/// Whether or not to force all endpoints to act as if they are authorized
Property ForceAuthorizeAllEndpoints As %Boolean [ InitialExpression = 1 ];

/// Whether or not to hide as much internal info (class names, Relationship info, etc) as possible
Property HideInternalInfo As %Boolean [ InitialExpression = 1 ];

/// Used to make sure the "nice name" a class is given when HideInternalInfo=1 is always the same for any given class
Property ClassMappings As %ArrayOfDataTypes [ Internal ];

/// The actual OpenAPI Specification object that is being generated
Property Specification As %pkg.isc.rest.openAPI.model.openAPI [ Internal ];

/// Resource information objects
Property ResourceInfo As list Of %pkg.isc.rest.openAPI.resourceInfo [ Internal ];

/// Action information objects
Property ActionInfo As list Of %pkg.isc.rest.openAPI.actionInfo [ Internal ];

/// The API path
Property APIRoot As %String [ Internal ];

/// The qualified API address
Property Endpoint As %String [ Internal ];

/// Base URL for the Class Reference documentation
Property ClassReferenceURL As %String [ Internal ];

/// User Context value (see %pkg.isc.rest.handler:GetUserContext)
Property UserContext As %pkg.isc.rest.model.resource [ Internal ];

/// List of classes that still need schema representations generated
Property NeededClasses As list Of %pkg.isc.rest.openAPI.resourceInfoStub [ Internal ];

/// List of classes that have already had schema representations generated
Property FinishedClasses As list Of %pkg.isc.rest.openAPI.resourceInfoStub [ Internal ];

/// Map of schema name -> schema for Schemas that have been generated to handle method behavior where methods have been overwritten to use/return non-standard object types
Property OverwriteSchemas As array Of %pkg.isc.rest.openAPI.model.schema;

/// Description of the API
Property Description As %String [ Internal ];

/// Namespace where the API lives
Property Namespace As %String [ Internal ];

/// Whether or not 2FA is enabled in the web application's settings
Property TwoFactor As %Boolean [ Internal ];

/// The web application's dispatch class
Property DispatchClass As %String [ Internal ];

/// The web application's authentication method, in the form of a Security.Datatype.Authentication value
Property AuthMethod [ Internal ];

/// Warnings that came up during spec generation
Property Warnings As list Of %String [ Internal ];

/// Errors that came up during spec generation
Property Errors As list Of %String [ Internal ];

/// Name of a global to update with the current stage
Property StageGlobal [ Internal, Private ];

/// @Override: Sets up new instances of this class
Method %OnNew() As %Status
{
	#define WriteSection(%text) do ..WriteSection(%text, .ws, .timer)
	
	Set ..Specification = ##class(%pkg.isc.rest.openAPI.model.openAPI).%New()
	Set ..Specification.Paths = ##class(%pkg.isc.rest.openAPI.model.paths).%New()
	Return $$$OK
}

/// Get the OpenAPI specification for the %pkg.isc.rest data associated with the given API path
/// @param response: Output parameter, set to the generated specification
/// @param userContext: The user context to use in CheckPermission calls, ignored if ..ForceAuthorizeAllEndpoints defaults to 1
/// @param apiRootPath: The path of the API in question, of the form "/sample/api/" (used to query the Security.Applications table)
/// @param debug: The debugging level to generate the specification at:
///                 debug=0: "off" return validation status, no console output, specification description will NOT contain error/warning information
///                 debug=1: "normal" return validation status, write timing info + warnings/errors as they are thrown, specification description WILL contain error/warning information
///                 debug=2: "verbose" return validation status, write timing info + warnings/errors as they are thrown + validation status of ALL components, specification description WILL contain error/warning information
///                 debug=3: "stripped" return validation status, write timing info + validation status of ONLY components that fail validation, specification description WILL contain error/warning information
/// @param internal: Whether or not this specification is being generated for users with knowledge of the application's back-end objectscript code
///                 internal=0: no class-names or auxiliary information (objectscript types, proxy class information, etc) will be present in the specification
///                 internal=1: class-names and auxiliary information (objectscript types, proxy class information, etc) will be present in the specification
ClassMethod GetSpecification(Output response As %pkg.isc.rest.openAPI.model.openAPI, userContext As %pkg.isc.rest.model.resource = "", apiRootPath As %String = "", debug As %Boolean = 0, internal As %Boolean = 0, stageGlobal As %Boolean = 0, endpointOverride As %String = "") As %Boolean
{
	
	// TODO: There are a ton of places in here (this class in general) where I'm _definitely_ not handling mediatypes correctly. Fix that!
	// TODO: Unit tests!
	// TODO: Enums (see PhoneNumber:type) are not present as-such in the schema... handle them properly!
	// TODO: In both the Action and the JSONMAPPING XDATA blocks I'm not handling a number of fields that are relevent to the output I'm producing...
	
	Set obj = ..%New()
	Set obj.DEBUG = debug
	Set obj.HideInternalInfo = 'internal
	Set obj.StageGlobal = stageGlobal
	Set success = obj.GetSpecificationI(userContext, apiRootPath, endpointOverride)
	Set response = obj.Specification
	Return success
}

/// Get the OpenAPI specification [ Use the ClassMethod instead of this! ]
Method GetSpecificationI(userContext = "", apiRootPath = "", endpointOverride As %String = "") As %Boolean [ Internal ]
{
	
	// Code runs in the following stages:
	//   Stage A: Information Collection
	//   Stage B: Write the Specification (contains additional Information Collection as-needed)
	//   Stage C: Run ModifyOpenAPI ClassMethods
	//   Stage D: Correct Output for Invalid / Broken Endpoints
	//   Stage E: Remove Now-Unused Schemas from the Specification
	//   Stage F: Check the Specification For Currently-Unchecked Warnings or Errors
	//   Stage G: (If Desired) Validate the Specification
	
	// Setup
	Set initialTime = $$$TimerNow
	Set:userContext="" userContext = $$$NULLOREF
	Set:apiRootPath="" apiRootPath = %request.Application
	Set ..UserContext = userContext
	Set ..APIRoot = apiRootPath
	Set ..Endpoint = endpointOverride
	
	// Stage A: Information Collection
	// A.1: Query the Security.Applications table
	$$$WriteSection("A.1: GetWebApplicationInfo()")
	Do ..GetWebApplicationInfo()
	// A.2: Switch to the appropriate namespace
	$$$WriteSection("A.2: Switch namespace")
	New $NAMESPACE
	Set $NAMESPACE = ..Namespace
	// A.3: Collect information from the %pkg_isc_rest.resourceMap table
	$$$WriteSection("A.3: CollectResourceInfo()")
	Do ..CollectResourceInfo()
	// A.4: Collect information from the %pkg_isc_rest.actionMap table
	$$$WriteSection("A.4: CollectActionInfo()")
	Do ..CollectActionInfo()
	
	// Stage B: Write the Specification
	// B.1: Initial writing
	$$$WriteSection("B.1: WriteMisc()")
	Do ..WriteMisc()
	$$$WriteSection("B.1: WriteResourceEndpoints()")
	Do ..WriteResourceEndpoints()
	$$$WriteSection("B.1: WriteActionEndpoints()")
	Do ..WriteActionEndpoints()
	$$$WriteSection("B.1: WriteOtherEndpoints()")
	Do ..WriteOtherEndpoints()
	// B.2: Additional information collection
	$$$WriteSection("B.2: FinalizeSchemas()")
	Do ..FinalizeSchemas()
	// B.3: Final writing
	$$$WriteSection("B.3: WriteSchemas()")
	Do ..WriteSchemas()
	// B.4: Final example generation
	$$$WriteSection("B.4: FinalizeExamples()")
	Do ..FinalizeExamples()
	
	// Stage C: Run ModifyOpenAPIInfo ClassMethods
	$$$WriteSection("C.1: HandleClassOverrides()")
	Do ..HandleClassOverrides()
	
	// Stage D: Correct Output for Invalid / Broken Endpoints
	$$$WriteSection("D.1: CorrectBrokenEndpoints()")
	Do ..CorrectBrokenEndpoints()
	If '..IncludeForbiddenEndpoints {
		$$$WriteSection("D.2: RemoveForbiddenEndpoints()")
		Do ..RemoveForbiddenEndpoints()
	}
	
	// Stage E: Remove Now-Unused Schemas from the Specification
	$$$WriteSection("E.1: CleanSpecification()")
	Do ..CleanSpecification()
	
	// Stage F: Check the Specification For Currently-Unchecked Warnings or Errors
	$$$WriteSection("F.1: CheckFinishedSpecification()")
	Do ..CheckFinishedSpecification()
	
	// Stage G: (If Desired) Validate the Specification
	// G.1: Write debug / in-dev info to the specification's description if needed; copy errors and warnings to the specification
	$$$WriteSection("G.1: Copy warnings, errors, and version notes to the specification")
	Set ..Specification.Warnings = ..Warnings
	Set ..Specification.Errors = ..Errors
	Set ..Specification.DispatchClass = ..DispatchClass
	If '$Piece(..Specification.Info.Version,".") {
		Set ..Specification.Info.Description = ..Specification.Info.Description _ "***This is an initial development build!*** (see [https://semver.org/](https://semver.org/))" _ $c(10)
	}
	If ..DEBUG {
		Set:..Specification.Errors.Count() ..Specification.Info.Description = ..Specification.Info.Description _ $c(10,10) _ "---" _ $c(10,10) _ "# Errors" _ $c(10)
		For i=1:1:..Specification.Errors.Count() {
			Set ..Specification.Info.Description = ..Specification.Info.Description _ "- " _ ..Specification.Errors.GetAt(i) _ $c(10)
		}
		Set:..Specification.Warnings.Count() ..Specification.Info.Description = ..Specification.Info.Description _ $c(10,10) _ "---" _ $c(10,10) _ "# Warnings" _ $c(10)
		For i=1:1:..Specification.Warnings.Count() {
			Set ..Specification.Info.Description = ..Specification.Info.Description _ "- " _ ..Specification.Warnings.GetAt(i) _ $c(10)
		}
	}
	// G.2: Validate the specification (if desired)
	Set validateDebugLevel = ..DEBUG-1
	Set:validateDebugLevel<0 validateDebugLevel = 0
	$$$WriteSection("G.2: Validate for return")
	Set return = ..Specification.Validate(,validateDebugLevel,0)
	
	// G.3: Add information on validation fails to the specification if needed
	If ..DEBUG && 'return {
		$$$WriteSection("G.3: Add validation fails to the specification")
		Set buffer = ##class(%pkg.isc.json.util.buffer).%New()
		Set validationText=""
		Set errorsStore = ..Specification.Errors.%ConstructClone()
		Set warningsStore = ..Specification.Warnings.%ConstructClone()
		Do ..Specification.Errors.Clear()
		Do ..Specification.Warnings.Clear()
		Do buffer.BeginCaptureOutput()
		Do ..Specification.Validate(,2,0)
		Do buffer.EndCaptureOutput(.validationText)
		Set ..Specification.Errors = errorsStore
		Set ..Specification.Warnings = warningsStore
		Set validationText = $ZStrip(validationText,"<>W")
		Set validationLines = $ListFromString(validationText,$c(10))
		If $Length(validationText) {
			Set ..Specification.Info.Description = ..Specification.Info.Description _ $c(10,10) _ "---" _ $c(10,10) _ "# Validation Failures" _ $c(10)
			For i=1:1:$ListLength(validationLines) {
				Set validationLine = $ZStrip($ListGet(validationLines, i),"<>W")
				Set ..Specification.Info.Description = ..Specification.Info.Description _ "- " _ validationLine _ $c(10)
			}
		}
	}
	
	// Finish + return
	// $$$TimerEnd is needed because there aren't going to be any more sections
	// ($$$WriteSection automatically calls $$$TimerEnd for the previous section)
	$$$TimerEnd
	Write:..DEBUG "Total execution time: " _ $$$TimerMSSince(initialTime) _ "ms",!
	Return return
}

Method HandleClassOverrides()
{
	Set allSchemas = ..Specification.GetAllFromSpec(..Specification, "%pkg.isc.rest.openAPI.model.schema")
	Set allPaths = ..Specification.GetAllFromSpec(..Specification, "%pkg.isc.rest.openAPI.model.paths")
	Set schemasMap = ##class(%ArrayOfObjects).%New()
	Set endpointsMap = ##class(%ArrayOfObjects).%New()
	Set endpointsList = ##class(%ArrayOfObjects).%New()
	For i=1:1:allSchemas.Count() {
		Set schema = allSchemas.GetAt(i)
		Continue:schema.SourceStub.ClassName=""
		Set arr = schemasMap.GetAt(schema.SourceStub.ClassName)
		If arr="" {
			Set list = ##class(%ListOfObjects).%New()
			Set arr = ##class(%pkg.isc.rest.openAPI.model.paths).%New()
			Set arr.UserMethodClass = schema.SourceStub.ClassName
			Set list2 = ##class(%ListOfDataTypes).%New()
			Do schemasMap.SetAt(list, schema.SourceStub.ClassName)
			Do endpointsMap.SetAt(arr, schema.SourceStub.ClassName)
			Do endpointsList.SetAt(list2, schema.SourceStub.ClassName)
			If schema.SourceStub.ResourceName'="" {
				For j=1:1:allPaths.Count() {
					Set url="", endpoint = allPaths.GetAt(j).GetNext(.url)
					While url'="" {
						If endpoint.SourceClasses.Find(schema.SourceStub.ClassName)'="" {
							Do arr.SetAt(endpoint, url)
							Do list2.Insert(url)
						}
						Set endpoint = allPaths.GetAt(j).GetNext(.url)
					}
				}
			}
		}
		Do list.Insert(schema)
	}
	Set className="", classSchemas= schemasMap.GetNext(.className)
	While className'="" {
		Set classEndpoints = endpointsMap.GetAt(className)
		Set classEndpointsList = endpointsList.GetAt(className)
		Set method = ##class(%Dictionary.CompiledMethod).%OpenId(className_"||ModifyOpenAPIInfo",,.sc)
		If '$System.Status.IsError(sc) && 'method.Abstract {
			Try {
				Do $ClassMethod(className, "ModifyOpenAPIInfo", .classSchemas, .classEndpoints)
				Set url="", endpoint = classEndpoints.GetNext(.url)
				While url'="" {
					Do ..Specification.Paths.SetAt(endpoint, url)
					Set endpoint = classEndpoints.GetNext(.url)
				}
				For i=1:1:classEndpointsList.Count() {
					Set url = classEndpointsList.GetAt(i)
					If classEndpoints.GetAt(url)="" {
						Do ..Specification.Paths.RemoveAt(url)
					}
				}
			} Catch ex {
				Do ..Error($System.Status.GetErrorText(ex.AsStatus()))
			}
		}
		Set classSchemas = schemasMap.GetNext(.className)
	}
	If ##class(%Dictionary.CompiledMethod).%OpenId(..DispatchClass_"||ModifyOpenAPISpecification")'="" {
		Try {
			Do $ClassMethod(..DispatchClass, "ModifyOpenAPISpecification", ..Specification)
		} Catch e {
			Do ..Error("Error " _ $system.Status.GetErrorText(e.AsStatus()) _ " in " _ ..DispatchClass _ ":ModifyOpenAPISpecification")
		}
	}
	Do ..Specification.GenerateRefKeys()
}

Method CheckFinishedSpecification()
{
	// Warn if no security objs are defined
	If '..Specification.Security.Count() {
		Do ..Warn("No security schemes are defined, consider supplying one by setting specification.Security in " _ ..DispatchClass _ ":ModifyOpenAPISpecification")
	}
	// APIVersion warnings
	Set apiVersionOverwritten = (..Specification.Info.Version '= $Parameter(..DispatchClass,"APIVersion"))
	If '$Match(..Specification.Info.Version, ##class(%pkg.isc.rest.openAPI.util).#SEMVERREGEX) {
		If 'apiVersionOverwritten {
			Do ..Warn("APIVersion parameter in class " _ ..DispatchClass _ " is not formatted as a Semantic Version number")
		} Else {
			Do ..Warn("APIVersion parameter set by method " _ ..DispatchClass _ ":ModifyOpenAPISpecification is not formatted as a Semantic Version number")
		}
	}
	Set apiVersionParameter = ##class(%Dictionary.CompiledParameter).%OpenId(..DispatchClass_"||APIVersion")
	If ('$IsObject(apiVersionParameter) || (apiVersionParameter.Origin="%pkg.isc.rest.handler")) && 'apiVersionOverwritten {
		Do ..Warn("APIVersion parameter should be set in handler class " _ ..DispatchClass _ " (to a SemVer version number)")
	}
	Set checkPermissionMethod = ##class(%Dictionary.CompiledMethod).%OpenId(..DispatchClass_"||CheckPermission")
	If ('$IsObject(checkPermissionMethod) || (checkPermissionMethod.Origin="%pkg.isc.rest.handler")) {
		Do ..Warn("The CheckPermission method is not overwritten in " _ ..DispatchClass _ "; access to all documentation-related endpoints will be denied")
	}
}

Method CorrectBrokenEndpoints()
{
	Set regenerateRefKeys = 0
	// Warn if endpoint parameters / returns use non-overwritten %DynamicObject / %DynamicArray types
	Set pathItems = ..Specification.GetAllFromSpec(..Specification, "%pkg.isc.rest.openAPI.model.pathItem")
	For i=1:1:pathItems.Count() {
		Set pathItem = pathItems.GetAt(i)
		#Dim pathItem As %pkg.isc.rest.openAPI.model.pathItem
		Set parameters = pathItem.GetAllFromSpec(pathItem, "%pkg.isc.rest.openAPI.model.parameterOrReference")
		For j=1:1:parameters.Count() {
			Set parameter = parameters.GetAt(j)
			If ($IsObject(parameter) && parameter.IsReference()) {
				Set parameter = ..Specification.ResolveReference(parameter.Ref, ..Specification)
			}
			#Dim parameter As %pkg.isc.rest.openAPI.model.parameter
			Set schemas = parameter.GetAllFromSpec(parameter, "%pkg.isc.rest.openAPI.model.schemaOrReference")
			For k=1:1:schemas.Count() {
				Set schema = schemas.GetAt(k)
				If ($IsObject(schema) && schema.IsReference()) {
					Set schema = ..Specification.ResolveReference(schema.Ref, ..Specification)
				}
				Continue:'$IsObject(schema)
				#Dim schema As %pkg.isc.rest.openAPI.model.schema
				If schema.SourceStub.ClassName = "%Library.DynamicObject" || (schema.SourceStub.ClassName = "%Library.DynamicArray") {
					Try {
						Set operation = parameter.GetContainingObject(..Specification)
						#Dim operation As %pkg.isc.rest.openAPI.model.operation
						If pathItem.EndpointType = "action" {
							Set argumentTarget="", checkArgument = operation.SourceActionInfo.Arguments.GetNext(.argumentTarget)
							While argumentTarget'="" {
								If (checkArgument.Name = parameter.Name) && (checkArgument.Source = parameter.In) {
									Quit
								}
								Set checkArgument = operation.SourceActionInfo.Arguments.GetNext(.argumentTarget)
							}
							Do ..Warn("Action " _ operation.SourceActionInfo.Class _ ":" _ operation.SourceActionInfo.CodeSource _ " argument " _ argumentTarget _ " is a dynamic array / object, consider providing an alternate schema using " _ operation.SourceActionInfo.Class _ ":ModifyOpenAPIInfo")
						} ElseIf pathItem.EndpointType = "resource" {
							Do ..Warn("Resource endpoint for " _ parameter.SourceClasses.GetAt(1) _ " has a dynamic array / object argument " _ parameter.Name _ ", consider providing an alternate schema using " _ parameter.SourceClasses.GetAt(1) _ ":ModifyOpenAPIInfo")
						} Else {
							Do ..Warn("Endpoint " _ ..Specification.GetReference(..Specification, pathItem) _ " has dynamic array / object argument " _ parameter.Name _ ", consider providing an alternate schema using " _ parameter.SourceClasses.GetAt(1) _ ":ModifyOpenAPIInfo")
						}
					} Catch ex {
						Do ..Warn("Endpoint " _ ..Specification.GetReference(..Specification, pathItem) _ " has dynamic array / object argument " _ parameter.Name _ ", consider providing an alternate schema using the ModifyOpenAPIInfo classmethod")
					}
				}
			}
		}
		Set requestBodies = pathItem.GetAllFromSpec(pathItem, "%pkg.isc.rest.openAPI.model.requestBodyOrReference")
		For j=1:1:requestBodies.Count() {
			Set requestBody = requestBodies.GetAt(j)
			If ($IsObject(requestBody) && requestBody.IsReference()) {
				Set requestBody = ..Specification.ResolveReference(requestBody.Ref, ..Specification)
			}
			#Dim requestBody As %pkg.isc.rest.openAPI.model.requestBody
			Set schemas = requestBody.GetAllFromSpec(requestBody, "%pkg.isc.rest.openAPI.model.schemaOrReference")
			For k=1:1:schemas.Count() {
				Set schema = schemas.GetAt(k)
				If ($IsObject(schema) && schema.IsReference()) {
					Set schema = ..Specification.ResolveReference(schema.Ref, ..Specification)
				}
				Continue:'$IsObject(schema)
				If schema.SourceStub.ClassName = "%Library.DynamicObject" || (schema.SourceStub.ClassName = "%Library.DynamicArray") {
					Try {
						Set schemaContainingPropName = $Piece(..Specification.GetReference(..Specification, schemas.GetAt(k), 1),$c(0),*)
						Set operation = requestBody.GetContainingObject(..Specification)
						If pathItem.EndpointType = "action" {
							Set argumentTarget="", checkArgument = operation.SourceActionInfo.Arguments.GetNext(.argumentTarget)
							While argumentTarget'="" {
								If checkArgument.Source = "body" || (checkArgument.Source = "body-key" && (checkArgument.Name = schemaContainingPropName)) {
									Quit
								}
								Set checkArgument = operation.SourceActionInfo.Arguments.GetNext(.argumentTarget)
							}
							Do ..Warn("Action " _ operation.SourceActionInfo.Class _ ":" _ operation.SourceActionInfo.CodeSource _ " argument " _ argumentTarget _ " is a dynamic array / object, consider providing an alternate schema using " _ operation.SourceActionInfo.Class _ ":ModifyOpenAPIInfo")
						} ElseIf pathItem.EndpointType = "resource" {
							Do ..Warn("Resource endpoint for " _ requestBody.SourceClasses.GetAt(1) _ " has a dynamic array / object request body, consider providing an alternate schema using " _ requestBody.SourceClasses.GetAt(1) _ ":ModifyOpenAPIInfo")
						} Else {
							Do ..Warn("Endpoint " _ ..Specification.GetReference(..Specification, pathItem) _ " has a dynamic array / object request body, consider providing an alternate schema using " _ requestBody.SourceClasses.GetAt(1) _ ":ModifyOpenAPIInfo")
						}
					} Catch ex {
						Do ..Warn("Endpoint " _ ..Specification.GetReference(..Specification, pathItem) _ " has a dynamic array / object request body, consider providing an alternate schema using the ModifyOpenAPIInfo classmethod")
					}
				}
			}
		}
		Set responses = pathItem.GetAllFromSpec(pathItem, "%pkg.isc.rest.openAPI.model.responseOrReference")
		For j=1:1:responses.Count() {
			Set response = responses.GetAt(j)
			If ($IsObject(response) && response.IsReference()) {
				Set response = ..Specification.ResolveReference(response.Ref, ..Specification)
			}
			#Dim response As %pkg.isc.rest.openAPI.model.response
			Set schemas = response.GetAllFromSpec(response, "%pkg.isc.rest.openAPI.model.schemaOrReference")
			For k=1:1:schemas.Count() {
				Set schema = schemas.GetAt(k)
				If ($IsObject(schema) && schema.IsReference()) {
					Set schema = ..Specification.ResolveReference(schema.Ref, ..Specification)
					If '$IsObject(schema) {
						// See the warning below for this section
						Set operation = response.GetContainingObject(..Specification)
						// Breaking at $c(1):* gets you to after the last passthroughobject in the spec (a PathItem), then 4 $c(0) forward is the mediatype (nothing -> operation -> content -> mediatype)
						Set schemaMediatype = $Piece($Piece(..Specification.GetReference(..Specification, schemas.GetAt(k), 1),$c(1),*),$c(0),4)
						Set url = $Piece(..Specification.GetReference(..Specification, pathItem, 1),$c(0),*)
						Set method = $Piece(..Specification.GetReference(..Specification, operation, 1),$c(0),*)
						Do ..Warn("Removed non-error HTTP results for " _ url _ ":" _ $ZConvert(method,"U") _ " with the " _ schemaMediatype _ " mediatype due to a broken schema (Note: this warning is just for completeness, the underlying cause should already be reported as an error)")
						Set opResponses = operation.Responses
						Set op200Response = opResponses.GetAt("200")
						If $IsObject(op200Response) && ($ClassName(op200Response)'="%pkg.isc.rest.openAPI.model.response") {
							Set op200Response = ..Specification.ResolveReference(op200Response.Ref, ..Specification)
						}
						If op200Response = response {
							Set key=""
							Set checkResponse = opResponses.GetNext(.key)
							#Dim checkResponse As %pkg.isc.rest.openAPI.model.response
							While key'="" {
								If (key '= "406") && (key '= "403") && (key '= "500") {
									// Don't bother trying to deal with referenced responses here, 403 is the only natively generated one anyway
									Continue:$ClassName(checkResponse)'="%pkg.isc.rest.openAPI.model.response"
									Do checkResponse.Content.RemoveAt(schemaMediatype)
									If 'checkResponse.Content.Count() {
										Do opResponses.RemoveAt(key)
										Set key = ""
									}
									Set regenerateRefKeys = 1
								}
								Set checkResponse = opResponses.GetNext(.key)
							}
						} Else {
							Do ..Error("Broken schema at location " _ ..Specification.GetReference(..Specification, schemas.GetAt(k)) _ " could not be fixed; this may cause actual behavior to differ from the specification")
						}
					}
				}
				Continue:'$IsObject(schema)
				If schema.SourceStub.ClassName = "%Library.DynamicObject" || (schema.SourceStub.ClassName = "%Library.DynamicArray") {
					Try {
						Set operation = response.GetContainingObject(..Specification)
						If pathItem.EndpointType = "action" {
							Do ..Warn("Action " _ operation.SourceActionInfo.Class _ ":" _ operation.SourceActionInfo.CodeSource _ " has a dynamic array / object response, consider providing an alternate schema using " _ operation.SourceActionInfo.Class _ ":ModifyOpenAPIInfo")
						} ElseIf pathItem.EndpointType = "resource" {
							Do ..Warn("Resource endpoint for " _ response.SourceClasses.GetAt(1) _ " has a dynamic array / object response, consider providing an alternate schema using " _ response.SourceClasses.GetAt(1) _ ":ModifyOpenAPIInfo")
						} Else {
							Do ..Warn("Endpoint " _ ..Specification.GetReference(..Specification, pathItem) _ " has dynamic array / object response, consider providing an alternate schema using " _ response.SourceClasses.GetAt(1) _ ":ModifyOpenAPIInfo")
						}
					} Catch ex {
						Do ..Warn("Endpoint " _ ..Specification.GetReference(..Specification, pathItem) _ " has dynamic array / object response, consider providing an alternate schema using the ModifyOpenAPIInfo classmethod")
					}
				}
			}
			If $$$comMemberDefined($classname(response),$$$cCLASSproperty,"Content") {
				Set key = "", mediatype = response.Content.GetNext(.key)
				While key '= "" {
					#Dim mediatype As %pkg.isc.rest.openAPI.model.mediaType
					Set schema = mediatype.Schema
					If ($IsObject(schema) && schema.IsReference()) {
						Set schema = ..Specification.ResolveReference(schema.Ref, ..Specification)
					}
					If schema.Type '= "object" && (schema.Type '= "array") && schema.AutoGenerated {
						// See the warning below for this section
						Set operation = response.GetContainingObject(..Specification)
						Set url = $Piece(..Specification.GetReference(..Specification, pathItem, 1),$c(0),*)
						Set method = $Piece(..Specification.GetReference(..Specification, operation, 1),$c(0),*)
						Set opResponses = operation.Responses
						Set op200Response = opResponses.GetAt("200")
						If $IsObject(op200Response) && ($ClassName(op200Response)'="%pkg.isc.rest.openAPI.model.response") {
							Set op200Response = ..Specification.ResolveReference(op200Response.Ref, ..Specification)
						}
						If op200Response = response {
							Do ..Warn("Adjusted endpoint " _ url _ ":" _ $ZConvert(method,"U") _ " with mediatype " _ key _ " and a non-JSONify-able return schema to not return a value")
							Do opResponses.RemoveAt("200")
							Set nocontentResponse = ##class(%pkg.isc.rest.openAPI.model.response).%New()
							Set nocontentResponse.Description = "Success, nothing to return."
							Do opResponses.SetAt(nocontentResponse, "204")
							Set regenerateRefKeys = 1
						}
					}
					Set mediatype = response.Content.GetNext(.key)
				}
			}
		}
	}
	Do:regenerateRefKeys ..Specification.GenerateRefKeys()
}

Method RemoveForbiddenEndpoints()
{
	Set key="", pathItem = ..Specification.Paths.GetNext(.key)
	While key '= "" {
		If $ClassName(pathItem) '= "%pkg.isc.rest.openAPI.model.pathItem" {
			Set pathItem = ..Specification.ResolveReference(pathItem.Ref, ..Specification)
		}
		#Dim pathItem As %pkg.isc.rest.openAPI.model.pathItem
		#Define CheckMethod(%httpmethod) ##Continue
		If $IsObject(pathItem.%httpmethod) { ##Continue
			Set status="" ##Continue
			Set remove = 1 ##Continue
			If $IsObject(pathItem.%httpmethod.Responses) { ##Continue
				Do pathItem.%httpmethod.Responses.GetNext(.status) ##Continue
				While status '= "" { ##Continue
					If ($Extract(status,1) = "2" && ($Length(status)=3)) || (status = "default") { ##Continue
						Set remove = 0 ##Continue
						Quit ##Continue
					} ##Continue
					Do pathItem.%httpmethod.Responses.GetNext(.status) ##Continue
				} ##Continue
			} ##Continue
			If remove { ##Continue
				Set ..Specification.Paths.GetAt(key).%httpmethod = "" ##Continue
			} ##Continue
		}
		$$$CheckMethod(Get)
		$$$CheckMethod(Put)
		$$$CheckMethod(Post)
		$$$CheckMethod(Delete)
		$$$CheckMethod(Trace)
		$$$CheckMethod(Options)
		$$$CheckMethod(Head)
		If '$IsObject(pathItem.Get) && '$IsObject(pathItem.Put) && '$IsObject(pathItem.Post) && '$IsObject(pathItem.Delete) && '$IsObject(pathItem.Trace) && '$IsObject(pathItem.Options) && '$IsObject(pathItem.Head) {
			Do ..Specification.Paths.RemoveAt(key)
			Set key = ""
		}
		Set pathItem = ..Specification.Paths.GetNext(.key)
	}
	Do ..Specification.GenerateRefKeys()
}

Method Reset()
{
	Set ..Specification = ##class(%pkg.isc.rest.openAPI.model.openAPI).%New()
	Set ..Specification.Paths = ##class(%pkg.isc.rest.openAPI.model.paths).%New()
	Do ..Warnings.Clear()
	Do ..Errors.Clear()
	Do ..ResourceInfo.Clear()
	Do ..ActionInfo.Clear()
	Do ..NeededClasses.Clear()
	Do ..FinishedClasses.Clear()
	Do ..OverwriteSchemas.Clear()
}

Method Warn(message)
{
	Write:..DEBUG&&(..DEBUG'=3) *27,"[59mWarning:",*27,"[0m " _ message,!
	Do ..Warnings.Insert(message)
}

Method WarnOnce(message)
{
	If '..Warnings.Find(message) {
		Do ..Warn(message)
	}
}

Method Error(message)
{
	Write:..DEBUG&&(..DEBUG'=3) *27,"[54mError:",*27,"[0m " _ message,!
	Do ..Errors.Insert(message)
}

Method ErrorOnce(message)
{
	If '..Errors.Find(message) {
		Do ..Error(message)
	}
}

Method CleanSpecification()
{
	// Trim unnecessary schemas from the specification
	Do ..Specification.TrimSchemas()
	
	// Get all the schemas new nice names, because previously-unavailable names might have become available
	Set references = ..Specification.GetAllFromSpec(..Specification, "%pkg.isc.rest.openAPI.model.reference")
	Do ..ClassMappings.Clear()
	Set schemas = ..Specification.Components.Schemas.%ConstructClone()
	
	Set key = "", schema = schemas.GetNext(.key)
	While key'="" {
		Set schemaRef = ..Specification.GetReference(..Specification, schema, 1)
		If '$Match(schemaRef, "#"_$c(0)_"components"_$c(0)_"schemas"_$c(0)_"(JSONError|TextError)") && $IsObject(schema.SourceStub) {
			//Write "Stub for " _ key _ " is " _ schema.SourceStub
			Set schemaNiceName = ..GetNiceName(schema.SourceStub)
			//Write " -> " _ schemaNiceName _ "_" _ schema.SourceDirection,!
			Do ..Specification.Components.Schemas.RemoveAt(key)
			Set newName = schemaNiceName _ "_" _ schema.SourceDirection
			Do ..Specification.Components.Schemas.SetAt(schema, "$NEW:"_newName)
			Set newSchemaRef = "#/components/schemas/" _ newName
			For i=1:1:references.Count() {
				Set:references.GetAt(i).Ref=$Replace(schemaRef,$c(0),"/") references.GetAt(i).Ref = "$NEW:"_newSchemaRef
			}
		}
		Set schema = schemas.GetNext(.key)
	}
	
	For i=1:1:references.Count() {
		Set:$Match(references.GetAt(i).Ref,"\$NEW:.*") references.GetAt(i).Ref = $Extract(references.GetAt(i).Ref,6,*)
	}
	Set schemas = ..Specification.Components.Schemas.%ConstructClone()
	Set key="", schema = schemas.GetNext(.key)
	While key'="" {
		If $Match(key,"\$NEW:.*") {
			Do ..Specification.Components.Schemas.RemoveAt(key)
			Do ..Specification.Components.Schemas.SetAt(schema, $Extract(key,6,*))
		}
		Set schema = schemas.GetNext(.key)
	}
	
	// Re-generate reference keys, because we might have changed the specification's elements
	Do ..Specification.GenerateRefKeys()
}

Method GetWebApplicationInfo() [ Internal, Private ]
{
	// Namespace switching
	New $NAMESPACE
	Set $NAMESPACE = "%SYS"
	
	// Get the relevent fields
	Set appSpec = $ClassMethod("Security.Applications", "%OpenId", $Extract(..APIRoot, 1, *-1))
	Set ..DispatchClass = appSpec.DispatchClass
	Set ..TwoFactor = appSpec.TwoFactorEnabled
	Set ..Description = appSpec.Description
	Set ..AuthMethod = appSpec.AutheEnabled
	Set ..Namespace = appSpec.NameSpace
	
	// Figure out URLs
	If ..Endpoint = "" {
		$$$ThrowOnError(##class(%Studio.General).GetWebServerPort(,,,.url))
		Set webRoot = $Extract(url,1,*-1) // Remove trailing slash
		Set ..Endpoint = webRoot _ appSpec.%Id()
	
		// Get class reference endpoint (for external documentation links)
		// TODO: Dont hardcode this! (its not hard to find...)
		// TODO: Properly handle when there is no documentation server locally
		// TODO: User-specifiable documentation url?
		Set ..ClassReferenceURL = webRoot _ "/csp/documatic/"
	}
}

Method CollectResourceInfo() [ Internal, Private ]
{
	// Get resource info from the %pkg.isc.rest.resourceMap table
	Set query = "select MediaType, ResourceClass, ResourceName from %pkg_isc_rest.resourceMap where DispatchClass = ?"
	Set result = ##class(%SQL.Statement).%ExecDirect(,query,..DispatchClass)
	If result.%SQLCODE < 0 {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message)
	}
	
	// Get ResourceInfo objects for all the resources we read
	While result.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(result.ResourceClass, $Parameter(result.ResourceClass, "JSONMAPPING"), result.ResourceName, result.MediaType)
		Do stub.PopulateNonOverwrittenValues()
		Set resourceInfo = ##class(%pkg.isc.rest.openAPI.resourceInfo).FromStub(stub, $This)
		Do ..OnResourceInfoRetrieval(resourceInfo)
	}
	
	// Generate schemas for overwritten methods as-needed
	For i=1:1:..ResourceInfo.Count() {
		Set resourceSchema = ..ResourceInfo.GetAt(i)
		
		// Generate a "fixed" GetCollection schema if the method returns something non-standard
		// TODO: Do this for some of the other methods too
		// NOTE: This setup _cannot_ be replaced with a ..GetSchema() call
		#Dim expectedCollectionSchema As %pkg.isc.rest.openAPI.model.schema
		Set expectedCollectionSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
		Set expectedCollectionSchema.AutoGenerated = 1
		Do expectedCollectionSchema.SourceClasses.Insert(resourceSchema.ClassName)
		Set expectedCollectionSchema.Type = "array"
		Set expectedCollectionSchema.Items = resourceSchema.OpenAPIOutputSchema
		Do ##class(%pkg.isc.rest.openAPI.schema).ReconcileFoundMethodSchema(expectedCollectionSchema, ##class(%pkg.isc.rest.openAPI.schema).GenerateSchemaIfOverwritten(resourceSchema.ClassName, "GetCollection"), .collectionSchema, .severity, 1)
		Set expectedCollectionSchema.SourceStub = resourceSchema
		#Dim collectionSchema As %pkg.isc.rest.openAPI.model.schema
		Set collectionSchema = collectionSchema.%ConstructClone(1)
		Set collectionSchema.AutoGenerated = 1
		For j=1:1:expectedCollectionSchema.SourceClasses.Count() {
			Do collectionSchema.SourceClasses.Insert(expectedCollectionSchema.SourceClasses.GetAt(j))
		}
		Do collectionSchema.SetExtendedProperty("uncertainty", severity)
		Set collectionSchema.ReadOnly = 1
		If '..HideInternalInfo {
			Set docs = ##class(%pkg.isc.rest.openAPI.model.externalDocumentation).%New()
			Set docs.URL = ..ClassReferenceURL _ "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY=" _ ..Namespace _ "&CLASSNAME=" _ resourceSchema.ClassName
			Set docs.Description = resourceSchema.ClassName _ " InterSystems Class Reference"
			Set collectionSchema.ExternalDocumentation = docs
		}
		Set collectionSchema.SourceDirection = "collection"
		Do:(severity'=0) ..OverwriteSchemas.SetAt(collectionSchema, ..GetNiceName(resourceSchema)_"_collection")
	}
}

/// Note: Must be non-private for unit tests to work
Method CollectActionInfo() [ Internal ]
{
	// Get action info from the %pkg.isc.rest.actionMap table
	Set query = "select AcceptsOrNUL, ActionName, ActionTarget, HTTPVerb, ImplementationClass, MediaTypeOrNUL, ResourceClass, ResourceName from %pkg_isc_rest.actionMap where DispatchClass = ?"
	Set result = ##class(%SQL.Statement).%ExecDirect(,query,..DispatchClass)
	If result.%SQLCODE < 0 {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message)
	}
	
	// Get ActionInfo objects for all the query results
	While result.%Next(.sc) {
		$$$ThrowOnError(sc)
		Do ##class(%pkg.isc.rest.openAPI.actionInfo).FromQueryValues(result, $This)
	}
}

Method FinalizeSchemas() [ Internal, Private ]
{
	// Get JSON schemas / examples for all the additional classes we need to represent
	While ..NeededClasses.Count() {
		Set stub = ..NeededClasses.GetAt(1)
		Set mapResourceName = ""
		Set mapResourceMediaType = ""
		/// resourceName="", mediatype="", resource=0
		Do ##class(%pkg.isc.rest.openAPI.resourceInfo).FromStub(stub, $This)
		Do ..OnResourceInfoRetrieval(stub)
	}
}

Method FinalizeExamples() [ Internal, Private ]
{
	Set allSchemas = ..Specification.GetAllFromSpec(..Specification.Components, "%pkg.isc.rest.openAPI.model.schema")
	For i=1:1:allSchemas.Count() {
		Set schema = allSchemas.GetAt(i)
		Continue:$Match(schema.GetReference(..Specification, schema), "#/components/schemas/(JSONError|TextError)")
		Set schema.Example = ##class(%pkg.isc.rest.openAPI.example).GetSchemaExample(schema, $This)
	}
}

Method WriteMisc() [ Internal, Private ]
{
	// Setup
	Set ..Specification.Info = ##class(%pkg.isc.rest.openAPI.model.info).%New()
	
	// Generate a title for the API
	Set apiPathTitle = $Extract($Replace(..APIRoot, "/", "-"), 1, *-1)
	Set ..Specification.Info.Title = apiPathTitle
	
	// Write the specification's version
	Set ..Specification.Info.Version = $Parameter(..DispatchClass, "APIVersion")
	If ..UserContext '= $$$NULLOREF && ('..ForceAuthorizeAllEndpoints) {
		If $IsObject(..UserContext) {
			Set userContextString = ##class(%pkg.isc.rest.openAPI.util).FormatString(..GetNiceName(##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New($ClassName(..UserContext))) _ "-" _ ..UserContext.%Id())
			Set:..UserContext.%Id()="" userContextString = "unsaved-" _ userContextString
		} Else {
			Set userContextString = ##class(%pkg.isc.rest.openAPI.util).FormatString(..UserContext)
		}
		If $Find(..Specification.Info.Version,"+") {
			Set ..Specification.Info.Version = ..Specification.Info.Version _ ".context-" _ userContextString
		} Else {
			Set ..Specification.Info.Version = ..Specification.Info.Version _ "+context-" _ userContextString
		}
	}
	If ..DEBUG {
		If $Find(..Specification.Info.Version,"+") {
			Set ..Specification.Info.Version = ..Specification.Info.Version _ ".debug"
		} Else {
			Set ..Specification.Info.Version = ..Specification.Info.Version _ "+debug"
		}
	}
	If '..HideInternalInfo {
		If $Find(..Specification.Info.Version,"+") {
			Set ..Specification.Info.Version = ..Specification.Info.Version _ ".internal"
		} Else {
			Set ..Specification.Info.Version = ..Specification.Info.Version _ "+internal"
		}
	}
	
	// Write the servers array
	// TODO: Handling of multiple servers (also noted above); simpler customization/parameterization of this
	Set server = ##class(%pkg.isc.rest.openAPI.model.server).%New()
	Set server.URL = ..Endpoint
	Set server.Description = ..Endpoint
	Do ..Specification.Servers.Insert(server)
}

Method WriteSchemas() [ Internal, Private ]
{
	// Write the class JSON schema mappings
	Set ..Specification.Components = ##class(%pkg.isc.rest.openAPI.model.components).%New()
	For i=1:1:..ResourceInfo.Count() {
		Set resourceSchema = ..ResourceInfo.GetAt(i)
		#Dim resourceSchema As %pkg.isc.rest.openAPI.resourceInfo
		Continue:resourceSchema.Invalid
		Do ..Specification.Components.Schemas.SetAt(resourceSchema.OpenAPIOutputSchema, ..GetNiceName(resourceSchema)_"_output")
		Do ..Specification.Components.Schemas.SetAt(resourceSchema.OpenAPIInputSchema, ..GetNiceName(resourceSchema)_"_input")
		Do:resourceSchema.OpenAPIInputSchema.Required'="" ..Specification.Components.Schemas.SetAt(resourceSchema.GetUpdateSchema(), ..GetNiceName(resourceSchema)_"_update")
	}
	
	// Write schemas for method overwrites
	Set name = "", schema = ..OverwriteSchemas.GetNext(.name)
	While name '="" {
		Do ..Specification.Components.Schemas.SetAt(schema, name)
		Set schema = ..OverwriteSchemas.GetNext(.name)
	}
	
	// Write error schemas
	Do ..WriteErrorSchemas()
	Do ..WriteQueryFilterSchema()
}

Method WriteQueryFilterSchema() [ Internal, Private ]
{
	/*
            "QueryFilter": {
                "description": "A query filter",
                "example": {
                    "eq": "Foo"
                },
                "properties": {
                    "eq": {
                        "description": "Indicates that the \"Name\" field must be equal to this value.",
                        "type": "string"
                    },
					...
                    "isnull": {
                        "description": "Indicates that the \"Name\" field must be null.",
                        "nullable": true,
                        "type": "string"
                    },
					...
                    "stwith": {
                        "description": "Indicates that the \"Name\" field must start with this value.",
                        "type": "string"
                    }
                },
				"required": [],
				"type": "object",
				"writeOnly": true
            },
	*/
	Set comparisons = $ListFromString("lte,gte,eq,leq,geq,stwith,isnull,notlte,notgte,noteq,notleq,notgeq,notstwith,notisnull")
	Set descriptions = $ListBuild("be less than or equal to this value","be greater than or equal to this value","be equal to this value","be less than or equal to this value","be greater than or equal to this value","start with this value","be null")
	// Type for isnull, notisnull should be null instead of string, but the viewer at https://editor.swagger.io/ complains about that for some reason.
	Set types = $ListFromString("integer,integer,string,integer,integer,string,string,integer,integer,string,integer,integer,string,string")
	Set descriptionsLength = $ListLength(descriptions)
	For j=1:1:descriptionsLength {
		Set $List(descriptions,j) = "Indicates that the value of this field field must # "_ $ListGet(descriptions,j) _ "."
	}
	#dim queryFilterSchema As %pkg.isc.rest.openAPI.model.schema
	Set queryFilterSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set queryFilterSchema.AutoGenerated = 1
	Set queryFilterSchema.Description = "A query filter."
	Set queryFilterSchema.Type = "object"
	Set queryFilterSchema.WriteOnly = 1
	For j=1:1:$ListLength(comparisons) {
		#dim parameterSchema As %pkg.isc.rest.openAPI.model.schema
		Set parameterSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
		Set parameterSchema.AutoGenerated = 1
		//Set parameterObj.Name = jsonName _ "[" _ $ListGet(comparisons,j) _ "]"
		Set inNot = j>descriptionsLength
		Set not = $Select(inNot:"not ",1:"")
		Set k = $Select(inNot:j-descriptionsLength,1:j)
		Set parameterSchema.Description = $Replace($ListGet(descriptions,k),"# ",not)
		If ($ListGet(comparisons,j)="isnull") || ($ListGet(comparisons,j)="notisnull") {
			Set parameterSchema.Nullable = 1
		}
		Set parameterSchema.Type = $ListGet(types,j)
		Do queryFilterSchema.Properties.SetAt(parameterSchema, $ListGet(comparisons,j))
	}
	Do ..Specification.Components.Schemas.SetAt(queryFilterSchema, "QueryFilter")
}

Method WriteErrorSchemas() [ Internal, Private ]
{
	// JSON-format error
	Set jsonErrorSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set jsonErrorSchema.AutoGenerated = 1
	Set jsonErrorSchema.Type = "object"
	Set jsonErrorSchema.Description = "An error message / multiple error messages"
	Set summaryProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set summaryProperty.AutoGenerated = 1
	Set summaryProperty.Type = "string"
	Set summaryProperty.Description = "A description of the error(s) that occurred"
	Do jsonErrorSchema.Properties.SetAt(summaryProperty, "summary")
	Set errorsProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set errorsProperty.AutoGenerated = 1
	Set errorsProperty.Type = "array"
	Set errorsProperty.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set errorsProperty.Items.AutoGenerated = 1
	Set errorsProperty.Description = "One of the errors that occurred"
	Set errorsProperty.Description = "An array containing information about each of the errors that occurred"
	Set errorProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set errorProperty.AutoGenerated = 1
	Set errorProperty.Type = "string"
	Set errorProperty.Description = "A string-format representation of the error"
	Do errorsProperty.Items.Properties.SetAt(errorProperty, "error")
	Set codeProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set codeProperty.AutoGenerated = 1
	Set codeProperty.Type = "integer"
	Set codeProperty.Description = "The error code"
	Do errorsProperty.Items.Properties.SetAt(codeProperty, "code")
	Set domainProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set domainProperty.AutoGenerated = 1
	Set domainProperty.Type = "string"
	//Set domainProperty.Description = "TODO: ???"
	Do errorsProperty.Items.Properties.SetAt(domainProperty, "domain")
	Set idProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set idProperty.AutoGenerated = 1
	Set idProperty.Type = "string"
	//Set idProperty.Description = "TODO: ???"
	Do errorsProperty.Items.Properties.SetAt(idProperty, "id")
	Set paramsProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set paramsProperty.AutoGenerated = 1
	Set paramsProperty.Type = "array"
	Set paramsProperty.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set paramsProperty.Items.AutoGenerated = 1
	Set paramsProperty.Items.Type = "string"
	//Set paramsProperty.Items.Description = "TODO: ???"
	//Set paramsProperty.Description = "TODO: ???"
	Do errorsProperty.Items.Properties.SetAt(paramsProperty, "params")
	Set errorsProperty2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set errorsProperty2.AutoGenerated = 1
	Set errorsProperty2.Type = "array"
	Set errorsProperty2.Items = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set errorsProperty2.Items.AutoGenerated = 1
	Set errorsProperty2.Items.Ref = "#/components/schemas/JSONError"
	//Set errorsProperty2.Description = "TODO: ???"
	Do errorsProperty.Items.Properties.SetAt(errorsProperty2, "errors")
	Do jsonErrorSchema.Properties.SetAt(errorsProperty, "errors")
	Do ..Specification.Components.Schemas.SetAt(jsonErrorSchema, "JSONError")
	// Non-JSON-format error
	Set textErrorSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set textErrorSchema.AutoGenerated = 1
	Set textErrorSchema.Type = "string"
	Set textErrorSchema.Description = "A string-format representation of the error that occurred"
	Do ..Specification.Components.Schemas.SetAt(textErrorSchema, "TextError")
	// HTTP 403 Response
	Set response403 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response403.Description = "Forbidden: Authentication Failure"
	Set ..Specification.Components.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	Do ..Specification.Components.Responses.SetAt(response403, "403")
}

Method WriteResourceEndpoints() [ Internal, Private ]
{
	#define ResourcePathNotForbidden(%arg) (resourceSchema.Supports%arg && (((..IncludeForbiddenEndpoints || ..ForceAuthorizeAllEndpoints) && ('resourceSchema.ForbidResource%arg || 'resourceSchema.ForbidUnderAllCircumstances)) || 'resourceSchema.ForbidResource%arg))

	// TODO: GetModelFromResultRow() support
	// TODO: What HTTP Code is thrown when an id can't be found?
	
	// Error mediatypes (so we don't need to redefine them every time)
	Set errorMediatypePlain = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set errorMediatypePlain.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set errorMediatypePlain.Schema.AutoGenerated = 1
	Set errorMediatypePlain.Schema.Ref = "#/components/schemas/TextError"
	Set errorMediatypeJSON = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set errorMediatypeJSON.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set errorMediatypeJSON.Schema.AutoGenerated = 1
	Set errorMediatypeJSON.Schema.Ref = "#/components/schemas/JSONError"
				
	// Write the resource endpoints
	For i=1:1:..ResourceInfo.Count() {
		Set resourceSchema = ..ResourceInfo.GetAt(i)
		If resourceSchema.ResourceEndpointsEnabled {
			#Dim pathObj As %pkg.isc.rest.openAPI.model.pathItem
			Set pathObj = ..Specification.Paths.GetAt("/"_resourceSchema.ResourceName)
			If '$IsObject(pathObj) {
				Set pathObj = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
				Set pathObj.EndpointType = "resource"
				Set pathObj.IsInstance = 0
			}
			Do pathObj.SourceClasses.Insert(resourceSchema.ClassName)
			
			// HTTP Get Method
			If $$$ResourcePathNotForbidden(Query) {
				If '$IsObject(pathObj.Get) {
					Set pathObj.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					Set pathObj.Get.Description = "Query the database for " _ resourceSchema.ResourceName _ "s" _ $select('..HideInternalInfo:" (instances of the " _ resourceSchema.RepresentativeClassName _ " class)",1:"") _ "."
					Set pathObj.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
				} Else {
					Set pathObj.Get.Description = "Query the database for " _ resourceSchema.ResourceName _ "s."
				}
				Do pathObj.Get.Tags.Insert(resourceSchema.ResourceName)
				Do pathObj.Get.SourceClasses.Insert(resourceSchema.ClassName)
				Do pathObj.Get.Responses.SourceClasses.Insert(resourceSchema.ClassName)
				
				// Parameter generation
				try {
					// The "nice" way to do this: these are the properties that are reported as being OK to query as reported by DBMappedResource
					Set parametersIterator = $ClassMethod(resourceSchema.ClassName, "getProxyColumnList").%GetIterator()
				} catch (ex) {
					// TODO: Come up with some way to handle classes that don't use DBMappedResource methods, instead of (incorrectly) listing them as having no parameters.
					// TODO: The following methods theoretically perform known operations:
					//         GetCollection, GetModelInstance, DeleteModelInstance, HandleInvokeClassAction, HandleInvokeInstanceAction
					//       In practice, classes can overwrite their behavior (possibly in non-standard ways), such as %pkg.isc.rest.model.environment, which returns a single static object (not wrapped in an array) from the Query endpoint.
					//       Ultimately there's no way to properly handle the range of these modifications without actually running the methods in question, which I'm trying to avoid for the following reasons:
					//         1) Wrt. the HandleInvoke methods, they may cause side-effects that cannot be rolled-back with transactions
					//         2) There is no way to ensure spec accuracy by testing the methods directly, and code-analysis is infeasable in the general case (ignoring its NP-completeness, it would take *forever* to implement with any degree of accuracy)
					//       Fortunately, it should be relatively easy to detect when classes have overwritten the methods.
					//       At the moment, my thought is that the best way to handle this is to do some basic analysis of the "safe" to call methods to make minor modifications to the expected spec, and mark the endpoints as possibly-incorrect somehow
					//       (I will need to look into the OpenAPI spec to see how best to do this). For methods whose responses cannot be reconciled with the expected responses at all, it may suffice to generate schemas based upon their responses and mark
					//       them as incorrect/unsafe as well. For methods that cannot be safely called at all, I need to see if there is any way to mark information as Unknown in the OpenAPI spec (so far as I know, there isn't, so I might need to get
					//       somewhat creative there).
					//       --> What to do about parameters in the case where the method has been overwritten??
					// UPDATE: An initial version of this is implemented with GetCollection()
					Set parametersIterator = {}.%GetIterator()
				}
				While parametersIterator.%GetNext(.jsonName,.realName) {
					// Iterate over all properties / comparison operators to generate parameters for all the combinations
					// TODO: Missing contains / notcontains
					Set comparisons = $ListFromString("lte,gte,eq,leq,geq,stwith,isnull,notlte,notgte,noteq,notleq,notgeq,notstwith,notisnull")
					Set descriptions = $ListBuild("be less than or equal to this value","be greater than or equal to this value","be equal to this value","be less than or equal to this value","be greater than or equal to this value","start with this value","be null")
					// Type for isnull, notisnull should be null instead of string, but the viewer at https://editor.swagger.io/ complains about that for some reason.
					Set types = $ListFromString("integer,integer,string,integer,integer,string,string,integer,integer,string,integer,integer,string,string")
					Set descriptionsLength = $ListLength(descriptions)
					For j=1:1:descriptionsLength {
						Set $List(descriptions,j) = "Indicates that the $ field must # " _ $ListGet(descriptions,j) _ "."
					}
					Set parameterObj = ""
					For j=1:1:pathObj.Get.Parameters.Count() {
						Set existingParameter = pathObj.Get.Parameters.GetAt(j)
						If existingParameter.Name = jsonName && (existingParameter.In = "query") {
							Set parameterObj = pathObj.Get.Parameters.GetAt(j)
							Quit
						}
					}
					// Don't need to generate a parameter if one already exists, because its contents will always be the same
					If parameterObj = "" {
						Set parameterObj = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
						Set parameterObj.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
						Set parameterObj.Schema.AutoGenerated = 1
						Set parameterObj.Schema.Ref = "#/components/schemas/QueryFilter"
						Do parameterObj.SourceClasses.Insert(resourceSchema.ClassName)
						Set parameterObj.Style = "deepObject"
						Set parameterObj.Explode = 1
						Set parameterObj.Required = 1
						Set parameterObj.In = "query"
						Set parameterObj.Name = jsonName
						Set parameterObj.Required = 0
						Do pathObj.Get.Parameters.Insert(parameterObj)
					}
				}
				
				If ..ForceAuthorizeAllEndpoints || 'resourceSchema.ForbidResourceQuery {
					If 'resourceSchema.Invalid {
						// HTTP 200
						Set response200 = pathObj.Get.Responses.GetAt("200")
						#Dim response200 As %pkg.isc.rest.openAPI.model.response
						If '$IsObject(response200) {
							Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
							Set response200.Description = "An array containing all " _ resourceSchema.ResourceName _ "s" _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instances)",1:"") _ " that match the specified query parameters."
						} Else {
							Set response200.Description = "An array containing all " _ resourceSchema.ResourceName _ "s that match the specified query parameters."
						}
						Do response200.SourceClasses.Insert(resourceSchema.ClassName)
						#Dim mediatype As %pkg.isc.rest.openAPI.model.mediaType
						Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
						Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
						Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema, "array", "output", , $this, 1)
						Do schema.SourceClasses.Insert(resourceSchema.ClassName)
						If ..OverwriteSchemas.IsDefined(..GetNiceName(resourceSchema) _ "_collection") {
							Set response200.Description = "The result of querying the " _ resourceSchema.ResourceName _ " collection endpoint. "
							If ..OverwriteSchemas.GetAt(..GetNiceName(resourceSchema)_"_collection").GetExtendedProperty("uncertainty") < 2 {
								Set pathObj.Get.Description = pathObj.Get.Description _ $Char(10,10) _ "<style>warn1{color:blue;font-weight:bold}</style><warn1>The return type of this endpoint follows a non-standard implementation.</warn1>"
							} Else {
								Set pathObj.Get.Description = pathObj.Get.Description _ $Char(10,10) _ "<style>warn2{color:red;font-weight:bold}</style><warn2>The reported return type of this endpoint may contain additional non-documented properties.</warn2>"
							}
							Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,, "collection", , $this, 1)
							Do schema.SourceClasses.Insert(resourceSchema.ClassName)
						}
						Set mediatype.Schema = schema
						Do response200.Content.SetAt(mediatype, resourceSchema.MediaType)
						Do pathObj.Get.Responses.SetAt(response200, "200")
					}
					// HTTP 406
					#Dim response406 As %pkg.isc.rest.openAPI.model.response
					Set response406 = pathObj.Get.Responses.GetAt("406")
					If '$IsObject(response406) {
						Set response406 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response406.SourceClasses.Insert(resourceSchema.ClassName)
					Set response406.Description = "Not Acceptable: The requested mediatype is not compatible with the any supported response mediatypes."
					Do response406.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
					Do response406.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
					Do pathObj.Get.Responses.SetAt(response406, "406")
				}
				// HTTP 403
				#Dim response403 As %pkg.isc.rest.openAPI.model.responseOrReference
				Set response403 = pathObj.Get.Responses.GetAt("403")
				If '$IsObject(response403) {
					Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
				}
				Do response403.SourceClasses.Insert(resourceSchema.ClassName)
				Set response403.Ref = "#/components/responses/403"
				Do pathObj.Get.Responses.SetAt(response403, "403")
			}
			
			// HTTP POST Method
			If $$$ResourcePathNotForbidden(Create) {
				If '$IsObject(pathObj.Post) {
					Set pathObj.Post = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					Set pathObj.Post.Description = "Create a new " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ ", and write it to the database."
					Set pathObj.Post.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
				} Else {
					Set pathObj.Post.Description = "Create a new " _ resourceSchema.ResourceName _ ", and write it to the database."
				}
				Do pathObj.Post.Tags.Insert(resourceSchema.ResourceName)
				Do pathObj.Post.SourceClasses.Insert(resourceSchema.ClassName)
				Do pathObj.Post.Responses.SourceClasses.Insert(resourceSchema.ClassName)
				#Dim requestBody As %pkg.isc.rest.openAPI.model.requestBody
				Set requestBody = pathObj.Post.RequestBody
				If '$IsObject(requestBody) {
					Set requestBody = ##class(%pkg.isc.rest.openAPI.model.requestBody).%New()
					Set requestBody.Description = "The information necessary to create a new " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ "."
					Set requestBody.Required = 1
				} Else {
					Set requestBody.Description = "The information necessary to create a new " _ resourceSchema.ResourceName _ "."
				}
				Do requestBody.SourceClasses.Insert(resourceSchema.ClassName)
				Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
				Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
				Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"input",,$this, 1)
				Do schema.SourceClasses.Insert(resourceSchema.ClassName)
				Set mediatype.Schema = schema
				Do requestBody.Content.SetAt(mediatype, resourceSchema.MediaType)
				Set pathObj.Post.RequestBody = requestBody
				
				If ..ForceAuthorizeAllEndpoints || 'resourceSchema.ForbidResourceCreate {
					If 'resourceSchema.Invalid {
						// HTTP 200
						Set response200 = pathObj.Post.Responses.GetAt("200")
						If '$IsObject(response200) {
							Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
							Set response200.Description = "The newly-created " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ "."
						} Else {
							Set response200.Description = "The newly-created " _ resourceSchema.ResourceName _ "."
						}
						Do response200.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
						Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
						Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"output",,$this, 1)
						Do schema.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype.Schema = schema
						Do response200.Content.SetAt(mediatype, resourceSchema.MediaType)
						Do pathObj.Post.Responses.SetAt(response200, "200")
					}
					// HTTP 415
					#Dim response415 As %pkg.isc.rest.openAPI.model.response
					Set response415 = pathObj.Post.Responses.GetAt("415")
					If '$IsObject(response415) {
						Set response415 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response415.SourceClasses.Insert(resourceSchema.ClassName)
					Set response415.Description = "Unsupported Mediatype: Mediatype is not compatible with any supported request mediatypes."
					Do response415.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
					Do response415.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
					Do pathObj.Post.Responses.SetAt(response415, "415")
				}
				
				// HTTP 403
				Set response403 = pathObj.Post.Responses.GetAt("403")
				If '$IsObject(response403) {
					Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
				}
				Do response403.SourceClasses.Insert(resourceSchema.ClassName)
				Set response403.Ref = "#/components/responses/403"
				Do pathObj.Post.Responses.SetAt(response403, "403")
			}
			If $$$ResourcePathNotForbidden(Query) || $$$ResourcePathNotForbidden(Create) {
				Do ..Specification.Paths.SetAt(pathObj, "/"_resourceSchema.ResourceName)
			}
			
			If $$$ResourcePathNotForbidden(Construct) {
				// Action $new
				Set pathObj = ..Specification.Paths.GetAt("/"_resourceSchema.ResourceName_"/$new")
				If '$IsObject(pathObj) {
					Set pathObj = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
					Set pathObj.EndpointType = "resource"
					Set pathObj.IsInstance = 0
				}
				Do pathObj.SourceClasses.Insert(resourceSchema.ClassName)
				If '$IsObject(pathObj.Get) {
					Set pathObj.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					Set pathObj.Get.ActionName = "new"
					Set pathObj.Get.Description = "Create a new " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ ", but do not write it to the database."
					Set pathObj.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
				} Else {
					Set pathObj.Get.Description = "Create a new " _ resourceSchema.ResourceName _ ", but do not write it to the database."
				}
				Do pathObj.Get.Tags.Insert(resourceSchema.ResourceName)
				Do pathObj.Get.SourceClasses.Insert(resourceSchema.ClassName)
				Do pathObj.Get.Responses.SourceClasses.Insert(resourceSchema.ClassName)
				If ..ForceAuthorizeAllEndpoints || 'resourceSchema.ForbidResourceConstruct {
					If 'resourceSchema.Invalid {
						// HTTP 200
						Set response200 = pathObj.Get.Responses.GetAt("200")
						If '$IsObject(response200) {
							Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
							Set response200.Description = "The newly-created " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ "."
						} Else {
							Set response200.Description = "The newly-created " _ resourceSchema.ResourceName _ "."
						}
						Do response200.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
						Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
						Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"output",,$this,1)
						Do schema.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype.Schema = schema
						Do response200.Content.SetAt(mediatype, resourceSchema.MediaType)
						Do pathObj.Get.Responses.SetAt(response200, "200")
					}
					// HTTP 406
					Set response406 = pathObj.Get.Responses.GetAt("406")
					If '$IsObject(response406) {
						Set response406 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response406.SourceClasses.Insert(resourceSchema.ClassName)
					Set response406.Description = "Unsupported Mediatype: The requested mediatype is not compatible with any supported response mediatypes."
					Do response406.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
					Do response406.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
					Do pathObj.Get.Responses.SetAt(response406, "406")
				}
				// HTTP 403
				Set response403 = pathObj.Get.Responses.GetAt("403")
				If '$IsObject(response403) {
					Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
				}
				Do response403.SourceClasses.Insert(resourceSchema.ClassName)
				Set response403.Ref = "#/components/responses/403"
				Do pathObj.Get.Responses.SetAt(response403, "403")
				Do ..Specification.Paths.SetAt(pathObj, "/"_resourceSchema.ResourceName_"/$new")
			}
			
			Set pathObj = ..Specification.Paths.GetAt("/"_resourceSchema.ResourceName_"/{id}")
			If '$IsObject(pathObj) {
				Set pathObj = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
				Set pathObj.EndpointType = "resource"
				Set pathObj.IsInstance = 1
			}
			Do pathObj.SourceClasses.Insert(resourceSchema.ClassName)
			If $$$ResourcePathNotForbidden(Read) {
				// Resource instance GET
				If '$IsObject(pathObj.Get) {
					Set pathObj.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					Set pathObj.Get.Description = "Get the " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ " whose ID matches the one supplied"
					Set pathObj.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
					Do ..SetIDParameter(pathObj.Get, resourceSchema.ClassName, resourceSchema.MediaType, 1)
				} Else {
					Set pathObj.Get.Description = "Get the " _ resourceSchema.ResourceName _ " whose ID matches the one supplied"
					Do ..SetIDParameter(pathObj.Get, resourceSchema.ClassName, resourceSchema.MediaType)
				}
				Do pathObj.Get.Tags.Insert(resourceSchema.ResourceName)
				Do pathObj.Get.SourceClasses.Insert(resourceSchema.ClassName)
				Do pathObj.Get.Responses.SourceClasses.Insert(resourceSchema.ClassName)
				If ..ForceAuthorizeAllEndpoints || 'resourceSchema.ForbidResourceRead {
					If 'resourceSchema.Invalid {
						// HTTP 200
						Set response200 = pathObj.Get.Responses.GetAt("200")
						If '$IsObject(response200) {
							Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
							Set response200.Description = "A successful response"
						} Else {
							Set response200.Description = "The " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ " whose ID matches the one supplied"
						}
						Do response200.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
						Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
						Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"output",,$this,1)
						Do schema.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype.Schema = schema
						Do response200.Content.SetAt(mediatype, resourceSchema.MediaType)
						Do pathObj.Get.Responses.SetAt(response200, "200")
					}
					// HTTP 406
					Set response406 = pathObj.Get.Responses.GetAt("406")
					If '$IsObject(response406) {
						Set response406 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response406.SourceClasses.Insert(resourceSchema.ClassName)
					Set response406.Description = "Unsupported Mediatype: The requested mediatype is not compatible with any supported response mediatypes."
					Do response406.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
					Do response406.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
					Do pathObj.Get.Responses.SetAt(response406, "406")
				}
				// HTTP 403
				Set response403 = pathObj.Get.Responses.GetAt("403")
				If '$IsObject(response403) {
					Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
				}
				Do response403.SourceClasses.Insert(resourceSchema.ClassName)
				Set response403.Ref = "#/components/responses/403"
				Do pathObj.Get.Responses.SetAt(response403, "403")
			}
			If $$$ResourcePathNotForbidden(Update) {
				// Resource instance PUT
				If '$IsObject(pathObj.Put) {
					Set pathObj.Put = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					Set pathObj.Put.Description = "Update properties of the " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"") _ " whose ID matches the one supplied with the specified values"
					Set pathObj.Put.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
					Do ..SetIDParameter(pathObj.Put, resourceSchema.ClassName, resourceSchema.MediaType, 1)
				} Else {
					Set pathObj.Put.Description = "Update properties of the " _ resourceSchema.ResourceName _ " whose ID matches the one supplied with the specified values"
					Do ..SetIDParameter(pathObj.Put, resourceSchema.ClassName, resourceSchema.MediaType)
				}
				Do pathObj.Put.Tags.Insert(resourceSchema.ResourceName)
				Do pathObj.Put.SourceClasses.Insert(resourceSchema.ClassName)
				Do pathObj.Put.Responses.SourceClasses.Insert(resourceSchema.ClassName)
				// PUT request body
				Set requestBody = pathObj.Put.RequestBody
				If '$IsObject(requestBody) {
					Set requestBody = ##class(%pkg.isc.rest.openAPI.model.requestBody).%New()
				}
				Do requestBody.SourceClasses.Insert(resourceSchema.ClassName)
				Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
				Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
				If resourceSchema.OpenAPIInputSchema.Required'="" {
					Set mediatype.Schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"update",,$this,1)
				} Else {
					Set mediatype.Schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"input",,$this,1)
				}
				Do mediatype.Schema.SourceClasses.Insert(resourceSchema.ClassName)
				Do requestBody.Content.SetAt(mediatype, resourceSchema.MediaType)
				Set pathObj.Put.RequestBody = requestBody
				If ..ForceAuthorizeAllEndpoints || 'resourceSchema.ForbidResourceUpdate {
					If 'resourceSchema.Invalid {
						// HTTP 200
						Set response200 = pathObj.Put.Responses.GetAt("200")
						If '$IsObject(response200) {
							Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
							Set response200.Description = "The updated " _ resourceSchema.ResourceName _ $select('..HideInternalInfo:" (" _ resourceSchema.RepresentativeClassName _ " instance)",1:"")	
						} Else {
							Set response200.Description = "The updated " _ resourceSchema.ResourceName	
						}
						Do response200.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
						Do mediatype.SourceClasses.Insert(resourceSchema.ClassName)
						Set schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(resourceSchema,,"output",,$this,1)
						Do schema.SourceClasses.Insert(resourceSchema.ClassName)
						Set mediatype.Schema = schema
						Do response200.Content.SetAt(mediatype, resourceSchema.MediaType)
						Do pathObj.Put.Responses.SetAt(response200, "200")
					}
					// HTTP 415
					Set response415 = pathObj.Put.Responses.GetAt("415")
					If '$IsObject(response415) {
 						Set response415 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response415.SourceClasses.Insert(resourceSchema.ClassName)
					Set response415.Description = "Unsupported Mediatype: Mediatype is not compatible with any supported request mediatypes."
					Do response415.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
					Do response415.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
					Do pathObj.Put.Responses.SetAt(response415, "415")
				}
				// HTTP 403
				Set response403 = pathObj.Put.Responses.GetAt("403")
				If '$IsObject(response403) {
					Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
				}
				Do response403.SourceClasses.Insert(resourceSchema.ClassName)
				Set response403.Ref = "#/components/responses/403"
				Do pathObj.Put.Responses.SetAt(response403, "403")
			}
			If $$$ResourcePathNotForbidden(Delete) {
				// Resource instance DELETE
				If '$IsObject(pathObj.Delete) {
					Set pathObj.Delete = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					//Set pathObj.Delete.Description = "TODO: This"
					Set pathObj.Delete.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
					Do ..SetIDParameter(pathObj.Delete, resourceSchema.ClassName, resourceSchema.MediaType, 1)
				} Else {
					//Set pathObj.Delete.Description = "TODO: This"
					Do ..SetIDParameter(pathObj.Delete, resourceSchema.ClassName, resourceSchema.MediaType)
				}
				Do pathObj.Delete.Tags.Insert(resourceSchema.ResourceName)
				Do pathObj.Delete.SourceClasses.Insert(resourceSchema.ClassName)
				Do pathObj.Delete.Responses.SourceClasses.Insert(resourceSchema.ClassName)
				If ..ForceAuthorizeAllEndpoints || 'resourceSchema.ForbidResourceDelete {
					If 'resourceSchema.Invalid {
						// HTTP 204
						#Dim response204 As %pkg.isc.rest.openAPI.model.response
						Set response204 = pathObj.Delete.Responses.GetAt("204")
						If '$IsObject(response204) {
							Set response204 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
						}
						Do response204.SourceClasses.Insert(resourceSchema.ClassName)
						Set response204.Description = "The object was successfully deleted."
						Do pathObj.Delete.Responses.SetAt(response204, "204")
					}
					// HTTP 404
					#Dim response404 As %pkg.isc.rest.openAPI.model.response
					Set response404 = pathObj.Delete.Responses.GetAt("404")
					If '$IsObject(response404) {
						Set response404 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response404.SourceClasses.Insert(resourceSchema.ClassName)
					Set response404.Description = "No object with the requested ID could be found."
					Do pathObj.Delete.Responses.SetAt(response404, "404")
					// HTTP 415
					Set response415 = pathObj.Delete.Responses.GetAt("415")
					If '$IsObject(response415) {
						Set response415 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					}
					Do response415.SourceClasses.Insert(resourceSchema.ClassName)
					Set response415.Description = "Unsupported Mediatype: Mediatype is not compatible with any supported request mediatypes."
					Do response415.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
					Do response415.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
					Do pathObj.Delete.Responses.SetAt(response415, "415")
				}
				// HTTP 403
				Set response403 = pathObj.Delete.Responses.GetAt("403")
				If '$IsObject(response403) {
					Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
				}
				Do response403.SourceClasses.Insert(resourceSchema.ClassName)
				Set response403.Ref = "#/components/responses/403"
				Do pathObj.Delete.Responses.SetAt(response403, "403")
			}
			If $$$ResourcePathNotForbidden(Read) || $$$ResourcePathNotForbidden(Update) || $$$ResourcePathNotForbidden(Delete) {
				Do ..Specification.Paths.SetAt(pathObj, "/"_resourceSchema.ResourceName_"/{id}")
			}
		}
	}
}

Method SetIDParameter(ByRef obj, className, classMediatype, classNameInDescription = 0) [ Internal, Private ]
{
	#Dim idParameter As %pkg.isc.rest.openAPI.model.parameter
	Set idParameter = ""
	For i=1:1:obj.Parameters.Count() {
		If obj.Parameters.GetAt(i).Name="id" && (obj.Parameters.GetAt(i).In = "path") {
			Set idParameter = obj.Parameters.GetAt(i)
			Quit
		}
	}
	If idParameter = "" {
		Set idParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
		Do obj.Parameters.Insert(idParameter)
		Set idParameter.In = "path"
		Set idParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
		Set idParameter.Schema.AutoGenerated = 1
		Set idParameter.Schema.Type = "string"
		Set idParameter.Name = "id"
		Set idParameter.Required = 1
	}
	Set:classNameInDescription idParameter.Example = ##class(%pkg.isc.rest.openAPI.example).GetPropertyExample(className, "", "", , "ID")
	Set:'classNameInDescription idParameter.Example = ""
	//Set:classNameInDescription idParameter.Description = "TODO: This!"
	//Set:'classNameInDescription idParameter.Description = "TODO: This!"
	Do idParameter.SourceClasses.Insert(className)
	Do idParameter.Schema.SourceClasses.Insert(className)
}

Method WriteActionEndpoints() [ Internal, Private ]
{
	
	// Error mediatypes
	Set errorMediatypePlain = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set errorMediatypePlain.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set errorMediatypePlain.Schema.AutoGenerated = 1
	Set errorMediatypePlain.Schema.Ref = "#/components/schemas/TextError"
	Set errorMediatypeJSON = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set errorMediatypeJSON.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set errorMediatypeJSON.Schema.AutoGenerated = 1
	Set errorMediatypeJSON.Schema.Ref = "#/components/schemas/JSONError"
	
	// Write the class endpoints here!
	For i=1:1:..ActionInfo.Count() {
		#dim actionSchema As %pkg.isc.rest.openAPI.actionInfo
		Set actionSchema = ..ActionInfo.GetAt(i)
		If ('actionSchema.Supported) && ((actionSchema.Forbidden && actionSchema.ForbidUnderAllCircumstances) ||
		   ('..IncludeForbiddenEndpoints && '..ForceAuthorizeAllEndpoints && actionSchema.Forbidden)) {
			Continue
		}
		#dim pathObj As %pkg.isc.rest.openAPI.model.pathItem
		If actionSchema.Target = "class" {
			Set pathObj = ..Specification.Paths.GetAt("/"_actionSchema.ResourceName_"/$"_actionSchema.ActionName)
		} Else {
			Set pathObj = ..Specification.Paths.GetAt("/"_actionSchema.ResourceName_"/{id}/$"_actionSchema.ActionName)
		}
		If '$IsObject(pathObj) {
			Set pathObj = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
			Set pathObj.EndpointType = "action"
			Set pathObj.IsInstance = actionSchema.Target="instance"
		}
		Do pathObj.SourceClasses.Insert(actionSchema.SourceClass)
		Set method = $ZConvert(actionSchema.HTTPMethod,"L")		
		Set httpVerbList = $ListBuild(
			"Get",
			"Post",
			"Put",
			"Patch",
			"Delete",
			"Head",
			"Options",
			"Trace"
		)
		#dim methodObj As %pkg.isc.rest.openAPI.model.operation
		Set ptr = 0
		While $ListNext(httpVerbList,ptr,httpVerb) {
			If (method = $ZConvert(httpVerb,"L")) { 
				Set methodObj = $Property(pathObj, httpVerb)
				If '$IsObject(methodObj) {
					Set methodObj = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
					Set methodObj.Description = actionSchema.Description
					Set methodObj.ActionName = actionSchema.ActionName
					Set methodObj.SourceActionInfo = actionSchema
					Set methodObj.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
					Do methodObj.Tags.Insert(actionSchema.ResourceName)
				}
				Set $Property(pathObj, httpVerb) = methodObj
				Quit
			}
		}
		If '$IsObject(methodObj) {
			$$$ThrowStatus($$$ERROR($$$GeneralError,""))
		}
		Do methodObj.SourceClasses.Insert(actionSchema.SourceClass)
		Do methodObj.Responses.SourceClasses.Insert(actionSchema.SourceClass)
		If actionSchema.Target '= "class" {
			Do ..SetIDParameter(methodObj, actionSchema.Class, actionSchema.RequestMediatype)
		}
		Set key = "", argument = actionSchema.Arguments.GetNext(.key)
		While key '= "" {
			#Dim argument As %pkg.isc.rest.openAPI.argumentInfo
			If argument.Source = "body" {
				// Request body
				Set requestBody = methodObj.RequestBody
				If '$IsObject(requestBody) {
					Set requestBody = ##class(%pkg.isc.rest.openAPI.model.requestBody).%New()
					//Set requestBody.Description = "TODO: This!"
				}
				Do requestBody.SourceClasses.Insert(actionSchema.SourceClass)
				Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
				Do mediatype.SourceClasses.Insert(argument.SourceClass)
				Set mediatype.Schema = argument.Schema
				Do requestBody.Content.SetAt(mediatype, actionSchema.RequestMediatype)
				Set requestBody.Required = requestBody.Required || argument.Required
				Set methodObj.RequestBody = requestBody
			} ElseIf (argument.Source = "query") || (argument.Source = "path") {
				// Query/Path Parameters
				#Dim parameter As %pkg.isc.rest.openAPI.model.parameter
				Set parameter = ""
				For j=1:1:methodObj.Parameters.Count() {
					Set existingParameter = methodObj.Parameters.GetAt(j)
					If existingParameter.Name = argument.Name && (existingParameter.In = argument.Source) {
						Set parameter = methodObj.Parameters.GetAt(j)
						Quit
					}
				}
				Set schema = argument.Schema
				Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
				Do mediatype.SourceClasses.Insert(argument.SourceClass)
				Set mediatype.Schema = schema
				If parameter = "" {
					Set parameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
					Do parameter.Content.SetAt(mediatype, argument.MediaType)
				} Else {
					Set existingSchema = parameter.Content.GetNext("")
					If $IsObject(existingSchema) {
						Set baseSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
						Set baseSchema.AutoGenerated = 1
						For j=1:1:existingSchema.SourceClasses.Count() {
							Do baseSchema.SourceClasses.Insert(existingSchema.SourceClasses.GetAt(j))
						}
						Do parameter.Content.Clear()
						Set parameter.Schema = baseSchema
						Do baseSchema.OneOf.Insert(existingSchema)
					} Else {
						Set baseSchema = parameter.Schema
					}
					Do baseSchema.OneOf.Insert(schema)
					For j=1:1:schema.SourceClasses.Count() {
						Do baseSchema.SourceClasses.Insert(schema.SourceClasses.GetAt(j))
					}
				}
				Do parameter.SourceClasses.Insert(argument.SourceClass)
				Set parameter.In = argument.Source
				Set parameter.Name = argument.Name
				//Set parameter.Description = "TODO: ???"
				// Path parameters are always required
				Set parameter.Required = argument.Required || (argument.Source = "path")
				Do methodObj.Parameters.Insert(parameter)
			} ElseIf argument.Source = "body-key" {
				// Body-Key Parameters
				Set requestBody = methodObj.RequestBody
				If '$IsObject(requestBody) {
					Set requestBody = ##class(%pkg.isc.rest.openAPI.model.requestBody).%New()
				}
				Do requestBody.SourceClasses.Insert(argument.SourceClass)
				//Set requestBody.Description = "TODO: This!"
				Set mediatype = requestBody.Content.GetAt(actionSchema.RequestMediatype)
				If '$IsObject(mediatype) {
					Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
					Do mediatype.SourceClasses.Insert(argument.SourceClass)
					Set mediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
					Set mediatype.Schema.AutoGenerated = 1
					Do mediatype.Schema.SourceClasses.Insert(actionSchema.SourceClass)
					Set mediatype.Schema.Type = "object"
				}
				Do mediatype.Schema.Properties.SetAt(argument.Schema, argument.Name)
				If argument.Required {
					If '$IsObject(mediatype.Schema.Required) {
						Set mediatype.Schema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
					}
					Do mediatype.Schema.Required.Insert(argument.Name)
				}
				Do requestBody.Content.SetAt(mediatype, actionSchema.RequestMediatype)
				Set requestBody.Required = requestBody.Required || argument.Required
				Set methodObj.RequestBody = requestBody
			}
			Set argument = actionSchema.Arguments.GetNext(.key)
		}
		If ..ForceAuthorizeAllEndpoints || 'actionSchema.Forbidden {
			If 'actionSchema.NoMethodFlag {
				// HTTP 200
				Set response200 = methodObj.Responses.GetAt("200")
				If '$IsObject(response200) {
					Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
					Set response200.Description = "A successful response" // (TODO: Let the user specify this!)
				}
				Do response200.SourceClasses.Insert(actionSchema.SourceClass)
				If $IsObject(actionSchema.ReturnSchema) {
					Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
					Do mediatype.SourceClasses.Insert(actionSchema.SourceClass)
					Set mediatype.Schema = actionSchema.ReturnSchema
					Do response200.Content.SetAt(mediatype, actionSchema.ReturnMediatype)
				}
				Do methodObj.Responses.SetAt(response200, "200")
			} Else {
				// HTTP 500
				#Dim response500 As %pkg.isc.rest.openAPI.model.response
				Set response500 = methodObj.Responses.GetAt("500")
				If '$IsObject(response500) {
					Set response500 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
				}
				Do response500.SourceClasses.Insert(actionSchema.SourceClass)
				Set response500.Description = "An internal server error occurred"
				Do response500.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
				Do response500.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
				Do methodObj.Responses.SetAt(response500, "500")
			}
			// HTTP 415
			Set response415 = methodObj.Responses.GetAt("415")
			If '$IsObject(response415) {
				Set response415 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
			}
			Do response415.SourceClasses.Insert(actionSchema.SourceClass)
			Set response415.Description = "Unsupported Mediatype: Mediatype is not compatible with any supported request mediatypes."
			Do response415.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
			Do response415.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
			Do methodObj.Responses.SetAt(response415, "415")
			// HTTP 406
			Set response406 = methodObj.Responses.GetAt("406")
			If '$IsObject(response406) {
				Set response406 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
			}
			Do response406.SourceClasses.Insert(actionSchema.SourceClass)
			Set response406.Description = "Unsupported Mediatype: The requested mediatype is not compatible with any supported response mediatypes."
			Do response406.Content.SetAt(errorMediatypePlain.%ConstructClone(), "default")
			Do response406.Content.SetAt(errorMediatypeJSON.%ConstructClone(), "application/json")
			Do methodObj.Responses.SetAt(response406, "406")
			// Could also handle HTTP 405 for method not found, but this is a known method so that shouldn't be needed
		}
		// HTTP 403
		Set response403 = methodObj.Responses.GetAt("403")
		If '$IsObject(response403) {
			Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
		}
		Do response403.SourceClasses.Insert(actionSchema.SourceClass)
		Set response403.Ref = "#/components/responses/403"
		Do methodObj.Responses.SetAt(response403, "403")
		
		Set resolvedActionName = ##class(%pkg.isc.rest.openAPI.actionInfo).GetResolvedActionName(actionSchema.ActionName)
		If (actionSchema.Target = "class") {
			Do ..Specification.Paths.SetAt(pathObj, "/"_actionSchema.ResourceName_"/$"_resolvedActionName)
		} Else {
			Do ..Specification.Paths.SetAt(pathObj, "/"_actionSchema.ResourceName_"/{id}/$"_resolvedActionName)
		}
	}
}

Method WriteOtherEndpoints() [ Internal, Private ]
{
	// Authentication Endpoints
	// Status
	Set endpoint = "/auth/status"
	If $ClassMethod(..DispatchClass,"Supports",endpoint,"GET") {
		#Dim authPath As %pkg.isc.rest.openAPI.model.pathItem
		Set authPath = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
		Set authPath.EndpointType = "other"
		Set authPath.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
		Set authPath.Get.Description = "Get information about the current user"
		Set authPath.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
		#Dim response200 As %pkg.isc.rest.openAPI.model.response
		Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
		Set response200.Description = "A representation of the current user"
		Set responseMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
		Set userResourceClass = ##class(%Dictionary.CompiledMethod).%OpenId(..DispatchClass_"||GetUserResource").ReturnType
		Set userResourceStub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(userResourceClass, "")
		Do userResourceStub.PopulateNonOverwrittenValues()
		Set responseMediatype.Schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(userResourceStub, , "output", ..NeededClasses, $This, 1)
		Set mediatype = ##class(%Dictionary.CompiledParameter).%OpenId(userResourceClass_"||MEDIATYPE").Default
		Do response200.Content.SetAt(responseMediatype, mediatype)
		Do authPath.Get.Responses.SetAt(response200, "200")
		#Dim response204 As %pkg.isc.rest.openAPI.model.response
		Set response204 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
		Set response204.Description = "No Content: No information was found on the current user"
		Do authPath.Get.Responses.SetAt(response204, "204")
		Do ..Specification.Paths.SetAt(authPath, endpoint)
	}
	// Logout
	Set endpoint = "/auth/logout"
	If $ClassMethod(..DispatchClass,"Supports",endpoint,"POST") {
		Set authPath = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
		Set authPath.EndpointType = "other"
		Set authPath.Post = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
		Set authPath.Post.Description = "Log out the current user"
		//  TODO ...responses?
		Set authPath.Post.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
		Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
		Set response200.Description = "A successful response"
		Do authPath.Post.Responses.SetAt(response200, "200")
		Do ..Specification.Paths.SetAt(authPath, endpoint)
	}
	
	// Documentation Endpoints
	Set endpoint = "/build-documentation"
	Set supportsBuildDocCreate = $ClassMethod(..DispatchClass,"Supports",endpoint,"POST")
	Set supportsBuildDocGet = $ClassMethod(..DispatchClass,"Supports",endpoint,"GET")
	If supportsBuildDocCreate || supportsBuildDocGet {
		Set buildDocsPath = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
		Set buildDocsPath.EndpointType = "other"
		Set response403 = ##class(%pkg.isc.rest.openAPI.model.responseReference).%New()
		Set response403.Ref = "#/components/responses/403"

		// POST
		If supportsBuildDocCreate {
			Set buildDocsPath.Post = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
			Set buildDocsPath.Post.Description = "Trigger a (re)build of REST API documentation"
			Set buildDocsPath.Post.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
			Do buildDocsPath.Post.Responses.SetAt(response403, "403")
			Set debugParam = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
			Set debugParam.Name = "debug"
			Set debugParam.In = "query"
			Set debugParam.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set debugParam.Schema.AutoGenerated = 1
			Set debugParam.Schema.Type = "integer"
			Set debugParam.Description = "The debug level to build documentation with (defaults to 0 if not specified)"
			Do buildDocsPath.Post.Parameters.Insert(debugParam)
			Set internalParam = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
			Set internalParam.Name = "internal"
			Set internalParam.In = "query"
			Set internalParam.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set internalParam.Schema.AutoGenerated = 1
			Set internalParam.Schema.Type = "integer"
			Set internalParam.Description = "Whether or not documentation should be built for readers with source code access (defaults to 0=false if not specified)"
			Do buildDocsPath.Post.Parameters.Insert(internalParam)
			Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
			Set response200.Description = "Information about the started build"
			Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
			Set schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set schema.AutoGenerated = 1
			Set schema.Type = "object"
			Set statusURLSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set statusURLSchema.AutoGenerated = 1
			Set statusURLSchema.Type = "string"
			Set statusURLSchema.Description = "URL to view the status of the started build"
			Set statusMethodSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set statusMethodSchema.AutoGenerated = 1
			Set statusMethodSchema.Type = "string"
			Set statusMethodSchema.Description = "HTTP Method to use in conjunction with statusUrl"
			Set startedSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set startedSchema.AutoGenerated = 1
			Set startedSchema.Type = "boolean"
			Set startedSchema.Description = "Whether or not the requested build was started successfully"
			Do schema.Properties.SetAt(statusURLSchema, "statusUrl")
			Do schema.Properties.SetAt(statusMethodSchema, "statusMethod")
			Do schema.Properties.SetAt(startedSchema, "buildStarted")
			Set schema.Example = ##class(%pkg.isc.rest.openAPI.model.genericObject).From({"statusUrl":"/build-documentation","statusMethod":"GET","buildStarted":true})
			Set mediatype.Schema = schema
			Do response200.Content.SetAt(mediatype, "application/json")
			Do buildDocsPath.Post.Responses.SetAt(response200, "200")
			Set response423 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
			Set response423.Description = "Locked: Another build is currently in-progress, try again later"
			Do response423.Content.SetAt(mediatype.%ConstructClone(1), "application/json")
			Do buildDocsPath.Post.Responses.SetAt(response423, "423")
		}

		// GET
		If supportsBuildDocGet {
			Set buildDocsPath.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
			Set buildDocsPath.Get.Description = "Get information on the current REST API documentation build"
			Set buildDocsPath.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
			Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
			Set response200.Description = "The status of either the build that is currently in-progress, or the last build if no build is currently in-progress"
			Set schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set schema.AutoGenerated = 1
			Set schema.Type = "object"
			Set schema.Description = "Information on the status of a build"
			Set inProgressSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set inProgressSchema.AutoGenerated = 1
			Set inProgressSchema.Type = "boolean"
			Set inProgressSchema.Description = "Whether or not the build is currently in-progress"
			Set startTimeSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set startTimeSchema.AutoGenerated = 1
			Set startTimeSchema.Type = "integer"
			Set startTimeSchema.Description = "When the build was started (Unix time)"
			Set endTimeSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set endTimeSchema.AutoGenerated = 1
			Set endTimeSchema.Type = "integer"
			Set endTimeSchema.Description = "When the build finished (Unix time), 0 = not-yet-determined"
			Set progressSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set progressSchema.AutoGenerated = 1
			Set progressSchema.Type = "object"
			Set stageSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set stageSchema.AutoGenerated = 1
			Set stageSchema.Type = "integer"
			Set stageSchema.Description = "The current stage of the over-all build process (monotonically increasing for a given build)"
			Set openapiSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set openapiSchema.AutoGenerated = 1
			Set openapiSchema.Type = "string"
			Set openapiSchema.Description = "The current stage of the OpenAPI build process"
			Set parametersSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set parametersSchema.AutoGenerated = 1
			Set parametersSchema.Type = "object"
			Set debugSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set debugSchema.AutoGenerated = 1
			Set debugSchema.Type = "integer"
			Set debugSchema.Description = "The build's debug parameter"
			Set internalSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set internalSchema.AutoGenerated = 1
			Set internalSchema.Type = "integer"
			Set internalSchema.Description = "The build's internal parameter"
			Set userContextSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set userContextSchema.AutoGenerated = 1
			Set userContextSchema.Type = "object"
			Set userContextID = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
			Set userContextID.AutoGenerated = 1
			Set userContextID.Type = "string"
			Set userContextID.Description = "The ID of the UserContext() that triggered this build (or the empty string if no such context exists)"
			Do schema.Properties.SetAt(inProgressSchema, "buildInProgress")
			Do schema.Properties.SetAt(startTimeSchema, "buildStartedTime")
			Do schema.Properties.SetAt(endTimeSchema, "buildFinishedTime")
			Do progressSchema.Properties.SetAt(stageSchema, "buildStage")
			Do progressSchema.Properties.SetAt(openapiSchema, "OpenAPI")
			Do schema.Properties.SetAt(progressSchema, "buildProgress")
			Do parametersSchema.Properties.SetAt(debugSchema, "debug")
			Do parametersSchema.Properties.SetAt(internalSchema, "internal")
			Do userContextSchema.Properties.SetAt(userContextID, "_id")
			Do parametersSchema.Properties.SetAt(userContextSchema, "userContext")
			Do schema.Properties.SetAt(parametersSchema, "buildParameters")
			Set mediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
			Set mediatype.Schema = schema
			Do response200.Content.SetAt(mediatype, "application/json")
			Do buildDocsPath.Get.Responses.SetAt(response200, "200")
			Do buildDocsPath.Get.Responses.SetAt(response403.%ConstructClone(), "403")
		}

		Do ..Specification.Paths.SetAt(buildDocsPath, endpoint)
	}
}

Method OnResourceInfoRetrieval(stub) [ Internal, Private ]
{
	// Update the finished/needed lists appropriately
	Do ..FinishedClasses.Insert(stub)
	For i=1:1:..NeededClasses.Count() {
		Quit:i>..NeededClasses.Count()
		For j=1:1:..FinishedClasses.Count() {
			If ..NeededClasses.GetAt(i).AsString() = ..FinishedClasses.GetAt(j).AsString() {
				Do ..NeededClasses.RemoveAt(i)
				Set i = i-1
				Quit
			}
		}
	}
}

/// Gets a "nice name" for a given class name
/// If ..HideInternalInfo = 0, this just returns the input class name.
/// Otherwise, it attempts to return a name that is more easily readable / is more in line with usual JSON property names
Method GetNiceName(stub As %pkg.isc.rest.openAPI.resourceInfoStub) [ Internal ]
{
	
	// Make sure we have a ClassMappings array to use
	Set:'$IsObject(..ClassMappings) ..ClassMappings = ##class(%ArrayOfDataTypes).%New()
	
	// Return the mapping for this class if it already exists
	If ..ClassMappings.IsDefined(stub.AsString()) {
		Return ..ClassMappings.GetAt(stub.AsString())
	}
	
	// Otherwise, generate it!
	Set className = stub.ClassName
	If '..HideInternalInfo {
		Set val = $Replace(className,"%","")
		Set:stub.JSONMapping'="" val = val_"_"_stub.JSONMapping
	} Else {
		
		// If this is a proxy, get the actual class name
		Set initialClassName = className
		If $ClassMethod(className, "%Extends", "%pkg.isc.rest.model.proxy") {
			Set className = $Parameter(className, "SOURCECLASS")
		}
		
		// Get either the resource name (if it exists), or create a "nice" looking name from the class name
		Set val = $Parameter(initialClassName,"RESOURCENAME")
		If val="" {
			Set val = ##class(%pkg.isc.rest.openAPI.util).FormatString($Piece(className,".",*))
			Set:stub.JSONMapping'="" val = val _ "_" _ ##class(%pkg.isc.rest.openAPI.util).FormatString(stub.JSONMapping)
			
			// First step for dealing with conflicts is to include some of the class' path and see if that helps
			Set num = $Length(className,".")
			While (..ClassMappings.Find(val)'="") && (num >= 1) {
				Set num = num-1
				Set val = ##class(%pkg.isc.rest.openAPI.util).FormatString($Piece(className,".",num) _ "." _ val)
			}
		} Else {
			Set:stub.JSONMapping'="" val = val _ "_" _ ##class(%pkg.isc.rest.openAPI.util).FormatString(stub.JSONMapping)
		}
	}
	
	// Its possible that there are still conflicts, so append a number to the end if needed to prevent that
	Set actual = val
	Set num = 0
	While ..ClassMappings.Find(actual)'="" {
		Set num = num+1
		Set actual = val_"_"_num
	}
	
	// Save and return the mapping
	Do ..ClassMappings.SetAt(actual, stub.AsString())
	Return actual
}

/// Notifies that a section of the generation is starting.
Method WriteSection(text, ByRef ws, ByRef timer) [ Internal, Private ]
{
	If ($Data(ws) && ws) {
		$$$TimerEnd
	} Else {
		$$$TimerStart
	} 
	Write:..DEBUG *27,"[63m" _ text,*27,"[0m",! 
	Set ws = 1
	Set:..StageGlobal $$$DocStageBuildOpenAPIGbl = text
}

}

