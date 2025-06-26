Vagrant.configure("2") do |config|

  # Define variables with default values
  num_cpu = "1"
  vm_memory = "1536"
  network_prefix = "10.10.20"
  num_workers = "3"
  num_managers = "1"

  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "manager01" do |manager|
    manager.vm.hostname = "Manager1"
    manager.vm.network "private_network", ip: "#{network_prefix}.11"
    manager.vm.provider "virtualbox" do |vb|
      vb.name = "ProjB-Manager01"
      vb.linked_clone = true
      vb.memory = vm_memory
      vb.cpus = num_cpu
    end
    manager.vm.provision "shell", path:"./provision/installDocker.sh"
    manager.vm.provision "shell", path:"./provision/firstManager.sh", args:["#{network_prefix}.11"]
  end

  (2..num_managers.to_i).each do |i|
    config.vm.define "manager0#{i}" do |manager|
      manager.vm.hostname = "Manager#{i}"
      manager.vm.network "private_network", ip: "#{network_prefix}.#{i + 10}"
      manager.vm.provider "virtualbox" do |vb|
        vb.name = "ProjB-Manager0#{i}"
        vb.linked_clone = true
        vb.memory = vm_memory
        vb.cpus = num_cpu
      end
      manager.vm.provision "shell", path:"./provision/installDocker.sh"
      manager.vm.provision "shell", path:"./provision/manager.sh"
    end
  end
  
  # Create workers dynamically
  (1..num_workers.to_i).each do |i|
    config.vm.define "worker0#{i}" do |worker|
      worker.vm.hostname = "Worker0#{i}"
      worker.vm.network "private_network", ip: "#{network_prefix}.#{i + 20}"
      worker.vm.provider "virtualbox" do |vb|
        vb.name = "ProjB-Worker0#{i}"
        vb.linked_clone = true
        vb.memory = vm_memory
        vb.cpus = num_cpu
      end
      worker.vm.provision "shell", path:"./provision/installDocker.sh"
      worker.vm.provision "shell", path:"./provision/worker.sh"
    end
  end

end
