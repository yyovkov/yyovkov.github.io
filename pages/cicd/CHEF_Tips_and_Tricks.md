# Chef Tips and Tricks



## Use cookbook version in chef recipe
```bash
file '/tmp/version' do
    content run_context.cookbook_collection[cookbook_name].version
    mode '0755'
    owner 'root'
    group 'root'
end
```


## Display chef environment in text file:
```bash
file '/etc/chef_env' do
  content "#{node.chef_environment}\n"
  # or: content "#{node.environment}\n"
  mode 0644
  owner 'root'
  group 'root'
end
```


## Chef envrionment based variable values
```bash
case environment
when 'hsm_dr'
  default['test']['value'] = 'hsm_dr'
when 'hsm_test'
  default['test']['value'] = 'hsm_test'
end
```


## Uninstall ChefDK from Mac
```bash
$ sudo rm -rf /opt/chefdk
$ sudo pkgutil --forget com.getchef.pkg.chefdk
$ sudo find /usr/local/bin -lname '/opt/chefdk/*' -delete
# For version under 11.x:
$ sudo find /usr/bin -lname '/opt/chefdk/*' -delete
```

## Gruby concatenate strings inside recipe
```ruby
databag_keyname = node['hs_develop_tools']['jenkins_user'].gsub(/\-/, '_').concat("_key")
```