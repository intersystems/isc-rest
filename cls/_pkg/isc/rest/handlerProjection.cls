Class %pkg.isc.rest.handlerProjection Extends %Projection.AbstractProjection [ System = 4 ]
{

/// Ensure this projection is applied in the main thread to prevent race conditions/deadlock when REST dispatch
/// classes and resources are being compiled at the same time.
Parameter DisableMulticompile As BOOLEAN = 1;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
	Set initTLevel = $TLevel
	Set sc = $$$OK
	Try {
		TSTART
		Set permittedClasses = ""
		Set resourceClasses = ##class(%Dictionary.ClassDefinition).SubclassOfFunc("%pkg.isc.rest.model.resource")
		While resourceClasses.%Next(.sc) {
			$$$ThrowOnError(sc)
			Set resourceClass = resourceClasses.Name
			If $$$comClassKeyGet(resourceClass,$$$cCLASSabstract) {
				Continue
			}
			If $classmethod(classname, "CheckResourcePermitted", resourceClass) {
				Do ..AddPermittedClass(classname, resourceClass)
				Set permittedClasses = permittedClasses_$ListBuild(resourceClass)
			}
		}
		$$$ThrowOnError(sc)
		
		// Remove resources for which access is no longer permitted
		&sql(delete from %pkg_isc_rest.resourceMap where DispatchClass = :classname and ResourceClass not %INLIST :permittedClasses)
		&sql(delete from %pkg_isc_rest.actionMap where DispatchClass = :classname and ResourceClass not %INLIST :permittedClasses)
		TCOMMIT
	} Catch e {
		Set sc = e.AsStatus()
	}
	While ($TLevel > initTLevel) {
		TROLLBACK 1
	}
	Quit sc
}

/// Called from trigger in resourceMap
ClassMethod ValidateDefaultForHandlers(resourceClass As %Dictionary.Classname)
{
	Set validSC = $$$OK
	Set handlerClasses = ##class(%Dictionary.ClassDefinition).SubclassOfFunc("%pkg.isc.rest.handler")
	While handlerClasses.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set handlerClass = handlerClasses.Name
		If $$$comClassKeyGet(handlerClass,$$$cCLASSabstract) {
			Continue
		}
		Try {
			If $System.CLS.IsMthd(handlerClass, "CheckResourcePermitted") && $classmethod(handlerClass, "CheckResourcePermitted", resourceClass) {
				Set resourceName = $Parameter(resourceClass,"RESOURCENAME")
				If ##class(%pkg.isc.rest.resourceMap).UniqueDefaultResourceExists(handlerClass, resourceName, 1, .id) {
					Set existingClass = ##class(%pkg.isc.rest.resourceMap).ResourceClassGetStored(id)
					If existingClass '= resourceClass {
						Set msg = $$$FormatText("%1 is already registered as the default resource for name %2 in dispatch class %3", existingClass, resourceName, handlerClass)
						$$$ThrowStatus($$$ERROR($$$GeneralError,msg))
					}
				}
			}
		} Catch e {
			set validSC = $$$ADDSC(validSC,e.AsStatus())
		}
	}
	$$$ThrowOnError(sc)
	$$$ThrowOnError(validSC)
}

/// Called from triggers in actionMap and resourceMap
ClassMethod AddResourceWherePermitted(resourceClass As %Dictionary.Classname)
{
	Set handlerClasses = ##class(%Dictionary.ClassDefinition).SubclassOfFunc("%pkg.isc.rest.handler")
	While handlerClasses.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set handlerClass = handlerClasses.Name
		If $$$comClassKeyGet(handlerClass,$$$cCLASSabstract) {
			Continue
		}
		Try {
			If $System.CLS.IsMthd(handlerClass, "CheckResourcePermitted") && $classmethod(handlerClass, "CheckResourcePermitted", resourceClass) {
				Do ..AddPermittedClass(handlerClass, resourceClass)
			}
		} Catch e {
			Write !,"Warning: Exception occurred updating permitted class cache: ",e.DisplayString()
		}
	}
	$$$ThrowOnError(sc)
}

ClassMethod AddPermittedClass(handlerClass As %Dictionary.Classname, resourceClass As %Dictionary.Classname) [ Private ]
{
	New %objlasterror // Avoid ERROR #6084
	// Add/update resourceMap based on the root dispatch-class-independent record
	If '##class(%pkg.isc.rest.resourceMap).UniqueByClassnamesExists(resourceClass,resourceClass,.id) {
		Write !,"WARNING: No resourceMap entry found for resource class "_resourceClass
		Quit
	}
	Set source = ##class(%pkg.isc.rest.resourceMap).%OpenId(id,,.sc)
	$$$ThrowOnError(sc)
	If ##class(%pkg.isc.rest.resourceMap).UniqueByClassnamesExists(handlerClass,resourceClass,.id) {
		Set target = ##class(%pkg.isc.rest.resourceMap).%OpenId(id,,.sc)
		$$$ThrowOnError(sc)
	} Else {
		Set target = ##class(%pkg.isc.rest.resourceMap).%New()
	}
	Set target.DispatchClass = handlerClass
	Set target.ResourceClass = resourceClass
	Set target.MediaType = source.MediaType
	Set target.ResourceName = source.ResourceName
	Set target.IsDefault = source.IsDefault
	$$$ThrowOnError(target.%Save())
	
	// Insert/update actionMap (update should always be a no-op)
	&sql(insert or update into %pkg_isc_rest.actionMap
		(DispatchClass, ResourceName, ActionName, ActionTarget, HTTPVerb, MediaType, Accepts, ResourceClass, ImplementationClass)
		select :handlerClass, ResourceName, ActionName, ActionTarget, HTTPVerb, MediaType, Accepts, ResourceClass, ImplementationClass
		from %pkg_isc_rest.actionMap
		where DispatchOrResourceClass = :resourceClass and ResourceClass = :resourceClass)
	$$$ThrowSQLIfError(SQLCODE,%msg)
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
	Set sc = $$$OK
	Try {
		// When recompiling, we handle incremental changes via CreateProjection.
		If 'recompile {
			Write !,"Clearing resourceMap and actionMap for class ",classname
			&sql(delete from %pkg_isc_rest.resourceMap where DispatchOrResourceClass = :classname)
			&sql(delete from %pkg_isc_rest.actionMap where DispatchOrResourceClass = :classname)
		}
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

}

