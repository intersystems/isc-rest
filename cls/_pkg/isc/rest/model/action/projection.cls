/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.projection Extends %Projection.AbstractProjection [ System = 3 ]
{

/// Ensure this projection is applied in the main thread to prevent race conditions/deadlock when REST dispatch
/// classes and resources are being compiled at the same time.
Parameter DisableMulticompile As BOOLEAN = 1;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
	Set sc = $$$OK
	Set initTransLevel = $TLevel
	Try {
		Set actions = ##class(%pkg.isc.rest.model.action.generator).GetActionMetadata(classname)
		If (actions.actions.Count() = 0) {
			Quit
		}
		
		TSTART
		
		// Create action handler class
		Set targetClass = classname_".Actions"
		
		Set classDefinition = ##class(%Dictionary.ClassDefinition).%New()
		Set classDefinition.Name = targetClass
		Set classDefinition.Super = "%pkg.isc.rest.model.action.handler"
		Set classDefinition.ProcedureBlock = 1
		
		Set param = ##class(%Dictionary.ParameterDefinition).%New()
		Set param.Name = "SOURCECLASS"
		Set param.Default = classname
		Do classDefinition.Parameters.Insert(param)
		
		Set dependencies = ##class(%pkg.isc.rest.model.action.generator).GetClassDependencies(classname)
		Set classDefinition.CompileAfter = $ListToString(dependencies)
		Set classDefinition.DependsOn = $ListToString(dependencies)
		
		$$$ThrowOnError(classDefinition.%Save())
		
		Do ..QueueClass(targetClass)
		
		TCOMMIT
	} Catch e {
		Set sc = e.AsStatus()
	}
	
	While ($TLevel > initTransLevel) {
		TROLLBACK 1
	}
	Quit sc
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
	Set sc = $$$OK
	Set initTransLevel = $TLevel
	Try {
		TSTART
		
		Set targetClass = classname_".Actions"
		If ##class(%Dictionary.ClassDefinition).%ExistsId(targetClass) {
			$$$ThrowOnError($System.OBJ.Delete(targetClass,.qstruct))
		}
		
		&sql(delete from %pkg_isc_rest.actionMap where ResourceClass = :classname)
		If (SQLCODE < 0) {
			Throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg)
		}
		
		TCOMMIT
	} Catch e {
		Set sc = e.AsStatus()
	}
	
	While ($TLevel > initTransLevel) {
		TROLLBACK 1
	}
	Quit sc
}

}

