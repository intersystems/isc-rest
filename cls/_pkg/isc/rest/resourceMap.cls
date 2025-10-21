/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.resourceMap Extends %Persistent [ System = 3 ]
{

Index UniqueByContext On (DispatchOrResourceClass, ResourceName, MediaType) [ Unique ];

Index ResourceClass On ResourceClass;

Index ResourceName On ResourceName;

Index UniqueByClassnames On (DispatchOrResourceClass, ResourceClass) [ Unique ];

Index UniqueDefaultResource On (DispatchOrResourceClass, ResourceName, IsDefault) [ Data = MediaType, Unique ];

/// Indicate a global for storage difinitions.
Parameter DEFAULTGLOBAL = "^pkg.isc.rest.resourceMap";

/// Set to null on resource class compilation, or to the dispatch class from the REST handler projection
Property DispatchClass As %Dictionary.Classname;

/// Set to either the DispatchClass or the ResourceClass
Property DispatchOrResourceClass As %Dictionary.Classname [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({DispatchClass},"":{ResourceClass},:{DispatchClass})}, SqlComputed ];

Property ResourceName As %String(MAXLEN = 128) [ Required ];

Property MediaType As %String(MAXLEN = 128) [ Required ];

Property ResourceClass As %Dictionary.Classname [ Required ];

/// Set to 1 if default, NULL if not. (Can only be 1 or null.)
Property IsDefault As %Integer(MAXVAL = 1, MINVAL = 1);

/// Recursive foreign key references the dispatch class-independent record associated with this one (possibly the current record).
/// "Cascade" ensures that deletes/updates to the base record are propagated to dispatch class-specific records.
ForeignKey BaseResourceMap(ResourceClass,ResourceName,MediaType) References %pkg.isc.rest.resourceMap(UniqueByContext) [ OnDelete = cascade, OnUpdate = cascade ];

Trigger ValidateDefaultForHandlers [ Event = INSERT, Foreach = row/object ]
{
	New handlerClasses,handlerClass,sc
	If ({DispatchClass} = "") && ({IsDefault}) {
		Do ##class(%pkg.isc.rest.handlerProjection).ValidateDefaultForHandlers({ResourceClass})
	}
}

Trigger UpdatePermittedHandlers [ Event = INSERT, Foreach = row/object, Time = AFTER ]
{
	New handlerClasses,handlerClass,sc
	If {DispatchClass} = "" {
		Do ##class(%pkg.isc.rest.handlerProjection).AddResourceWherePermitted({ResourceClass})
	}
}

/// Helper method, 
ClassMethod FindDefaultResourceForRequest(pClassName As %String, pResource As %String, pMediaTypeList As %Library.List) As %String
{
	Set resourceClass = ""
	If ##class(%pkg.isc.rest.resourceMap).UniqueDefaultResourceExists(pClassName,pResource,1,.id) {
		Set pointer = 0
		Set defaultResourceClass = ##class(%pkg.isc.rest.resourceMap).ResourceClassGetStored(id)
		Set mediaType = ##class(%pkg.isc.rest.resourceMap).MediaTypeGetStored(id)
		Set orderedTypeList = ##class(%pkg.isc.rest.handler).OrderMediaTypeList(pMediaTypeList)
		While $ListNext(orderedTypeList,pointer,type) {
			// Convert accepted media type to RegEx
			Set regEx = $Replace(type,"*",".*")
			Set regEx = $Replace(regEx,"+","\+")
			If $Match(mediaType,regEx) {
				Set resourceClass = defaultResourceClass
			}
		}
	}
	Return resourceClass
}

Storage Default
{
<Data name="resourceMapDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DispatchClass</Value>
</Value>
<Value name="3">
<Value>ResourceName</Value>
</Value>
<Value name="4">
<Value>MediaType</Value>
</Value>
<Value name="5">
<Value>ResourceClass</Value>
</Value>
<Value name="6">
<Value>IsDefault</Value>
</Value>
</Data>
<DataLocation>^pkg.isc.rest.resourceMapD</DataLocation>
<DefaultData>resourceMapDefaultData</DefaultData>
<IdLocation>^pkg.isc.rest.resourceMapD</IdLocation>
<IndexLocation>^pkg.isc.rest.resourceMapI</IndexLocation>
<StreamLocation>^pkg.isc.rest.resourceMapS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

