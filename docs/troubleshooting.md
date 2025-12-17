<!-- omit in toc -->
# isc.rest Technical/Troubleshooting Guide

- [Introduction](#introduction)
- [Metadata Storage](#metadata-storage)
  - [Resource Class Compilation](#resource-class-compilation)
  - [Dispatch Class Compilation](#dispatch-class-compilation)
- [Utility Methods](#utility-methods)
  - [MapPersistentData](#mappersistentdata)
  - [CopyPersistentData](#copypersistentdata)
- [Debugging](#debugging)
  - [Table Checking](#table-checking)
  - [Error Code Handling](#error-code-handling)
    - [401](#401)
    - [403](#403)
    - [404](#404)
    - [405](#405)
    - [406/415](#406415)

## Introduction

This document does a deep dive into the technical implementation and debugging 
approaches when using isc.rest. Since the framework is intended to abstract away
a lot of details, there is a lot of seemingly "black box magic" happening under 
the hood which this document should demystify.

## Metadata Storage

One of the fundamental building blocks of isc.rest is metadata stored about REST 
resources during class compilation. This metadata is used to determine which 
REST resource to dispatch requests to from the Dispatch Class which has a UrlMap
full of regular expressions. Below we discuss in detail how this works.

### Resource Class Compilation 

Whenever a resource class is compiled, there are always entries 
that are modified in the table for the persistent class 
[%pkg.isc.rest.resourceMap](../cls/pkg/isc/rest/resourceMap.cls). This is done via
the projection [%pkg.isc.rest.model.resourceMapProjection](../cls/pkg/isc/rest/model/resourceMapProjection.cls).
If there are any actions defined in the Actions XData block, then similar changes 
are made to [%pkg.isc.rest.actionMap](../cls/pkg/isc/rest/actionMap.cls).

There is a "master" entry with the `DispatchClass` property set to empty and then 
additional entries, one for each dispatch class that the resource class is exposed
in.
The "master" entry is used to tie a foreign key between the "master" record and the 
dispatch class specific records to cascade changes.
The dispatch class specific entries are determined by iterating all available 
dispatch classes in the namespace i.e. subclasses of [%pkg.isc.rest.handler](../cls/pkg/isc/rest/handler.cls)
and calling the `CheckResourcePermitted` function on them for the current class.
If it returns 1, a record is added.

### Dispatch Class Compilation

Whenever a dispatch class is compiled, the projection [%pkg.isc.rest.handlerProjection](../cls/pkg/isc/rest/handlerProjection.cls)
is used to update records of [%pkg.isc.rest.resourceMap](../cls/pkg/isc/rest/resourceMap.cls)
and optionally [%pkg.isc.rest.actionMap](../cls/pkg/isc/rest/actionMap.cls) if
actions are defined in the Actions XData block.
This is done by querying all resource classes in the namespace i.e. subclasses 
of [%pkg.isc.rest.resource](../cls/pkg/isc/rest/model/resource.cls) and calling
the `CheckResourcePermitted` function on them for the resource class.
If it returns 1, a record is added.

## Utility Methods

Utility methods exist in [`%pkg.isc.rest.utils`](../cls/pkg/isc/rest/utils.cls).

### MapPersistentData

Maps all persistent metadata for isc.rest for a given namespace from a different
database. Is useful if classes are compiled in one namespace but a dispatch class
needs to exist in another namespace.

### CopyPersistentData

Copies all persistent metadata for isc.rest from one namespace to another. Is useful
if classes are compiled in one namespace but a dispatch class needs to exist in 
another namespace.
Would recommend using this method instead of `MapPersistentData` if data needs 
to be overlaid from multiple source namespaces.

## Debugging

The debugging steps below are organized in the sequence in which they should be 
performed.

### Table Checking

Be sure to check in the same namespace as the dispatch class! If the data is in 
another namespace, be sure to use one of the [utility methods](#utility-methods)
to ensure the data exists in the appropriate namespace.

Some useful queries to run in the namespace of the dispatch class:
- `SELECT * FROM %pkg_isc_rest.resourceMap WHERE DispatchClass = ?`: This will 
help you confirm that all the resources for your dispatch class are present. Can 
replace `%pkg_isc_rest.resourceMap` with `%pkg_isc_rest.actionMap` as well.
- `SELECT * FROM %pkg_isc_rest.resourceMap WHERE ResourceName = ?`: This will 
help you check what are the various resource classes that share the same resource 
name to understand how logic could be split across classes/all media types available 
for a given resource.

### Error Code Handling

Once you verify that the persistent tables are up-to-date in the same namespace,
you should be able to make requests via an HTTP client such as Postman. If you 
see unexpected errors, below is a guide of what could be going wrong based on the
error code.
If the error code doesn't match any of the below, the error is likely due to 
errors in your application logic instead of isc.rest.

#### 401

Ensure you are indeed including an Auhorization header/providing some form of 
authenticaton in your requests.
Investigate the authentication strategy class or any other custom authentication 
you have in play. A good way to check if authentication is working is by making 
a request to the `/auth/status` endpoint.

#### 403

Ensure you have overridden the `CheckPermission` method for your resource class.
It is common to forget to do this but `isc.rest` keeps security at top of mind 
rather than an afterthought! Can read more about this in the [User Guide](user-guide.md#permissions).

#### 404

Check persistence in `%pkg_isc_rest.resourceMap` first by querying by `ResourceName`
and `DispatchClass`. Similarly, check if your actions are present in `%pkg_isc_rest.actionMap`.
If they are present, you should no longer see this specific error code.
Also, check if there is an implementation of `Supports` either in your dispatch class 
or resource class because if that returns 0 under any conditions, then a 404 is returned.

#### 405

Check your HTTP verb used for the request. If making a basic CRUD request, only 
GET, POST, PUT and DELETE are supported. If making a custom action request, check 
`%pkg_isc_rest.actionMap` persistence to ensure that the `HTTPVerb` column contains 
the HTTP verb used in your request.

For a custom request, the response will indicate the supported HTTP verbs.
Be sure to check that the Accept and Content-Type headers in your request
match the persistence mentioned above. Can look at the section below for further details 
on matching headers appropriately.

#### 406/415

This is the most common type of error seen when first developing using isc.rest
because isc.rest is very particular about media types in request headers and expects
the client to indicate exactly which media types should be used. 
This is crucial because without exact information, we cannot uniquely identify 
which REST resource to dispatch to given the metadata.

For basic CRUD operations:
- For GET requests, the `Accept` request header must match the `MediaType` property
for the resource in `%pkg_isc_rest.resourceMap`.
- For all other requests, the `ContentType` request header must match the `MediaType`
property for the resource in `%pkg_isc_rest.resourceMap`.

For custom action requests:
- The `Accepts` request header must match the `MediaType` property
for the resource in `%pkg_isc_rest.actionMap`.
- The `ContentType` request header must match the `Accepts` property
for the resource in `%pkg_isc_rest.actionMap`.

The error response should also tell you what the available media types are for 
`Accepts` and `ContentType` respectively provided a match was found for the action 
name and just media types are incorrect.
