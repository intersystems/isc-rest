/// Helper class to track endpoint-level permissions (particularly useful for service-based access)
/// To use this in an %pkg.isc.rest-based application:
/// <ul>
/// <li>Subclass <class>%pkg.isc.rest.authorization.permission</class></li>
/// <li>Override <method>GetContexts</method></li>
/// <li>Override <parameter>RESOURCENAME</parameter> to control exposure as as REST Resource.</li>
/// <li>Override <method>CheckPermission</method> to control REST access to permissions.</li>
/// <li>In your application's authentication strategy class, override CheckPermission and call the 
/// <method>CheckAllPermission</method> in your Permission subclass.</li>
/// </ul>
Class %pkg.isc.rest.authorization.permission Extends (%Persistent, %pkg.isc.rest.model.adaptor) [ Abstract, NoExtent ]
{

Property ResourceClass As %Dictionary.CacheClassname [ Required ];

Property ResourceName As %String(MAXLEN = 128) [ Calculated, SqlComputeCode = {Set {*} = $Parameter({ResourceClass},"RESOURCENAME")}, SqlComputed ];

Property MediaType As %String(MAXLEN = 128) [ Calculated, SqlComputeCode = {Set {*} = $Parameter({ResourceClass},"MEDIATYPE")}, SqlComputed ];

Property Context As %String;

Property Operation As %String;

Property Granted As %Boolean [ Calculated, Transient ];

Method GrantedGet() As %Boolean
{
	Quit ..ClassContextExists(..ResourceClass, ..Context, ..Operation)
}

Index ClassContext On (ResourceClass, Context, Operation) [ Unique ];

Index ResourceContext On (ResourceName, MediaType, Context, Operation) [ Unique ];

Index Context On Context;

/// Given a User Context object used by the subclassing application's REST APIs, returns
/// a $ListBuild list of strings representing that user context (for example, an API key or SSO GUID, 
/// or a list of platform-level privileges if IRIS security is used).
/// Subclasses *MUST* override this method.
ClassMethod GetContexts(pUserContext As %RegisteredObject) As %List [ Abstract ]
{
}

/// Easy to use in %pkg.isc.rest.authentication:CheckPermission
/// Can also pass a $ListBuild list instead of pUserContext
ClassMethod CheckAuthorization(pResourceClassName As %Dictionary.CacheClassname, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean
{
	If $IsObject(pUserContext) {
		Set contexts = ..GetContexts(pUserContext)
	} Else {
		Set contexts = pUserContext
	}
	Set pointer = 0
	While $ListNext(contexts, pointer, context) {
		If ..ClassContextExists(pResourceClassName, context, pOperation) {
			Return 1
		}
	}
	Return 0
}

/// Defines a mapping of actions available for this model class to the associated methods and arguments.
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions>
<action name="granted-permissions" method="GET" query="ListGrantedPermissions">
<argument source="query" name="context" target="context" />
</action>
<action name="available-permissions" method="GET" query="ListAvailablePermissions">
<argument source="query" name="context" target="context" />
</action>
</actions>
}

ClassMethod GetListGrantedPermissionsQuery() [ CodeMode = objectgenerator, Private ]
{
	Set query = "select ResourceName,MediaType,ResourceClass,Context,Operation "_
		"from "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_
		" where Context = ?"_
		" order by ResourceName,MediaType,CASE Operation "_
			"when 'CREATE' then 1 "_
			"when 'READ' then 2 "_
			"when 'UPDATE' then 3 "_
			"when 'DELETE' then 4 "_
			"when 'QUERY' then 5 "_
			"else 6 end, Operation"
	Do %code.WriteLine(" Quit "_$$$QUOTE(query))
	Quit $$$OK
}

Query ListGrantedPermissions(context As %String) As %Query(ROWSPEC = "ResourceName:%String,MediaType:%String,ResourceClass:%String,Context:%String,Operation:%String") [ SqlProc ]
{
}

ClassMethod ListGrantedPermissionsExecute(ByRef qHandle As %Binary, context As %String) As %Status
{
	Set query = ..GetListGrantedPermissionsQuery()
	Set qHandle = ##class(%SQL.Statement).%ExecDirect(,query,context)
	If (qHandle.%SQLCODE < 0) {
		Quit $$$ERROR($$$SQLError,qHandle.%SQLCODE,qHandle.%Message)
	}
	Quit $$$OK
}

ClassMethod ListGrantedPermissionsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListAllPermissionsExecute ]
{
	If qHandle.%Next() {
		Set Row = $ListBuild(qHandle.%GetData(1),qHandle.%GetData(2),qHandle.%GetData(3),qHandle.%GetData(4),qHandle.%GetData(5))
	} Else {
		Set AtEnd = 1
	}
	Quit $$$OK
}

ClassMethod ListGrantedPermissionsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListAllPermissionsExecute ]
{
	Quit $$$OK
}

Query ListAvailablePermissions(context As %String) As %SQLQuery [ SqlProc ]
{
	select * from (
	select r.ResourceName, r.MediaType, r.ResourceClass, :context As "Context", o.Operation As "Operation"
	from %pkg_isc_rest.resourceMap r,(select 'CREATE' As "Operation"
		union all
		select 'READ'
		union all
		select 'UPDATE'
		union all
		select 'DELETE'
		union all
		select 'QUERY') o
	union all
	select r.ResourceName, r.MediaType, r.ResourceClass, :context As "Context", 'ACTION:'||ActionName As "Operation"
	from %pkg_isc_rest.resourceMap r
	join %pkg_isc_rest.actionMap o
		on o.ResourceClass = r.ResourceClass
	)
	order by ResourceName,MediaType,CASE Operation
		when 'CREATE' then 1
		when 'READ' then 2
		when 'UPDATE' then 3
		when 'DELETE' then 4
		when 'QUERY' then 5
		else 6 end, Operation
}

/// If true, the whole SQL result row is passed to GetModelInstance rather than just the ID.
/// If true, GetModelFromResultRow must be overridden and implemented.
Parameter ConstructFromResultRow As BOOLEAN = 1;

ClassMethod GetModelFromResultRow(pResultRow As %Library.IResultSet) As %pkg.isc.rest.model.dbMappedResource
{
	// For queries that include ID, just use it.
	If pResultRow.%IsA("%SQL.ClassQueryResultSet") {
		// %SQL.ClassQueryResultSet:%Get throws <PROPERTY DOES NOT EXIST> for invalid column names,
		// so use Get instead (here and above).
		If pResultRow.Get("ID") {
			Quit ..%OpenId(pResultRow.Get("ID"))
		}
	} ElseIf pResultRow.%Get("ID") {
		// For a result set that implements the interface correctly, we check for an ID column this way.
		Quit ..%OpenId(pResultRow.%Get("ID"))
	}
	
	// Otherwise, instantiate a new instance from the result row.
	Set instance = ..%New()
	For prop = "ResourceClass","Context","Operation" {
		Set $Property(instance,prop) = pResultRow.%Get(prop)
	}
	// "Granted" is calculated.
	Quit instance
}

}

