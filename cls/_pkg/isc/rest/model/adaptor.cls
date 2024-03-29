Include %occErrors

/// A class may extend %Persistent, %pkg.isc.rest.model.adaptor, and %JSON.Adaptor to grant automatic (but gated) rest exposure of a particular representation.
Class %pkg.isc.rest.model.adaptor Extends %pkg.isc.rest.model.dbMappedResource [ Abstract, System = 4 ]
{

/// For an adapted class, the class itself is the source.
Parameter SOURCECLASS As COSEXPRESSION [ Final ] = "$classname()";

/// Uses the data from a persistent object to populate the properties of this model.
ClassMethod GetModelFromObject(object As %Persistent) As %pkg.isc.rest.model.adaptor [ Final ]
{
	Return object
}

/// Saves the model instance
Method SaveModelInstance(pUserContext As %RegisteredObject) [ Final ]
{
	Do ..OnBeforeSaveModel(.pUserContext)
	$$$ThrowOnError(..%Save())
	Do ..OnAfterSaveModel(.pUserContext)
}

/// Deletes an instance of this model, based on the identifier <var>pID</var>
ClassMethod DeleteModelInstance(pID As %String) As %Boolean [ Final ]
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
	Quit ..%JSONImport(.input, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status [ Final ]
{
	Quit ..%JSONExport(..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status [ Final ]
{
	Quit ..%JSONExportToStream(.export, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status [ Final ]
{
	Quit ..%JSONExportToString(.%export, ..#JSONMAPPING)
}

}

