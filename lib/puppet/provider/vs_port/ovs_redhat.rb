require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'redhat', 'ifcfg.rb'))

Puppet::Type.type(:vs_port).provide(:ovs_redhat, :parent => :ovs) do
  desc 'Openvswitch port manipulation for RedHat OSes family'

  confine    :osfamily => :redhat
  defaultfor :osfamily => :redhat

  commands :grep   => 'grep'
  commands :ip     => 'ip'
  commands :ifdown => 'ifdown'
  commands :ifup   => 'ifup'
  commands :vsctl  => 'ovs-vsctl'

  def create
    begin
      super unless vsctl('br-exists', @resource[:name])
    rescue Puppet::ExecutionFailure => e
      super
    end
    IFCFG::Port.new(@resource[:interface], @resource[:bridge]).save

    if link?
      if dynamic?
        # Persistent MAC address
        bridge_mac_address = nil
        datapath_id = vsctl('get', 'bridge', @resource[:bridge], 'datapath_id')
        bridge_mac_address = datapath_id[-14..-3].scan(/.{1,2}/).join(':') if datapath_id
        IFCFG::BridgeDynamic.new(@resource[:bridge], @resource[:interface], bridge_mac_address).save
      else
        device = ip('addr', 'show', @resource[:interface])
        cidr = device.to_s.match(/inet (\d*\.\d*\.\d*\.\d*\/\d*)/)[1]
        IFCFG::BridgeStatic.new(@resource[:bridge], cidr).save
      end
    else
      IFCFG::Bridge.new(@resource[:bridge]).save
    end

    ifdown(@resource[:interface])
    ifdown(@resource[:bridge])
    ifup(@resource[:interface])
    ifup(@resource[:bridge])
  end

  def exists?
    super && IFCFG::OVS.exists?(@resource[:interface])
  end

  def destroy
    super && IFCFG::OVS.remove(@resource[:interface])
  end

  def dynamic?
    device = ''
    device = ip('addr', 'show', @resource[:interface])
    return device =~ /dynamic/ ? true : false
  end

  def link?
    grep('up', "/sys/class/net/#{@resource[:interface]}/operstate")
  end
end
