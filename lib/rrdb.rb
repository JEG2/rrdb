#!/usr/bin/env ruby -wKU

class RRDB
  VERSION = "0.0.1"
  
  def self.run_command(command)
    output = `#{command} 2>&1`
    $?.success? ? output : nil
  rescue
    nil
  end
  
  def self.config(hash_or_key = nil)
    case hash_or_key
    when nil
      @config ||= Hash.new
    when Hash
      config.merge!(hash_or_key)
    else
      config[hash_or_key]
    end
  end
  
  config :rrdtool_path   => (run_command("which rrdtool") || "rrdtool").strip,
         :reserve_fields => 10
end
