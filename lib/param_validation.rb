
class ParamValidation

  # Given a hash of data and a validation hash, check all the validations, raising an Error on the first invalid key
  def initialize(data, validations)
    validations.each do |key, validators|
      val = key === :root ? data : (data[key] || data[key.to_s] || data[key.to_sym])
      validators.each do |name, arg|
        validator = @@validators[name]
        msg = validations[key][:message]
        next unless validator
        is_valid = @@validators[name].call(val, arg, data)
        msg_proc = @@messages[name]
        msg ||= @@messages[name].call({key: key, data: data, val: val, arg: arg}) if msg_proc
        raise Error.new(msg, {key: key, val: val, name: name}) unless is_valid
      end
    end
    return true
  end

  def self.messages; @@messages; end
  def self.set_message(name, &block)
    @@messages[name] = block
  end

  def self.validators; @@validators; end
  def self.add_validator(name, &block)
    @@validators[name] = block
  end
  def self.structure_validators; @@structure_validators; end
  def self.add_structure_validator(name, &block)
    @@structure_validators[name] = block
  end

  # In each Proc
  #  - val is the value we are actually validating from the data passed in
  #  - arg is the argument passed into the validator (eg for {required: true}, it is `true`)
  #  - data is the entire set of data
  @@validators = {
    required:  Proc.new {|val, arg, data| !val.nil?},
    absent: Proc.new {|val, arg, data| val.nil?},
    not_included_in: Proc.new {|val, arg, data| !arg.include?(val)},
    included_in: Proc.new {|val, arg, data| arg.include?(val)},
    format: Proc.new {|val, arg, data| val =~ arg},
    is_integer: Proc.new {|val, arg, data| val.is_a?(Integer) || val =~ /\A[+-]?\d+\Z/},
    is_float: Proc.new {|val, arg, data| val.is_a?(Float) || (!!Float(val) rescue false) },
    min_length: Proc.new{|val, arg, data| val.count >= arg},
    max_length: Proc.new{|val, arg, data| val.count <= arg},
    length_range: Proc.new{|val, arg, data| arg.cover?(val.count)},
    length_equals: Proc.new{|val, arg, data| val.count == arg},
    equals: Proc.new{|val, arg, data| val == arg},
    min: Proc.new{|val, arg, data| val >= arg},
    max: Proc.new{|val, arg, data| val <= arg},
    is_array: Proc.new{|val, arg, data| val.is_a?(Array)},
    is_hash: Proc.new{|val, arg, data| val.is_a?(Hash)},
    is_json: Proc.new{|val, arg, data| ParamValidation.is_valid_json?(val)},
    in_range: Proc.new{|val, arg, data| arg.cover?(val)},
    array_of_hashes: Proc.new{|val, arg, data| data.is_a?(Array) && data.map{|key, val| ParamValidation.new({key: val}, arg)}.all?}
  }

  @@messages = {
    required: Proc.new {|h| "#{h[:key]} is required"},
    absent: Proc.new {|h| "#{h[:key]} must not be present"},
    not_included_in: Proc.new {|h| "#{h[:key]} must not be included in #{h[:arg].join(", ")}"},
    included_in: Proc.new {|h|"#{h[:key]} must be one of #{h[:arg].join(", ")}"},
    format: Proc.new {|h|"#{h[:key]} doesn't have the right format"},
    is_integer: Proc.new {|h|"#{h[:key]} should be an integer"},
    is_float: Proc.new {|h|"#{h[:key]} is required"},
    min_length: Proc.new {|h|"#{h[:key]} is required"},
    max_length: Proc.new {|h|"#{h[:key]} is required"},
    length_range: Proc.new {|h|"#{h[:key]} is required"},
    length_equals: Proc.new {|h|"#{h[:key]} is required"},
    equals: Proc.new {|h|"#{h[:key]} is required"},
    min: Proc.new {|h|"#{h[:key]} is required"},
    max: Proc.new {|h|"#{h[:key]} is required"},
    in_range: Proc.new {|h|"#{h[:key]} is required"},
    array_of_hashes: Proc.new{|h| "Please pass in an array of hashes"}
  }


  class Error < RuntimeError
    attr_accessor :key, :message, :val, :name
    def initialize(message, data)
      @data = data
      super message
    end
    def data; @data; end
  end

  # A convient error class to return if a required record is not found
  class NotFound < RuntimeError
    def initialize(message="Record not found.")
      super(message)
    end
  end

  # small utility for testing json validity
  def self.is_valid_json?(str)
    begin
      JSON.parse(str)
      return true
    rescue JSON::ParseError => e
      return false
    end
  end
end

