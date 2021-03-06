include Chef::Mixin::ShellOut

action :install do
  extension = new_resource.name
  version = new_resource.version

  ext_dir = get_extension_dir(new_resource.prefix)
  ext_dir << ::File::SEPARATOR if ext_dir[-1].chr != ::File::SEPARATOR
  so_file   = "#{ext_dir}/#{extension}.so"

  extension = "#{extension}-#{version}" unless version.nil?

  execute "pecl install #{extension}" do
    not_if do
      ::File.exist?(so_file)
    end
  end

  new_resource.updated_by_last_action(true)

end

action :copy do
  cbf = cookbook_file "#{get_extension_dir(new_resource.prefix)}/#{new_resource.name}" do
    cookbook 'php'
    source new_resource.ext_file.to_s
    mode 0644
  end

  new_resource.updated_by_last_action(cbf.updated_by_last_action?)
end

action :compile do

  raise "Missing 'source_dir'." if new_resource.source_dir.empty?

  source_dir = new_resource.source_dir
  unless ::File.exist?(source_dir)
    raise "The 'source_dir' does not exist: #{source_dir}"
  end

  extension = new_resource.name

  configure = './configure'

  cflags = new_resource.cflags
  if !cflags.nil? && !cflags.empty?
    configure = "CFLAGS=\"#{cflags}\" #{configure}"
  end

  commands = [
    'phpize',
    configure,
    'make',
    "cp modules/#{extension}.so #{get_extension_dir(new_resource.prefix)}"
  ]

  commands.each do |command|
    Chef::Log.debug("Running #{command} in #{source_dir}")
    cmd = ::Mixlib::ShellOut.new(command, :cwd => source_dir)
    cmd.run_command
    cmd.error!
  end

  new_resource.updated_by_last_action(true)

end

def get_extension_dir(prefix)
  config = ::Php::Config.new('', {})
  config.get_extension_dir(prefix)
end

def get_extension_files(name)
  config = ::Php::Config.new(new_resource.name, {})
  config.get_extension_files
end
