Class isc.sample.rest.phonebook.Installer Extends %ZPM.AbstractInstaller
{

ClassMethod OnConfigureComponent(pNamespace As %String, pVerbose As %Boolean = 0, ByRef pVars) As %Status
{
    Set sc = $$$OK
    Try {
        If pVerbose {
            Write !,"[isc.sample.rest.phonebook.Installer:OnConfigureComponent] Populating sample data... "
        }
        $$$ThrowOnError(##class(isc.sample.rest.phonebook.model.Person).%KillExtent())
        $$$ThrowOnError(##class(isc.sample.rest.phonebook.model.Person).Populate(100))
        $$$ThrowOnError(##class(isc.sample.rest.phonebook.model.PhoneNumber).Populate(300))
        If pVerbose {
            Write "done."
        }
    } Catch e {
        Set sc = e.AsStatus()
        If pVerbose {
            Write "An error occurred: ",$System.Status.GetErrorText(sc)
        }
    }
	Quit sc
}

}
