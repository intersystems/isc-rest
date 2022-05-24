Class %pkg.isc.rest.openAPI.resourceInfoStub Extends %RegisteredObject
{

Property ClassName As %String;

Property JSONMapping As %String;

Property ResourceName As %String;

Property MediaType As %String;

Property Null As %Boolean;

Property NullOverwritten As %Boolean [ Internal ];

Property IgnoreNull As %Boolean;

Property IgnoreNullOverwritten As %Boolean [ Internal ];

Property Reference As %String;

Property ReferenceOverwritten As %Boolean [ Internal ];

Property IncludeID As %Boolean;

Property IDField As %String;

Property Include As %String;

Property IncludeOverwritten As %Boolean [ Internal ];

Property FieldName As %String;

Property FieldNameOverwritten As %Boolean [ Internal ];

Property JSONType As %String;

Property JSONTypeOverwritten As %Boolean [ Internal ];

Property Description As %String [ Internal ];

Property PropertiesDefaultJSONMapping As %String;

Property PropertiesDefaultJSONMappingOverwritten As %Boolean [ Internal ];

Property PropertiesDefaultIncludeID As %Boolean;

Property PropertiesDefaultIncludeIDOverwritten As %Boolean [ Internal ];

Property PropertiesDefaultIDField As %String;

Property PropertiesDefaultIDFieldOverwritten As %Boolean [ Internal ];

Property PropertiesDefaultReference As %String;

Property PropertiesDefaultReferenceOverwritten As %Boolean [ Internal ];

Method %OnNew(className, jsonMapping, resourceName, mediaType, includeID, idField, null, ignoreNull, propertiesDefaultJSONMapping, reference, include, fieldName, jsonType, propertiesDefaultIncludeID, propertiesDefaultIDField, propertiesDefaultReference) As %Status
{
	// Set the "normal" values
	Set:$Data(className) ..ClassName = className
	Set:$Data(jsonMapping) ..JSONMapping = jsonMapping
	Set:$Data(resourceName) ..ResourceName = resourceName
	Set:$Data(mediaType) ..MediaType = mediaType
	Set:$Data(includeID) ..IncludeID = includeID
	Set:$Data(idField) ..IDField = idField
	
	// Figure out what (if anything) is being overwritten
	Set ..NullOverwritten = $Data(null) && (null'=$c(0)) && (null'="")
	Set ..IgnoreNullOverwritten = $Data(ignoreNull) && (ignoreNull'=$c(0)) && (ignoreNull'="")
	Set ..PropertiesDefaultJSONMappingOverwritten = $Data(propertiesDefaultJSONMapping) && (propertiesDefaultJSONMapping'=$c(0))
	Set ..ReferenceOverwritten = $Data(reference) && (reference'=$c(0))
	Set ..IncludeOverwritten = $Data(include) && (include'=$c(0))
	Set ..FieldNameOverwritten = $Data(fieldName) && (fieldName'=$c(0))
	Set ..JSONTypeOverwritten = $Data(jsonType) && (jsonType'=$c(0))
	Set ..PropertiesDefaultIncludeIDOverwritten = $Data(propertiesDefaultIncludeID) && (propertiesDefaultIncludeID'=$c(0))
	Set ..PropertiesDefaultIDFieldOverwritten = $Data(propertiesDefaultIDField) && (propertiesDefaultIDField'=$c(0))
	Set ..PropertiesDefaultReference = $Data(propertiesDefaultReference) && (propertiesDefaultReference'=$c(0))
	
	// Set the overwritten values accordingly
	Set:..NullOverwritten ..Null = null
	Set:..IgnoreNullOverwritten ..IgnoreNull = ignoreNull
	Set:..PropertiesDefaultJSONMappingOverwritten ..PropertiesDefaultJSONMapping = propertiesDefaultJSONMapping
	Set:..ReferenceOverwritten ..Reference = reference
	Set:..IncludeOverwritten ..Include = include
	Set:..FieldNameOverwritten ..FieldName = fieldName
	Set:..JSONTypeOverwritten ..JSONType = jsonType
	Set:..PropertiesDefaultIncludeIDOverwritten ..PropertiesDefaultIncludeID = propertiesDefaultIncludeID
	Set:..PropertiesDefaultIDFieldOverwritten ..PropertiesDefaultIDField = propertiesDefaultIDField
	Set:..PropertiesDefaultReferenceOverwritten ..PropertiesDefaultReference = propertiesDefaultReference
	
	Return $$$OK
}

Method PopulateNonOverwrittenValues(fallbackReference = "OBJECT", fallbackIncludeID = 1, fallbackIDField = "_id")
{
	
	// JSON Type
	If '..JSONTypeOverwritten {
		Set ..JSONType = ##class(%pkg.isc.rest.openAPI.util).GetJSONType(..ClassName)
	}
	
	// XData or Class Parameters + Property Parameters
	If ..JSONMapping '= "" && (..JSONMapping'=$c(0)) {
		Try {
			Set mapping = ##class(%pkg.isc.rest.openAPI.util).ParseJSONMapping(..ClassName, ..JSONMapping)
			Set:'..PropertiesDefaultJSONMappingOverwritten ..PropertiesDefaultJSONMapping = mapping.Mapping
			Set:'..PropertiesDefaultReferenceOverwritten ..PropertiesDefaultReference = mapping.Reference
			// Use $Property for Cache/IRIS cross-compatability
			Set:'..PropertiesDefaultIncludeIDOverwritten ..PropertiesDefaultIncludeID = $Property(mapping, "IncludeID")
			Set:'..PropertiesDefaultIDFieldOverwritten ..PropertiesDefaultIDField = $Property(mapping, "IDField")
		} Catch {}
	} Else {
		//Set:'..PropertiesDefaultJSONMappingOverwritten ..PropertiesDefaultJSONMapping = $Parameter(..ClassName, "%JSONMAPPING")
		Set:'..ReferenceOverwritten ..Reference = $ZConvert($Parameter(..ClassName, "%JSONREFERENCE"),"U")
		Set ..IncludeID = $Parameter(..ClassName, "%JSONINCLUDEID")
		Set ..IDField = $Parameter(..ClassName, "%JSONIDFIELD")
	}
	
	// Handle default values
	Set:..MediaType="" ..MediaType = "application/json"
	Set:..Null="" ..Null = 0
	Set:..IgnoreNull="" ..IgnoreNull = 0
	Set:..Reference="" ..Reference = fallbackReference
	Set:..IncludeID="" ..IncludeID = fallbackIncludeID
	Set:..IDField="" ..IDField = fallbackIDField
}

/// Get a string-valued representation of this object (allows for easy equality comparisons)
Method AsString() As %String
{
	Return ..ClassName_"||"_..JSONMapping_"||"_$s(..NullOverwritten:..Null,1:0)_"||"_$s(..IgnoreNullOverwritten:..IgnoreNull,1:0)_"||"_$s(..PropertiesDefaultJSONMappingOverwritten:..PropertiesDefaultJSONMapping,1:"")_"||"_$s(..ReferenceOverwritten:..Reference,1:"OBJECT")_"||"_$s(..IncludeID="":1,1:..IncludeID)_"||"_$s(..IDField="":"_id",1:..IDField)_"||"_$s(..JSONTypeOverwritten:..JSONType,1:"")_"||"_$s(..PropertiesDefaultIncludeIDOverwritten:..PropertiesDefaultIncludeID,1:1)_"||"_$s(..PropertiesDefaultIDFieldOverwritten:..PropertiesDefaultIDField,1:"_id")_"||"_$s(..PropertiesDefaultReferenceOverwritten:..PropertiesDefaultReference,1:"OBJECT")
}

}

