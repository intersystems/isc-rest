/// Use or operation of this code is subject to acceptance of the license available in the code repository for this code.
/// This is a sample embeddable class representing an address.
Class UnitTest.isc.rest.sample.data.address Extends (%SerialObject, %Populate, %XML.Adaptor, %pkg.isc.rest.model.iSerializable, %pkg.isc.json.adaptor)
{

Parameter MEDIATYPE = "application/vnd.intersystems.com.isc.rest.unit.test.address+v1.json";

/// The street address.
Property Street As %String(MAXLEN = 80, POPSPEC = "Street()");

/// The city name.
Property City As %String(MAXLEN = 80, POPSPEC = "City()");

/// The 2-letter state abbreviation.
Property State As %String(MAXLEN = 2, POPSPEC = "USState()");

/// The 5-digit U.S. Zone Improvement Plan (ZIP) code.
Property Zip As %String(MAXLEN = 5, POPSPEC = "USZip()");

/// JSONImport imports JSON or dynamic object input into this object.<br />
/// The input argument is either JSON as a string or stream, or a subclass of %DynamicAbstractObject.
Method JSONImport(input) As %Status
{
	Quit ..%JSONImport(.input)
}

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
	Quit ..%JSONExportToString(.%export)
}

Storage Default
{
<Data name="addressState">
<Value name="1">
<Value>Street</Value>
</Value>
<Value name="2">
<Value>City</Value>
</Value>
<Value name="3">
<Value>State</Value>
</Value>
<Value name="4">
<Value>Zip</Value>
</Value>
</Data>
<State>addressState</State>
<StreamLocation>^UnitTest.isc.rest6EBF.addressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}

