import * from bat::BDD
import * from bat::Assertions
import * from bat::Mutable
import toBase64 from dw::core::Binaries
import * from dw::util::Values

//import tests::customFunctions

var context = HashMap()

var cliId = secret('mon-client-id-alias') default 'Client ID not found'
var cliSecret = secret('mon-client-secret-alias') default 'Client Secret not found'

//var orgId = config.organizationId
//var envId = config.environmentId

// Replace the a19065cb-4dd4-4916-9401-bb64b169742c and 2e16bf69-7e76-4387-ad51-1fdd939b4d86 with actual values and uncomment below 2 lines before deploying
var orgId = "a19065cb-4dd4-4916-9401-bb64b169742c"
var envId = "2e16bf69-7e76-4387-ad51-1fdd939b4d86"

var api_deploy_endpoint = "https://anypoint.mulesoft.com/amc/adam/api/organizations/" ++ orgId ++ "/environments/" ++ envId ++ "/deployments"
var api_appDeployDetails_endpoint = "https://anypoint.mulesoft.com/armui/api/v2/applications"
var api_auth_endpoint = "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token"

//var api_deploy_endpoint = config.urlAppDeployDetails
//var api_appDeployDetails_endpoint = config.urlAppsDetails
//var api_auth_endpoint = config.urlAuth

var appNamesIgnoreList = "checkperm-helloworld|devlocation"
//var appNamesIgnoreList = config.ignoreList

fun getApplicationStatus(id: String): Object =  (
    GET `$(api_deploy_endpoint)/$(id)` with {
        "headers": {
          "Authorization": "Bearer $(context.get('access_token'))"
        }
    }
)

fun shouldIgnoreIt(appName: String,ignoreList: String): Boolean = 
     ignoreList contains(appName)

fun descTestStatement(appName: String,ignoreList: String): String = 
      if (shouldIgnoreIt(appName, ignoreList)) "Skipping test for '" ++ appName ++ "' as it is in ignoreList" else "Check if '" ++ appName ++ "' is Running" 


---
describe ("Check-API-Health-Suite") in [
  it must 'Create Access Token' in [
    POST `$(api_auth_endpoint)` with {
      "body": {
        "client_id": cliId,
        "client_secret" : cliSecret,
        "grant_type" : "client_credentials"
      }
    } assert [
      $.response.status mustEqual 200,
      $.response.mime mustEqual "application/json"
    ] execute [
        context.set('access_token', $.response.body.access_token),
        log("orgId", orgId),
        log("envId", envId)
    ] 
  ],
  it must "Get Application Names and deployment Ids" in [
    GET `$(api_appDeployDetails_endpoint)` with {
      "headers": {
        "Authorization": "Bearer $(context.get('access_token'))",
        "X-ANYPNT-ORG-ID": orgId,
        "X-ANYPNT-ENV-ID": envId
      }
    } assert [
        $.response.status mustEqual 200
    ]execute [
      context.set('appDetails', $.response.body.data),
      //log("appDetails", context.get('appDetails')),
      $.response.body.data map context.set($.artifact.name, $.id),
      log("INFO", "Execution Completed")
    ]
  ],
  it should "$((descTestStatement("checkperm-helloworld", appNamesIgnoreList)))" 
    assuming (shouldIgnoreIt("checkperm-helloworld", appNamesIgnoreList) == false) in [
    getApplicationStatus(context.get('checkperm-helloworld'))
    assert [
      $.response.status mustEqual 200,
      $.response.body.name mustEqual "checkperm-helloworld",
      $.response.body.application.status mustEqual "RUNNING"
    ]
    execute [
      log("INFO", "Execution Completed")
    ]
  ],
  it should "$((descTestStatement("devlocation", appNamesIgnoreList)))" 
    assuming (shouldIgnoreIt("devlocation", appNamesIgnoreList) == false) in [
    getApplicationStatus(context.get('devlocation'))
    assert [
      $.response.status mustEqual 200,
      $.response.body.name mustEqual "devlocation",
      $.response.body.application.status mustEqual "RUNNING"
    ]
    execute [
      log("INFO", "Execution Completed")
    ]
  ],
  it should "$((descTestStatement("hello-world-3345", appNamesIgnoreList)))" 
    assuming (shouldIgnoreIt("hello-world-3345", appNamesIgnoreList) == false) in [
    getApplicationStatus(context.get('hello-world-3345'))
    assert [
      $.response.status mustEqual 200,
      $.response.body.name mustEqual "hello-world-3345",
      $.response.body.application.status mustEqual "RUNNING"
    ]
    execute [
      log("INFO", "Execution Completed")
    ]
  ]
]