/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.resourceMapProjection Extends %Projection.AbstractProjection [ System = 3 ]
{

/// Ensure this projection is applied in the main thread to prevent race conditions/deadlock when REST dispatch
/// classes and resources are being compiled at the same time.
Parameter DisableMulticompile As BOOLEAN = 1;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
	// Skip abstract classes.
	If $$$comClassKeyGet(classname,$$$cCLASSabstract) {
		Quit $$$OK
	}
	Set sc = $$$OK
	Try {
		Set resourceName = $Parameter(classname,"RESOURCENAME")
		Set mediaType = $Parameter(classname,"MEDIATYPE")
		
		// For each resource, there is exactly one Proxy class per mediaType.
		// Therefore, if we already have a mapping for this resourceName and mediaType, make sure
		// the classname of the class we're compiling matches what we have on record for this (resourceName, mediaType) pair.
		If ##class(%pkg.isc.rest.resourceMap).UniqueByClassnamesExists(classname,classname,.id) {
			Set map = ##class(%pkg.isc.rest.resourceMap).%OpenId(id,,.sc)
			$$$ThrowOnError(sc)
			If (map.ResourceName '= resourceName) || (map.MediaType '= mediaType) {
				Set sc = ##class(%pkg.isc.rest.resourceMap).%DeleteId(id)
				$$$ThrowOnError(sc)
			}
		}
		If ##class(%pkg.isc.rest.resourceMap).UniqueByContextExists(classname,resourceName,mediaType,.id) {
			Set map = ##class(%pkg.isc.rest.resourceMap).%OpenId(id,,.sc)
			$$$ThrowOnError(sc)
			If map.ResourceClass '= classname {
				Set sc = $$$ERROR($$$GeneralError,$$$FormatText("Resource '%1', media type '%2' is already in use by class %3",resourceName,mediaType,map.ResourceClass))
				$$$ThrowStatus(sc)
			}
		} Else {
			// If we don't yet have a mapping for this (resourceName, mediaType) pair, create one and populate its fields appropriately
			Set map = ##class(%pkg.isc.rest.resourceMap).%New()
		}
		Set map.ResourceName = resourceName
		Set map.MediaType = mediaType
		Set map.ResourceClass = classname
		$$$ThrowOnError(map.%Save())
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
	Set sc = $$$OK
	// Don't actually remove if it's a recompile and the class still has the projection
	// (This avoids interruption in API availability during compilation.)
	Set remove = '(recompile && ..ClassHasThisProjection(classname))
	If remove {
		If ##class(%pkg.isc.rest.resourceMap).UniqueByClassnamesExists(classname,classname,.id) {
			Set sc = ##class(%pkg.isc.rest.resourceMap).%DeleteId(id)
		}
	}
	Quit sc
}

/// Helper method to determine if the class supplied has this projection in its current definition
/// (*NOT* compiled class metadata, as that has not yet been updated when RemoveProjection is run)
ClassMethod ClassHasThisProjection(classname As %Dictionary.CacheClassname) As %Boolean
{
	// At this stage, assume the class definition is up-to-date,
	// but the compiled class metadata is not yet.
	Set found = 0

	// Find defined projections:
	Set projection = ""
	For {
		Set projection = $$$defMemberNext(classname,$$$cCLASSprojection,projection)
		If (projection = "") {
			Quit
		}
		If $$$defMemberKeyGet(classname,$$$cCLASSprojection,projection,$$$cPROJtype) = $ClassName() {
			Set found = 1
		}
	}
	
	If 'found {
		// Find inherited projections:
		Set supers = $ListFromString($$$defClassKeyGet(classname,$$$cCLASSsuper))
		Set pointer = 0
		While $ListNext(supers,pointer,super) {
			Set found = found || ..ClassHasThisProjection(super)
			If (found) {
				Quit
			}
		}
	}

	Quit found
}

}

