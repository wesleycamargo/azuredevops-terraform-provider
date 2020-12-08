provider "azuredevops" {
  version = ">= 0.0.1"
  org_service_url = var.azdo_url
  personal_access_token = var.azdo_token
}

resource "azuredevops_project" "project" {
  name        = var.teamproject_name
  description = "Team Project created using Az DevOps Terraform Provider!"
}