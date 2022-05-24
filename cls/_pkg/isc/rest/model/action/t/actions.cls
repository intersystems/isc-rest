/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.t.actions Extends (%RegisteredObject, %XML.Adaptor) [ System = 2 ]
{

Parameter NAMESPACE As STRING = "http://www.intersystems.com/_pkg/isc/rest/action";

Parameter XMLIGNOREINVALIDATTRIBUTE As BOOLEAN = 0;

Property actions As list Of %pkg.isc.rest.model.action.t.action(XMLNAME = "action", XMLPROJECTION = "element");

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
    Set sc = $$$OK
	For i=1:1:..actions.Count() {
        Set sc = $$$ADDSC(sc,..actions.GetAt(i).%ValidateObject())
    }
	Quit sc
}

}
