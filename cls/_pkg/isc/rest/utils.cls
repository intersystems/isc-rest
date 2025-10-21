Include %syConfig

/// General utility class.
Class %pkg.isc.rest.utils [ Abstract, System = 4 ]
{

/// This module contains some persistent classes to keep track of metadata for 
/// REST APIs. This method maps all persistent data from a source database to
/// a target namespace. <br />
/// @API.Method <br />
/// @Argument	pSourceDatabase		Source database from which to copy global
/// data. <br />
/// @Argument	pTargetNamespace	Target namespace to which data is to be copied.
/// MUST NOT be an implied namespace. <br />
ClassMethod MapPersistentData(pSourceDatabase As %String, pTargetNamespace As %String)
{
	Set initTLevel = $Tlevel
	Set sc = $$$OK
	Try {
		// Get globals
		Set globalList = ..GetPersistentDataGlobalList(pTargetNamespace)
		// Add mappings for all globals
		TSTART
		New $Namespace
		Set $Namespace = "%SYS"
		Kill props
		Set props("Database") = pSourceDatabase
		Set ptr = 0
		While $ListNext(globalList,ptr,global) {
			// get rid of the prefix "^" of the global name
    		Set global = $Select($Extract(global, 1) = "^": $Extract(global, 2, *), 1: global)
			If '$ClassMethod("Config.MapGlobals", "Exists", pTargetNamespace, global) {
				Set sc = $ClassMethod("Config.MapGlobals", "Create", pTargetNamespace, global, .props, , $$$CPFSave)
				$$$ThrowOnError(sc)
			}
		}
		// Activate cpf file
		Set sc = $ClassMethod("Config.CPF", "Write")
		$$$ThrowOnError(sc)
		Set sc = $ClassMethod("Config.Map", "MoveToActive")
		$$$ThrowOnError(sc)
		Set sc = $ClassMethod("Config.Namespaces", "Load", pTargetNamespace)
		$$$ThrowOnError(sc)
		TCOMMIT
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	While ($Tlevel > initTLevel) {
		TROLLBACK 1
	}
	$$$ThrowOnError(sc)
}

/// This module contains some persistent classes to keep track of metadata for 
/// REST APIs. This method copies all persistent data from a source namespace to
/// a target one. <br />
/// @API.Method <br />
/// @Argument	pSourceNamespace	Source namespace from which to copy global
/// data. Can be an implied namespace. <br />
/// @Argument	pTargetNamespace	Target namespace to which data is to be copied.
/// MUST NOT be an implied namespace. <br />
/// @Argument	pKillTargetBeforeCopy	Whether to kill globals in target namespace
/// before copying their content from the source namespace. <br />
ClassMethod CopyPersistentData(pSourceNamespace As %String, pTargetNamespace As %String, pKillTargetBeforeCopy As %Boolean = 1)
{
	Set initTLevel = $Tlevel
	Set sc = $$$OK
	Try {
		// Get globals
		Set globalList = ..GetPersistentDataGlobalList(pTargetNamespace)
		TSTART
		// Copy all globals to target namespace
		Set ptr = 0
		While $ListNext(globalList,ptr,global) {
			Set sourceGlobal = "^|"_$$$QUOTE(pSourceNamespace)_"|"_$Extract(global,2,*)
			Set targetGlobal = "^|"_$$$QUOTE(pTargetNamespace)_"|"_$Extract(global,2,*)
			If (pKillTargetBeforeCopy) {
				// Need to kill target to have a clean slate before merging
				Kill @targetGlobal
			}
			Merge @targetGlobal = @sourceGlobal
		}
		TCOMMIT
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	While ($Tlevel > initTLevel) {
		TROLLBACK 1
	}
	$$$ThrowOnError(sc)
}

ClassMethod GetPersistentDataGlobalList(pNamespace As %String) As %List [ Internal, Private ]
{
	Set globalList = ""
	New $Namespace
	Set $Namespace = pNamespace
	Set query = "SELECT * FROM %Dictionary.ClassDefinition_SubclassOf('%Library.Persistent')"_
		" WHERE Name %STARTSWITH ?"
	#dim resultSet As %SQL.StatementResult
	Set resultSet = ##class(%SQL.Statement).%ExecDirect(, query, "%pkg.isc.rest.")
	$$$ThrowSQLIfError(resultSet.%SQLCODE,resultSet.%Message)
	While resultSet.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set class = resultSet.%Get("Name")
		// Get storage globals and append to list
		For globalType = $$$cSDEFdatalocation,$$$cSDEFindexlocation,$$$cSDEFstreamlocation {
			Set global = $$$comMemberKeyGet(class,$$$cCLASSstorage,"Default",globalType)
			If (global '= "") {
				// Could not have a specific global for child classes so only
				// add if non empty.
				Set globalList = globalList _ $ListBuild(global)
			}
		}
	}
	Return globalList
}

}

