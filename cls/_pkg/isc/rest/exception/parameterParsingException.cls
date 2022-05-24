Class %pkg.isc.rest.exception.parameterParsingException Extends %pkg.isc.rest.exception.queryGenerationException [ System = 3 ]
{

Parameter ExceptionName = "<Parameter Syntax Incorrect>";

Method DisplayMessage() As %String
{
	Return "The parameter value '" _ ..Content _ "' could not be parsed."
}

}

