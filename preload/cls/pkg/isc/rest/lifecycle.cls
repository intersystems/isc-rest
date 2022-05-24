Class %pkg.isc.rest.lifecycle Extends %ZPM.PackageManager.Developer.Lifecycle.Module
{
ClassMethod RunOnLoad() [ CodeMode = objectgenerator ]
{
	Quit:$Extract($Namespace)="^" $$$OK
	Set sc = $$$OK
	Try {
		Set sourceDB = ##class(%ZPM.PackageManager.Developer.Utils).GetRoutineDatabase($Namespace)
		Set sc = ##class(%ZPM.PackageManager.Developer.Utils).AddGlobalMapping($Namespace,"oddPKG(""%pkg.isc.rest"")",sourceDB)
		$$$ThrowOnError(sc)
		Set sc = ##class(%ZPM.PackageManager.Developer.Utils).AddPackageMapping($Namespace,"%pkg.isc.rest",sourceDB)
		$$$ThrowOnError(sc)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

Method %Reload(ByRef pParams) As %Status
{
	Set sc = $$$OK
	Try {
		Set sourceDB = ##class(%ZPM.PackageManager.Developer.Utils).GetRoutineDatabase($Namespace)
		Set sc = ##class(%ZPM.PackageManager.Developer.Utils).AddGlobalMapping($Namespace,"oddPKG(""%pkg.isc.rest"")",sourceDB)
		$$$ThrowOnError(sc)
		Set sc = ##class(%ZPM.PackageManager.Developer.Utils).AddPackageMapping($Namespace,"%pkg.isc.rest",sourceDB)
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
		Do ##class(%ZPM.PackageManager.Developer.Utils).RemoveGlobalMapping($Namespace,"oddPKG(""%pkg.isc.rest"")")
		Do ##class(%ZPM.PackageManager.Developer.Utils).RemovePackageMapping($Namespace,"%pkg.isc.rest")
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

}

