provider "azuredevops" {
  version = ">= 0.0.1"
  org_service_url = var.azdo_url
  personal_access_token = var.azdo_token
}

resource "azuredevops_project" "project" {
  name        = var.teamproject_name
  description = "Team Project created using Az DevOps Terraform Provider!"
}

resource "azuredevops_git_repository" "repo" {
  project_id = azuredevops_project.project.id
  name       = var.repository_name
  initialization {
    init_type = "Import"
    source_type = "Git"
    source_url = var.repository_template
  }
}

resource "azuredevops_user_entitlement" "user" {
  principal_name       = var.pr_approver  
}

resource "azuredevops_branch_policy_min_reviewers" "reviewerspolicy" {
  project_id = azuredevops_project.project.id

  enabled  = true
  blocking = true

  settings {
    reviewer_count     = 1
    submitter_can_vote = false

    scope {
      repository_id  = azuredevops_git_repository.repo.id
      repository_ref = azuredevops_git_repository.repo.default_branch
      match_type     = "Exact"
    }

    scope {
      repository_id  = azuredevops_git_repository.repo.id
      repository_ref = "refs/heads/releases"
      match_type     = "Prefix"
    }
  }
}

resource "azuredevops_branch_policy_auto_reviewers" "reviewersbydirectory" {
  project_id = azuredevops_project.project.id

  enabled  = true
  blocking = true

  settings {
    auto_reviewer_ids  = [azuredevops_user_entitlement.user.id]
    submitter_can_vote = false
    message            = "Auto reviewer"
    path_filters       = ["*/src/*.ts","infrastructure/*"]

    scope {
      repository_id  = azuredevops_git_repository.repo.id
      repository_ref = azuredevops_git_repository.repo.default_branch
      match_type     = "Exact"
    }
  }
}


resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = var.service_endpoint_name
  description = "Managed by Terraform" 
  credentials {
    serviceprincipalid  = var.serviceprincipalid
    serviceprincipalkey = var.serviceprincipalkey
  }
  azurerm_spn_tenantid      = var.azurerm_spn_tenantid
  azurerm_subscription_id   = var.azurerm_subscription_id
  azurerm_subscription_name = var.azurerm_subscription_name
}


resource "azuredevops_build_definition" "build" {
  project_id = azuredevops_project.project.id
  name       = "Terraform Build"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.repo.id
    branch_name = azuredevops_git_repository.repo.default_branch
    yml_path    = "azure-pipelines.yml"
  }

  variable {
    name  = "PipelineVariable"
    value = "Automatic Variables!"
  }

  variable {
    name      = "PipelineSecret"
    secret_value     = "ZGV2cw"
    is_secret = true
  }

  variable {
    name    = "ServiceEndpointName"
    value   = var.service_endpoint_name
  }
}
