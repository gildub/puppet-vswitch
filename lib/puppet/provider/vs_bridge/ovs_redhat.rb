require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'redhat', 'ifcfg.rb'))

Puppet::Type.type(:vs_bridge).provide(:ovs_redhat, :parent => :ovs) do
  desc 'Openvswitch bridge manipulation for RedHat OSes family'

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  commands :vsctl => 'ovs-vsctl'

  def create
    begin
      super unless vsctl('br-exists', @resource[:name])
    rescue Puppet::ExecutionFailure => e
      super
    end
    IFCFG::Bridge.new(@resource[:name]).save
  end

  def exists?
    super && IFCFG::OVS.exists?(@resource[:name])
  end

  def destroy
    super && IFCFG::OVS.remove(@resource[:name])
  end
end
