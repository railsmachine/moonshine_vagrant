## Introduction

Sometimes you want to do something really *risky* with your app, but don't want to break staging or production.  Well, we always want to do risky things, so we decided we needed a way to quickly provision, deploy to and destroy a local copy of something that looks a lot like staging or production. So we wrote this little collection of cap tasks to generate all the config files needed to "clone" an existing stage into a new vagrant stage.

This is **brand new** so there are probably bugs (ok, there are SURELY bugs, please help find them).  We also make a lot of assumptions about how you have things set up, so be sure to check the prerequisites before you try this.  Also, we shouldn't destroy anything that exists already, so feel free to play around.

## Prerequisites

* This was all done on OS X. It probably won't work on Windows, but should work fine on Linux.
* An app already set up with Moonshine, with multiple deploy stages (using capistrano-ext's multistage stuff).
* capistrano-cowboy installed and set up so you can do <code>cap STAGE cowboy deploy</code>.
* A staging or production environment/stage with at least one machine in it.
* Some patience.
* [VirualBox](http://virtualbox.org)
* [Vagrant](http://vagrantup.com)
* dnsmasq - If you use homebrew, <code>brew install dnsmasq</code>.  It's also available for almost all flavors of \*nix.
* You also need [moonshine_dnsmasq](http://github.com/railsmachine/moonshine_dnsmasq) and the resolv_conf moonshine recipe.  See below for configuration.
* Update your moonshine plugins! We had to fix a few bugs in Moonshine and add a feature to moonshine_dnsmasq to get this to work. We'll probably end up finding bugs in other plugins the more we use this.

### dnsmasq and resolv.conf

We tried using vagrant-dns, but it only works on your local machine and doesn't allow the guests to talk to each other, which is a bummer.  We already suggest using dnsmasq in production, and it works just as well locally.

We're going to be using dnsmasq both locally and on the guests to create the DNS records for all the guests in the vagrant deployment, so you need to have those recipes in your manifest if they're not already (and they should be because dnsmasq is awesome):

<pre><code>recipe :resolv_conf
recipe :dnsmasq</code></pre>

And in config/moonshine.yml:

<pre><code>:resolv:
  :nameservers:
    - 127.0.0.1
    - 8.8.8.8
    - 8.8.4.4
    - 208.67.222.222
    - 208.67.220.220</code></pre>

### SSH Config

So you can ssh into all the boxes as the vagrant user w/out using a password and deploy easily, you need to add the following to your ~/.ssh/config:

<pre><code>Host *.rm
  User vagrant
  IdentityFile ~/.vagrant.d/insecure_private_key</code></pre>

### Vagrant + VMware

[Vagrant + VMware](http://www.vagrantup.com/vmware) can provide significant
performance increases over VirtualBox. If you have purchased the Vagrant+VWmare
plugin it is possible ot use the VMware provider with moonshine_vagrant.

1. Install the appropriate Vagrant+VMware plugin for your platform.
2. Download the Ubuntu 10.04 basebox for VMware from the Opscode Bento
   baseboxes and name it `lucid64`:

<pre><code>
    $ vagrant box add lucid64 http://opscode-vm-bento.s3.amazonaws.com/vagrant/vmware/opscode_ubuntu-10.04_chef-provisionerless.box
</code></pre>

3. Use the appropriate VMware provider for your platform when starting your Vagrant VMs:

<pre><code>
    $ vagrant up --provider=vmware_fusion # Use vmware_fusion for Mac OS X
</code></pre>

## Installation

### Rails 2

<pre><code>script/plugin install git://github.com/railsmachine/moonshine_vagrant.git</code></pre>

### Rails 3

<pre><code>script/rails plugin install git://github.com/railsmachine/moonshine_vagrant.git</code></pre>

### Rails 4

You'll need to install the plugger gem and put it and shadow_puppet in your Gemfile, do a bundle install and then you can do this:

<pre><code>plugger install git://github.com/railsmachine/moonshine_vagrant.git</code></pre>

## Generating Your Vagrant Stage

Wow, it's been quite a trip to get here, but it's worth it.  Since we're cloning a stage, let's assume staging, we need to run the cap task from that stage.  To generate your vagrant stage, run:

<pre><code>cap staging vagrant_setup:create_vagrant_stage</code></pre>

That should spit out a ton of things to do next (since we don't want to accidentally destroy an existing vagrant stage, you'll need to copy some files around).

If you need those instructions later, they're in vendor/plugins/moonshine_vagrant/templates/next_steps.txt.

## Things You May Need to Change and Add

* You'll probably need to change the names of the _servers arrays in config/moonshine/vagrant.yml.  They're built with the roles from capistrano, so you'll probably need to change "app_servers" to "application_servers", "db_servers" to "database_servers", etc.
* You need to add the vagrant stage to config/deploy.rb.  The list of stages is usually at the top.
* You need to add a vagrant section to config/database.yml pointed at the right IP address and/or local hostname (like, say, db1.APPNAME.local)

Feature request? [Add it to the TODO List](https://github.com/railsmachine/moonshine_vagrant/wiki/TODO-List)!!
