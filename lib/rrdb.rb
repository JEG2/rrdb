#!/usr/bin/env ruby -wKU

class RRDB
  VERSION = "0.0.1"
  
  def self.const_missing(error_name)
    if error_name.to_s =~ /Error\z/
      const_set(error_name, Class.new(RuntimeError))
    else
      super
    end
  end
  
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
  
  def self.field_name(name)
    name.to_s.delete("^a-zA-Z0-9_")[0..18]
  end
  
  def initialize(id)
    @id = id
  end
  
  attr_reader :id
  
  def path
    File.join(self.class.config[:database_directory], "#{id}.rrd")
  end
  
  def fields(include_types = false)
    schema = rrdtool(:info).to_s
    fields = schema.scan(/^ds\[([^\]]+)\]/).flatten.uniq
    if include_types
      Hash[ *fields.map { |f|
        [ f, "#{schema[/^ds\[#{f}\]\.type\s*=\s*"([^"]+)"/, 1]}:"            +
             "#{schema[/^ds\[#{f}\]\.minimal_heartbeat\s*=\s*(\d+)/, 1]}:"   + 
             "#{schema[/^ds\[#{f}\]\.min\s*=\s*(\S+)/, 1].sub('NaN', 'U')}:" +
             "#{schema[/^ds\[#{f}\]\.max\s*=\s*(\S+)/, 1].sub('NaN', 'U')}" ]
      }.flatten ]
    else
      fields
    end
  rescue InfoError
    include_types ? Hash.new : Array.new
  end
  
  def step
    (rrdtool(:info).to_s[/^step\s+=\s+(\d+)/, 1] || 300).to_i
  rescue InfoError
    300
  end
  
  def update(time, data)
    safe_data = Hash[*data.map { |f, v| [self.class.field_name(f), v] }.flatten]
    if safe_data.size != data.size or
       safe_data.keys.any? { |f| not f.size.between?(1, 19) }
      raise FieldNameConflictError,
            "Your field names cannot be unambiguously converted to RRDtool " +
            "field names (1 to 19 [a-zA-Z0-9_] characters)."
    end
    if File.exist? path
      claim_new_fields(safe_data.keys)
    else
      create_database(time, safe_data.keys)
    end
    params = fields.map do |f|
      safe_data[f].send(safe_data[f].to_s =~ /\A\d+\./ ? :to_f : :to_i)
    end
    rrdtool(:update, "'#{time.to_i}:#{params.join(':')}'")
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
    field_names.each { |f| schema << " 'DS:#{f}:#{field_type(f)}'" }
    (self.class.config[:reserve_fields].to_i - field_names.size).times do |i|
      name   =  "_reserved#{i}"
      schema << " 'DS:#{name}:#{field_type(name)}'"
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
        raise FieldsExhaustedError,
              "There are not enough reserved fields to complete this update."
      else
        claims = new_fields.zip(reserved).
                            map { |n, o| " -r '#{o}:#{n}'" +
                                         " -d '#{n}:#{field_type(n)}'" }.
                            join.strip
        rrdtool(:tune, claims)
      end
    end
  end
  
  def field_type(field_name)
    if (setting = self.class.config[:data_sources]).is_a? String
      setting
    else
      setting[field_name.to_sym] || setting[field_name] || "GAUGE:600:U:U"
    end
  end
  
  def rrdtool(command, params = nil)
    self.class.run_command(
      "#{self.class.config[:rrdtool_path]} #{command} '#{path}' #{params}"
    ) or raise self.class.const_get("#{command.to_s.capitalize}Error"),
               self.class.last_error
  end
end
