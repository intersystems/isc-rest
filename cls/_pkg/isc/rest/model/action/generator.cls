/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.generator [ System = 2 ]
{

ClassMethod GenerateClassActions(pCode As %Stream.Object, pActionClassName As %Dictionary.CacheClassname)
{
	Do ..GenerateActions(pCode, pActionClassName, "class")
}

ClassMethod GenerateInstanceActions(pCode As %Stream.Object, pActionClassName As %Dictionary.CacheClassname)
{
	Do ..GenerateActions(pCode, pActionClassName, "instance")
}

ClassMethod GenerateActions(pCode, pActionClassName, pType) [ Private ]
{
	#dim metadata As %pkg.isc.rest.model.action.t.actions
	#dim action As %pkg.isc.rest.model.action.t.action
	
	Set initTLevel = $TLevel

	Try {
		
		Set sourceClass = ..GetSourceClass(pActionClassName)
		If (sourceClass = "") {
			Quit
		}
		
		Set metadata = ..GetActionMetadata(sourceClass)
		Set resourceName = $Parameter(sourceClass,"RESOURCENAME")
		
		TSTART
		Kill generateMap // Keeps track of generated code per action
		Kill seenActionMap // Keeps track actions that have already been seen (using the action resolved name)
		For index=1:1:metadata.actions.Count() {
			Set action = metadata.actions.GetAt(index)
			If (action.target '= pType) {
				Continue
			}
			// NOTE: Important to use the resolved name to ensure actions with
			// the same path parameters (but differently named) are flagged
			// as duplicate. e.g. /hello/:one and /hello/:two are fundamentally
			// the same action and so should be disallowed.
			Set seenActionMapKey = $ListBuild(action.resolvedName,action.method)
			If $Data(seenActionMap(seenActionMapKey)) {
				// This action name + method has been seen so there is a duplicate
				// which is not permitted
				Set msg = $$$FormatText("Duplicate action found. Name: '%1'. Method: '%2'",action.name,action.method)
				$$$ThrowStatus($$$ERROR($$$GeneralError,msg))
			}
			Do action.Generate(sourceClass, .actionCode, .accepts, .contentType)
			
			// Register newly-created actions.
			&sql(insert or update into %pkg_isc_rest.actionMap
				(DispatchClass, ResourceName, ActionName, ActionTarget, HTTPVerb, MediaType, Accepts, ResourceClass, ImplementationClass) values
				(NULL, :resourceName, :action.name, :action.target, :action.method, :contentType, :accepts, :sourceClass, :pActionClassName))
			If (SQLCODE < 0) {
				Throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg)
			}
			
			Set seenActionMap(seenActionMapKey) = ""
			Merge generateMap($ListBuild(action.resolvedName,action.method)) = actionCode
		}
		
		Do %code.WriteLine($c(9)_"Set tAction = $ZConvert(pAction,""L"")")
		
		Set key = ""
		For {
			Set key = $Order(generateMap(key),1,lineCount)
			Quit:key=""
			
			Set $ListBuild(actionResolvedName,httpMethod) = key
			
			If $Increment(counter) = 1 {
				Set prefix = $c(9)_"If "
			} Else {
				Set prefix = $c(9)_"} ElseIf "
			}
			Set prefix = prefix _ "$Match(tAction, "_$$$QUOTE($ZConvert(actionResolvedName,"L"))_") && (pHTTPMethod = "_$$$QUOTE(httpMethod)_") {"
			
			Do %code.WriteLine(prefix)
			
			For line=1:1:lineCount {
				Do %code.WriteLine($c(9)_generateMap(key,line))
			}
		}
		
		If $Get(counter,0) {
			Do %code.WriteLine($c(9)_"}")
		}
		
		TCOMMIT
	} Catch e {
	} // Finally:
	
	While $TLevel > initTLevel {
		TROLLBACK 1
	}
	
	If $IsObject($Get(e)) {
		Throw e
	}
}

ClassMethod GetActionMetadata(pSourceClass As %Dictionary.CacheClassname) As %pkg.isc.rest.model.action.t.actions
{
	Set emptyActions = ##class(%pkg.isc.rest.model.action.t.actions).%New()
	If (pSourceClass = "") || $$$comClassKeyGet(pSourceClass,$$$cCLASSabstract) {
		Return emptyActions
	}
	
	Set origin = $$$comMemberKeyGet(pSourceClass,$$$cCLASSxdata,"ActionMap",$$$cXDATAorigin)
	Set xData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(origin,"ActionMap",,.sc)
	$$$ThrowOnError(sc)
	
	If (xData.Data.Size = 0) {
		Return emptyActions
	}
	
	Set reader = ##class(%XML.Reader).%New()
	Do reader.CorrelateRoot("%pkg.isc.rest.model.action.t.actions")
	$$$ThrowOnError(reader.OpenStream(xData.Data))
	While reader.Next(.actions,.sc) {
		$$$ThrowOnError(sc)
		$$$ThrowOnError(actions.%ValidateObject())
		Return actions
	}
	$$$ThrowOnError(sc)
	
	Return emptyActions
}

ClassMethod GetSourceClass(pActionClassName As %Dictionary.CacheClassname) As %Dictionary.CacheClassname
{
	If $$$comClassKeyGet(pActionClassName,$$$cCLASSabstract) {
		Quit ""
	}
	
	Set sourceClass = $$$comMemberKeyGet(pActionClassName,$$$cCLASSparameter,"SOURCECLASS",$$$cPARAMdefault)
	If (sourceClass = "") {
		Set sc = $$$ERROR($$$GeneralError,$$$FormatText("SOURCECLASS parameter not defined in class %1",pActionClassName))
		$$$ThrowStatus(sc)
	}
	Quit sourceClass
}

ClassMethod GetClassDependencies(pSourceClass As %Dictionary.CacheClassname) As %List
{
	#dim metadata As %pkg.isc.rest.model.action.t.actions
	#dim action As %pkg.isc.rest.model.action.t.action
	
	Set metadata = ..GetActionMetadata(pSourceClass)
	Set list = ""
	For index=1:1:metadata.actions.Count() {
		Set action = metadata.actions.GetAt(index)
		Do action.GetDependencies(pSourceClass,.dependencies)
	}
	
	Set class = ""
	For {
		Set class = $Order(dependencies(class))
		Quit:class=""
		
		Set list = list_$ListBuild(class)
	}
	
	Quit list
}

}

