/// Provide REST access to a persistent class which represents a singleton i.e.
/// a persistent class which has a single record. <br />
/// @API.Extensible <br />
Class %pkg.isc.rest.model.singleton Extends (%pkg.isc.rest.model.resource, %pkg.isc.json.adaptor) [ Abstract, DependsOn = %pkg.isc.rest.abstractSingleton, System = 3 ]
{

/// The class to which this class provides REST access. It must adhere to the following
/// (validated during compilation): 
/// <ul>
/// <li> Must extend <class>%Library.Persistent</class> and <class>%pkg.isc.rest.abstractSingleton</class>. </li>
/// <li> Must have its %JSONENABLED class parameter set to 1 (e.g., by extending <class>%pkg.isc.json.adaptor</class>). </li>
/// </ul>
/// Subclasses MUST override this parameter. <br />
/// @API.Overrideable <br />
Parameter SingletonClass As STRING [ Abstract ];

/// The JSON mapping of the related JSON-enabled class to use.
/// Defaults to empty (the default mapping for the associated class).
Parameter JSONMAPPING As STRING;

Property %instance As %pkg.isc.rest.abstractSingleton [ Private, Transient ];

/// Ensures all required parameters are overridden in non-abstract subclasses.
ClassMethod "%%CheckClassValidity"() [ CodeMode = objectgenerator, Internal, Private ]
{
    Set sc = $$$OK
    Try {
        If (%class.Abstract) {
            Quit
        }
        // Require overrides of abstract parameters
        Set overrides = $ListBuild("p:RESOURCENAME","p:MEDIATYPE","p:SingletonClass")
        Set sc = ##class(%pkg.isc.rest.compileTimeCheck).RequireOverrides(overrides)
        $$$ThrowOnError(sc)

        // Checks on singleton class
        
        Set singletonClass = $$$defMemberKeyGet(%class.Name,$$$cCLASSparameter,"SingletonClass",$$$cPARAMdefault)
        // Singleton class can be empty if defined in super class. This is ok and nothing to do then.
        If (singletonClass '= "") {
            // Check that SingletonClass is in DependsOn list of resource class
            Set dependsOnClass = $ListBuild(singletonClass)
            Set sc = ##class(%pkg.isc.rest.compileTimeCheck).HasDependsOn(%class.Name, dependsOnClass)
            $$$ThrowOnError(sc)
            
            // Confirmed that singleton class is in depends on so is already compiled so can run 
            // below checks now.
            // NOTE: We cannot move the super class check to abstractSingleton since it requires
            // the class to be compiled.

            // Check for super classes. Each of the checker methods returns error statuses to be thrown
            Set superClasses = $ListBuild("%Persistent", "%pkg.isc.rest.abstractSingleton")
            Set sc = ##class(%pkg.isc.rest.compileTimeCheck).HasSuperClass(singletonClass, superClasses)
            $$$ThrowOnError(sc)
            // Check for JSON enabled
            Set sc = ##class(%pkg.isc.rest.compileTimeCheck).IsJsonEnabled(singletonClass)
            $$$ThrowOnError(sc)
        }

    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
    Return sc
}

ClassMethod Supports(pOperation As %String, pType As %String(VALUELIST=",instance,class"), pRequest As %CSP.Request = {$$$NULLOREF}) As %Boolean [ Final ]
{
    // Only support class level requests
    If (pType '= "class") {
        Return 0
    }
	// Only support GET, POST
    If (pOperation = $$$OperationQuery) || (pOperation = $$$OperationCreate) {
        Return 1
    }
    // Custom handling for actions
    If $$$OperationIsAction(pOperation) {
        Return ..SupportsAction(pOperation, pRequest)
    }
    Return 0
}

/// Returns 1 if the provided class-level action is supported. Look at <method>Supports</method>
/// for argument documentation. <br />
/// By default, all actions supported. <br />
ClassMethod SupportsAction(pOperation As %String, pRequest As %CSP.Request = {$$$NULLOREF}) As %Boolean
{
    Return 1
}

ClassMethod GetCollection(ByRef params, selectMode As %Integer)
{
    Set proxy = ..GetModelInstance()
    Do proxy.JSONExport()
}

ClassMethod GetModelInstance(args...) As %pkg.isc.rest.model.resource
{
	Set proxy = ..%New()
    Set proxy.%instance = $ClassMethod(..#SingletonClass, "GetSingletonRecord")
    Return proxy
}

/// Saves the model instance.
Method SaveModelInstance(pUserContext As %RegisteredObject)
{
    Set sc = ..%instance.%Save()
	$$$ThrowOnError(sc)
}

/// JSONImport imports JSON or dynamic object input into this object.<br />
/// The input argument is either JSON as a string or stream, or a subclass of %DynamicAbstractObject.
Method JSONImport(input) As %Status [ Final ]
{
	Quit ..%instance.%JSONImport(.input, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status [ Final ]
{
	Quit ..%instance.%JSONExport(..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status [ Final ]
{
	Quit ..%instance.%JSONExportToStream(.export, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status [ Final ]
{
	Quit ..%instance.%JSONExportToString(.%export, ..#JSONMAPPING)
}

}
