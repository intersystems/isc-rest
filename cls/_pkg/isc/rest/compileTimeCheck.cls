Class %pkg.isc.rest.compileTimeCheck [ System = 2 ]
{

/// Invoke this from CodeMode = objectgenerator methods <br />
/// Returns a consolidated error %Status with all errors for the class if the specified
/// overrides are not defined for the current class (references the public variable %class) <br />
/// Example use: <br />
/// <code>
/// ClassMethod "%%CheckClassValidity"() [ CodeMode = objectgenerator, Private, Internal, Final ]
/// {
/// 	// Require overriding RESOURCENAME and SOURCECLASS parameters
/// 	Set overrides = $ListBuild("p:SOURCECLASS","p:RESOURCENAME")
/// 	Return ##class(%pkg.isc.rest.compileTimeCheck).RequireOverrides(overrides)
/// }
/// </code>
/// If <var>prohibitedOrigin</var> is defined, will also validate that the member's origin is not that class.
ClassMethod RequireOverrides(overrides As %List, prohibitedOrigin As %Dictionary.Classname = "") As %Status
{
	Set sc = $$$OK
	Set className = %class.Name
	// Overrides not required in abstract subclasses
	If $$$comClassKeyGet(className,$$$cCLASSabstract) {
		Quit $$$OK
	}
	Set pointer = 0
	While $ListNext(overrides, pointer, override) {
		Set memberType = $Piece(override,":")
		Set memberName = $Piece(override,":",2)
		If '..HasOverride(className, memberType, memberName, prohibitedOrigin, .oneStatus) {
			Set sc = $$$ADDSC(sc,oneStatus)
		}
	}
	Quit sc
}

/// Returns true if <var>memberName</var> in class <var>className</var> is defined and not abstract.
/// Valid values for <var>memberType</var> are first letter of the member type, or the whole word:
/// <ul>
/// <li>p[arameter]</li>
/// <li>m[ethod]</li>
/// <li>x[data]</li>
/// </ul>
ClassMethod HasOverride(className As %Dictionary.Classname, memberType As %String, memberName As %Dictionary.Identifier, prohibitedOrigin As %Dictionary.Classname, Output status As %Status) As %Boolean [ Internal, Private ]
{
	Set status = $$$OK
	Set memberType = $Case($ZConvert(memberType,"L"),
		"method":$$$cCLASSmethod,
		$$$cCLASSmethod:$$$cCLASSmethod,
		"parameter":$$$cCLASSparameter,
		$$$cCLASSparameter:$$$cCLASSparameter,
		"xdata":$$$cCLASSxdata,
		$$$cCLASSxdata:$$$cCLASSxdata)
	Set isAbstract = $Case(memberType,
		$$$cCLASSmethod:$$$comMemberKeyGet(className,memberType,memberName,$$$cMETHabstract),
		$$$cCLASSparameter:$$$comMemberKeyGet(className,memberType,memberName,$$$cPARAMabstract),
		$$$cCLASSxdata:0 /* XData blocks cannot be [Abstract] */)
	Set origin = $$$comMemberKeyGet(className,memberType,memberName,$$$cXXXXorigin)
	Set overridden = $$$comMemberDefined(className,memberType,memberName) && 'isAbstract && (origin '= prohibitedOrigin)
	If 'overridden {
		Set memberTypeDisplay = $Case(memberType,
			$$$cCLASSmethod:"Method",
			$$$cCLASSparameter:"Parameter",
			$$$cCLASSxdata:"XData")
		Set status = $$$ERROR($$$GeneralError,$$$FormatText("%1 %2 must be defined for class %3",memberTypeDisplay,memberName,className))
	}
	Quit overridden
}

}

