/// Base abstract class for any singleton persistent class to extend to be
/// used as part of <class>%pkg.isc.rest.model.singleton</class>.
/// @API.Extensible <br />
Class %pkg.isc.rest.abstractSingleton Extends (%Persistent, %pkg.isc.json.adaptor) [ Abstract, NoExtent, System = 3 ]
{

/// Read only property to store the class name which serves as the IdKey of 
/// the singleton record.
Property Classname As %Dictionary.Classname(%JSONINCLUDE = "NONE") [ Final, InitialExpression = {$ClassName()}, ReadOnly, Required ];

Index IdKey On Classname [ IdKey ];

/// Returns the singleton record. If this is the singleton doesn't exist, will create 
/// a new singleton record. <br />
/// <var>pConcurrency</var> specifies the concurrency argument to for %OpenId(). By default, uses DEFAULTCONCURRENCY <br />
/// <var>pSaveFirstInstance</var> if set to 1, will then save the first instance of the singleton so as to make sure the storage global exists. By default it will only return and not save the singleton. <br />
ClassMethod GetSingletonRecord(pConcurrency As %Integer = -1, pSaveFirstInstance As %Boolean = 0) As %pkg.isc.rest.abstractSingleton [ Final ]
{
    Set classname = ..%ClassName(1)
    If ..%ExistsId(classname) {
        Set obj = ..%OpenId(classname, pConcurrency, .sc)
        $$$ThrowOnError(sc)
    } Else {
        Set obj = ..%New()
        If (pSaveFirstInstance) {
        	// Call %Save to make sure the storage global of this singleton record exists for the first instance of it
        	$$$ThrowOnError(obj.%Save())
        }
    }
    Return obj
}

}

