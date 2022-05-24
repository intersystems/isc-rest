Class %pkg.isc.rest.exception.invalidColumnException Extends %pkg.isc.rest.exception.queryGenerationException [ System = 3 ]
{

Parameter ExceptionName = "<Invalid Column>";

Method DisplayMessage() As %String
{
	Return "Column '"_..Content_"' does not exist."
}

}

