/// Represents singleton settings object implemented using the singleton resource model provided OOTB
Class UnitTest.isc.rest.sample.model.settingsWithSingleton Extends %pkg.isc.rest.model.singleton [ DependsOn = UnitTest.isc.rest.sample.data.settings ]
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "settings-with-singleton";

/// @API.Overrideable <br />
Parameter SingletonClass As STRING = "UnitTest.isc.rest.sample.data.settings";

/// Checks the user's permission for a particular operation on a particular record.
/// <var>pOperation</var> may be one of the macros of the form $$$Operation*
/// present in %pkg.isc.rest.general.inc. <br />
/// If this method returns 0, the corresponding dispatch class will return a 403
/// Unauthorized status when the operation is invoked. <br />
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>. <br />
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
    // Only allow user with %All to access
	Return $$$IOwnAllRole
}

}

