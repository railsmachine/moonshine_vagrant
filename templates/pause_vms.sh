#!/usr/bin/env ruby

vms = `VBoxManage list runningvms`.split(/\n/)

vms.each do |vm|
  # {40c2fbf8-cce7-4d54-946d-eaef92fc9672}
  uuid = vm.match(/\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\}/)
  puts "Pausing VM: #{uuid}"
  print `VBoxManage controlvm #{uuid} pause`
end