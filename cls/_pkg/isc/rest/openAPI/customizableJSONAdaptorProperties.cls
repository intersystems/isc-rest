Class %pkg.isc.rest.openAPI.customizableJSONAdaptorProperties [ System = 2 ]
{

/// The %JSONFIELDNAME parameter specifies the field name that this property is mapped to in JSON.
/// The default %JSONFIELDNAME is the property name.
Parameter %JSONFIELDNAME As STRING;

/// The %JSONINCLUDE parameter controls if this property will be included in the JSON output or input.
/// Possible values are INOUT, INPUTONLY, OUTGPUTONLY and NONE.  The default is INOUT.
Parameter %JSONINCLUDE As STRING [ Constraint = "INOUT,INPUTONLY,OUTPUTONLY,NONE", Flags = ENUM ];

}

