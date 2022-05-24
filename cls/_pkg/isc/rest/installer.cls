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

}

