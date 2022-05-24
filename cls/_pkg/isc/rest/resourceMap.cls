/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.resourceMap Extends %Persistent [ System = 3 ]
{

Index UniqueByContext On (DispatchOrResourceClass, ResourceName, MediaType) [ Unique ];

Index ResourceClass On ResourceClass;

Index UniqueByClassnames On (DispatchOrResourceClass, ResourceClass) [ Unique ];

/// Indicate a global for storage difinitions.
Parameter DEFAULTGLOBAL = "^pkg.isc.rest.resourceMap";

/// Set to null on resource class compilation, or to the dispatch class from the REST handler projection
Property DispatchClass As %Dictionary.CacheClassname;

/// Set to either the DispatchClass or the ResourceClass
Property DispatchOrResourceClass As %Dictionary.CacheClassname [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({DispatchClass},"":{ResourceClass},:{DispatchClass})}, SqlComputed ];

Property ResourceName As %String(MAXLEN = 128);

Property MediaType As %String(MAXLEN = 128);

Property ResourceClass As %Dictionary.CacheClassname;

/// Recursive foreign key references the dispatch class-independent record associated with this one (possibly the current record).
/// "Cascade" ensures that deletes/updates to the base record are propagated to dispatch class-specific records.
ForeignKey BaseResourceMap(ResourceClass,ResourceName,MediaType) References %pkg.isc.rest.resourceMap(UniqueByContext) [ OnDelete = cascade, OnUpdate = cascade ];

Trigger UpdatePermittedHandlers [ Event = INSERT, Foreach = row/object, Time = AFTER ]
{
	New handlerClasses,handlerClass,sc
	If {DispatchClass} = "" {
		Do ##class(%pkg.isc.rest.handlerProjection).AddResourceWherePermitted({ResourceClass})
	}
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
</Data>
<DataLocation>^pkg.isc.rest.resourceMapD</DataLocation>
<DefaultData>resourceMapDefaultData</DefaultData>
<IdLocation>^pkg.isc.rest.resourceMapD</IdLocation>
<IndexLocation>^pkg.isc.rest.resourceMapI</IndexLocation>
<StreamLocation>^pkg.isc.rest.resourceMapS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

