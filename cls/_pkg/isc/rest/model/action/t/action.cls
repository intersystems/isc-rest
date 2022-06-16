Include %occClassname

/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.t.action Extends (%RegisteredObject, %XML.Adaptor) [ System = 2 ]
{

Parameter XMLIGNOREINVALIDATTRIBUTE As BOOLEAN = 0;

Parameter NAMESPACE As STRING = "http://www.intersystems.com/_pkg/isc/rest/action";

Property arguments As list Of %pkg.isc.rest.model.action.t.argument(XMLNAME = "argument", XMLPROJECTION = "element");

/// Name of the action (used in URLs)
Property name As %String(MAXLEN = 255, XMLPROJECTION = "attribute") [ Required ];

Property resolvedName As %String(XMLPROJECTION = "none") [ Calculated, SqlComputeCode = {Set {*} = ##class(%pkg.isc.rest.model.action.t.action).GetResolvedActionName({name}) }, SqlComputed ];

/// Whether the action targets the class or instance. Default is "class".
Property target As %String(VALUELIST = ",class,instance", XMLPROJECTION = "attribute") [ InitialExpression = "class", Required ];

/// The method to call - either the name of a class/instance method, or (if in another class) may take the format <code>classname:methodname</code>
Property call As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// The class query to wrap. May just be the query name if the query is in the current class, or <code>classname:queryname</code> if in a different class.
Property query As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// The method to use for the action. Defaults to POST, as this will be most common.
Property method As %String(VALUELIST = ",GET,POST,PUT,DELETE", XMLPROJECTION = "attribute") [ InitialExpression = "POST", Required ];

/// For queries, the model class of result instances (if different from the source class)
Property modelClass As %Dictionary.CacheClassname(XMLPROJECTION = "attribute");

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	If (..call = "") = (..query = "") {
		// If call and query are both empty or both nonempty, we have a problem.
		Set msg = $$$FormatText("Action %1: must specify either a call or a query to use.",..name)
		Return $$$ERROR($$$GeneralError,msg)
	}
	
	If (..query '= "") {
		If (..method = "POST") {
			Set msg = $$$FormatText("Action %1: must use GET method with a query.",..name)
			Return $$$ERROR($$$GeneralError,msg)
		}
	} Else {
		If (..modelClass '= "") {
			Set msg = $$$FormatText("Action %1: modelClass may only be defined for query actions",..name)
			Return $$$ERROR($$$GeneralError,msg)
		}
	}

	If (..name [ ":") {
		// Verify that arguments exist for each path parameter
		Set pathList = $ListFromString(..name, "/")
		Kill pathArgsArray
		Set iter = 0
		While $ListNext(pathList, iter, path) {
			Set remainingPath = $Extract(path, 2, *)
			If (remainingPath [ ":") {
				Set msg = $$$FormatText("Action %1: name cannot contain ':' UNLESS it occurs directly after a '/' to indicate a path parameter",..name)
				Return $$$ERROR($$$GeneralError,msg)
			}
			If $Data(pathArgsArray(remainingPath))#2 {
				Set msg = $$$FormatText("Action %1: name cannot contain duplicate path parameter %2",..name,path)
				Return $$$ERROR($$$GeneralError,msg)
			}
			If ($Extract(path, 1) = ":") {
				Set pathArgsArray(remainingPath) = ""
			}
		}
	}
	
    Set sc = $$$OK
	Kill nameSourceArray
	Kill targetArray
	Set seenBodyArgument = 0
	For i=1:1:..arguments.Count() {
		#dim argument As %pkg.isc.rest.model.action.t.argument
		Set argument = ..arguments.GetAt(i)
        Set sc = $$$ADDSC(sc,argument.%ValidateObject())
		Set argSource = argument.source
		Set argTarget = argument.target
		Set argName = argument.name
		If (argName = "") {
			// name can be empty for singelton arguments like body
			Set argName = $Char(0)
		}
		If (argSource = "body") {
			If (seenBodyArgument) {
				Set msg = $$$FormatText("Action %1: Can only have single argument of source = 'body' but multiple present",..name)
				Return $$$ERROR($$$GeneralError,msg)
			}
			Set seenBodyArgument = 1
		}
		// Check if name + source combination already seen (this combination must be unique)
		If $Data(nameSourceArray(argName,argSource))#2 {
			Set msg = $$$FormatText("Action %1: Duplicate combination for arguments of name '%2' and source '%3'",..name,argName,argSource)
			Return $$$ERROR($$$GeneralError,msg)
		}
		// Check if target is not duplicated
		If $Data(targetArray(argTarget),argTargetValue)#2 {
			Set msg = $$$FormatText("Action %1: Duplicate target '%2'. Occurs for arguments '%3' and '%4'",..name,argTargetValue,argName,argName)
			Return $$$ERROR($$$GeneralError,msg)
		}
		// Accumulate name + source combination
		Set nameSourceArray(argName,argSource) = ""
		Set targetArray(argTarget) = argName
		If (argSource = "path") {
			If '($Data(pathArgsArray(argName))#2) {
				Set msg = $$$FormatText("Action %1: argument '%2' is missing in action name",..name,argName)
				Return $$$ERROR($$$GeneralError,msg)
			}
			// Found in pathArgsArray so kill
			Kill pathArgsArray(argName)
		}
    }

	// Whatever is left in pathArgsArray is path parameters that are in the path
	// but have no argument listed
	If $Data(pathArgsArray) {
		Set key = ""
		Set missingList = ""
		While 1 {
			Set key = $Order(pathArgsArray(key))
			If (key = "") {
				Quit
			}
			Set missingList = missingList _ $ListBuild(key)
		}
		Set msg = $$$FormatText("Action %1: the following arguments are in the path but have no corresponding argument element: %2",..name,$ListToString(missingList))
		Return $$$ERROR($$$GeneralError,msg)
	}
	Return sc
}

Method GetDependencies(pSourceClass As %String, ByRef pClassArray)
{
	// Always depends on the source class.
	Set pClassArray(pSourceClass) = ""
	
	If (..modelClass '= "") {
		Set pClassArray(..modelClass) = ""
	}
	
	// Other dependencies
	If (..query '= "") {
		If $Length(..query,":") > 1 {
			Set pClassArray($Piece(..query,":")) = ""
		}
	} Else {
		If $Length(..call,":") > 1 {
			Set class = $Piece(..call,":")
			Set method = $Piece(..call,":",2)
			Set pClassArray(class) = ""
		} Else {
			Set class = pSourceClass
			Set method = ..call
		}
		Set formalspec = $$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHformalspecparsed)
		Set pointer = 0
		While $ListNext(formalspec, pointer, argument) {
			If $Data(argument)#2 && ($ListGet(argument,2) '= "") {
				Set pClassArray($$$NormalizeClassname($ListGet(argument,2))) = ""
			}
		}
		Set returnType = $$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHreturntype)
		If (returnType '= "") {
			Set pClassArray($$$NormalizeClassname(returnType)) = ""
		}
	}
}

/// Get the resolved action name, replacing path parameters with regular
/// expression for matching.
ClassMethod GetResolvedActionName(pActionName As %String, Output pMatchParams) As %String
{
	If (pActionName '[ ":") {
		// No path params so return as is
		Return pActionName
	}
	// Adapted from %CSP.REST
	Kill pMatchParams
	Set actionRegex = ""
	Set actionNameParts = $ListFromString(pActionName, "/")
	Set iter = 0
	While $ListNext(actionNameParts,iter,part) {
		Set value = part
		If ($Extract(part,1) = ":") {
			Set value = ("([^"_$Char(0)_"]+)")
			Set pMatchParams($Increment(pMatchParams)) = $Extract(part,2,*)
		}
		Set actionRegex = actionRegex _ $ListBuild(value)
	}
	// Create regex by adding back / characters, replacing $c(0) with / so that
	// the matcher explicitly matches all characters EXCEPT / and escape $ as \$.
	Return $Replace($Translate($ListToString(actionRegex,"/"),$Char(0),"/"),"$","\$")
}

Method Generate(pSourceClass As %String, Output pCodeArray, Output pExpectedContentType As %String, Output pResultContentType As %String)
{
	#define GENERATE(%line) Set pCodeArray($i(pCodeArray)) = $c(9)_%line
	
	Kill pCodeArray
	Set pExpectedContentType = ""
	Set pResultContentType = ""
	Set tResultClass = pSourceClass
	Do ..GetFormalSpecMap(.tResultClass, .class, .method, .argArray, .nameMap, .returnType)
	$$$GENERATE("// "_..method_" $"_..name)

	// Substitute variable placeholders for capture group
	Kill matchParams
	Set resolvedActionName = ..GetResolvedActionName(..name,.matchParams)
	Set matchParamsCount = $Get(matchParams,0)
	Set actionRegex = "(.*)"_resolvedActionName
	If (matchParamsCount > 0) {
		// NOTE: Initial match against .* is for web app name of URL + resource name 
		// that we do not need but the .* is needed so the regex matcher works
		$$$GENERATE("Set actionRegex = "_$$$QUOTE(actionRegex))
		// Run regex matcher
		$$$GENERATE("Set matcher = ##class(%Regex.Matcher).%New(actionRegex)")
		$$$GENERATE("Do matcher.Match(%request.URL)")
		$$$GENERATE("Kill argsValues")
		// Skip first value intentionally as it is just web app name + resource
		$$$GENERATE("For i=2:1:matcher.GroupCount {")
		$$$GENERATE("	Set argsValues($Increment(argsValues)) = matcher.Group(i)")
		$$$GENERATE("}")
		// Size of argsValues and paamToValueMap MUST match so this is safe.
		// If they do not match, then this action would not have been matched
		// at the REST handler layer.
		Kill paramToValueMap
		For i=1:1:$Get(matchParams) {
			$$$GENERATE("Set paramToValueMap("_$$$QUOTE(matchParams(i))_") = argsValues("_i_")")
		}
	}
	
	$$$GENERATE("Set args = "_$Get(argArray,0))
	
	Set generatedBodyFromJSON = 0
	For argIndex = 1:1:..arguments.Count() {
		#dim argument As %pkg.isc.rest.model.action.t.argument
		Set argument = ..arguments.GetAt(argIndex)
		Set position = $Get(nameMap(argument.target))
		If (position = "") {
			Set msg = $$$FormatText("Action %1: Target '%2' expected in formal spec of %3:%4 but not found",..name,argument.target,class,method)
			$$$ThrowStatus($$$ERROR($$$GeneralError,msg))
		}
		Set argType = $ListGet(argArray(position),2)
		If (argument.source = "query") {
			If (argument.required) {
				$$$GENERATE("Set args("_position_") = %request.Get("_$$$QUOTE(argument.name)_")")
				$$$GENERATE("If (args("_position_") = """") {")
				$$$GENERATE("	Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP400BADREQUEST))
				$$$GENERATE("	Return")
				$$$GENERATE("}")
			} Else {
				$$$GENERATE("Merge args("_position_") = %request.Data("_$$$QUOTE(argument.name)_",1)")
			}
		} ElseIf (argument.source = "form-data") {
			Set pExpectedContentType = "multipart/form-data"
			If (argument.required) {
				$$$GENERATE("Set args("_position_") = $Get(%request.MimeData("_$$$QUOTE(argument.name)_",1))")
				$$$GENERATE("If (args("_position_") = """") {")
				$$$GENERATE("	Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP400BADREQUEST))
				$$$GENERATE("	Return")
				$$$GENERATE("}")
			} Else {
				$$$GENERATE("Merge args("_position_") = %request.MimeData("_$$$QUOTE(argument.name)_",1)")
			}
		} ElseIf (argument.source = "path") {
			// No need to check required as path parameters are always required
			// as is confirmed during validation in %pkg.isc.rest.model.action.t.action
			$$$GENERATE("Set args("_position_") = $Get(paramToValueMap("_$$$QUOTE(argument.name)_"))")
		} ElseIf (argument.source = "body") || (argument.source = "body-key") {
			If (argument.source = "body-key") && (argument.name = "") {
				// By default, use the method argument name as the key in the body.
				Set argument.name = argument.target
			}
			
			// Source is either the whole body, or a key within it.
			Set source = $Case(argument.source,
				"body":"body",
				"body-key":"body."_argument.name)
			Set tab = $Select(argument.required:"",1:"	")
			If ('argument.required) {
				$$$GENERATE("If %request.Content.Size = 0 {")
				If (argument.source = "body") {
					$$$GENERATE("	Set args("_position_") = $$$NULLOREF")
				}
				$$$GENERATE("} Else {")
				If 'generatedBodyFromJSON {
					$$$GENERATE("	Set body = {}.%FromJSON(%request.Content)")
					Set generatedBodyFromJSON = 1
				}
			} ElseIf 'generatedBodyFromJSON {
				$$$GENERATE("Set body = {}.%FromJSON(%request.Content)")
				Set generatedBodyFromJSON = 1
			}
			If $ClassMethod(argType,"%Extends","%Library.DynamicAbstractObject") {
				Set pExpectedContentType = "application/json"
				$$$GENERATE(tab_"Set args("_position_") = "_source)
			} ElseIf $ClassMethod(argType,"%Extends","%pkg.isc.rest.model.resource") {
				Set pExpectedContentType = $Case(argument.source,"body":$Parameter(argType,"MEDIATYPE"),:"application/json")
				$$$GENERATE(tab_"Set model = ##class("_argType_").GetModelInstance()")
				$$$GENERATE(tab_"$$$ThrowOnError(model.JSONImport("_source_"))")
				$$$GENERATE(tab_"Set args("_position_") = model")
			} ElseIf $Parameter(argType,"%JSONENABLED") {
				Set pExpectedContentType = "application/json"
				$$$GENERATE(tab_"Set model = ##class("_argType_").%New()")
				$$$GENERATE(tab_"$$$ThrowOnError(model.%JSONImport("_source_"))")
				$$$GENERATE(tab_"Set args("_position_") = model")
			} ElseIf (argument.name '= "") {
				Set pExpectedContentType = "application/json"
				$$$GENERATE(tab_"Set args("_position_") = "_source)
			}
			If ('argument.required) {
				$$$GENERATE("}")
			}
		} ElseIf (argument.source = "id") {
			Set indexToUse = $Parameter(pSourceClass,"IndexToUse")
			If (indexToUse = "") || (indexToUse = "ID") {
				// TODO: support alternative method in %pkg.isc.rest.model.resource to get the ID of an instance
				$$$GENERATE("	Set args("_position_") = pInstance.%Id()")
			} Else {
				Set backingClass = $Parameter(pSourceClass,"SOURCECLASS")
				If (backingClass = "") {
					// TODO: support alternative method in %pkg.isc.rest.model.resource to get the ID of an instance
					$$$GENERATE("	Set args("_position_") = pInstance.%Id()")
				} Else {
					// TODO: support multi-property indices??
					Set property = $$$comSubMemberKeyGet(backingClass,$$$cCLASSindex,indexToUse,$$$cINDEXproperty,1,$$$cINDEXPROPproperty)
					$$$GENERATE("	Set args("_position_") = pInstance."_property)
				}
			}
		} ElseIf (argument.source = "user-context") {
			$$$GENERATE("Merge args("_position_") = pUserContext")
		}
	}
	
	If (..query '= "") {
		Set methodCall = "set result = ##class(%pkg.isc.rest.model.queryResult).FromClassQuery("_$$$QUOTE(tResultClass)_","_$$$QUOTE(class)_","_$$$QUOTE(method)_",args...)"
	} Else {
		If (returnType = "") {
			Set methodCall = "Do "
		} Else {
			Set methodCall = "Set result = "
		}
		Set methodCall = methodCall_$Case(..target,
			"instance":"pInstance.",
			"class":"##class("_class_").")_method_"(args...)"
	}
	$$$GENERATE(methodCall)
	If (returnType = "%Library.Status") {
		$$$GENERATE("$$$ThrowOnError(result)")
	} ElseIf (returnType '= "") {
		If $ClassMethod(returnType,"%Extends","%Library.DynamicAbstractObject") {
			Set pResultContentType = "application/json"
			Set exportCommand = "Write result.%ToJSON()"
		} ElseIf $ClassMethod(returnType,"%Extends","%pkg.isc.rest.model.resource") {
			Set pResultContentType = $Parameter(returnType,"MEDIATYPE")
			Set exportCommand = "Do result.JSONExport()"
		} ElseIf $ClassMethod(returnType,"%Extends","%pkg.isc.rest.model.queryResult") {
			Set pResultContentType = $Parameter(tResultClass,"MEDIATYPE")
			Set exportCommand = "$$$ThrowOnError(result.JSONExport())"
		}ElseIf $ClassMethod(returnType,"%Extends","%Stream.Object") {
			Set pResultContentType = "application/octet-stream"
			Set exportCommand = "Do result.OutputToDevice()"
		} ElseIf $Parameter(returnType,"%JSONENABLED") {
			Set pResultContentType = "application/json"
			Set exportCommand = "Do result.%JSONExport()"
		} Else {
			$$$GENERATE("// Unknown handling for return type: "_returnType)
			$$$GENERATE("Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP204NOCONTENT))
			Quit
		}
		$$$GENERATE("Set %response.ContentType = "_$$$QUOTE(pResultContentType))
		$$$GENERATE("If $IsObject(result) {")
		$$$GENERATE("	"_exportCommand)
		$$$GENERATE("} Else {")
		$$$GENERATE("	Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP204NOCONTENT))
		$$$GENERATE("}")
	}
}

Method GetFormalSpecMap(ByRef pModelClass As %String, Output pClass, Output pMethod, Output pArgArray, Output pNameMap, Output pReturnType)
{
	Kill pClass,pMethod,pArgArray,pNameMap,returnType
	
	If (..query '= "") {
		// Class Query - method = query name
		If $Length(..query,":") > 1 {
			Set pClass = $Piece(..query,":")
			Set pMethod = $Piece(..query,":",2)
		} Else {
			Set pClass = pModelClass
			Set pMethod = ..query
		}
		
		Set formalspec = $$$comMemberKeyGet(pClass,$$$cCLASSquery,pMethod,$$$cQUERYformalspecparsed)
		Set pointer = 0
		While $ListNext(formalspec, pointer, argument) {
			Set pArgArray($Increment(pArgArray)) = $List(argument,1,2)
			Set pNameMap($ListGet(argument)) = pArgArray
		}
		If (..modelClass '= "") {
			Set pModelClass = ..modelClass
		}
		Set pReturnType = "%pkg.isc.rest.model.queryResult"
	} Else {
		// Normal method call
		If $Length(..call,":") > 1 {
			Set pClass = $Piece(..call,":")
			Set pMethod = $Piece(..call,":",2)
		} Else {
			Set pClass = pModelClass
			Set pMethod = ..call
		}
		
		Set formalspec = $$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHformalspecparsed)
		Set pointer = 0
		While $ListNext(formalspec, pointer, argument) {
			Set pArgArray($Increment(pArgArray)) = $List(argument,1,2)
			Set pNameMap($ListGet(argument)) = pArgArray
		}
		Set pReturnType = $$$NormalizeClassname($$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHreturntype))
	}
}

}

