# set Variables for pipeline

## install Azure DevOps extension if not already done
az extension add --name azure-devops

az devops configure --defaults organization=https://dev.azure.com/myOrg project=myProject

## set pipeline variables

$pipeline = "myYAML-CI"

$pipelineId = (az pipelines show --name $pipeline --query id -o tsv)

az pipelines variable create --pipeline-id $pipelineId --name azSub   --value "Learning" --secret true
az pipelines variable create --pipeline-id $pipelineId --name appName --value "myYAML"
az pipelines variable create --pipeline-id $pipelineId --name rgName --value "lil-myYaml-rg"
