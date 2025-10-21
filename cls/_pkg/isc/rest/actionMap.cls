/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.actionMap Extends %Persistent [ System = 2 ]
{

Index UniqueByRequest On UniqueByRequest [ Unique ];

Index ResourceClass On ResourceClass;

Index ResourceName On ResourceName;

Index ImplementationClass On ImplementationClass;

Index ContextForResourceClass On (DispatchOrResourceClass, ResourceClass);

/// Indicate a global for storage difinitions.
Parameter DEFAULTGLOBAL = "^pkg.isc.rest.actionMap";

/// Set to null on resource class compilation, or to the dispatch class from the REST handler projection
Property DispatchClass As %Dictionary.CacheClassname;

/// Set to either the DispatchClass or the ResourceClass
Property DispatchOrResourceClass As %Dictionary.CacheClassname [ Calculated, Required, SqlComputeCode = {Set {*} = $CASE({DispatchClass},"":{ResourceClass},:{DispatchClass})}, SqlComputed ];

Property ResourceName As %String(MAXLEN = 128) [ Required ];

Property ActionName As %String(MAXLEN = 255) [ Required ];

Property ActionResolvedName As %String [ Calculated, SqlComputeCode = { Set {*} = ##class(%pkg.isc.rest.model.action.t.action).GetResolvedActionName({ActionName}) }, SqlComputed ];

Property ActionTarget As %String(VALUELIST = ",class,instance") [ Required ];

Property HTTPVerb As %String(VALUELIST = ",GET,HEAD,POST,PUT,DELETE,CONNECT,OPTIONS,TRACE,PATCH") [ Required ];

/// What the action responds with so corresponds to the Accepts request header + response ContentType header
Property MediaType As %String(MAXLEN = 128);

Property MediaTypeOrNUL As %String [ Calculated, Required, SqlComputeCode = {Set {*} = $CASE({MediaType},"":$CHAR(0),:{MediaType})}, SqlComputed ];

/// What the action accepts so corresponds to the ContentType request header
Property Accepts As %String(MAXLEN = 128);

Property AcceptsOrNUL As %String [ Calculated, Required, SqlComputeCode = {Set {*} = $CASE({Accepts},"":$CHAR(0),:{Accepts})}, SqlComputed ];

Property ResourceClass As %Dictionary.CacheClassname [ Required ];

Property ImplementationClass As %Dictionary.CacheClassname [ Required ];

/// Used for UniqueByRequestIndex
Property UniqueByRequest As %String(MAXLEN = 256) [ Calculated, SqlComputeCode = {Set {*} = ##class(%pkg.isc.rest.actionMap).ConcatenateAndHash({DispatchOrResourceClass}, {ResourceName}, {ActionTarget}, {MediaTypeOrNUL}, {AcceptsOrNUL}, {ActionName}, {HTTPVerb})}, SqlComputed ];

/// Used by RootImplementation foreign key.
Property RootImplementation As %String(MAXLEN = 256) [ Calculated, SqlComputeCode = {Set {*} = ##class(%pkg.isc.rest.actionMap).ConcatenateAndHash({ResourceClass}, {ResourceName}, {ActionTarget}, {MediaTypeOrNUL}, {AcceptsOrNUL}, {ActionName}, {HTTPVerb})}, SqlComputed ];

/// Recursive foreign key references the dispatch class-independent record associated with this one (possibly the current record).
/// "Cascade" ensures that deletes/updates to the base record are propagated to dispatch class-specific records.
ForeignKey RootImplementation(RootImplementation) References %pkg.isc.rest.actionMap(UniqueByRequest) [ OnDelete = cascade, OnUpdate = cascade ];

Trigger UpdatePermittedHandlers [ Event = INSERT, Foreach = row/object, Time = AFTER ]
{
	New handlerClasses,handlerClass,sc
	If {DispatchClass} = "" {
		Do ##class(%pkg.isc.rest.handlerProjection).AddResourceWherePermitted({ResourceClass})
	}
}

/// Creates a short hash of all method args concatenated together so it fits in the subscript limitations 
/// for a unique index (511 bytes). Used SHA-256 for hashing.
ClassMethod ConcatenateAndHash(pArgs...) [ Internal ]
{
    Set result = ""
    Set index = ""
    While 1 {
        Set index = $ORDER(pArgs(index),1,value)
        If (index = "") {
            Quit
        }
        Set result = result _ value
    }
    Return $SYSTEM.Encryption.SHAHash(256, result)
}

/// For a given request, identify the corresponding action.
/// Returns an instance of this class if an action if found.
/// If not found, returns a null oref.
ClassMethod FindActionForRequest(pDispatchClass As %String, pResourceName As %String, pTarget As %String, pContentTypeList As %Library.List, pAcceptsList As %Library.List, pHTTPMethod As %String, pAction As %String, Output pHasMatchedAction As %Boolean, Output pSupportedHttpVerbs As %DynamicArray) As %pkg.isc.rest.actionMap
{
    Set pHasMatchedAction = 0
    Set pSupportedHttpVerbs = []
    // First try direct check of every accept/content type combination
    Set i = 0
    While $LISTNEXT(pAcceptsList,i,accepts) {
        Set j = 0
        While $LISTNEXT(pContentTypeList,j,contentType) {
            Set exists = ##class(%pkg.isc.rest.actionMap).UniqueByRequestExists(
                ..ConcatenateAndHash(
                    pDispatchClass,
                    pResourceName,
                    pTarget,
                    contentType,
                    accepts,
                    pAction,
                    pHTTPMethod
                ),
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
    Kill supportedHttpVerbs
    While resultSet.%Next(.sc) {
        $$$ThrowOnError(sc)
        Set httpMethod = resultSet.%Get("HTTPVerb")
        Set actionName = resultSet.%Get("ActionResolvedName")
        If '($DATA(supportedHttpVerbs(httpMethod))#2) {
            // Only add when not present to avoid duplicates
            Set supportedHttpVerbs(httpMethod) = ""
            Do pSupportedHttpVerbs.%Push(httpMethod)
        }

        // Check if action regex matches
        If $MATCH(pAction, actionName) {
            Set pHasMatchedAction = 1
            If (httpMethod = pHTTPMethod) {
                Set matchedId = resultSet.%Get("ID")
                Quit
            }
        }
    }

    // Check for a default resource for this request and use the requested action if found
    If (matchedId = "") {
	 	Set resourceClass = ##class(%pkg.isc.rest.resourceMap).FindDefaultResourceForRequest(pDispatchClass, pResourceName, pContentTypeList)
        // If a default is found, use the corresponding action on this resource for the request
        If (resourceClass '= "") {
            Set query = "SELECT ID FROM %pkg_isc_rest.actionMap WHERE "_
                        "DispatchClass = ? AND " _
                        "ResourceClass = ? AND " _
                        "ActionTarget = ? AND " _
                        "ActionName = ? AND " _
                        "HTTPVerb = ? AND " _
                        "AcceptsOrNUL %INLIST ?"
            Set resultSet = ##class(%SQL.Statement).%ExecDirect(, query,
                pDispatchClass, resourceClass, pTarget, pAction, pHTTPMethod, pAcceptsList
            )
            $$$ThrowSQLIfError(resultSet.%SQLCODE,resultSet.%Message)
            While resultSet.%Next(.sc) {
                $$$ThrowOnError(sc)
                Set matchedId = resultSet.%GetData(1)
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

ClassMethod FindSupportedMediaTypesForRequest(pDispatchClass As %String, pResourceName As %String, pTarget As %String, pHTTPMethod As %String, pAction As %String, Output pResourceFound As %Boolean, Output pActionFound As %Boolean) As %DynamicArray
{
    #dim typesArr As %DynamicArray
    Set typesArr = []
    Set pResourceFound = 0
    Set pActionFound = 0
    Set query = "SELECT Accepts, MediaType, ActionTarget, ActionResolvedName "_
        "FROM %pkg_isc_rest.actionMap "_
        "WHERE DispatchClass = ? AND ResourceName = ? AND HTTPVerb = ?"
    #dim resultSet As %SQL.StatementResult
    Set resultSet = ##class(%SQL.Statement).%ExecDirect(, query,
        pDispatchClass, pResourceName, pHTTPMethod
    )
    $$$ThrowSQLIfError(resultSet.%SQLCODE,resultSet.%Message)
    While resultSet.%Next(.sc) {
        $$$ThrowOnError(sc)
        Set target = resultSet.%Get("ActionTarget")
        Set name = resultSet.%Get("ActionResolvedName")
        Set pResourceFound = 1
        If (target = pTarget) && $MATCH(pAction, name) {
            Set pActionFound = 1
            // Found action so now accumulate types
            Do typesArr.%Push({
                "accepts": (resultSet.%Get("MediaType")),
                "contentType": (resultSet.%Get("Accepts"))
            })
        }
    }
    $$$ThrowOnError(sc)
    Return typesArr
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

