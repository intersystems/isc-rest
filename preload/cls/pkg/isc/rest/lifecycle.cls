Class pkg.isc.rest.lifecycle Extends %ZPM.PackageManager.Developer.Lifecycle.Module
{
ClassMethod RunOnLoad() [ CodeMode = objectgenerator ]
{
	Quit:$Extract($Namespace)="^" $$$OK
	Set sc = $$$OK
	Try {
		If ##class(%Dictionary.ClassDefinition).%ExistsId("%IPM.Utils.Module") {
			Set utilClass = "%IPM.Utils.Module"
		} Else {
			Set utilClass = "%ZPM.PackageManager.Developer.Utils"
		}
		Set sourceDB = $ClassMethod(utilClass, "GetRoutineDatabase", $Namespace)
		Set sc = $ClassMethod(utilClass, "AddGlobalMapping", $Namespace, "oddPKG(""%pkg.isc.rest"")", sourceDB)
		$$$ThrowOnError(sc)
		Set sc = $ClassMethod(utilClass, "AddPackageMapping", $Namespace, "%pkg.isc.rest", sourceDB)
		$$$ThrowOnError(sc)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

ClassMethod GetUtilClass() As %String
{
	If ##class(%Dictionary.ClassDefinition).%ExistsId("%IPM.Utils.Module") {
		Return "%IPM.Utils.Module"
	} Else {
		Return "%ZPM.PackageManager.Developer.Utils"
	}
}

Method %Reload(ByRef pParams) As %Status
{
	Set sc = $$$OK
	Try {
		Set utilClass = ..GetUtilClass()
		Set sourceDB = $ClassMethod(utilClass, "GetRoutineDatabase", $Namespace)
		Set sc = $ClassMethod(utilClass, "AddGlobalMapping", $Namespace, "oddPKG(""%pkg.isc.rest"")", sourceDB)
		$$$ThrowOnError(sc)
		Set sc = $ClassMethod(utilClass, "AddPackageMapping", $Namespace, "%pkg.isc.rest", sourceDB)
		$$$ThrowOnError(sc)
		// Ensure super is called AFTER mappings are set up
		Set sc = ##super(.pParams)
		$$$ThrowOnError(sc)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

Method %Clean(ByRef pParams) As %Status
{
	Set sc = $$$OK
	Try {
		Set sc = ##super(.pParams)
		$$$ThrowOnError(sc)
		Set utilClass = ..GetUtilClass()
		Do $ClassMethod(utilClass, "RemoveGlobalMapping", $Namespace, "oddPKG(""%pkg.isc.rest"")")
		Do $ClassMethod(utilClass, "RemovePackageMapping", $Namespace,"%pkg.isc.rest")
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

}

