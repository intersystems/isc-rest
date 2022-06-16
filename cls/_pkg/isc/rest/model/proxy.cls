Include %occErrors

/// Provides REST access to a particular (named) representation of a JSON-enabled persistent class.
Class %pkg.isc.rest.model.proxy Extends %pkg.isc.rest.model.dbMappedResource [ Abstract, System = 4 ]
{

Property %instance As %pkg.isc.json.adaptor [ Private, Transient ];

ClassMethod GetModelFromObject(obj As %Persistent) As %pkg.isc.rest.model.proxy [ Internal ]
{
	Set proxy = ..%New()
	Set proxy.%instance = obj
	Return proxy
}

/// Saves the model instance
Method SaveModelInstance(pUserContext As %RegisteredObject)
{
	do ..OnBeforeSaveModel(.pUserContext)
	$$$ThrowOnError(..%instance.%Save())
	do ..OnAfterSaveModel(.pUserContext)
}

/// Deletes an instance of this model, based on the identifier <var>pID</var>
ClassMethod DeleteModelInstance(pID As %String) As %Boolean
{
	If ..#IndexToUse = "ID" {
		Set tSC = $classmethod(..#SOURCECLASS,"%DeleteId",pID)
	} Else {
		Set tSC = $classmethod(..#SOURCECLASS,..#IndexToUse_"Delete",pID)
	}
	If $System.Status.Equals(tSC,$$$DeleteObjectNotFound) || $System.Status.Equals(tSC,$$$KeyValueNotFoundDelete) {
		Quit 0
	}
	$$$ThrowOnError(tSC)
	Quit 1
}

/// JSONImport imports JSON or dynamic object input into this object.<br />
/// The input argument is either JSON as a string or stream, or a subclass of %DynamicAbstractObject.
Method JSONImport(input) As %Status [ Final ]
{
	Quit ..%instance.%JSONImport(.input, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status [ Final ]
{
	Quit ..%instance.%JSONExport(..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status [ Final ]
{
	Quit ..%instance.%JSONExportToStream(.export, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status [ Final ]
{
	Quit ..%instance.%JSONExportToString(.%export, ..#JSONMAPPING)
}

}

