# Set up Azure DevOps CLI
az extension add --name azure-devops

az devops configure --defaults organization=https://dev.azure.com/myOrg project=myProject

$repoName = "Learn-YAMLPipelines"
$branch = "03-06e"

# CI pipeline
az pipelines create --repository-type tfsgit --name "CD" --repository $repoName --branch $branch --yml-path .ado/cd.yml --skip-first-run
az pipelines create --repository-type tfsgit --name "Infra" --repository $repoName --branch $branch --yml-path .ado/infra.yml --skip-first-run

az pipelines create --repository-type tfsgit --name "PR" --repository $repoName --branch $branch --yml-path .ado/pr-create.yml --skip-first-run

az pipelines create --repository-type tfsgit --name "Cleanup" --repository $repoName --branch $branch --yml-path .ado/cleanup.yml --skip-first-run

