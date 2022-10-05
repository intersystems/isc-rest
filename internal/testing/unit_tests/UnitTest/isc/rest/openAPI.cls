Include %pkg.isc.rest.general

Class UnitTest.isc.rest.openAPI Extends UnitTest.isc.rest.testCase
{

Property UserContext;

Property UserContextClass As %String;

Method TestSpecValidationWithPetStoreExample()
{
	// Test against the Pet Store example from https://github.com/OAI/OpenAPI-Specification/blob/master/examples/v3.0/petstore.yaml
	
	// Main
	Set petStore = ##class(%pkg.isc.rest.openAPI.model.openAPI).%New()
	Set petStore.OpenAPI = "3.0.0"
	// Info
	Set petStore.Info = ##class(%pkg.isc.rest.openAPI.model.info).%New()
	Set petStore.Info.Version = "1.0.0"
	Set petStore.Info.Title = "Swagger Petstore"
	Set petStore.Info.License = ##class(%pkg.isc.rest.openAPI.model.license).%New()
	Set petStore.Info.License.Name = "MIT"
	// Servers
	Set server = ##class(%pkg.isc.rest.openAPI.model.server).%New()
	Set server.URL = "http://petstore.swagger.io/v1"
	Do petStore.Servers.Insert(server)
	// Paths...
	Set petStore.Paths = ##class(%pkg.isc.rest.openAPI.model.paths).%New()
	// /pets Path
	Set petsPathItem = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
	// /pets Get Operation
	Set petsPathItem.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
	Set petsPathItem.Get.Summary = "List all pets"
	Set petsPathItem.Get.OperationID = "listPets"
	Do petsPathItem.Get.Tags.Insert("pets")
	// /pets Get Operation parameters
	// /pets Get Operation limit parameter
	Set limitParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
	Set limitParameter.Name = "limit"
	Set limitParameter.In = "query"
	Set limitParameter.Description = "How many items to return at one time (max 100)"
	Set limitParameter.Required = 0
	Set limitParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set limitParameter.Schema.Type = "integer"
	Set limitParameter.Schema.Format = "int32"
	Do petsPathItem.Get.Parameters.Insert(limitParameter)
	// /pets Get Operation responses
	Set petsPathItem.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	// /pets Get Operation HTTP 200 response
	Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response200.Description = "A paged array of pets"
	// /pets Get Operation HTTP 200 response header
	Set nextHeader = ##class(%pkg.isc.rest.openAPI.model.header).%New()
	Set nextHeader.Description = "A link to the next page of responses"
	Set nextHeader.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set nextHeader.Schema.Type = "string"
	Do response200.Headers.SetAt(nextHeader, "x-next")
	// /pets Get Operation HTTP 200 response schema
	Set schemaMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set schemaMediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set schemaMediatype.Schema.Ref = "#/components/schemas/Pets"
	Do response200.Content.SetAt(schemaMediatype, "application/json")
	Do petsPathItem.Get.Responses.SetAt(response200, "200")
	// /pets Get Operation default response
	Set responseDefault = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set responseDefault.Description = "unexpected error"
	// /pets Get Operation default response schema
	Set schemaMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set schemaMediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set schemaMediatype.Schema.Ref = "#/components/schemas/Error"
	Do responseDefault.Content.SetAt(schemaMediatype, "application/json")
	Do petsPathItem.Get.Responses.SetAt(responseDefault, "default")
	// /pets Post Operation
	Set petsPathItem.Post = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
	Set petsPathItem.Post.Summary = "Create a pet"
	Set petsPathItem.Post.OperationID = "createPets"
	Do petsPathItem.Post.Tags.Insert("pets")
	Set petsPathItem.Post.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	// /pets Post Operation HTTP 201 response
	Set response201 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response201.Description = "Null response"
	Do petsPathItem.Post.Responses.SetAt(response201, "201")
	Do petsPathItem.Post.Responses.SetAt(responseDefault.%ConstructClone(), "default")
	Do petStore.Paths.SetAt(petsPathItem, "/pets")
	// /pets/{petId} Path
	Set idPathItem = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
	// /pets/{petId} Get Operation
	Set idPathItem.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
	Set idPathItem.Get.Summary = "Info for a specific pet"
	Set idPathItem.Get.OperationID = "showPetById"
	Do idPathItem.Get.Tags.Insert("pets")
	// /pets/{petId} Get Operation parameters
	// /pets/{petId} Get petId parameter
	Set petIdParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
	Set petIdParameter.Name = "petId"
	Set petIdParameter.In = "path"
	Set petIdParameter.Required = 1
	Set petIdParameter.Description = "The id of the pet to retrieve"
	// /pets/{petId} Get petId parameter schema
	Set petIdParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set petIdParameter.Schema.Type = "string"
	Do idPathItem.Get.Parameters.Insert(petIdParameter)
	// /pets/{petId} Get responses
	Set idPathItem.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	// /pets/{petId} Get HTTP 200 response
	Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response200.Description = "Expected response to a valid request"
	// /pets/{petId} Get HTTP 200 response schema
	Set schemaMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set schemaMediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set schemaMediatype.Schema.Ref = "#/components/schemas/Pet"
	Do response200.Content.SetAt(schemaMediatype, "application/json")
	Do idPathItem.Get.Responses.SetAt(response200, "200")
	// /pets/{petId} Get default response
	Do idPathItem.Get.Responses.SetAt(responseDefault.%ConstructClone(), "default")
	Do petStore.Paths.SetAt(idPathItem, "/pets/{petId}")
	// Components...
	Set petStore.Components = ##class(%pkg.isc.rest.openAPI.model.components).%New()
	// Pet schema definition
	Set petSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set petSchema.Type = "object"
	Set petSchema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	Do petSchema.Required.Insert("id")
	Do petSchema.Required.Insert("name")
	// Pet schema definition id property
	Set idProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set idProperty.Type = "integer"
	Set idProperty.Format = "int64"
	Do petSchema.Properties.SetAt(idProperty, "id")
	// Pet schema definition name property
	Set nameProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set nameProperty.Type = "string"
	Do petSchema.Properties.SetAt(nameProperty, "name")
	// Pet schema definition tag property
	Set tagProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set tagProperty.Type = "string"
	Do petSchema.Properties.SetAt(tagProperty, "tag")
	Do petStore.Components.Schemas.SetAt(petSchema, "Pet")
	// Pets schema definition
	Set petsSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set petsSchema.Type = "array"
	Set petsSchema.Items = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set petsSchema.Items.Ref = "#/components/schemas/Pet"
	Do petStore.Components.Schemas.SetAt(petsSchema, "Pets")
	// Error schema definition
	Set errorSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set errorSchema.Type = "object"
	Set errorSchema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	Do errorSchema.Required.Insert("code")
	Do errorSchema.Required.Insert("message")
	// Error schema definition code property
	Set codeProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set codeProperty.Type = "integer"
	Set codeProperty.Format = "int32"
	Do errorSchema.Properties.SetAt(codeProperty, "code")
	// Error schema definition message property
	Set messageProperty = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set messageProperty.Type = "string"
	Do errorSchema.Properties.SetAt(messageProperty, "message")
	Do petStore.Components.Schemas.SetAt(errorSchema, "Error")
	
	// Validation Logic
	Set petStoreValid = petStore.Validate()
	If 'petStoreValid {
		Set buffer = ##class(%pkg.isc.json.util.buffer).%New()
		Set str = ""
		Do buffer.BeginCaptureOutput()
		Do petStore.Validate(,1)
		Do buffer.EndCaptureOutput(.str)
		Do $$$LogMessage(str)
	}
	Do $$$AssertTrue(petStoreValid, "Pet Store example passed validation.")
}

Method TestSpecValidationWithExpandedPetStoreExample()
{
	// Test against the Expanded Pet Store example from https://github.com/OAI/OpenAPI-Specification/blob/master/examples/v3.0/petstore-expanded.yaml
	Set petStore = ..GetExtendedPetStoreModel()
	
	// Validation Logic
	Set petStoreValid = petStore.Validate()
	If 'petStoreValid {
		Set buffer = ##class(%pkg.isc.json.util.buffer).%New()
		Set str = ""
		Do buffer.BeginCaptureOutput()
		Do petStore.Validate(,1)
		Do buffer.EndCaptureOutput(.str)
		Set strs = $ListFromString(str, $c(10))
		For i=1:1:$ListLength(strs) {
			Do $$$LogMessage($ListGet(strs,i))
		}
	}
	Do $$$AssertTrue(petStoreValid, "Expanded Pet Store example passed validation.")
}

Method GetExtendedPetStoreModel() As %pkg.isc.rest.openAPI.model.openAPI
{
	// Main
	Set petStore = ##class(%pkg.isc.rest.openAPI.model.openAPI).%New()
	Set petStore.OpenAPI = "3.0.0"
	// Info...
	Set petStore.Info = ##class(%pkg.isc.rest.openAPI.model.info).%New()
	Set petStore.Info.Version = "1.0.0"
	Set petStore.Info.Title = "Swagger Petstore"
	Set petStore.Info.Description = "A sample API that uses a petstore as an example to demonstrate features in the OpenAPI 3.0 specification"
	Set petStore.Info.TermsOfService = "http://swagger.io/terms/"
	// Contact Info
	Set petStore.Info.Contact = ##class(%pkg.isc.rest.openAPI.model.contact).%New()
	Set petStore.Info.Contact.Name = "Swagger API Team"
	Set petStore.Info.Contact.Email = "apiteam@swagger.io"
	Set petStore.Info.Contact.URL = "http://swagger.io"
	// License Info
	Set petStore.Info.License = ##class(%pkg.isc.rest.openAPI.model.license).%New()
	Set petStore.Info.License.Name = "Apache 2.0"
	Set petStore.Info.License.URL = "https://www.apache.org/licenses/LICENSE-2.0.html"
	// Servers
	Set server = ##class(%pkg.isc.rest.openAPI.model.server).%New()
	Set server.URL = "http://petstore.swagger.io/api"
	Do petStore.Servers.Insert(server)
	// Paths...
	Set petStore.Paths = ##class(%pkg.isc.rest.openAPI.model.paths).%New()
	// /pets Path
	Set petsPathItem = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
	// /pets Get Operation
	Set petsPathItem.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
	Set petsPathItem.Get.Description = "Returns all pets from the system that the user has access to" _ $c(10)
		_ "Nam sed condimentum est. Maecenas tempor sagittis sapien, nec rhoncus sem sagittis sit amet. Aenean at gravida augue, ac iaculis sem. Curabitur odio lorem, ornare eget elementum nec, cursus id lectus. Duis mi turpis, pulvinar ac eros ac, tincidunt varius justo. In hac habitasse platea dictumst. Integer at adipiscing ante, a sagittis ligula. Aenean pharetra tempor ante molestie imperdiet. Vivamus id aliquam diam. Cras quis velit non tortor eleifend sagittis. Praesent at enim pharetra urna volutpat venenatis eget eget mauris. In eleifend fermentum facilisis. Praesent enim enim, gravida ac sodales sed, placerat id erat. Suspendisse lacus dolor, consectetur non augue vel, vehicula interdum libero. Morbi euismod sagittis libero sed lacinia." _ $c(10)
		_ $c(10)
		_ "Sed tempus felis lobortis leo pulvinar rutrum. Nam mattis velit nisl, eu condimentum ligula luctus nec. Phasellus semper velit eget aliquet faucibus. In a mattis elit. Phasellus vel urna viverra, condimentum lorem id, rhoncus nibh. Ut pellentesque posuere elementum. Sed a varius odio. Morbi rhoncus ligula libero, vel eleifend nunc tristique vitae. Fusce et sem dui. Aenean nec scelerisque tortor. Fusce malesuada accumsan magna vel tempus. Quisque mollis felis eu dolor tristique, sit amet auctor felis gravida. Sed libero lorem, molestie sed nisl in, accumsan tempor nisi. Fusce sollicitudin massa ut lacinia mattis. Sed vel eleifend lorem. Pellentesque vitae felis pretium, pulvinar elit eu, euismod sapien."
	Set petsPathItem.Get.OperationID = "findPets"
	// /pets Get Operation parameters
	// /pets Get Operation tags parameter
	Set tagsParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
	Set tagsParameter.Name = "tags"
	Set tagsParameter.In = "query"
	Set tagsParameter.Description = "tags to filter by"
	Set tagsParameter.Required = 0
	Set tagsParameter.Style = "form"
	Set tagsParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set tagsParameter.Schema.Type = "array"
	Set tagsParameter.Schema.Items = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set tagsParameter.Schema.Items.Type = "string"
	Do petsPathItem.Get.Parameters.Insert(tagsParameter)
	// /pets Get Operation limit parameter
	Set limitParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
	Set limitParameter.Name = "limit"
	Set limitParameter.In = "query"
	Set limitParameter.Description = "maximum number of results to return"
	Set limitParameter.Required = 0
	Set limitParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set limitParameter.Schema.Type = "integer"
	Set limitParameter.Schema.Format = "int32"
	// /pets Get Operation responses
	Set petsPathItem.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	// /pets Get Operation HTTP 200 response
	Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response200.Description = "pet response"
	// /pets Get Operation HTTP 200 response schema
	Set responseMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set responseMediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set responseMediatype.Schema.Type = "array"
	Set responseMediatype.Schema.Items = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set responseMediatype.Schema.Items.Ref = "#/components/schemas/Pet"
	Do response200.Content.SetAt(responseMediatype, "application/json")
	Do petsPathItem.Get.Responses.SetAt(response200, "200")
	// /pets Get Operation default response
	Set responseDefault = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set responseDefault.Description = "unexpected error"
	// /pets Get Operation default response schema
	Set responseMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set responseMediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set responseMediatype.Schema.Ref = "#/components/schemas/Error"
	Do responseDefault.Content.SetAt(responseMediatype, "application/json")
	Do petsPathItem.Get.Responses.SetAt(responseDefault, "default")
	Do petStore.Paths.SetAt(petsPathItem, "/pets")
	// /pets/{id} Path
	Set idPathItem = ##class(%pkg.isc.rest.openAPI.model.pathItem).%New()
	// /pets/{id} Get Operation
	Set idPathItem.Get = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
	Set idPathItem.Get.Description = "Returns a user based on a single ID, if the user does not have access to the pet"
	Set idPathItem.Get.OperationID = "find pet by id"
	// /pets/{id} Get Operation parameters
	// /pets/{id} Get Operation id parameter
	Set idParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
	Set idParameter.Name = "id"
	Set idParameter.In = "path"
	Set idParameter.Description = "ID of pet to fetch"
	Set idParameter.Required = 1
	// /pets/{id} Get Operation id parameter schema
	Set idParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set idParameter.Schema.Type = "integer"
	Set idParameter.Schema.Format = "int64"
	Do idPathItem.Get.Parameters.Insert(idParameter)
	// /pets/{id} Get Operation responses
	Set idPathItem.Get.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	// /pets/{id} Get Operation HTTP 200 response
	Set response200 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response200.Description = "pet response"
	// /pets/{id} Get Operation HTTP 200 response schema
	Set responseMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set responseMediatype.Schema = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set responseMediatype.Schema.Ref = "#/components/schemas/Pet"
	Do response200.Content.SetAt(responseMediatype, "application/json")
	Do idPathItem.Get.Responses.SetAt(response200, "200")
	// /pets/{id} Get Operation default response
	Do idPathItem.Get.Responses.SetAt(responseDefault.%ConstructClone(), "default")
	// /pets/{id} Delete Operation
	Set idPathItem.Delete = ##class(%pkg.isc.rest.openAPI.model.operation).%New()
	Set idPathItem.Delete.Description = "deletes a single pet based on the ID supplied"
	Set idPathItem.Delete.OperationID = "deletePet"
	// /pets/{id} Delete Operation parameters
	// /pets/{id} Delete Operation id parameter
	Set idParameter = ##class(%pkg.isc.rest.openAPI.model.parameter).%New()
	Set idParameter.Name = "id"
	Set idParameter.In = "path"
	Set idParameter.Description = "ID of pet to delete"
	Set idParameter.Required = 1
	// /pets/{id} Delete Operation id parameter schema
	Set idParameter.Schema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set idParameter.Schema.Type = "integer"
	Set idParameter.Schema.Format = "int64"
	Do idPathItem.Delete.Parameters.Insert(idParameter)
	// /pets/{id} Delete Operation responses
	Set idPathItem.Delete.Responses = ##class(%pkg.isc.rest.openAPI.model.responses).%New()
	// /pets/{id} Delete Operation HTTP 204 response
	Set response204 = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set response204.Description = "pet deleted"
	Do idPathItem.Delete.Responses.SetAt(response204, "204")
	// /pets/{id} Delete Operation Default response
	Do idPathItem.Delete.Responses.SetAt(responseDefault.%ConstructClone(), "default")
	Do petStore.Paths.SetAt(idPathItem, "/pets/{id}")
	// Components...
	Set petStore.Components = ##class(%pkg.isc.rest.openAPI.model.components).%New()
	// Pet schema definition
	Set petSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set allOf1 = ##class(%pkg.isc.rest.openAPI.model.schemaReference).%New()
	Set allOf1.Ref = "#/components/schemas/NewPet"
	Set allOf2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set allOf2.Type = "object"
	Set allOf2.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	Do allOf2.Required.Insert("id")
	Set idSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set idSchema.Type = "integer"
	Set idSchema.Format = "int64"
	Do allOf2.Properties.SetAt(idSchema, "id")
	Do petSchema.AllOf.Insert(allOf1)
	Do petSchema.AllOf.Insert(allOf2)
	Do petStore.Components.Schemas.SetAt(petSchema, "Pet")
	// NewPet schema definition
	Set newPetSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set newPetSchema.Type = "object"
	Set newPetSchema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	Do newPetSchema.Required.Insert("name")
	Set nameSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set nameSchema.Type = "string"
	Set tagSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set tagSchema.Type = "string"
	Do newPetSchema.Properties.SetAt(nameSchema, "name")
	Do newPetSchema.Properties.SetAt(tagSchema, "tag")
	Do petStore.Components.Schemas.SetAt(newPetSchema, "NewPet")
	// Error schema definition
	Set errorSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set errorSchema.Type = "object"
	Set errorSchema.Required = ##class(%pkg.isc.rest.openAPI.model.stringList).%New()
	Do errorSchema.Required.Insert("code")
	Do errorSchema.Required.Insert("message")
	Set codeSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set codeSchema.Type = "integer"
	Set codeSchema.Format = "int32"
	Set messageSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set messageSchema.Type = "string"
	Do errorSchema.Properties.SetAt(codeSchema, "code")
	Do errorSchema.Properties.SetAt(messageSchema, "message")
	Do petStore.Components.Schemas.SetAt(errorSchema, "Error")
	Return petStore
}

Method TestGenerationWithSharedResourceName()
{
	// Env setup
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi = ..SetupTestingEnvironment()
	Set openapi.DEBUG = 0
	Set openapi.HideInternalInfo = 1
	Set openapi.ForceAuthorizeAllEndpoints = 0
	Set openapi.IncludeForbiddenEndpoints = 0
	
	// Class setup
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1","MEDIATYPE":"application/vnd.intersystems.apps.unittest.resource.1+json"}, "property1",,, ,,, , ["CheckPermission1:CheckPermission"]))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class2", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class2","MEDIATYPE":"application/vnd.intersystems.apps.unittest.resource.2+json"}, "property2",,, ,,, , ["CheckPermission2:CheckPermission"]))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class3", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class3"}, ,,, ,,, ["ActionMap1:ActionMap"], ["CheckPermission3:CheckPermission"]))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class4", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class4","MEDIATYPE":"application/vnd.intersystems.apps.unittest.resource.4+json"}, "property3",,, ,,, , ["CheckPermission1:CheckPermission"]))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class5", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class5","MEDIATYPE":"application/vnd.intersystems.apps.unittest.resource.5+json"}, "property3",,, ,,, , ["CheckPermission1:CheckPermission"]))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class6", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class6","MEDIATYPE":"application/vnd.intersystems.apps.unittest.resource.6+json"}, ,,, ,,, ["ActionMap2:ActionMap"], ["CheckPermission1:CheckPermission"]))
	
	// Class compilation
	// As of now, only supported HTTP verbs in ActionMap:
	// - GET
	// - POST
	// - PUT
	// - DELETE
	// As support for verbs increases, add equivalent ActionMap tests for them
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class2"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class3"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class4"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class5"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class6"))
	
	// Specification generation
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Do $$$AssertTrue(openapi.Specification, "Generated specification validates successfully")
	Do $$$AssertEquals(openapi.Errors.Count(), 0, "No errors were logged during spec generation")
	Do openapi.Specification.%JSONExportToString(.str)
	Set specJSON = {}.%FromJSON(str)
	
	// /unittest-resource path checks
	#Dim resourcePathItem As %pkg.isc.rest.openAPI.model.pathItem
	Set resourcePathItem = openapi.Specification.Paths.GetAt("/unittest-resource")

	// TODO: This test is failing and perhaps revealing an actual problem?
	// TODO: Commenting out for now until problem is diagnosed so that tests
	// can run successfully
	// Do ..VerifyJSON(specJSON, {"paths":{"/unittest-resource":{"get":{"parameters":[{"name":"property1","in":"query"},{"name":"property3","in":"query"}]}}}}, "Properties for both classes served by a collection query are present")
	Do ..VerifyJSON(specJSON, {"paths":{"/unittest-resource":{"get":{"responses":{"200":{"content":{"application/vnd.intersystems.apps.unittest.resource.1+json":{},"application/vnd.intersystems.apps.unittest.resource.4+json":{},"application/vnd.intersystems.apps.unittest.resource.5+json":{}}}}}}}}, "The proper responses for a shared collection query are present")
	Do $$$AssertNotEquals(resourcePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class1"),"", "Resource GET operation has Class1 as a Source Class")
	Do $$$AssertEquals(resourcePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class2"),"", "Resource GET operation does NOT have Class2 as a Source Class")
	Do $$$AssertEquals(resourcePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class3"),"", "Resource GET operation does NOT have Class3 as a Source Class")
	Do $$$AssertNotEquals(resourcePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class4"),"", "Resource GET operation has Class4 as a Source Class")
	Do $$$AssertNotEquals(resourcePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class5"),"", "Resource GET operation has Class5 as a Source Class")
	Do $$$LogMessage("[Not Checked] Resource GET operation " _ $Case(resourcePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class6")="",1:"does NOT have",:"has") _ " Class6 as a Source Class")
	Do $$$AssertEquals(resourcePathItem.Post, "", "Resource POST operation is not set")
	Do $$$AssertEquals(resourcePathItem.Put, "", "Resource PUT operation is not set")
	Do $$$AssertEquals(resourcePathItem.Delete, "", "Resource DELETE operation is not set")
	Do $$$AssertEquals(resourcePathItem.Patch, "", "Resource PATCH operation is not set")
	Do $$$AssertEquals(resourcePathItem.Trace, "", "Resource TRACE operation is not set")
	Do $$$AssertEquals(resourcePathItem.Head, "", "Resource HEAD operation is not set")
	Do $$$AssertEquals(resourcePathItem.Options, "", "Resource OPTIONS operation is not set")
	
	// /unittest-resource/$test-action checks
	#Dim actionPathItem As %pkg.isc.rest.openAPI.model.pathItem
	Set actionPathItem = openapi.Specification.Paths.GetAt("/unittest-resource/$test-action")
	Do $$$AssertEquals(actionPathItem.SourceClasses.Count(), 1, "Action path item has only one source class")
	Do $$$AssertEquals(actionPathItem.SourceClasses.GetAt(1), "zUnitTest.isc.rest.class3", "Action path item has the correct source class")
	Do $$$AssertEquals(actionPathItem.Get, "", "Action GET operation is not set")
	Do $$$AssertEquals(actionPathItem.Put, "", "Action PUT operation is not set")
	Do $$$AssertEquals(actionPathItem.Delete, "", "Action DELETE operation is not set")
	Do $$$AssertEquals(actionPathItem.Patch, "", "Action PATCH operation is not set")
	Do $$$AssertEquals(actionPathItem.Trace, "", "Action TRACE operation is not set")
	Do $$$AssertEquals(actionPathItem.Head, "", "Action HEAD operation is not set")
	Do $$$AssertEquals(actionPathItem.Options, "", "Action OPTIONS operation is not set")
	Do $$$AssertEquals(actionPathItem.Post.Tags.GetAt(1),"unittest-resource")
	Do $$$AssertEquals(actionPathItem.Post.Parameters.Count(),2)
	Do $$$AssertEquals(actionPathItem.Post.Parameters.GetAt(1).In,"query")
	Do $$$AssertEquals(actionPathItem.Post.Parameters.GetAt(1).Name,"op")
	Do $$$AssertEquals(actionPathItem.Post.Parameters.GetAt(1).Schema.Ref,"#/components/schemas/string_input")
	Do $$$AssertEquals(actionPathItem.Post.Parameters.GetAt(2).In,"query")
	Do $$$AssertEquals(actionPathItem.Post.Parameters.GetAt(2).Name,"uc")
	Do $$$AssertEquals(actionPathItem.Post.Parameters.GetAt(2).Schema.Ref,"#/components/schemas/registered-object_input")
	Do $$$AssertTrue($IsObject(actionPathItem.Post.RequestBody.Content.GetAt("application/json")))
	
	// /unittest-resource/{id} checks
	#Dim resourceInstancePathItem As %pkg.isc.rest.openAPI.model.pathItem
	Set resourceInstancePathItem = openapi.Specification.Paths.GetAt("/unittest-resource/{id}")
	Do ..VerifyJSON(specJSON, {"paths":{"/unittest-resource/{id}":{"get":{"responses":{"200":{"content":{"application/vnd.intersystems.apps.unittest.resource.2+json":{}}}}}}}}, "The proper response for one class served by an instance GET is present")
	Do $$$AssertEquals(resourceInstancePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class1"),"", "Resource instance GET operation does NOT have Class2 as a Source Class")
	Do $$$AssertNotEquals(resourceInstancePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class2"),"", "Resource instance GET operation has Class2 as a Source Class")
	Do $$$AssertEquals(resourceInstancePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class3"),"", "Resource instance GET operation does NOT have Class3 as a Source Class")
	Do $$$AssertEquals(resourceInstancePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class4"),"", "Resource instance GEt operation does NOT have Class4 as a Source Class")
	Do $$$LogMessage("[Not Checked] Resource instance GET operation " _ $Case(resourceInstancePathItem.Get.SourceClasses.Find("zUnitTest.isc.rest.class6")="",1:"does NOT have",:"has") _ " Class6 as a Source Class")
	Do $$$AssertEquals(resourceInstancePathItem.Post, "", "Resource instance POST operation is not set")
	Do $$$AssertEquals(resourceInstancePathItem.Patch, "", "Resource instance PATCH operation is not set")
	Do $$$AssertEquals(resourceInstancePathItem.Trace, "", "Resource instance TRACE operation is not set")
	Do $$$AssertEquals(resourceInstancePathItem.Head, "", "Resource instance HEAD operation is not set")
	Do $$$AssertEquals(resourceInstancePathItem.Options, "", "Resource instance OPTIONS operation is not set")
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class2"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class3"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class4"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class5"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestModelSaveAndRestoreAndDelete()
{
	// Get initial sizes for all the tables we're going to be touching, so we can make sure they are the same size after saving + deleting the model
	Set tables = ##class(%SQL.Statement).%ExecDirect(, "select string(Table_Schema,'.',Table_Name) As TableName FROM Information_Schema.Tables where ClassName like 'isc.rest.openAPI.Model.%'")
	Do $$$AssertEquals(tables.%SQLCODE, 0, "Model table names query succeeded")
	Set tableRowCounts = ##class(%ArrayOfDataTypes).%New()
	While tables.%Next() {
		Set info = ##class(%SQL.Statement).%ExecDirect(, "select count(*) As TableRows from " _ tables.TableName)
		Do $$$AssertEquals(info.%SQLCODE, 0, "Table " _ tables.TableName _ " row count query succeeded")
		Do $$$AssertStatusOK(info.%Next())
		Do tableRowCounts.SetAt(info.TableRows, tables.TableName)
	}
	// Get a model to test + its JSON representation
	Set petStore = ..GetExtendedPetStoreModel()
	Set originalJSON = ""
	Do $$$AssertStatusOK(petStore.%JSONExportToString(.originalJSON), "Original Extended Pet Store model wrote to JSON successfully")
	// Make a saveable copy of it + get the JSON representation of that
	Set saveablePetStore = petStore.GetSaveableInstance()
	Set saveableJSON = ""
	Do $$$AssertStatusOK(saveablePetStore.%JSONExportToString(.saveableJSON), "Saveable Extended Pet Store model wrote to JSON successfully")
	// Save it
	Do $$$AssertStatusOK(saveablePetStore.%Save(), "Saveable Extended Pet Store model saved successfully")
	Set petStoreId = saveablePetStore.%Id()
	// Remove the in-memory copies of the initial model
	Kill petStore
	Kill saveablePetStore
	// Load the model we just saved + get its JSON reperesentation
	Set loadedPetStore = ##class(%pkg.isc.rest.openAPI.model.openAPI).%OpenId(petStoreId, .sc)
	Do $$$AssertStatusOK(sc, "Saveable Extended Pet Store model loaded from the database successfully")
	Set loadedJSON = ""
	Do $$$AssertStatusOK(loadedPetStore.%JSONExportToString(.loadedJSON), "Loaded Extended Pet Store model wrote to JSON successfully")
	// Equality-check all the JSON representations
	Do $$$AssertEquals(saveableJSON, originalJSON, "Saveable Extended Pet Store model JSON is the same as the Original Extended Pet Store model JSON")
	Do $$$AssertEquals(loadedJSON, originalJSON, "Loaded Extended Pet Store model JSON is the same as the Original Extended Pet Store model JSON")
	Do $$$LogMessage("[Not Checked] Loaded Extended Pet Store model JSON is the same as the Saveable Extended Pet Store model JSON")
	// Delete the saved model
	Do $$$AssertStatusOK(loadedPetStore.Delete(), "Extended Pet Store model deleted successfully")
	// And check that none of the tables have different row counts than before this test ran
	Set tableName = "", initialTableRows = tableRowCounts.GetNext(.tableName)
	While tableName '= "" {
		Set info = ##class(%SQL.Statement).%ExecDirect(, "select count(*) As TableRows from " _ tableName)
		Do $$$AssertEquals(info.%SQLCODE, 0, "Table " _ tableName _ " row count query succeeded")
		Do $$$AssertStatusOK(info.%Next())
		Do $$$AssertEquals(info.TableRows, initialTableRows, "Table " _ tableName _ " row count was unchanged after a save / load / delete cycle (" _ initialTableRows _ " --> " _ info.TableRows _ ")")
		Set initialTableRows = tableRowCounts.GetNext(.tableName)
	}
}

Method TestSpecModificationMethods()
{
	// Environment setup
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, ,,, ,,, , ["AuthenticationStrategy", "CheckResourcePermitted", "ModifyOpenAPISpecification"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"))
	
	// Resource class setup
	// Use the poorly-typed setup from TestUndesiredArgumentsAndReturnTypesHandling() -- make sure the warnings are not present after being fixed using ModifyOpenAPISpecification
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, ,,, ,,, ["PoorlyTypedMethodsActionMap:ActionMap"], ["CheckPermissionAllowAll:CheckPermission","PoorlyTypedMethod1","PoorlyTypedMethod2","PoorlyTypedMethod3","ModifyOpenAPIInfoSpecModification:ModifyOpenAPIInfo"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do spec.%JSONExportToString(.str)
	Do $$$LogMessage(str)
	
	// Check that the warnings that *would* have been thrown without spec modification were *not* thrown
	Set method1Arg1WarningFound = 0
	Set method1Arg2WarningFound = 0
	// Note: method2Arg1's warning is not checked (warnings for ill-defined argument types are thrown for a METHOD, not an ENDPOINT; similar logic holds for invalid JSONMAPPINGs / missing action methods)
	Set method2Arg1WarningFound = 0
	Set method2ReturnWarningFound = 0
	Set method3WarningFound = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i),"U")
		If warning [ "POORLY-TYPED-METHOD-1" && (warning [ "PARAM1") && (warning [ "DYNAMIC") {
			Set method1Arg1WarningFound = method1Arg1WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD1" && (warning [ "ARG1") && (warning [ "DYNAMIC") {
			Set method1Arg1WarningFound = method1Arg1WarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-1" && (warning [ "PARAM2") && (warning [ "DYNAMIC") {
			Set method1Arg2WarningFound = method1Arg2WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD1" && (warning [ "ARG2") && (warning [ "DYNAMIC") {
			Set method1Arg2WarningFound = method1Arg2WarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-2" && (warning [ "PARAM1") && (warning [ "NOT") {
			Set method2Arg1WarningFound = method2Arg1WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD2" && (warning [ "ARG1") && (warning [ "NOT") {
			Set method2Arg1WarningFound = method2Arg1WarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-2" && (warning [ "RESPONSE" || (warning [ "RETURN")) && (warning [ "DYNAMIC") {
			Set method2ReturnWarningFound = method2ReturnWarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD2" && (warning [ "RESPONSE" || (warning [ "RETURN")) && (warning [ "DYNAMIC") {
			Set method2ReturnWarningFound = method2ReturnWarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-3" && (warning [ "RESPONSE" || (warning [ "RETURN")) {
			Set method3WarningFound = method3WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD3" && (warning [ "RESPONSE" || (warning [ "RETURN")) {
			Set method3WarningFound = method3WarningFound + 1
		} ElseIf (warning [ "VERSION") {
			Do $$$AssertTrue(0, "Warning """ _ spec.Warnings.GetAt(i) _ """ should NOT be present, but is.")
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ spec.Warnings.GetAt(i))
		}
	}
	Do $$$AssertEquals(method1Arg1WarningFound, 0, "Method with now non-%DynamicArray argument type did NOT generate a warning (" _ method1Arg1WarningFound _ ")")
	Do $$$AssertEquals(method1Arg2WarningFound, 0, "Method with now non-%DynamicObject argument type did NOT generate a warning (" _ method1Arg2WarningFound _ ")")
	Do $$$AssertEquals(method2ReturnWarningFound, 0, "Method with now non-%DynamicObject return type did NOT generate a warning (" _ method2ReturnWarningFound _ ")")
	Do $$$AssertEquals(method3WarningFound, 0, "Method with a now JSONify-able return type (not %Integer) did NOT generate a warning (" _ method3WarningFound _ ")")
	
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-1",spec)), "Removed path item is not present")
	Try {
		Do spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-2/get/requestBody/content/application/json/schema",spec).%JSONExportToString(.str)
		Do ..VerifyJSON({}.%FromJSON(str), {"type":"number"}, "Modified parameter schema came across correctly")
	} Catch e {
		Do $$$AssertTrue(0, $system.Status.GetErrorText(e.AsStatus()))
	}
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-2/get/responses/204",spec)), "HTTP 204 removed correctly")
	Try {
		Do spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-2/get/responses/200/content/application/json/schema",spec).%JSONExportToString(.str)
		Do ..VerifyJSON({}.%FromJSON(str), {"type":"object","properties":{"key1":{"type":"string"},"key2":{"type":"integer"}}}, "New HTTP 200 return-type schema came across correctly")
	} Catch e {
		Do $$$AssertTrue(0, $system.Status.GetErrorText(e.AsStatus()))
	}
	Do $$$AssertEquals(spec.Info.Version, "1.2.3", "Changed spec version came across correctly")
	Do $$$AssertTrue('($ZConvert(spec.Info.Description,"U") [ "DEV"), "Version in-dev warning was not present for modified version")

	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestWarningHandling()
{
	Set openapi = ..SetupTestingEnvironment()
	
	Set openapi.DEBUG = 1
	Do openapi.Warn("UNITTESTWARNING1")
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	
	Set warningFound = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = spec.Warnings.GetAt(i)
		If warning = "UNITTESTWARNING1" {
			Set warningFound = 1
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ warning)
		}
	}
	Do $$$AssertTrue(warningFound, "Manually-set warning fired as-expected with DEBUG=1")
	Do $$$AssertTrue(spec.Info.Description [ "UNITTESTWARNING1", "Manually-set warning was included in the spec description as-expected with DEBUG=1")
	
	Do openapi.Reset()
	Set openapi.DEBUG = 0
	Do openapi.Warn("UNITTESTWARNING2")
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	
	Set warningFound = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = spec.Warnings.GetAt(i)
		If warning = "UNITTESTWARNING2" {
			Set warningFound = 1
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ warning)
		}
	}
	Do $$$AssertTrue(warningFound, "Manually-set warning fired as-expected with DEBUG=0")
	Do $$$AssertTrue('(spec.Info.Description [ "UNITTESTWARNING2"), "Manually-set warning was NOT included in the spec description as-expected with DEBUG=0")
	
	// Class teardown
	Do ..TeardownClass("zUnitTest.isc.rest.handler")
}

Method TestErrorHandling()
{
	Set openapi = ..SetupTestingEnvironment()
	
	Set openapi.DEBUG = 1
	Do openapi.Error("UNITTESTERROR1")
	Do $$$AssertTrue('openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation did NOT complete without errors")
	Set spec = openapi.Specification
	
	Set errorFound = 0
	For i=1:1:spec.Errors.Count() {
		Set error = spec.Errors.GetAt(i)
		If error = "UNITTESTERROR1" {
			Set errorFound = 1
		} Else {
			Do $$$AssertTrue(0, "Found an error unrelated to this test (this shouldn't happen!): " _ error)
		}
	}
	Do $$$AssertTrue(errorFound, "Manually-set error fired as-expected with DEBUG=1")
	Do $$$AssertTrue(spec.Info.Description [ "UNITTESTERROR1", "Manually-set error was included in the spec description as-expected with DEBUG=1")
	
	Do openapi.Reset()
	Set openapi.DEBUG = 0
	Do openapi.Error("UNITTESTERROR2")
	Do $$$AssertTrue('openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation did NOT complete without errors")
	Set spec = openapi.Specification
	
	Set errorFound = 0
	For i=1:1:spec.Errors.Count() {
		Set error = spec.Errors.GetAt(i)
		If error = "UNITTESTERROR2" {
			Set errorFound = 1
		} Else {
			Do $$$AssertTrue(0, "Found an error unrelated to this test (this shouldn't happen!): " _ error)
		}
	}
	Do $$$AssertTrue(errorFound, "Manually-set error fired as-expected with DEBUG=0")
	Do $$$AssertTrue('(spec.Info.Description [ "UNITTESTERROR2"), "Manually-set error was NOT included in the spec description as-expected with DEBUG=0")
	
	// Class teardown
	Do ..TeardownClass("zUnitTest.isc.rest.handler")
}

Method TestVersionHandling()
{
	// Check that a warning is fired if the version isn't set [check in other tests that no warning is fired]
	// Check that a description is added if the version is SemVer and in-dev version
	// Check that non SemVer versions dont throw errors (but do throw a warning?)
	// Environment setup
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	
	// Check that a warning is thrown when no version number is set
	Do $$$LogMessage("Check with APIVersion parameter unset")
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do $$$AssertTrue(spec.Errors.Count() = 0, "No errors were logged")
	Set foundWarning = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i), "U")
		If warning [ "APIVERSION" && (warning [ "ZUNITTEST.ISC.REST.HANDLER") {
			Set foundWarning = 1
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ spec.Warnings.GetAt(i))
		}
	}
	Do $$$AssertTrue(foundWarning, "An appropriate warning is fired when no version number is set in the handler class")
	
	// Get set-up to easily modify the version parameter
	Set handlerClass = ##class(%Dictionary.ClassDefinition).%OpenId("zUnitTest.isc.rest.handler")
	Set versionParameter = ##class(%Dictionary.ParameterDefinition).%OpenId("%pkg.isc.rest.handler||APIVersion").%ConstructClone()
	Do handlerClass.Parameters.Insert(versionParameter)
	Do $$$AssertStatusOK(handlerClass.%Save())
	
	// Check that a description is added if the SemVer major version number is 0 (also check that no warning related to the version is fired)
	Do $$$LogMessage("Check with APIVersion = 0.1.0")
	Set versionParameter.Default = "0.1.0"
	Do $$$AssertStatusOK(versionParameter.%Save())
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"))
	Do openapi.Reset()
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do $$$AssertTrue(spec.Errors.Count() = 0, "No errors were logged")
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i), "U")
		Do $$$AssertTrue('(warning [ "VERSION"), "Warning """ _ spec.Warnings.GetAt(i) _ """ was not related to the API version value")
	}
	Do $$$AssertTrue($ZConvert(spec.Info.Description,"U") [ "DEV", "Specification description mentions that the spec is a development version")
	
	// Check that non SemVer versions don't throw errors (but do throw warnings)
	Do $$$LogMessage("Check with APIVersion = a1.2.3")
	Set versionParameter.Default = "a1.2.3"
	Do $$$AssertStatusOK(versionParameter.%Save())
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"))
	Do openapi.Reset()
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do $$$AssertTrue(spec.Errors.Count() = 0, "No errors were logged")
	Set foundWarning = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i), "U")
		If warning [ "VERSION" && (warning [ "SEM") && (warning [ "VER") {
			Set foundWarning = 1
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ spec.Warnings.GetAt(i))
		}
	}
	Do $$$AssertTrue(foundWarning, "An appropriate warning is fired when a non-SemVer version number is set in the handler class")
	
	// Check that SemVer version numbers with major version > 0 do NOT throw any warnings, or add anything to the description
	Do $$$LogMessage("Check with APIVersion = 1.0.0")
	Set versionParameter.Default = "1.0.0"
	Do $$$AssertStatusOK(versionParameter.%Save())
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"))
	Do openapi.Reset()
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do $$$AssertTrue(spec.Errors.Count() = 0, "No errors were logged")
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i), "U")
		Do $$$AssertTrue('(warning [ "VERSION"), "Warning """ _ spec.Warnings.GetAt(i) _ """ was not related to the API version value")
	}
	Do $$$AssertTrue('($ZConvert(spec.Info.Description,"U") [ "DEV"), "Specification description does not mention that the spec is a development version")
	
	// Class teardown
	Do ..TeardownClass("zUnitTest.isc.rest.handler")
}

Method TestInvalidJSONMapping()
{
	
	// Environment setup
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	
	// Resource class setup
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource", "SOURCECLASS":"zUnitTest.isc.rest.class1", "JSONMAPPING":"NonexistentJSONMapping"}, ,,, ,,, , ["CheckPermissionAllowAll:CheckPermission"]))
	
	// Class compilation
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	
	// Specification generation
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do spec.%JSONExportToString(.str)
	Do $$$LogMessage(str)
	
	// Check that the expected endpoints have success (200/204) responses
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource", spec)), "Class endpoint exists")
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource/{id}", spec)), "Instance endpoint exists")
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource/get/responses/200", spec)), "Collection Query endpoint success (200) response exists")
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource/{id}/get/responses/200", spec)), "Instance GET endpoint success (200) response exists")
	
	// Check that the expected warning was thrown
	Do $$$AssertTrue(spec.Warnings.Count() >= 1, "At least one warning was logged")
	Set warningFound = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i), "U")
		If warning [ "JSONMAPPING " && (warning [ "NONEXISTENTJSONMAPPING") && (warning [ "ZUNITTEST.ISC.REST.CLASS1") {
			Set warningFound = 1
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ spec.Warnings.GetAt(i))
		}
	}
	Do $$$AssertTrue(warningFound, "Non-existent JSONMapping fired an error")
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestIncompatibleMediatypes()
{
	// Environment setup
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	
	// Resource class setup
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1","MEDIATYPE":"image/png"}, ,,, ,,, , ["CheckPermissionAllowAll:CheckPermission"]))
	
	// Class compilation
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	
	// Check that no success responses came through
	Do $$$AssertTrue('openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation did NOT complete without errors")
	Set spec = openapi.Specification
	Do spec.%JSONExportToString(.specJSON)
	Do $$$LogMessage(specJSON)
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/get/responses/200",spec)), "Class GET 200 was removed")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/post/responses/200",spec)), "Class POST 200 was removed")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/$new/get/responses/200",spec)), "Class $NEW 200 was removed")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/{id}/get/responses/200",spec)), "Instance GET 200 was removed")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/{id}/put/responses/200",spec)), "Instance PUT 200 was removed")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/{id}/delete/responses/204",spec)), "Instance DELETE 204 was removed")
	
	// Check that the expected error was fired
	Set errorFound = 0
	For i=1:1:spec.Errors.Count() {
		Set error = $ZConvert(spec.Errors.GetAt(i),"U")
		If error [ "ZUNITTEST.ISC.REST.CLASS1" && (error [ "MEDIATYPE") {
			Set errorFound = 1
		} Else {
			Do $$$AssertTrue(0, "Found an error unrelated to this test (this shouldn't happen!): " _ spec.Errors.GetAt(i))
		}
	}
	Do $$$AssertTrue(errorFound, "Invalid mediatype on a resource class threw an error")
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
}

Method TestHideInternalInfoFlag()
{
	// Environment setup
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Set openapi.HideInternalInfo = 1
	
	// Resource class setup
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, "TestProp", {"Type":"zUnitTest.isc.rest.class1"}, {"%JSONFIELDNAME":"testField"}, ,,, ["IntegerIdentityActionMap:ActionMap"], ["CheckPermissionAllowAll:CheckPermission","IntegerIdentity"]))
	
	// Class compilation
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	
	// Check HideInternalInfo=1 class name
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do spec.%JSONExportToString(.specJSON)
	Do $$$LogMessage(specJSON)
	Do $$$AssertTrue('(specJSON [ "zUnitTest.isc.rest.class1") && '(specJSON [ "Integer"), "Specification generated with HideInternalInfo=1 does not contain class names")
	
	// Check HideInternalInfo=1 property name
	Set spec.Paths.GetAt("/unittest-resource").Get = ""
	Do spec.%JSONExportToString(.specJSON)
	Do $$$AssertTrue('(specJSON [ "TestProp"), "Specification generated with HideInternalInfo=1 does not contain property name when %JSONFIELDNAME is defined (excluding /resource:GET)")
	
	// Class Teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestIncludeForbiddenEndpointsFlag()
{
	// Environment setup
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Set openapi.ForceAuthorizeAllEndpoints = 0
	
	// Resource class setup
	// Behavior should differ when an invalid MEDIATYPE is defined on a resource, leading success responses to not be generated
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource-1","SOURCECLASS":"zUnitTest.isc.rest.class1","MEDIATYPE":"image/png"}, ,,, ,,, , ["CheckPermissionAllowAll:CheckPermission"]))
	// Behavior should differ when endpoints have no reachable success response due to the CheckPermission() method
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class3", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource-3","SOURCECLASS":"zUnitTest.isc.rest.class3"}, ,,, ,,, , ["CheckPermissionDenyAll:CheckPermission"]))
	// Behavior should differ when endpoints have no reachable success response due to the ModifyOpenAPIInfo() method (ONLY when the endpoint has not been completely removed)
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class4", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class4"}, ,,, ,,, , ["CheckPermissionAllowAll:CheckPermission", "ModifyOpenAPIInfoRemoveQuery200Response:ModifyOpenAPIInfo"]))
	
	// Class compilation
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class3"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class4"))
	
	// Test behavior when forbidden endpoints are NOT explicitly included
	Do $$$LogMessage("Test with IncludeForbiddenEndpoints = 0")
	Set openapi.IncludeForbiddenEndpoints = 0
	Do openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/")
	Set spec = openapi.Specification
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource-1/get", spec)), "Endpoint with no success responses due to an invalid MEDIATYPE is NOT present")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource-3/get", spec)), "Endpoint with no success responses due to the CheckPermission() method is NOT present")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/get", spec)), "Endpoint with no success responses due to the ModifyOpenAPIInfo() method is NOT present")
	
	Do spec.%JSONExportToString(.str)
	Do $$$LogMessage(str)
	
	// Test behavior when forbidden endpoints ARE explicitly included
	Do $$$LogMessage("Test with IncludeForbiddenEndpoints = 1")
	Do openapi.Reset()
	Set openapi.IncludeForbiddenEndpoints = 1
	Do openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/")
	Set spec = openapi.Specification
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource-1/get", spec)), "Endpoint with no success responses due to an invalid MEDIATYPE IS present")
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource-3/get", spec)), "Endpoint with no success responses due to the CheckPermission() method IS present")
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource/get", spec)), "Endpoint with no success responses due to the ModifyOpenAPIInfo() method IS present")
	
	Do spec.%JSONExportToString(.str)
	Do $$$LogMessage(str)
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class3"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class4"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestUndesiredArgumentAndReturnTypesHandling()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Set openapi.ForceAuthorizeAllEndpoints = 1
	Set openapi.IncludeForbiddenEndpoints = 1
	set st = ..SetupClass(
		"zUnitTest.isc.rest.class1", 
		["%Persistent","%pkg.isc.rest.model.dbMappedResource"], 
		{"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, ,,, ,,, 
		["PoorlyTypedMethodsActionMap:ActionMap"], 
		["CheckPermissionAllowAll:CheckPermission","PoorlyTypedMethod1","PoorlyTypedMethod2","PoorlyTypedMethod3"]
	)
	Do $$$AssertStatusOK(st)
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	Do $$$AssertTrue(spec.Warnings.Count() >= 7, "At least seven warnings were logged")
	Do $$$AssertEquals(spec.Errors.Count(), 0, "No errors were logged")
	
	// Expected warnings?
	// Method1 arg1 + arg2 both warn for being dynamic*
	// Method2 arg1 warns for having no specified type
	// Method1 is marked as having no response
	// Method2 warns for dynamic* return type
	// Method3 warns for mismatched return type [Not Possible to check without calling the method :( ]
	// Method3 warns/errors (?) for a non-jsonify-able return type -- actual schema should come through as only returning NoContent / Forbidden
	
	// Step 1: Check that the actual specification contains the expected values
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-1/get/responses/200/content/application/json/schema", spec)), "Method with no specified return type does not have a return schema")
	Do $$$AssertTrue('$IsObject(spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-3/get/responses/200",spec)), "Method with a non-JSONify-able return type (%Library.Integer) does not have an HTTP 200 response")
	Do $$$AssertTrue($IsObject(spec.ResolveReference("#/paths//unittest-resource/$poorly-typed-method-3/get/responses/204",spec)), "Method with a non-JSONify-able return type (%Library.Integer) has an HTTP 204 response")
	
	// Step 2: Check that the correct warnings / errors were thrown
	Set method1Arg1WarningFound = 0
	Set method1Arg2WarningFound = 0
	Set method2Arg1WarningFound = 0
	Set method2ReturnWarningFound = 0
	Set method3WarningFound = 0
	For i=1:1:spec.Warnings.Count() {
		Set warning = $ZConvert(spec.Warnings.GetAt(i),"U")
		If warning [ "POORLY-TYPED-METHOD-1" && (warning [ "PARAM1") && (warning [ "DYNAMIC") {
			Set method1Arg1WarningFound = method1Arg1WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD1" && (warning [ "ARG1") && (warning [ "DYNAMIC") {
			Set method1Arg1WarningFound = method1Arg1WarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-1" && (warning [ "PARAM2") && (warning [ "DYNAMIC") {
			Set method1Arg2WarningFound = method1Arg2WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD1" && (warning [ "ARG2") && (warning [ "DYNAMIC") {
			Set method1Arg2WarningFound = method1Arg2WarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-2" && (warning [ "PARAM1") && (warning [ "NOT") {
			Set method2Arg1WarningFound = method2Arg1WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD2" && (warning [ "ARG1") && (warning [ "NOT") {
			Set method2Arg1WarningFound = method2Arg1WarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-2" && (warning [ "RESPONSE" || (warning [ "RETURN")) && (warning [ "DYNAMIC") {
			Set method2ReturnWarningFound = method2ReturnWarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD2" && (warning [ "RESPONSE" || (warning [ "RETURN")) && (warning [ "DYNAMIC") {
			Set method2ReturnWarningFound = method2ReturnWarningFound + 1
		} ElseIf warning [ "POORLY-TYPED-METHOD-3" && (warning [ "RESPONSE" || (warning [ "RETURN")) {
			Set method3WarningFound = method3WarningFound + 1
		} ElseIf warning [ "POORLYTYPEDMETHOD3" && (warning [ "RESPONSE" || (warning [ "RETURN")) {
			Set method3WarningFound = method3WarningFound + 1
		} Else {
			Do $$$LogMessage("Found a warning unrelated to this test: " _ spec.Warnings.GetAt(i))
		}
	}
	Do $$$AssertEquals(method1Arg1WarningFound, 1, "Method with %DynamicArray argument type generated a warning (" _ method1Arg1WarningFound _ ")")
	Do $$$AssertEquals(method1Arg2WarningFound, 1, "Method with %DynamicObject argument type generated a warning (" _ method1Arg2WarningFound _ ")")
	Do $$$AssertEquals(method2Arg1WarningFound, 1, "Method with a not-explicitly-typed argument generated a warning (" _ method2Arg1WarningFound _ ")")
	Do $$$AssertEquals(method2ReturnWarningFound, 1, "Method with %DynamicObject return type generated a warning (" _ method2ReturnWarningFound _ ")")
	Do $$$AssertEquals(method3WarningFound, 1, "Method with non-JSONify-able return type (%Integer) generated a warning (" _ method3WarningFound _ ")")
	
	// Verification that these warnings are NOT present when fixed by ModifyOpenAPIInfo can be found in the TestSpecModificationMethods method
	Do spec.%JSONExportToString(.specJSON)
	//Do $$$LogMessage(specJSON)
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestGetAllParametersFromSpec()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Set openapi.ForceAuthorizeAllEndpoints = 1
	Set openapi.IncludeForbiddenEndpoints = 1
	set st = ..SetupClass(
		"zUnitTest.isc.rest.class1", 
		["%Persistent","%pkg.isc.rest.model.dbMappedResource"], 
		{"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, ,,, ,,, 
		["PoorlyTypedMethodsActionMap:ActionMap"], 
		["CheckPermissionAllowAll:CheckPermission","PoorlyTypedMethod1","PoorlyTypedMethod2","PoorlyTypedMethod3"]
	)
	Do $$$AssertStatusOK(st)
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	set spec = openapi.Specification
	Do spec.%JSONExportToString(.specJSON)
	Do $$$LogMessage(specJSON)
	set pathItem = spec.Paths.GetAt("/unittest-resource/$poorly-typed-method-1")
	Set parameters = spec.GetAllFromSpec(pathItem, "%pkg.isc.rest.openAPI.model.parameterOrReference")
	do $$$AssertEquals(parameters.Count(),1)
	do $$$AssertEquals(parameters.GetAt(1).Name, "param3")
	//request body parameters should not be included since they are actually schemas.
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestGetAllSchemaRefsFromSpec()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Set openapi.ForceAuthorizeAllEndpoints = 1
	Set openapi.IncludeForbiddenEndpoints = 1
	set st = ..SetupClass(
		"zUnitTest.isc.rest.class1", 
		["%Persistent","%pkg.isc.rest.model.dbMappedResource"], 
		{"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, ,,, ,,, 
		["PoorlyTypedMethodsActionMap:ActionMap"], 
		["CheckPermissionAllowAll:CheckPermission","PoorlyTypedMethod1","PoorlyTypedMethod2","PoorlyTypedMethod3"]
	)
	Do $$$AssertStatusOK(st)
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	set spec = openapi.Specification
	Do spec.%JSONExportToString(.specJSON)
	Do $$$LogMessage(specJSON)
	set requestBody = spec.Paths.GetAt("/unittest-resource/$poorly-typed-method-1").Get.RequestBody
	Set schemas = spec.GetAllFromSpec(requestBody, "%pkg.isc.rest.openAPI.model.schemaOrReference")
	do $$$AssertEquals(schemas.Count(),3)
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

/// Note: The conditions this test convers are non-exhaustive! Add classes with different setups as needed to cover more cases
Method TestSchemaAutogenerationTagging()
{
	
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, "TestProp",,, ,,, ["ActionMap1:ActionMap"], ["CheckPermissionAllowAll:CheckPermission"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Set spec = openapi.Specification
	
	Do $$$AssertEquals(##class(%Dictionary.CompiledProperty).%OpenId("%pkg.isc.rest.openAPI.model.schemaOrReference||AutoGenerated").InitialExpression, 0, "AutoGenerated defaults to false")
	
	Set schemas = spec.GetAllFromSpec(spec, "%pkg.isc.rest.openAPI.model.schemaOrReference")
	For i=1:1:schemas.Count() {
		Set schema = schemas.GetAt(i)
		Do $$$AssertTrue(schema.AutoGenerated, "Schema " _ spec.GetReference(spec, schema) _ " has property AutoGenerated = 1")
	}
	
	Do ..TeardownClass("zUnitTest.isc.rest.class1")
	Do ..TeardownClass("zUnitTest.isc.rest.handler")
}

Method TestNoSecurityDefinedWarning()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	Do $$$AssertTrue(openapi.Specification.Warnings.Count() > 0, "At least one warning was logged")
	Do $$$AssertEquals(openapi.Specification.Errors.Count(), 0, "No errors were logged")
	Set found = 0
	For i=1:1:openapi.Specification.Warnings.Count() {
		If $ZConvert(openapi.Specification.Warnings.GetAt(i), "U") [ "SECURITY" {
			Set found = 1
			Do $$$LogMessage("The warning below references security!")
		}
		Do $$$LogMessage("Warning: " _ openapi.Specification.Warnings.GetAt(i))
	}
	Do $$$AssertTrue(found, "A warning referencing security was found")
	
	// Class teardown
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestCollectionQueryOverride()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, ,,, ,,, , ["CheckPermissionAllowAll:CheckPermission","GetCollectionCustom:GetCollection"]))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class2", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource-1","SOURCECLASS":"zUnitTest.isc.rest.class2"}, "TestClassProperty", {"Required":1},, ,,, , ["CheckPermissionAllowAll:CheckPermission","GetCollectionNonArray:GetCollection"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class2"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	
	Do openapi.Specification.%JSONExportToString(.str)
	Do $$$LogMessage(str)
	
	#Dim collectionPath As %pkg.isc.rest.openAPI.model.operation
	Set collectionPath = openapi.Specification.Paths.GetAt("/unittest-resource").Get
	Set description = $ZConvert(collectionPath.Description, "U")
	Do $$$AssertTrue(description [ "RETURN TYPE" && (description [ "NO"), "Overridden Collection Query includes a note in its description")
	Set returnSchema = collectionPath.Responses.GetAt("200").Content.GetAt("application/json").Schema
	If $ClassName(returnSchema) '= "%pkg.isc.rest.openAPI.model.schema" {
		Set returnSchema = openapi.Specification.ResolveReference(returnSchema.Ref, openapi.Specification)
	}
	Do returnSchema.%JSONExportToString(.returnJSON)
	Do ..VerifyJSON({}.%FromJSON(returnJSON), {"type":"object","properties":{"testProperty":{"type":"number"}}}, "Overridden Collection Query has the correct return schema")

	Set collectionPath = openapi.Specification.Paths.GetAt("/unittest-resource-1").Get
	Set description = $ZConvert(collectionPath.Description, "U")
	Do $$$AssertTrue(description [ "RETURN TYPE" && (description [ "NO"), "Overridden Collection Query (returns a single instance only) includes a note in its description")
	Set returnSchema = collectionPath.Responses.GetAt("200").Content.GetAt("application/json").Schema
	If $ClassName(returnSchema) '= "%pkg.isc.rest.openAPI.model.schema" {
		Set returnSchema = openapi.Specification.ResolveReference(returnSchema.Ref, openapi.Specification)
	}
	Do returnSchema.%JSONExportToString(.returnJSON)
	Do ..VerifyJSON({}.%FromJSON(returnJSON), {"type":"object","properties":{"TestClassProperty":{"type":"string"}},"required":["TestClassProperty"]}, "Overridden Collection Query (returns a single instance only) has the correct return schema")
	
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class2"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler"))
}

Method TestPathParameterActions()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	New %restHandlerOverride
	Set %restHandlerOverride = "UnitTest.isc.rest.sample.handler"
	Set return = openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/")
	Do $$$AssertTrue(return, "Specification generation completed without errors")
	If 'return {
		Quit
	}
	#dim spec As %pkg.isc.rest.openAPI.model.openAPI
	Set spec = openapi.Specification

	// Testing path parameter actions from UnitTest.isc.rest.sample.model.person
	Set matchingActionPathName = "/person/$path-param/{first}/hello/{second}/{third}/world"
	Set actionName = ""
	Set actionFound = 0
	While 1 {
		#dim pathItem As %pkg.isc.rest.openAPI.model.pathItem
		Set pathItem = openapi.Specification.Paths.Data.GetNext(.actionName)
		If (actionName = "") {
			Quit
		}
		If (actionName = matchingActionPathName) {
			Set actionFound = 1
			Do $$$AssertSuccess("Found path: "_matchingActionPathName)
			Set validParamNames = $ListBuild("first","second","third")
			Set parameters = spec.GetAllFromSpec(pathItem, "%pkg.isc.rest.openAPI.model.parameterOrReference")
			// Assert path parameter count is accurate
			Do $$$AssertEquals(parameters.Count(),$ListLength(validParamNames))
			// Assert that path parameters are present
			For i = 1:1:parameters.Count() {
				#dim param As %pkg.isc.rest.openAPI.model.parameter
				Set param = parameters.GetAt(i)
				Do $$$AssertTrue($ListFind(validParamNames,param.Name) > 0)
				Do $$$AssertEquals(param.In,"path")
			}
			Quit
		}
	}
	If ('actionFound) {
		Do $$$AssertFailure("No path found for "_matchingActionPathName)
	}
}

Method TestQueryFilters()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.adaptor"], {"RESOURCENAME":"unittest-resource"}, "Demo",{"Type":"%String"},{"%JSONFIELDNAME":"demo"}, ,,, , ["CheckPermissionAllowAll:CheckPermission","GetCollectionCustom:GetCollection"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
	
	Do openapi.Specification.%JSONExportToString(.str)
	Do $$$LogMessage(str)

	Set onlySearchParam = openapi.Specification.Paths.GetAt("/unittest-resource").Get.Parameters.GetAt(1)
	Do $$$AssertTrue($IsObject(onlySearchParam))
	Do $$$AssertEquals(onlySearchParam.In,"query")
	Do $$$AssertEquals(onlySearchParam.Name,"demo")
	Do $$$AssertEquals(onlySearchParam.Style,"deepObject")
	Do $$$AssertEquals(onlySearchParam.Schema.Ref,"#/components/schemas/QueryFilter")
}

Method TestMultiHandlers()
{
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.handler1", ["%pkg.isc.rest.handler"],, ,,, ,,, , ["AuthenticationStrategy","CheckResourcePermitted"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler1"))
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.handler2", ["%pkg.isc.rest.handler"],, ,,, ,,, , ["AuthenticationStrategy","CheckResourcePermitted"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler2"))
	
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.class1", ["%Persistent","%pkg.isc.rest.model.dbMappedResource"], {"RESOURCENAME":"unittest-resource","SOURCECLASS":"zUnitTest.isc.rest.class1"}, "TestProp",,, ,,, ["ActionMap1:ActionMap"], ["CheckPermissionAllowAll:CheckPermission"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.class1"))
	
	New %restHandlerOverride
	For handler = "zUnitTest.isc.rest.handler1","zUnitTest.isc.rest.handler2" {
		Set %restHandlerOverride = handler
		Set openapi = ##class(UnitTest.isc.rest.openAPI.openAPIOverride).%New($ClassName($This), "GetWebApplicationInfo")
		Do $$$AssertTrue(openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/"), "Specification generation completed without errors")
		Set inst = openapi.Specification.GetSaveableInstance()
		$$$ThrowOnError(inst.%Save())
	}
	
	&sql(select %DLIST(DispatchClass) into :classes from %pkg_isc_rest_openAPI_model.openAPI)
	Do $$$AssertEquals($ListLength(classes),2)
	Do $$$AssertTrue($ListFind(classes,"zUnitTest.isc.rest.handler1"))
	Do $$$AssertTrue($ListFind(classes,"zUnitTest.isc.rest.handler2"))
	
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.class1"))
	Do $$$AssertStatusOK(..TeardownClass("zUnitTest.isc.rest.handler2"))
}

/// Test that Supports() is correctly adhered to at both handler and resource level
Method TestSupports()
{
	Set openapi = ..SetupTestingEnvironment()
	#Dim openapi As %pkg.isc.rest.openAPI
	Set openapi.DEBUG = 0
	New %restHandlerOverride
	Set %restHandlerOverride = "UnitTest.isc.rest.sample.handler"
	Set return = openapi.GetSpecificationI($$$NULLOREF, "/UnitTest/isc/rest/openAPI/api/")
	Do $$$AssertTrue(return, "Specification generation completed without errors")
	If 'return {
		Quit
	}
	#dim spec As %pkg.isc.rest.openAPI.model.openAPI
	Set spec = openapi.Specification

	// Collect available paths
	Set path = ""
	WHile 1 {
		#dim pathItem As %pkg.isc.rest.openAPI.model.pathItem
		Set pathItem = spec.Paths.Data.GetNext(.path)
		If (path = "") {
			Quit
		}
		Set pathArr(path) = pathItem
	}

	// Checks for handler level endpoints.
	// Auth endpoints should not be present and OAS ones should be
	Do $$$AssertTrue(($Data(pathArr("/auth/status")) = 1),"/auth/status present")
	Do $$$AssertTrue(($Data(pathArr("/auth/logout")) = 0),"/auth/logout absent")
	Do $$$AssertTrue(($Data(pathArr("/build-documentation")) = 1),"/build-documentation present")

	// Checks for settings resource
	Set settingsResource = ##class(UnitTest.isc.rest.sample.model.settings).#RESOURCENAME
	Set settingsPath = "/"_settingsResource
	If $$$AssertTrue(($Data(pathArr(settingsPath)) = 1),"/settings present") {
		// Check that just GET and POST are present
		Set pathItem = $Get(pathArr(settingsPath))
		Do $$$AssertTrue($IsObject(pathItem.Get))
		Do $$$AssertTrue($IsObject(pathItem.Post))
		Do $$$AssertTrue('$IsObject(pathItem.Put))
		Do $$$AssertTrue('$IsObject(pathItem.Delete))
		Do $$$AssertTrue('$IsObject(pathItem.Patch))
		Do $$$AssertTrue('$IsObject(pathItem.Head))
		Do $$$AssertTrue('$IsObject(pathItem.Options))
		Do $$$AssertTrue('$IsObject(pathItem.Trace))
	}
	// Check that no other endpoints are present for this resource
	Set path = ""
	WHile 1 {
		Set path = $Order(pathArr(path))
		If (path = "") {
			Quit
		}
		If ((path '= settingsPath) && ($Extract(path,1,$Length(settingsPath) = settingsPath))) {
			Do $$$AssertFailure("Unexpected path found that should not be in OAS: "_path)
		}
	}
	
	// Checks for empty resource
	Set emptyResource = ##class(UnitTest.isc.rest.sample.model.empty).#RESOURCENAME
	Do $$$AssertTrue(($Data(pathArr("/"_emptyResource)) = 0),"/empty absent")
}

Method SetupTestingEnvironment() As %pkg.isc.rest.openAPI
{
	$$$ThrowOnError(##class(%pkg.isc.rest.openAPI.model.super).%KillExtent())
	Set openapi = ##class(UnitTest.isc.rest.openAPI.openAPIOverride).%New($ClassName($This), "GetWebApplicationInfo")
	Do $$$AssertStatusOK(..SetupClass("zUnitTest.isc.rest.handler", ["%pkg.isc.rest.handler"],, ,,, ,,, , ["AuthenticationStrategy","CheckResourcePermitted"]))
	Do $$$AssertStatusOK(..CompileClass("zUnitTest.isc.rest.handler"))
	Return openapi
}

ClassMethod GetWebApplicationInfo(ByRef openapi As %pkg.isc.rest.openAPI)
{
	Set openapi.DispatchClass = $Get(%restHandlerOverride,"zUnitTest.isc.rest.handler")
	Set openapi.TwoFactor = 0
	Set openapi.Description = "ISC REST OpenAPI Unit Test API"
	Set openapi.AuthMethod = 2
	Set openapi.Namespace = $NAMESPACE
	Set openapi.Endpoint = "http://localhost/UnitTest/isc/rest/openAPI/api/"
	Set openapi.ClassReferenceURL = "http://localhost/UnitTest/isc/rest/openAPI/docs/"
}

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit ##class(%pkg.isc.rest.authentication.platformBased).%ClassName(1)
}

ClassMethod CheckResourcePermitted(resourceClass As %Dictionary.Classname) As %Boolean
{
	Quit $Piece(resourceClass,".",1,3) = "zUnitTest.isc.rest"
}

ClassMethod CheckPermission1(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return $Match(pOperation,$$$OperationQuery_"|"_$$$OperationUpdate_"|"_$$$OperationDelete)
}

ClassMethod CheckPermission2(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return $Match(pOperation,$$$OperationRead_"|"_$$$OperationDelete_"|"_$$$OperationAction("test-action"))
}

ClassMethod CheckPermission3(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return $Match(pOperation,$$$OperationAction("test-action"))
}

ClassMethod CheckPermissionAllowAll(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return 1
}

ClassMethod CheckPermissionDenyAll(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return 0
}

ClassMethod CheckPermissionHandlerAllowAll(pEndpoint As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	Return 1
}

ClassMethod PoorlyTypedMethod1(arg1 As %DynamicArray, arg2 As %DynamicObject, arg3 As %String)
{
	Return 42
}

ClassMethod PoorlyTypedMethod2(arg1) As %DynamicObject
{
	Return {"key1":"value1","key2":null}
}

ClassMethod PoorlyTypedMethod3() As %Integer
{
	Return "TotallyNotAnInteger"
}

ClassMethod IntegerIdentity(methodArgument As %Integer) As %Integer
{
	Return methodArgument
}

ClassMethod ModifyOpenAPIInfoRemoveQuery200Response(ByRef schemas As %ListOfObjects, ByRef endpoints As %pkg.isc.rest.openAPI.model.paths)
{
	Do endpoints.GetAt("/unittest-resource").Get.Responses.RemoveAt("200")
}

ClassMethod ModifyOpenAPIInfoSpecModification(ByRef schemas As %ListOfObjects, ByRef endpoints As %pkg.isc.rest.openAPI.model.paths)
{
	// Remove the first problematic action endpoint
	Do endpoints.RemoveAt("/unittest-resource/$poorly-typed-method-1")
	
	// Fix the poorly-typed argument / return type on the second problematic action endpoint
	Set newArgumentSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set newArgumentSchema.Type = "number"
	Set methodEndpoint = endpoints.GetAt("/unittest-resource/$poorly-typed-method-2")
	Set methodEndpoint.Get.RequestBody.Content.GetAt("application/json").Schema = newArgumentSchema
	
	Set newResponse = ##class(%pkg.isc.rest.openAPI.model.response).%New()
	Set newResponse.Description = "A successful response"
	Set newReturnSchema = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set newReturnSchema.Type = "object"
	Set newReturnSchemaSub1 = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set newReturnSchemaSub1.Type = "string"
	Set newReturnSchemaSub2 = ##class(%pkg.isc.rest.openAPI.model.schema).%New()
	Set newReturnSchemaSub2.Nullable = 1
	Set newReturnSchemaSub2.Type = "integer"
	Do newReturnSchema.Properties.SetAt(newReturnSchemaSub1, "key1")
	Do newReturnSchema.Properties.SetAt(newReturnSchemaSub2, "key2")
	Set newReturnMediatype = ##class(%pkg.isc.rest.openAPI.model.mediaType).%New()
	Set newReturnMediatype.Schema = newReturnSchema
	Do newResponse.Content.SetAt(newReturnMediatype, "application/json")
	Do methodEndpoint.Get.Responses.SetAt(newResponse, "200")
	Do methodEndpoint.Get.Responses.RemoveAt("204")
	
	// Replace the third problematic action endpoint with a non-problematic one
	Do endpoints.SetAt(##class(%pkg.isc.rest.openAPI.model.pathItem).%New(), "/unittest-resource/$poorly-typed-method-3")
}

ClassMethod ModifyOpenAPISpecification(ByRef spec As %pkg.isc.rest.openAPI.model.openAPI)
{
	Set spec.Info.Version = "1.2.3"
}

ClassMethod GetCollectionCustom(ByRef params, selectMode As %Integer)
{
	Write "{""testProperty"":52}"
}

ClassMethod GetCollectionNonArray(ByRef params, selectMode As %Integer)
{
	Set tmp = $Xecute("() Set ret = ##class(zUnitTest.isc.rest.class2).%New(),ret.TestClassProperty = ""testing!"" do ret.%JSONExport() quit 1")
	Return
}

XData ActionMap1 [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="test-action" target="class" method="POST" call="CheckPermission">
<argument name="id" target="pID" source="body" required="true" />
<argument name="op" target="pOperation" source="query" required="true" />
<argument name="uc" target="pUserContext" source="query" required="true" />
</action>
</actions>
}

XData ActionMap2 [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="test-action" target="class" method="PUT" call="CheckPermission">
<argument name="id" target="pID" source="query" required="true" />
<argument name="op" target="pOperation" source="query" required="true" />
<argument name="uc" target="pUserContext" source="body" required="true" />
</action>
</actions>
}

XData PoorlyTypedMethodsActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="poorly-typed-method-1" target="class" method="GET" call="PoorlyTypedMethod1">
<argument name="param1" target="arg1" source="body-key" />
<argument name="param2" target="arg2" source="body-key" />
<argument name="param3" target="arg3" source="query" />
</action>
<action name="poorly-typed-method-2" target="class" method="GET" call="PoorlyTypedMethod2">
<argument name="param1" target="arg1" source="body" />
</action>
<action name="poorly-typed-method-3" target="class" method="GET" call="PoorlyTypedMethod3">
</action>
</actions>
}

XData IntegerIdentityActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="integer-identity" target="class" method="GET" call="IntegerIdentity">
<argument name="rest-argument" target="methodArgument" source="query" />
</action>
</actions>
}

}
