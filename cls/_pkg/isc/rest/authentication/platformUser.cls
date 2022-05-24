Class %pkg.isc.rest.authentication.platformUser Extends (%RegisteredObject, %JSON.Adaptor, %pkg.isc.rest.model.iSerializable)
{

Property Username As %String [ InitialExpression = {$Username} ];

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status
{
    Quit ..%JSONExport()
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status
{
    Quit ..%JSONExportToStream(.export)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status
{
    Quit ..%JSONExportToString(.export)
}

}
