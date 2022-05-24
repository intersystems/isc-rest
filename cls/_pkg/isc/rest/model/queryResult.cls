/// This class is internal to %pkg.isc.rest; consumers should not need to use it directly.
Class %pkg.isc.rest.model.queryResult Extends (%RegisteredObject, %pkg.isc.rest.model.iSerializable) [ System = 4 ]
{

/// Only used in method signatures.
Parameter MODELCLASS As STRING;

Property rows As list Of %pkg.isc.rest.model.resource;

ClassMethod FromClassQuery(pModelClass As %Dictionary.CacheClassname, pQueryClass As %Dictionary.CacheClassname, pQueryName As %Dictionary.CacheIdentifier, pArgs...) As %pkg.isc.rest.model.queryResult [ Internal ]
{
	// Use ResultSet rather than %SQL.Statement to support non-SQLProc class queries
	Set result = ##class(%Library.ResultSet).%New(pQueryClass _ ":" _ pQueryName)
	Quit ..FromResultSet(pModelClass, result, pArgs...)
}

ClassMethod FromResultSet(pModelClass As %Dictionary.CacheClassname, pResultSet As %Library.ResultSet, pArgs...) As %pkg.isc.rest.model.queryResult
{
	Set instance = ..%New()
	$$$ThrowOnError(pResultSet.%Execute(pArgs...))
	If (pResultSet.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(pResultSet.%SQLCODE,pResultSet.%Message)
	}
	Set useResult = +$Parameter(pModelClass, "ConstructFromResultRow")
	While pResultSet.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set resource = $classmethod(pModelClass,"GetModelInstance",$Select(useResult:pResultSet,1:pResultSet.%GetData(1)))
		If $IsObject(resource) {
			Do instance.rows.Insert(resource)
		}
	}
	$$$ThrowOnError(sc)
	Quit instance
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status
{
	Set sc = ..JSONExportToStream(.stream)
	If $$$ISOK(sc) {
		Do stream.OutputToDevice()
	}
	Quit sc
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status
{
	Quit ..JSONExportInternal(1,.export)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef export As %String) As %Status
{
	Quit ..JSONExportInternal(0,.export)
}

Method JSONExportInternal(pStreamMode As %Boolean = 1, Output export) As %Status
{
	Try {
		Set buffer = ##class(%pkg.isc.json.util.buffer).%New()
		$$$ThrowOnError(buffer.BeginCaptureOutput())
		Write "["
		For index=1:1:..rows.Count() {
			If (index > 1) {
				Write ","
			}
			$$$ThrowOnError(..rows.GetAt(index).JSONExport())
			If (index#100 = 0) {
				Do ..FlushBuffer(.buffer, pStreamMode, .export)
			}
		}
		Write "]"
		Do ..FlushBuffer(.buffer, pStreamMode, .export)
		$$$ThrowOnError(buffer.EndCaptureOutput())
	} Catch e {
		Kill export
		Set sc = e.AsStatus()
	}
	Quit sc
}

Method FlushBuffer(ByRef pBuffer As %pkg.isc.json.util.buffer, pStreamMode As %Boolean = 1, Output export) [ Private ]
{
	If (pStreamMode) {
		$$$ThrowOnError(pBuffer.ReadToStream(.export))
		$$$ThrowOnError(pBuffer.EndCaptureOutput())
		Set pBuffer = ##class(%pkg.isc.json.util.buffer).%New()
		$$$ThrowOnError(pBuffer.BeginCaptureOutput())
	} Else {
		$$$ThrowOnError(pBuffer.ReadToString(.export))
		$$$ThrowOnError(pBuffer.EndCaptureOutput())
		Set pBuffer = ##class(%pkg.isc.json.util.buffer).%New()
		$$$ThrowOnError(pBuffer.BeginCaptureOutput())
	}
}

}
