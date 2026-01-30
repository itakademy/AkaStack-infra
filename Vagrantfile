# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  ENV_FILE = File.join(__dir__, "../.env")

  if File.exist?(ENV_FILE)
    File.readlines(ENV_FILE).each do |line|
      next if line.strip.empty? || line.start_with?("#")
      key, value = line.strip.split("=", 2)
      ENV[key] ||= value
    end
  else
    abort "❌ .env not found"
  end

  RANDOM_SUFFIX = rand(1000..9999)
  VM_NAME       = "akastack-#{RANDOM_SUFFIX}"

  # ================================
  # Base box (Parallels)
  # ================================
  config.vm.provider "parallels" do |p|
    p.cpus  = ENV.fetch("VM_CPUS").to_i
    p.memory = ENV.fetch("VM_MEMORY").to_i
    p.name = VM_NAME
  end

  # ================================
  # Base box (VirtualBox) - example
  # ================================
  # Uncomment to use VirtualBox instead of Parallels.
  #
  # config.vm.provider "virtualbox" do |v|
  #   v.cpus   = ENV.fetch("VM_CPUS").to_i
  #   v.memory = ENV.fetch("VM_MEMORY").to_i
  #   v.name   = VM_NAME
  # end

  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202502.21.0"

  # ================================
  # VM identity & network
  # ================================
  config.vm.hostname = VM_NAME

  config.vm.network "private_network", ip: ENV.fetch("VM_IP")

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true

  # SSH Agent forwarding
  config.ssh.forward_agent = true

  domain = ENV.fetch('VM_DOMAIN')

  config.hostmanager.aliases = [
    "www.#{domain}",
    "back.#{domain}",
    "api.#{domain}",
    "redis.#{domain}",
    "mail.#{domain}",
    "mongo.#{domain}",
    "swagger.#{domain}",
    domain
  ]

  # ================================
  # Synced folders
  # ================================
  config.vm.synced_folder "./", "/vagrant", disabled: true
  config.vm.synced_folder "./../", "/var/www/", owner: "vagrant", group: "www-data"

  # ================================
  # Provisioning
  # ================================
  config.vm.provision "shell",
    path: "bootstrap.sh",
    privileged: true,
    env: {
      "VM_IP"        => ENV.fetch("VM_IP"),
      "VM_NAME"      => VM_NAME,
      "VM_DOMAIN"    => ENV.fetch("VM_DOMAIN")
    }

  # ================================
  # Debug (optionnel)
  # ================================

  puts "▶ VM #{VM_NAME}"
  puts "▶ IP=#{ENV.fetch("VM_IP")} | CPU=#{ENV.fetch("VM_CPUS")} | RAM=#{ENV.fetch("VM_MEMORY")}MB"
end
