/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.actionMap Extends %Persistent [ System = 2 ]
{

Index UniqueByRequest On (DispatchOrResourceClass, ResourceName, ActionTarget, MediaTypeOrNUL, AcceptsOrNUL, ActionName, HTTPVerb) [ Unique ];

Index ResourceClass On ResourceClass;

Index ImplementationClass On ImplementationClass;

Index ContextForResourceClass On (DispatchOrResourceClass, ResourceClass);

/// Indicate a global for storage difinitions.
Parameter DEFAULTGLOBAL = "^pkg.isc.rest.actionMap";

/// Set to null on resource class compilation, or to the dispatch class from the REST handler projection
Property DispatchClass As %Dictionary.CacheClassname;

/// Set to either the DispatchClass or the ResourceClass
Property DispatchOrResourceClass As %Dictionary.CacheClassname [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({DispatchClass},"":{ResourceClass},:{DispatchClass})}, SqlComputed ];

Property ResourceName As %String(MAXLEN = 128) [ Required ];

Property ActionName As %String(MAXLEN = 255) [ Required ];

Property ActionResolvedName As %String [ Calculated, SqlComputeCode = { Set {*} = ##class(%pkg.isc.rest.model.action.t.action).GetResolvedActionName({ActionName}) }, SqlComputed ];

Property ActionTarget As %String(VALUELIST = ",class,instance") [ Required ];

Property HTTPVerb As %String(VALUELIST = ",GET,POST,PUT,DELETE") [ Required ];

Property MediaType As %String(MAXLEN = 128);

Property MediaTypeOrNUL As %String [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({MediaType},"":$c(0),:{MediaType})}, SqlComputed ];

Property Accepts As %String(MAXLEN = 128);

Property AcceptsOrNUL As %String [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({Accepts},"":$c(0),:{Accepts})}, SqlComputed ];

Property ResourceClass As %Dictionary.CacheClassname [ Required ];

Property ImplementationClass As %Dictionary.CacheClassname [ Required ];

/// Recursive foreign key references the dispatch class-independent record associated with this one (possibly the current record).
/// "Cascade" ensures that deletes/updates to the base record are propagated to dispatch class-specific records.
ForeignKey RootImplementation(ResourceClass,ResourceName,ActionTarget,MediaTypeOrNUL,AcceptsOrNUL,ActionName,HTTPVerb) References %pkg.isc.rest.actionMap(UniqueByRequest) [ OnDelete = cascade, OnUpdate = cascade ];

Trigger UpdatePermittedHandlers [ Event = INSERT, Foreach = row/object, Time = AFTER ]
{
	New handlerClasses,handlerClass,sc
	If {DispatchClass} = "" {
		Do ##class(%pkg.isc.rest.handlerProjection).AddResourceWherePermitted({ResourceClass})
	}
}

/// For a given request, identify the corresponding action.
/// Returns an instance of this class if an action if found.
/// If not found, returns a null oref.
ClassMethod FindActionForRequest(pDispatchClass As %String, pResourceName As %String, pTarget As %String, pContentTypeList As %Library.List, pAcceptsList As %Library.List, pHTTPMethod As %String, pAction As %String, Output pHasMatchedAction As %Boolean) As %pkg.isc.rest.actionMap
{
    Set pHasMatchedAction = 0
    // First try direct check of every accept/content type combination
    Set i = 0
    While $ListNext(pAcceptsList,i,accepts) {
        Set j = 0
        While $ListNext(pContentTypeList,j,contentType) {
            Set exists = ##class(%pkg.isc.rest.actionMap).UniqueByRequestExists(
                pDispatchClass,
                pResourceName,
                pTarget,
                contentType,
                accepts,
                pAction,
                pHTTPMethod,
                .id
            )
            If (exists) {
                Set obj = ##class(%pkg.isc.rest.actionMap).%OpenId(id, , .sc)
                $$$ThrowOnError(sc)
                Set pHasMatchedAction = 1
                Return obj
            }
        }
    }
    // Try regex matching on action
    Set query = "SELECT ID, HTTPVerb, ActionResolvedName FROM %pkg_isc_rest.actionMap WHERE "_
        "DispatchOrResourceClass = ? AND "_
        "ResourceName = ? AND "_
        "ActionTarget = ? AND "_
        "MediaTypeOrNUL %INLIST ? AND "_
        "AcceptsOrNUL %INLIST ?"
    #dim resultSet As %SQL.StatementResult
    Set resultSet = ##class(%SQL.Statement).%ExecDirect(, query,
        pDispatchClass, pResourceName, pTarget, pContentTypeList, pAcceptsList
    )
    $$$ThrowSQLIfError(resultSet.%SQLCODE,resultSet.%Message)
    Set matchedId = ""
    While resultSet.%Next(.sc) {
        $$$ThrowOnError(sc)
        Set httpMethod = resultSet.%Get("HTTPVerb")
        Set actionName = resultSet.%Get("ActionResolvedName")
        // Check if action regex matches
        If $Match(pAction, actionName) {
            Set pHasMatchedAction = 1
            If (httpMethod = pHTTPMethod) {
                Set matchedId = resultSet.%Get("ID")
                Quit
            }
        }
    }
    $$$ThrowOnError(sc)
    If (matchedId '= "") {
        Set obj = ##class(%pkg.isc.rest.actionMap).%OpenId(matchedId, , .sc)
        $$$ThrowOnError(sc)
        Return obj
    }
    Return $$$NULLOREF
}

Storage Default
{
<Data name="ActionMapDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ResourceName</Value>
</Value>
<Value name="3">
<Value>ActionName</Value>
</Value>
<Value name="4">
<Value>ActionTarget</Value>
</Value>
<Value name="5">
<Value>HTTPVerb</Value>
</Value>
<Value name="6">
<Value>MediaType</Value>
</Value>
<Value name="7">
<Value>Accepts</Value>
</Value>
<Value name="8">
<Value>ResourceClass</Value>
</Value>
<Value name="9">
<Value>ImplementationClass</Value>
</Value>
<Value name="10">
<Value>DispatchClass</Value>
</Value>
</Data>
<DataLocation>^pkg.isc.rest.actionMapD</DataLocation>
<DefaultData>ActionMapDefaultData</DefaultData>
<IdLocation>^pkg.isc.rest.actionMapD</IdLocation>
<IndexLocation>^pkg.isc.rest.actionMapI</IndexLocation>
<StreamLocation>^pkg.isc.rest.actionMapS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

