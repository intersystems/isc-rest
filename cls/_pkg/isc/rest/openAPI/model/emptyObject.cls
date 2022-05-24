Class %pkg.isc.rest.openAPI.model.emptyObject Extends (%pkg.isc.rest.openAPI.model.schemaOrReference, %pkg.isc.rest.openAPI.model.super)
{

Method JSONExportOverride(write As %Boolean) As %Status
{
	Write:write "{}"
	Set:'write %export = %export_"{}"
	Return $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}

