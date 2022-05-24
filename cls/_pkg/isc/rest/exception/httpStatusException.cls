/// If thrown in an %pkg.isc.rest action, the response will have the provided HTTP status code.
Class %pkg.isc.rest.exception.httpStatusException Extends %Exception.AbstractException
{

Property StatusCode As %String;

Method %OnNew(pStatusCode As %String = "500") As %Status [ Private ]
{
    set ..StatusCode = pStatusCode
    set ..Name = "HTTP "_pStatusCode
    return $$$OK
}

}

