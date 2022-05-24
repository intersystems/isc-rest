Class UnitTest.isc.rest.sampleUnprotectedClass Extends (%UnitTest.TestCase, %pkg.isc.rest.model.resource)
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "unittest-fake-resource";

/// This is very bad in any other case, though there is no business logic for this class, so it's fine.
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean
{
	Quit 1
}

/// Asserts that the implementation of CheckPermission for this class is located correctly.
Method TestListImplementations()
{
	Do ##class(%pkg.isc.rest.auditor).ListSecurityImplementations(.impl,1)
	Do $$$AssertEquals(impl($classname(),1),$c(9)_"Quit 1")
}

/// Asserts that this class is the only non-whitelisted, non-security-protected class.
Method TestThatIAmUnprotected()
{
	Set list = ##class(%pkg.isc.rest.auditor).ListUnprotectedClasses(1)
	Do $$$AssertEquals($ListLength(list),1,"Only one class was recognized as unprotected.")
	Set pointer = 0
	Set found = 0
	While $ListNext(list,pointer,class) {
		If (class '= $classname()) {
			Do $$$AssertFailure()
		} Else {
			Set found = 1
			Do $$$AssertEquals(class,$classname(),$classname()_" was treated as an unprotected class.")
		}
	}
	If 'found {
		Do $$$AssertFailure($classname()_" was not recgonized as an unprotected class.")
	}
}

/// Tests whitelist behavior.
Method TestWhitelist()
{
	Do ##class(%pkg.isc.rest.auditor).WhiteListClass($classname())
	Set list = ##class(%pkg.isc.rest.auditor).ListUnprotectedClasses()
	Do $$$AssertEquals(list,"")
	Do $$$AssertEquals(##class(%pkg.isc.rest.auditor).IsClassWhiteListed($classname()),1)
	Do ##class(%pkg.isc.rest.auditor).RemoveClassFromWhiteList($classname())
	Do $$$AssertEquals(##class(%pkg.isc.rest.auditor).IsClassWhiteListed($classname()),0)
}

Method TestCompilation()
{
	// Gets a bit of test coverage credit for code generation for this class.
	Do $System.OBJ.Compile($classname(),"ck-d/nomulticompile")
}

}

