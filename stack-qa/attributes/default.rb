# 'stack-qa' is the cluster we run in
# 'vagrant-ci' is the layer (role) we are dealing with

default['stack-qa']['deploy_role'] = 'vagrant-ci'

default['stack-qa']['vagrant-ci']['apps'] = []
