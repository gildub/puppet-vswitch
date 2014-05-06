Puppet::Type.newtype(:vs_port) do
  desc 'A Virtual Switch Port'
  ensurable

  newparam(:interface, :namevar => true) do
    desc 'The interface to attach to the bridge'

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid interface #{value}. Requires a String, not a #{value.class}"
      end
    end
  end

  newparam(:bridge) do
    desc "What bridge to use"

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Invalid bridge #{value}. Requires a String, not a #{value.class}'"
      end
    end
  end

  autorequire(:vs_bridge) do
    self[:bridge] if self[:bridge]
  end
end
