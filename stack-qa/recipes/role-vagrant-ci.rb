include_recipe 'easybib::role-generic'
include_recipe 'virtualbox'
include_recipe 'vagrant'
# include_recipe 'supervisor'

include_recipe 'stack-qa::deploy-vagrant-ci'
