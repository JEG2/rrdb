#!/usr/bin/env ruby -wKU

class RRDB
  VERSION = "0.0.1"
  
  def self.run_command(command)
    output = `#{command} 2>&1`
    if $?.success?
      @last_error = nil
      output
    else
      @last_error = output
      nil
    end
  rescue
    nil
  end
  
  def self.last_error
    @last_error
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
  
  config :rrdtool_path         => ( run_command("which rrdtool") ||
                                    "rrdtool" ).strip,
         :database_directory   => ".",
         :reserve_fields       => 10,
         :data_sources         => "GAUGE:600:U:U",
         :round_robin_archives => Array.new
  
  def initialize(id)
    @id = id
  end
  
  attr_reader :id
  
  def path
    File.join(self.class.config[:database_directory], "#{id}.rrd")
  end
  
  def fields
    rrdtool(:info).to_s.scan(/^ds\[([^\]]+)\]/).flatten.uniq
  end
  
  def step
    (rrdtool(:info).to_s[/^step\s+=\s+(\d+)/, 1] || 300).to_i
  end
  
  def update(time, data)
    p data
    data = Hash[*data.map { |f, v| [f.to_s, v] }.flatten]
    if File.exist? path
      claim_new_fields(data.keys)
    else
      p "Creating..."
      create_database(time, data.keys)
    end
    rrdtool(:update, "'#{time.to_i}:#{fields.map { |f| data[f].send(data[f].to_s =~ /\A\d+\./ ? :to_f : :to_i) }.join(':')}'")
  end
  
  def fetch(field, range = Hash.new)
    params = "'#{field}' "
    %w[start end resolution].each do |option|
      if param = range[option.to_sym] || range[option]
        params << " --#{option} '#{param.to_i}'"
      end
    end
    data    = rrdtool(:fetch, params)
    fields  = data.to_a.first.split
    results = Hash.new
    data.scan(/^\s*(\d+):((?:\s+\S+){#{fields.size}})/) do |time, values|
      floats = values.split.map { |f| f =~ /\A\d/ ? Float(f) : 0 }
      results[Time.at(time.to_i)] = Hash[*fields.zip(floats).flatten]
    end
    results
  end
  
  private
  
  def create_database(time, field_names)
    schema = String.new
    %w[step start].each do |option|
      if setting = self.class.config[:"database_#{option}"]
        schema << " --#{option} '#{setting.to_i}'"
      elsif option == "start"
        schema << " --start '#{(time - 10).to_i}'"
      end
    end
    field_names.each do |f|
      dst = if (setting = self.class.config[:data_sources]).is_a? String
              setting
            else
              setting[f.to_sym] || setting[f]
            end
      schema << " 'DS:#{f}:#{dst}'"
    end
    (self.class.config[:reserve_fields].to_i - field_names.size).times do |i|
      schema << " 'DS:_reserved#{i}:GAUGE:600:U:U'"
    end
    Array(self.class.config[:round_robin_archives]).each do |a|
      schema << " 'RRA:#{a}'"
    end
    rrdtool(:create, schema.strip)
  end
  
  def claim_new_fields(field_names)
    old_fields = fields
    new_fields = field_names - old_fields
    unless new_fields.empty?
      reserved = old_fields.grep(/\A_reserved\d+\Z/).
                            sort_by { |f| f[/\d+/].to_i }
      if new_fields.size > reserved.size
        
      else
        claims = new_fields.zip(reserved).
                            map { |n, o| " --data-source-rename '#{o}:#{n}'"}.
                            join.strip
        rrdtool(:tune, claims)
      end
    end
  end
  
  def rrdtool(command, params = nil)
    self.class.run_command(
      "#{self.class.config[:rrdtool_path]} #{command} '#{path}' #{params}"
    )
  end
end
