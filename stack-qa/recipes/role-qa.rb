include_recipe 'ies::role-phpapp'

include_recipe 'php::module-posix'
if is_aws
  include_recipe 'stack-qa::deploy-qa'
else
  include_recipe 'stack-qa::deploy-qa-vagrant'
end
