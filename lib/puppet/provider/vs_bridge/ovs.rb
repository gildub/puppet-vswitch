Puppet::Type.type(:vs_bridge).provide(:ovs) do

  commands :vsctl => 'ovs-vsctl'
  commands :ip    => 'ip'

  def self.instances
    bridges = vsctl('list-br')
    bridges.split("\n").collect do |line|
      name, external_ids = line.split(' ', 2)
      new( :name         => name,
           :ensure       => :present,
           :external_ids => external_ids,
      )
    end
  end

  def self.prefetch(resources)
    bridges = instances
    resources.keys.each do |name|
      if provider = bridges.find{ |bridge| bridge.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vsctl('add-br', @resource[:name])
    ip('link', 'set', @resource[:name], 'up')
    @property_hash[:ensure] = :present
   # external_ids = @resource[:external_ids] if @resource[:external_ids]
    @property_hash[:external_ids] = @resource[:external_ids] if @resource[:external_ids]
  end

  def destroy
    ip('link', 'set', @resource[:name], 'down')
    vsctl('del-br', @resource[:name])
    @property_hash.clear
  end

  def _split(string, splitter=',')
    return Hash[string.split(splitter).map{|i| i.split('=')}]
  end

  def external_ids
    result = vsctl('br-get-external-id', @resource[:name])
    return result.split("\n").join(',')
  end

  def external_ids=(value)
    old_ids = _split(external_ids)
    new_ids = _split(value)

    new_ids.each_pair do |k,v|
      unless old_ids.has_key?(k)
        vsctl('br-set-external-id', @resource[:name], k, v)
      end
    end
    @property_hash[:external_ids] = value
  end
end
