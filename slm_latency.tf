variable NEW_RELIC_API_KEY { 
    type = string
}

provider "graphql" {
  url = "https://api.newrelic.com/graphql"
  headers = {
    "API-Key" = var.NEW_RELIC_API_KEY
  }
}

data "graphql_query" "basic_query" {
  query_variables = { 
    accountId = var.accountId
  }
  query = file("./getCapabilitySliOrderApi.gql")
}

# Uncoment to see the output from the NRQL query
# output "response" {
#     value = data.graphql_query.basic_query.query_response
# }

resource "newrelic_service_level" "foo" {
    guid = "MjAxMDIzN3xBUE18QVBQTElDQVRJT058NTE3NDg4MzE0"
    name = "FoodMe - Latency Capability SLI - Order API (Terraform)"
    description = "Proportion of requests that are served faster than a threshold."

    events {
        account_id = var.accountId
        valid_events {
            from = "Transaction"
            where = "appName = 'FoodMe' AND (transactionType='Web')"
        }
        good_events {
            from = "Transaction"
            where = "appName = 'FoodMe' AND (transactionType= 'Web') AND duration < ${jsondecode(data.graphql_query.basic_query.query_response).data.actor.account.nrql.results[0]["percentile.duration"]["95"]}"
        }
    }

    objective {
        target = 99.00
        time_window {
            rolling {
                count = 7
                unit = "DAY"
            }
        }
    }
}

# output "nrql_dashboard" {
#   value=newrelic_one_dashboard_json.nrql_dashboard.permalink 
# }