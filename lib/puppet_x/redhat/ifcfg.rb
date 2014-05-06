module IFCFG
  class OVS
    Base = '/etc/sysconfig/network-scripts/ifcfg-'

    def self.remove(name)
      File.delete(Base + name)
    rescue Errno::ENOENT
    end

    def self.exists?(name)
      File.exist?(Base + name)
    end

    def initialize(name)
      @name        = name
      @device_type = 'ovs'
      @onboot      = 'yes'
    end

    def to_s
      ifcfg =  "DEVICE=#{@name}\n"
      ifcfg << "DEVICETYPE=#{@device_type}\n"
      ifcfg << "TYPE=#{@type}\n"
      ifcfg << "ONBOOT=yes\n"
      ifcfg << "OVSBOOTPROTO=#{@bootproto}\n"
    end

    def save
      File.open(Base + @name, 'w+') { |file|
        file << self.to_s
      }
    end
  end

  class Bridge < OVS
    def initialize(name, bootproto = nil)
      super(name)
      @type      = 'OVSBridge'
      @bootproto = bootproto ? bootproto : 'none'
    end
  end

  class BridgeDynamic < Bridge
    def initialize(name, interface, bridge_mac_address=nil)
      super(name, 'dhcp')
      @interface = interface
      @bridge_mac_address = bridge_mac_address
    end

    def to_s
      ifcfg = super
      ifcfg << "OVSDHCPINTERFACES=#{@interface}\n"
      if @bridge_mac_address
        ifcfg << "OVS_EXTRA=\"set bridge #{@name} other-config:hwaddr=#{@bridge_mac_address}\"\n"
      end
      ifcfg
    end
  end

  class BridgeStatic < Bridge
    def initialize(name, cidr)
      super(name)
      cidr.match('(.*)\/(.*)') { |m|
        @ipaddr = m[1]
        @prefix = m[2]
      }
    end

    def to_s
      ifcfg = super
      if @cidr != ''
        ifcfg << "IPADDR=#{@ipaddr}\n"
        ifcfg << "PREFIX=#{@prefix}\n"
      end
      ifcfg
    end
  end

  class Port < OVS
    def initialize(name, bridge)
      super(name)
      @type      = 'OVSPort'
      @bridge    = bridge
      @bootproto = 'none'
    end

    def to_s
      super + "OVS_BRIDGE=#{@bridge}\n"
    end
  end
end
