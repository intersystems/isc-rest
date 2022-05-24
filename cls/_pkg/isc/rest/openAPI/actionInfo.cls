Include %pkg.isc.rest.general

Class %pkg.isc.rest.openAPI.actionInfo Extends %RegisteredObject
{

/// Classname of this action's instance method handler
Property InstanceHandler As %String [ Internal ];

/// Whether or not this action's instance method handler has been overwritten
Property InstanceHandlerOverwritten As %Boolean [ Internal ];

/// Classname of this action's class method handler
Property ClassHandler As %String [ Internal ];

/// Whether or not this action's class method handler has been overwritten
Property ClassHandlerOverwritten As %Boolean [ Internal ];

/// Action name for this action
Property ActionName As %String [ Internal ];

/// Resource class for this action
Property Class As %String [ Internal ];

/// Class that contains the ActionMap XData block
Property SourceClass As %String [ Internal ];

/// Resource name for this action
Property ResourceName As %String [ Internal ];

/// HTTP Method associated with this action
Property HTTPMethod As %String [ Internal ];

/// Action method target ("class" or "instance")
Property Target As %String [ Internal ];

/// Map of Target -> {Type, Name} for this action's arguments
Property Arguments As array Of %pkg.isc.rest.openAPI.argumentInfo [ Internal ];

/// Mediatype of this action's request value(s)
Property RequestMediatype As %String [ Internal ];

/// Mediatype of this action's return value(s)
Property ReturnMediatype As %String [ Internal ];

/// OpenAPI Schema representing this action's return value(s)
Property ReturnSchema As %pkg.isc.rest.openAPI.model.schema [ Internal, Transient ];

/// Description of this action
Property Description As %String [ Internal ];

/// Whether or not this endpoint is forbidden
Property Forbidden As %Boolean [ Internal ];

/// Whether or not this endpoint is *always* forbidden
Property ForbidUnderAllCircumstances As %Boolean [ InitialExpression = 0, Internal ];

/// The JSONMappng to use for the model class
Property Mapping As %String [ Internal ];

/// The name of the method / query for this action
Property CodeSource As %String [ Internal ];

/// Used to track whether an action does not have a valid method associated with it
Property NoMethodFlag As %Boolean [ InitialExpression = 0, Internal ];

ClassMethod FromQueryValues(result As %SQL.StatementResult, openapi As %pkg.isc.rest.openAPI) As %pkg.isc.rest.openAPI.actionInfo [ Internal ]
{
	
	// TODO: Comment!
	Set actionInfo = ..%New()
	Set actionInfo.SourceClass = $Parameter($$$CLASSNAME(result.ImplementationClass), "SOURCECLASS")
	Set actionInfo.InstanceHandler = $$$CLASSNAME(##class(%Dictionary.CompiledMethod).%OpenId($$$CLASSNAME(result.ImplementationClass) _ "||HandleInvokeInstanceAction").Origin)
	Set actionInfo.ClassHandler = $$$CLASSNAME(##class(%Dictionary.CompiledMethod).%OpenId($$$CLASSNAME(result.ImplementationClass) _ "||HandleInvokeClassAction").Origin)
	Set actionInfo.InstanceHandlerOverwritten = actionInfo.InstanceHandler'="%pkg.isc.rest.model.action.handler"
	Set actionInfo.ClassHandlerOverwritten = actionInfo.ClassHandler'="%pkg.isc.rest.model.action.handler"
	Set actionInfo.Class = $$$CLASSNAME(result.ResourceClass)
	Set actionInfo.HTTPMethod = result.HTTPVerb
	Set actionInfo.ReturnMediatype = result.MediaTypeOrNUL
	Set actionInfo.RequestMediatype = result.AcceptsOrNUL
	Set:actionInfo.RequestMediatype=$c(0) actionInfo.RequestMediatype = "application/json"
	Set actionInfo.ResourceName = result.ResourceName
	Set actionInfo.ActionName = result.ActionName
	
	// TODO: Comment!
	Set actions = ##class(%pkg.isc.rest.openAPI.util).ParseXData($$$CLASSNAME(result.ResourceClass), "ActionMap", "%pkg.isc.rest.model.action.t.actions")
	For i=1:1:actions.actions.Count() {
		Set action = actions.actions.GetAt(i)
		#Dim action As %pkg.isc.rest.model.action.t.action
		Continue:action.name'=result.ActionName
		Set actionInfo.Target = action.target
		For j=1:1:action.arguments.Count() {
			Set argument = action.arguments.GetAt(j)
			#Dim argument As %pkg.isc.rest.model.action.t.argument
			Set argumentObj = ##class(%pkg.isc.rest.openAPI.argumentInfo).%New()
			Set argumentObj.SourceClass = actionInfo.SourceClass
			Set argumentObj.Name = argument.name
			Set:argumentObj.Name="" argumentObj.Name = argument.target
			Set argumentObj.Source = argument.source
			Set argumentObj.Required = argument.required || (argument.source = "id")
			Set argumentObj.MediaType = actionInfo.RequestMediatype
			Set:argumentObj.MediaType=$c(0) argumentObj.MediaType = "application/json"
			Do actionInfo.Arguments.SetAt(argumentObj, argument.target)
		}
		If action.call '= "" {
			Set actionInfo.CodeSource = action.call
			Set methodClass = $$$CLASSNAME(result.ResourceClass)
			If $Find(action.call,":") {
				Set methodClass = $Piece(action.call,":",1)
				Set action.call = $Piece(action.call,":",2)
			}
			Set method = ##class(%Dictionary.CompiledMethod).%OpenId(methodClass _ "||" _ action.call)
			If '$IsObject(method) {
				Do openapi.Error("Action " _ actionInfo.Class _ ":" _ result.ActionName _ " references a non-existant method " _ methodClass _ ":" _ action.call)
				Continue:'openapi.IncludeForbiddenEndpoints
				Set actionInfo.NoMethodFlag = 1
			} ElseIf method.ReturnType '= "" {
				// TODO: This isn't necessarily correct... might want to run through the method code to see if you find any return/quit <...> because the return type might just be unspecified?
				Set returnTypeClass = $$$CLASSNAME(method.ReturnType)
				Set jsonType = ""
				If $ClassMethod(returnTypeClass,"%Extends","%pkg.isc.rest.model.queryResult") {
					// Check for MODELCLASS parameter in return type
					Set jsonType = "array"
					If (method.ReturnTypeParams [ "MODELCLASS=") {
						Set returnTypeClass = $Piece($Piece(method.ReturnTypeParams,"MODELCLASS=""",2),"""")
					} Else {
						Set returnTypeClass = methodClass
					}
				}
				Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(returnTypeClass, $Parameter(returnTypeClass, "JSONMAPPING"))
				Do stub.PopulateNonOverwrittenValues()
				Set actionInfo.ReturnSchema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(stub,jsonType,"output",openapi.NeededClasses,openapi,1)
				Do actionInfo.ReturnSchema.SourceClasses.Insert(actionInfo.SourceClass)
			}
		} Else {
			Set actionInfo.CodeSource = action.query
			Set queryClass = $$$CLASSNAME(result.ResourceClass)
			If $Find(action.query,":") {
				Set queryClass = $$$CLASSNAME($Piece(action.query,":",1))
				Set action.query = $Piece(action.query,":",2)
			}
			Set method = ##class(%Dictionary.CompiledQuery).%OpenId(queryClass _ "||" _ action.query)
			If '$IsObject(method) {
				Do openapi.Error("Action " _ actionInfo.Class _ ":" _ result.ActionName _ " references a non-existant class-query " _ queryClass _ ":" _ action.query)
				Continue:'openapi.IncludeForbiddenEndpoints
				Set actionInfo.NoMethodFlag = 1
			} Else {
				// Code to handle arbitrary SQL query results (not currently supported by %pkg.isc.rest.handler)
				//Set actionInfo.ReturnSchema = ##class(Schema).GenerateSchemaFromSQL(method.SqlQuery)
				Set stub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(actionInfo.Class, $Parameter(actionInfo.Class, "JSONMAPPING"))
				Do stub.PopulateNonOverwrittenValues()
				Set actionInfo.ReturnSchema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(stub,"array","output",openapi.NeededClasses,openapi,1)
				Do actionInfo.ReturnSchema.SourceClasses.Insert(actionInfo.SourceClass)
			}
		}
		
		// TODO: Should replace class names with nice class names in the description!
		Set:'actionInfo.NoMethodFlag actionInfo.Description = method.Description
		Set:actionInfo.Description="" actionInfo.Description = "Performs the " _ ..GetResolvedActionName(action.name) _ " action."
		
		If 'actionInfo.NoMethodFlag {
			For j=1:1:$ListLength(method.FormalSpecParsed) {
				Set argumentSpec = $ListGet(method.FormalSpecParsed,j)
				Set argumentTarget = $ListGet(argumentSpec,1)
				Set argumentType = $$$CLASSNAME($ListGet(argumentSpec,2))
				Continue:'actionInfo.Arguments.IsDefined(argumentTarget)	// parameter that has a default, hopefully TODO: verify this?
				Continue:$Piece($Piece($Piece(method.FormalSpec,argumentTarget,2),",",1),":",2)=""	// parameter with no explictly-defined type (handled below)
				Set argumentObj = actionInfo.Arguments.GetAt(argumentTarget)
				Set argumentStub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New(argumentType,$Parameter(argumentType,"JSONMAPPING"))
				Do argumentStub.PopulateNonOverwrittenValues()
				Set argumentObj.Schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(argumentStub,,"input",openapi.NeededClasses,openapi,1)
				Do argumentObj.Schema.SourceClasses.Insert(actionInfo.SourceClass)
			}
			Set key="", argument = actionInfo.Arguments.GetNext(.key)
			While key'="" {
				If '$IsObject(argument.Schema) {
					Do openapi.Warn("Parameter " _ key _ " for method " _ method.Name _ " used in action " _ actionInfo.ResourceName _ "/$" _ actionInfo.ActionName _ " does not have an explicitly-defined type; treating it as a %String")
					Set argumentStub = ##class(%pkg.isc.rest.openAPI.resourceInfoStub).%New($$$CLASSNAME("%String"))
					Do argumentStub.PopulateNonOverwrittenValues()
					Set argument.Schema = ##class(%pkg.isc.rest.openAPI.schema).GetSchema(argumentStub,,"input",openapi.NeededClasses,openapi,1)
				}
				Set argument = actionInfo.Arguments.GetNext(.key)
			}
		}
		Try {
			Try {
				Set actionInfo.Forbidden = '$ClassMethod($$$CLASSNAME(result.ResourceClass), "CheckPermission", "", "ACTION:" _ action.name, openapi.UserContext)
			} Catch {
				Set actionInfo.Forbidden = 1
			}
			Set actionInfo.ForbidUnderAllCircumstances = ##class(%Dictionary.CompiledMethod).%OpenId($$$CLASSNAME(result.ResourceClass)_ "||CheckPermission").Origin = "%pkg.isc.rest.model.resource"
		} Catch {
			Set actionInfo.Forbidden = 1
			Set actionInfo.ForbidUnderAllCircumstances = 1
		}
		Do openapi.ActionInfo.Insert(actionInfo)
	}
	Return actionInfo
}

/// Replace all : path parameter with {} instead to match OAS format
ClassMethod GetResolvedActionName(pActionName As %String) As %String [ Internal ]
{
	Set resolvedName = ##class(%pkg.isc.rest.model.action.t.action).GetResolvedActionName(pActionName, .params)
	For i = 1:1:$Get(params) {
		// Replace one param at a time
		Set resolvedName = $Replace(resolvedName,"([^/]+)","{"_params(i)_"}",,1)
	}
	Return resolvedName
}

}

