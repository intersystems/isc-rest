/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.handler [ Abstract, System = 3 ]
{

/// The class for which action handlers will be generated.
Parameter SOURCECLASS As CLASSNAME;

ClassMethod HandleInvokeClassAction(pHTTPMethod As %String, pAction As %String, pUserContext As %pkg.isc.rest.model.resource) [ CodeMode = objectgenerator ]
{
	Set sc = $$$OK
	Try {
		Do ##class(%pkg.isc.rest.model.action.generator).GenerateClassActions(%code, %compiledclass.Name)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

ClassMethod HandleInvokeInstanceAction(pHTTPMethod As %String, pInstance As %pkg.isc.rest.model.resource, pAction As %String, pUserContext As %pkg.isc.rest.model.resource) [ CodeMode = objectgenerator ]
{
	Set sc = $$$OK
	Try {
		Do ##class(%pkg.isc.rest.model.action.generator).GenerateInstanceActions(%code, %compiledclass.Name)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

}
