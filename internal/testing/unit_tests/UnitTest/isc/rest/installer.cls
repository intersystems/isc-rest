Class UnitTest.isc.rest.installer Extends %UnitTest.TestCase
{

Method TestRemoveAndReconfigureMappings()
{
	Set codeDB = ##class(%SYS.Namespace).GetRoutineDest()
	Set globalDB = ##class(%SYS.Namespace).GetGlobalDest()
	Do $$$AssertStatusOK(##class(%pkg.isc.rest.installer).%UnconfigureMappings())
	
	For gbl = "ActionMap","ResourceMap" {
		For suffix = "D","I","S" {
			Set global = "^pkg.isc.rest."_gbl_suffix
			Do $$$AssertEquals(##class(%SYS.Namespace).GetGlobalDest(,global),globalDB,global_" mapped to namespace-default data database.")
		}
	}
	
	Do $$$AssertStatusOK($System.OBJ.Compile("%pkg.isc.rest.installer","ck/nomulticompile"))
	
	For gbl = "ActionMap","ResourceMap" {
		For suffix = "D","I","S" {
			Set global = "^pkg.isc.rest."_gbl_suffix
			Do $$$AssertEquals(##class(%SYS.Namespace).GetGlobalDest(,global),codeDB,global_" mapped to namespace-default code database.")
		}
	}
}

}
