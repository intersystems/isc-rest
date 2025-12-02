Include %syConfig

IncludeGenerator %syConfig

Class %pkg.isc.rest.installer [ System = 2 ]
{

/// Automatic on compilation, those possibly a no-op.
ClassMethod %ConfigureMappings() As %Status [ CodeMode = objectgenerator ]
{
	New $Namespace
	Set oldNamespace = $Namespace
	Set sc = $$$OK
	Try {
		// Step 1: Enumerate globals based on storage definitions for %pkg.isc.rest classes
		Set queries = ""
		For field = "DataLocation","IndexLocation","StreamLocation" {
			Set queries = queries_$ListBuild(
				"SELECT "_field_" as gbl FROM %Dictionary.StorageDefinition "_
				"WHERE parent %STARTSWITH '%pkg.isc.rest.' and "_field_" is not null")
		}
		Set query = $ListToString(queries," UNION ")
		Set result = ##class(%SQL.Statement).%ExecDirect(,query)
		Set defaultCodeDB = ##class(%SYS.Namespace).GetRoutineDest()
		If (result.%SQLCODE < 0) {
			Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message)
		}
		While result.%Next(.sc) {
			$$$ThrowOnError(sc)
			Set currentDB = ##class(%SYS.Namespace).GetGlobalDest(,result.gbl)
			If (currentDB '= defaultCodeDB) {
				Set gbl(result.gbl) = $lb(currentDB,defaultCodeDB)
			}
		}
		$$$ThrowOnError(sc)
		
		If '$Data(gbl) {
			// Nothing to do!
			Quit
		}
		
		// Step 3: Migrate data from old database to new database
		// Only relevant for initial migration, with safeguards to avoid repeating
		Set global = ""
		For {
			Set global = $Order(gbl(global),1,data)
			If (global = "") {
				Quit
			}
			Set $ListBuild(sourceDB,targetDB) = data
			Set sourceGbl = "^|""^"_sourceDB_"""|"_$Extract(global,2,*)
			Set targetGbl = "^|""^"_targetDB_"""|"_$Extract(global,2,*)
			If '$Data(@targetGbl) && $Data(@sourceGbl) {
				Write !,"Merging "_sourceGbl_" to empty "_targetGbl
				Merge @targetGbl = @sourceGbl
			}
		}
		
		// Step 4: Configure global mappings
		Set targetNamespace = $Namespace
		Set $Namespace = "%SYS"
		$$$ThrowOnError(##class(Config.Databases).DatabasesByDirectory($Piece(targetDB,"^"),$Piece(targetDB,"^",2),.dbList))
		Set codeDBName = $ListGet(dbList)
		Set changesMade = 0
		Set global = ""
		For {
			Set global = $Order(gbl(global))
			If (global = "") {
				Quit
			}
			Set globalName = $Extract(global,2,*)
			If '##Class(Config.MapGlobals).Exists(targetNamespace,globalName) {
				Set props("Database") = codeDBName
				Set database = ##class(SYS.Database).%OpenId(targetDB)
				If $IsObject(database) {
					Set tProps("Collation") = database.NewGlobalCollation
				}
				Write !,"Adding global mapping of "_global_" to "_codeDBName_" in namespace "_targetNamespace
				$$$ThrowOnError(##class(Config.MapGlobals).Create(targetNamespace,globalName,.props,,$$$CPFSave))
				Set changesMade = 1
			}
		}
		If changesMade {
			$$$ThrowOnError(##class(Config.CPF).Write())
			$$$ThrowOnError(##class(Config.Map).MoveToActive())
			$$$ThrowOnError(##class(Config.Namespaces).Load(targetNamespace))
		}
	} Catch e {
		Set sc = e.AsStatus()
	}
	Set $Namespace = oldNamespace // Explicit to work around DP-403815
	Quit sc
}

ClassMethod %UnconfigureMappings() As %Status
{
	New $Namespace
	Set oldNamespace = $Namespace
	Set sc = $$$OK
	Try {
		// Step 1: Enumerate globals based on storage definitions for %pkg.isc.rest classes
		Set queries = ""
		For field = "DataLocation","IndexLocation","StreamLocation" {
			Set queries = queries_$ListBuild(
				"SELECT "_field_" as gbl FROM %Dictionary.StorageDefinition "_
				"WHERE parent %STARTSWITH '%pkg.isc.rest.' and "_field_" is not null")
		}
		Set query = $ListToString(queries," UNION ")
		Set result = ##class(%SQL.Statement).%ExecDirect(,query)
		Set defaultCodeDB = ##class(%SYS.Namespace).GetRoutineDest()
		If (result.%SQLCODE < 0) {
			Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message)
		}
		While result.%Next(.sc) {
			$$$ThrowOnError(sc)
			Set currentDB = ##class(%SYS.Namespace).GetGlobalDest(,result.gbl)
			If (currentDB = defaultCodeDB) {
				Set gbl(result.gbl) = $lb(currentDB,defaultCodeDB)
			}
		}
		$$$ThrowOnError(sc)
		
		// Step 2: Remove global mappings
		Set targetNamespace = $Namespace
		Set $Namespace = "%SYS"
		Set changesMade = 0
		Set global = ""
		For {
			Set global = $Order(gbl(global))
			If (global = "") {
				Quit
			}
			Set globalName = $Extract(global,2,*)
			If ##Class(Config.MapGlobals).Exists(targetNamespace,globalName) {
				Write !,"Removing global mapping of "_global_" in namespace "_targetNamespace
				$$$ThrowOnError(##class(Config.MapGlobals).Delete(targetNamespace,globalName,,$$$CPFSave))
				Set changesMade = 1
			}
		}
		If changesMade {
			$$$ThrowOnError(##class(Config.CPF).Write())
			$$$ThrowOnError(##class(Config.Map).MoveToActive())
			$$$ThrowOnError(##class(Config.Namespaces).Load(targetNamespace))
		}
	} Catch e {
		Set sc = e.AsStatus()
	}
	Set $Namespace = oldNamespace // Explicit to work around DP-403815
	Quit sc
}

/// Called before tests are run (via module.xml <Invoke Phase="Test" When="Before">).
/// Handles the optional HSTools.UnitTest.Mock package dependency:
/// - If the real package exists: Tests run normally with full mocking functionality
/// - If the package is missing: Creates temporary stub classes that skip all mock-dependent tests
/// This allows tests to compile and run gracefully even when the optional mock package is unavailable.
ClassMethod HandleMockTests()
{
	// First, attempt to clean up any leftover stub classes from a previous failed run
	Do ..CleanupMockTests()

	// Check if HSTools.UnitTest.Mock.TestCase exists
	Set mockPackageExists = ##class(%Dictionary.ClassDefinition).%ExistsId("HSTools.UnitTest.Mock.TestCase")

	If mockPackageExists {
		// Check if this is our stub or the real package
		// Our stub has a special parameter we can check for
		Set isOurStub = ..IsStubMockClass("HSTools.UnitTest.Mock.TestCase")

		If isOurStub {
			// This is our stub from a previous run, clean it up and recreate
			Write !,"Found leftover stub classes from previous run, cleaning up..."
			Do ..CleanupMockTests()
			Set mockPackageExists = 0
		} Else {
			// Real package exists, tests can run normally
			Write !,"Real HSTools.UnitTest.Mock package detected. Tests will run normally."
			// Clear any leftover flags since there's nothing to clean up
			Kill ^||MockTestsCreated
			Kill ^%pkg.isc.rest.CleanMockTests
			Quit $$$OK
		}
	}

	// Store whether we created stub classes in a global so cleanup knows what to do
	Set ^||MockTestsCreated = 1

	Write !,"HSTools.UnitTest.Mock package not found. Creating stub HSTools.UnitTest.Mock classes."

	Set sc = $$$OK
	Try {
		// Set persistent flag in case tests fail and cleanup doesn't run
		Set ^%pkg.isc.rest.CleanMockTests = 1
		// Create the missing HSTools.UnitTest.Mock.MethodCall class
		Set classObj = ##class(%Dictionary.ClassDefinition).%New()
		Set classObj.Name = "HSTools.UnitTest.Mock.MethodCall"
		Set classObj.Super = "%RegisteredObject"

		$$$ThrowOnError(classObj.%Save())
		$$$ThrowOnError($System.OBJ.Compile("HSTools.UnitTest.Mock.MethodCall","c"))

		Write !,"Created stub HSTools.UnitTest.Mock.MethodCall class."

		// Create the missing HSTools.UnitTest.Mock.TestCase class
		Set classObj = ##class(%Dictionary.ClassDefinition).%New()
		Set classObj.Name = "HSTools.UnitTest.Mock.TestCase"
		Set classObj.Super = "%UnitTest.TestCase"

		// Add CALLSREALMETHODS parameter
		Set paramObj = ##class(%Dictionary.ParameterDefinition).%New()
		Set paramObj.Name = "CALLSREALMETHODS"
		Set paramObj.Default = 1
		Do classObj.Parameters.Insert(paramObj)

		// Add marker parameter to identify this as our stub
		Set markerObj = ##class(%Dictionary.ParameterDefinition).%New()
		Set markerObj.Name = "ISCRESTSTUBCLASS"
		Set markerObj.Default = 1
		Do classObj.Parameters.Insert(markerObj)

		// Add OnBeforeOneTest method that skips each test
		Set methodObj = ##class(%Dictionary.MethodDefinition).%New()
		Set methodObj.Name = "OnBeforeOneTest"
		Set methodObj.ReturnType = "%Status"

		Do methodObj.Implementation.WriteLine(" Do ..AssertSkippedViaMacro(""HSTools.UnitTest.Mock package not available"")")
		Do methodObj.Implementation.WriteLine(" Quit ##super()")

		Do classObj.Methods.Insert(methodObj)

		// Add mock() method stub
		Set mockMethodObj = ##class(%Dictionary.MethodDefinition).%New()
		Set mockMethodObj.Name = "mock"
		Set mockMethodObj.FormalSpec = "args..."

		Do mockMethodObj.Implementation.WriteLine(" Quit $$$NULLOREF")

		Do classObj.Methods.Insert(mockMethodObj)

		// Add mockStatic() method stub
		Set mockStaticObj = ##class(%Dictionary.MethodDefinition).%New()
		Set mockStaticObj.Name = "mockStatic"
		Set mockStaticObj.FormalSpec = "args..."

		Do mockStaticObj.Implementation.WriteLine(" Quit")

		Do classObj.Methods.Insert(mockStaticObj)

		// Add when() method stub
		Set whenObj = ##class(%Dictionary.MethodDefinition).%New()
		Set whenObj.Name = "when"
		Set whenObj.FormalSpec = "args..."

		Do whenObj.Implementation.WriteLine(" Quit $this")

		Do classObj.Methods.Insert(whenObj)

		// Add verify() method stub
		Set verifyObj = ##class(%Dictionary.MethodDefinition).%New()
		Set verifyObj.Name = "verify"
		Set verifyObj.FormalSpec = "args..."

		Do verifyObj.Implementation.WriteLine(" Quit")

		Do classObj.Methods.Insert(verifyObj)

		// Add thenReturn() method stub
		Set thenReturnObj = ##class(%Dictionary.MethodDefinition).%New()
		Set thenReturnObj.Name = "thenReturn"
		Set thenReturnObj.FormalSpec = "args..."

		Do thenReturnObj.Implementation.WriteLine(" Quit")

		Do classObj.Methods.Insert(thenReturnObj)

		// Add thenAnswer() method stub
		Set thenAnswerObj = ##class(%Dictionary.MethodDefinition).%New()
		Set thenAnswerObj.Name = "thenAnswer"
		Set thenAnswerObj.FormalSpec = "args..."

		Do thenAnswerObj.Implementation.WriteLine(" Quit")

		Do classObj.Methods.Insert(thenAnswerObj)

		// Add thenInvokeRealMethod() method stub
		Set thenInvokeObj = ##class(%Dictionary.MethodDefinition).%New()
		Set thenInvokeObj.Name = "thenInvokeRealMethod"
		Set thenInvokeObj.FormalSpec = ""

		Do thenInvokeObj.Implementation.WriteLine(" Quit")

		Do classObj.Methods.Insert(thenInvokeObj)

		// Add times() method stub
		Set timesObj = ##class(%Dictionary.MethodDefinition).%New()
		Set timesObj.Name = "times"
		Set timesObj.FormalSpec = "count:%Integer"

		Do timesObj.Implementation.WriteLine(" Quit $this")

		Do classObj.Methods.Insert(timesObj)

		// Add anyString() method stub
		Set anyStringObj = ##class(%Dictionary.MethodDefinition).%New()
		Set anyStringObj.Name = "anyString"
		Set anyStringObj.FormalSpec = ""

		Do anyStringObj.Implementation.WriteLine(" Quit """"")

		Do classObj.Methods.Insert(anyStringObj)

		// Add optional() method stub
		Set optionalObj = ##class(%Dictionary.MethodDefinition).%New()
		Set optionalObj.Name = "optional"
		Set optionalObj.FormalSpec = "count:%Integer=0"

		Do optionalObj.Implementation.WriteLine(" Quit """"")

		Do classObj.Methods.Insert(optionalObj)

		// Add withMethod() method stub
		Set withMethodObj = ##class(%Dictionary.MethodDefinition).%New()
		Set withMethodObj.Name = "withMethod"
		Set withMethodObj.FormalSpec = "args..."

		Do withMethodObj.Implementation.WriteLine(" Quit $$$NULLOREF")

		Do classObj.Methods.Insert(withMethodObj)

		// Save and compile with "c" flag only
		$$$ThrowOnError(classObj.%Save())
		$$$ThrowOnError($System.OBJ.Compile("HSTools.UnitTest.Mock.TestCase","c"))

		Write !,"Created stub HSTools.UnitTest.Mock.TestCase class."

	} Catch e {
		Set sc = e.AsStatus()
		Write !,"Error in HandleMockTests: "_$System.Status.GetErrorText(sc)
	}

	Quit sc
}

ClassMethod IsStubMockClass(className As %String) As %Boolean [ Private ]
{
	// Check if a class has our stub marker parameter
	Try {
		If '##class(%Dictionary.ClassDefinition).%ExistsId(className) {
			Return 0
		}

		// Check for our marker parameter
		Set paramId = className_"||ISCRESTSTUBCLASS"
		If ##class(%Dictionary.ParameterDefinition).%ExistsId(paramId) {
			Return 1
		}
	} Catch {
		// If we can't check, assume it's not our stub
		Return 0
	}

	Return 0
}

/// Called after tests are run (via module.xml <Invoke Phase="Test" When="After">).
/// Also called at the start of HandleMockTests to clean up any leftover stubs from previous failed runs.
/// Deletes temporary stub classes (HSTools.UnitTest.Mock.TestCase and HSTools.UnitTest.Mock.MethodCall)
/// that were created when the real mock package was unavailable.
/// Uses marker parameter (ISCRESTSTUBCLASS) to distinguish our stubs from the real package,
/// ensuring we never accidentally delete the actual HSTools.UnitTest.Mock classes if they get installed.
ClassMethod CleanupMockTests()
{
	// Check if we created stub classes (either in this run or a previous failed run)
	Set needsCleanup = $Get(^||MockTestsCreated) || $Get(^%pkg.isc.rest.CleanMockTests)

	If 'needsCleanup {
		// We didn't create stubs, nothing to clean up
		Quit $$$OK
	}

	Write !,"Cleaning up stub HSTools.UnitTest.Mock classes."

	Set sc = $$$OK
	Try {
		// Delete the stub classes we created, but only if they're our stubs
		// Use -d flag to delete even if there are errors
		If ##class(%Dictionary.ClassDefinition).%ExistsId("HSTools.UnitTest.Mock.TestCase") {
			// Only delete if this is our stub, not the real package
			If ..IsStubMockClass("HSTools.UnitTest.Mock.TestCase") {
				Set deleteSc = $System.OBJ.Delete("HSTools.UnitTest.Mock.TestCase","-d")
				If $$$ISOK(deleteSc) {
					Write !,"Deleted stub HSTools.UnitTest.Mock.TestCase class."
				} Else {
					Write !,"Warning: Could not delete HSTools.UnitTest.Mock.TestCase: "_$System.Status.GetErrorText(deleteSc)
				}
			} Else {
				Write !,"Real HSTools.UnitTest.Mock.TestCase detected, skipping deletion."
			}
		}

		If ##class(%Dictionary.ClassDefinition).%ExistsId("HSTools.UnitTest.Mock.MethodCall") {
			// MethodCall doesn't need a marker check since it's always ours if TestCase is our stub
			If ..IsStubMockClass("HSTools.UnitTest.Mock.TestCase") || '##class(%Dictionary.ClassDefinition).%ExistsId("HSTools.UnitTest.Mock.TestCase") {
				Set deleteSc = $System.OBJ.Delete("HSTools.UnitTest.Mock.MethodCall","-d")
				If $$$ISOK(deleteSc) {
					Write !,"Deleted stub HSTools.UnitTest.Mock.MethodCall class."
				} Else {
					Write !,"Warning: Could not delete HSTools.UnitTest.Mock.MethodCall: "_$System.Status.GetErrorText(deleteSc)
				}
			}
		}

		// Clean up the flags
		Kill ^||MockTestsCreated
		Kill ^%pkg.isc.rest.CleanMockTests

	} Catch e {
		Set sc = e.AsStatus()
		Write !,"Error in CleanupMockTests: "_$System.Status.GetErrorText(sc)
	}

	Quit sc
}

}
