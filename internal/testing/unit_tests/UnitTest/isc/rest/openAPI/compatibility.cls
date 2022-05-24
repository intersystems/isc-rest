/// Utilities for compatibility with %pkg.isc.json
Class UnitTest.isc.rest.openAPI.compatibility
{

ClassMethod GetJSONAdaptorClass() As %String
{
	try {
		return ##class(%pkg.isc.json.adaptor).%ClassName(1)		
	} catch {}
	return ##class(%JSON.Adaptor).%ClassName(1)
}

ClassMethod GetJSONMappingClass() As %String
{
	try {
		return ##class(%pkg.isc.json.mapping).%ClassName(1)		
	} catch {}
	return ##class(%JSON.Mapping).%ClassName(1)
}

ClassMethod GetBooleanClass() As %String
{
	try {
		return ##class(%pkg.isc.json.dataType.boolean).%ClassName(1)		
	} catch {}
	return ##class(%Library.Boolean).%ClassName(1)
}

}

