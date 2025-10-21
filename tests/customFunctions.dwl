%dw 2.0
//output application/json

import * from bat::BDD
import * from bat::Assertions
import * from bat::Mutable

// Declare a variable holding a pipe-delimited string of application names
var appNamesToFilter = "hello-world-3345|checkperm-helloworld"

// Split the string into an array of names
var nameList = appNamesToFilter splitBy "|"

//var nameList = config.ignoreList splitBy "|"

fun extractApplications(data): Object  = (
    data filter (nameList contains $.artifact.name)
  // Map the filtered results to the desired structure
  map {
    applicationName: $.artifact.name,
    status: $.application.status
  }
)

fun shouldIgnoreIt(appName: String,ignoreList: String): Boolean = 
     ignoreList contains(appName)

fun descTestStatement(appName: String,ignoreList: String): String = 
      if (shouldIgnoreIt(appName, ignoreList)) "Skipping test for '" ++ appName ++ "' as it is in ignoreList" else "Check if '" ++ appName ++ "' is Running" 

