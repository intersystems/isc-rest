/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.t.argument Extends (%RegisteredObject, %XML.Adaptor) [ System = 2 ]
{

Parameter XMLIGNOREINVALIDATTRIBUTE As BOOLEAN = 0;

Parameter NAMESPACE As STRING = "http://www.intersystems.com/_pkg/isc/rest/action";

/// Name of the parameter (used in URLs)
Property name As %String(XMLPROJECTION = "attribute");

/// Whether the the parameter value comes from the body, the URL, or (for instance actions) the ID of the object in question; default is 'url'
/// The "source" of the argument. Below describes each possible source:
/// <ul>
///     <li>
///         body: The entire body content. Can have AT MOST ONE argument with this source.
///     </li>
///     <li>
///         body-key: A single key from a JSON body e.g. for JSON
///         { "foo": {...}, "bar": {...} }, can use body-key to target
///         just "foo".
///     </li>
///     <li>
///         form-data: Multi-part form data
///     </li>
///     <li>
///         query: A query parameter in the URL.
///     </li>
///     <li>
///         path: A path parameter in the URL. MUST also be present with a colon
///         in the URL, matching the same name e.g. if the URL path for the action
///         is /example/:ex, then the <property>name</property> MUST be ex.
///     </li>
///     <li>
///         id: The ID from the path for instance actions.
///     </li>
///     <li>
///         user-context: the user context object, as provided by the subclass of <class>%pkg.isc.rest.handler</class> in use
///     </li>
/// </ul>
Property source As %String(VALUELIST = ",body,body-key,form-data,query,path,id,user-context", XMLPROJECTION = "attribute") [ InitialExpression = "query", Required ];

/// Target parameter in the method/query
Property target As %String(XMLPROJECTION = "attribute") [ Required ];

/// True if the argument is required (if not specified, it's a problem with the client)
Property required As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0, Required ];

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
    Set sourcesWithNameNotRequired = $ListBuild("body", "body-key", "id", "user-context")
	If '$ListFind(sourcesWithNameNotRequired, ..source) && (..name = "") {
        Set msg = "MUST have 'name' attribute set on argument unless source is one of "_$ListToString(sourcesWithNameNotRequired)
        Return $$$ERROR($$$GeneralError,msg)
    }
    Return $$$OK
}

}

