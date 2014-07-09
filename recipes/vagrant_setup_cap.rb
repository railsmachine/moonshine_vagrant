namespace :vagrant_setup do
  
  set :server_list do
    find_servers
  end
  
  set :vagrant_servers do
    YAML.load(File.read("config/vagrant_servers.yml"))
  end
  
  task :vagrant_servers_from_stage do
    app = fetch(:application)
    ip = 3
    servers = []
    
    server_list.each do |server|
      vagrant_server = {}
      prefix = server.host.split(".").first
      vagrant_server[:name] = prefix
      vagrant_server[:hostname] = "#{prefix}.#{app}.rm"
      vagrant_server[:internal_hostname] = "#{prefix}.#{app}.local.rm"
      vagrant_server[:ip] = "192.168.50.#{ip}"
      vagrant_server[:internal_ip] = "10.0.10.#{ip}"
      vagrant_server[:roles] = []
      vagrant_server[:options] = server.options
      
      roles.each do |r,v|
        vagrant_server[:roles] << r if v.servers.include?(server)
      end
      
      ip += 1
      servers << vagrant_server
    end
    
    f = File.open("config/vagrant_servers.yml","w+")
    f.puts servers.to_yaml
    f.close
  end

  task :generate_local_dnsmasq do
    f = File.open("local_dnsmasq.generated.txt","w+")
    
    vagrant_servers.each do |server|
      f.puts "# #{server[:name]}"
      f.puts "address=/#{server[:hostname]}/#{server[:ip]}"
      f.puts "address=/#{server[:internal_hostname]}/#{server[:internal_ip]}"
      f.puts ""
    end
    
    f.close
  end
  
  task :generate_bootstrap_dnsmasq do
    f = File.open("config/vagrant/dnsmasq.conf","w+")
    f.puts <<-eos
    listen-address = 127.0.0.1
    all-servers
    eos
    
    vagrant_servers.each do |server|
      f.puts "# #{server[:name]}"
      f.puts "address=/#{server[:hostname]}/#{server[:ip]}"
      f.puts "address=/#{server[:internal_hostname]}/#{server[:internal_ip]}"
      f.puts ""
    end
    
    f.close
  end
  
  task :generate_bootstrap_resolv do
    # creating resolv.conf
    f = File.open("config/vagrant/resolv.conf","w+")
    f.puts "nameserver 127.0.0.1"
    f.puts "nameserver 8.8.8.8"
    f.puts "nameserver 8.8.4.4"
    f.close
  end
  
  task :create_vagrant_config_directory do
    run_locally "mkdir -p config/vagrant"
  end
  
  task :generate_vagrant_capistrano do
    f = File.open("config/deploy/vagrant.generated.rb","w+")
    
    f.puts "before 'deploy:update_code', 'cowboy:configure'"
    f.puts ""
    f.puts "task :exclude_vagrant do"
    f.puts "  set :copy_exclude, (fetch(:copy_exclude, []) + ['.vagrant/*'])"
    f.puts "end"
    f.puts "after 'cowboy:configure', 'exclude_vagrant'"
    f.puts ""

    vagrant_servers.each do |server|
      line = "server '#{server[:hostname]}'"
      server[:roles].each do |r|
        line << ", :#{r}"
      end
      server[:options].each do |k,v|
        line << ", :#{k} => #{v}"
      end
      f.puts line
    end
    
    f.close 
  end
  
  task :generate_vagrant_moonshine do
    moonshine = {
      :domain => "something.rm",
      :domain_aliases => ["www.something.rm"],
      :user => "vagrant",
      :rails_env => 'vagrant',
      :dnsmasq => {
        :records => {}
      }
    }
    
    vagrant_servers.each do |server|
      moonshine[:dnsmasq][:records][server[:hostname]] = server[:ip]
      moonshine[:dnsmasq][:records][server[:internal_hostname]] = server[:internal_ip]
      
      server[:roles].each do |role|
        role_name = "#{role}_servers".to_sym
        if moonshine[role_name].nil?
          moonshine[role_name] = []
        end
        moonshine[role_name] << server[:hostname]
      end
    end
    
    f = File.open("config/moonshine/vagrant.generated.yml","w+")
    f.puts moonshine.to_yaml
    f.close

  end
  
  task :copy_stage_environment_config do
    exec("cp config/environments/#{fetch(:stage)}.rb config/environments/vagrant.generated.rb")
  end
  
  desc "Creates a new Vagrant stage based on existing stage."
  task :create_vagrant_stage do
    vagrant_servers_from_stage
    create_vagrant_config_directory
    generate_vagrantfile
    generate_local_dnsmasq
    generate_bootstrap_dnsmasq
    generate_bootstrap_resolv
    generate_vagrant_capistrano
    generate_vagrant_moonshine
    copy_stage_environment_config
    output_next_steps
  end
  
  task :output_next_steps do
    puts `cat vendor/plugins/moonshine_vagrant/templates/next_steps.txt`
  end

  task :generate_vagrantfile do
    f = File.open("Vagrantfile.generated","w+")
    f.puts "# -*- mode: ruby -*-"
    f.puts "# vi: set ft=ruby :"
    f.puts ""
    f.puts 'Vagrant.configure("2") do |config|'
    f.puts "  config.vm.box = 'lucid64'"
    f.puts "  config.ssh.forward_agent = true"
    f.puts "  config.vm.provision :shell, :path => 'vendor/plugins/moonshine_vagrant/templates/provision.sh'"
    f.puts "  config.vm.provider :virtualbox do |vb|"
    f.puts '    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]'
    f.puts '    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]'
    f.puts '  end'
    f.puts ''
    f.puts '  config.vm.provider "vmware_fusion" do |v|'
    f.puts '    v.vmx["memsize"] = "512"'
    f.puts '    v.vmx["numvcpus"] = "1"'
    f.puts '  end'
    f.puts ''
    forwarded_port = 23022
    vagrant_servers.each do |server|
      f.puts "  config.vm.define '#{server[:name]}' do |guest|"
      f.puts "    guest.vm.hostname = '#{server[:hostname]}'"
      f.puts "    guest.vm.network :private_network, ip: '#{server[:internal_ip]}'"
      f.puts "    guest.vm.network :private_network, ip: '#{server[:ip]}'"
      f.puts "    guest.vm.network :forwarded_port, guest: 22, host: #{forwarded_port}"
      f.puts '  end'
      f.puts ''
      forwarded_port += 1
    end
    f.puts 'end'
    f.close
  end


end
