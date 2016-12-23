
class ParamValidation

  # Given a hash of data and a validation hash, check all the validations, raising an Error on the first invalid key
  def initialize(data, validations)
    validations.each do |key, validators|
      val = key === :root ? data : (data[key] || data[key.to_s] || data[key.to_sym])
      next if validators[:required].nil? && val.nil?
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
    required:  lambda {|val, arg, data| !val.nil?},
    absent: lambda {|val, arg, data| val.nil?},
    not_blank: lambda {|val, arg, data| val.is_a?(String) && val.length > 0},
    not_included_in: lambda {|val, arg, data| !arg.include?(val)},
    included_in: lambda {|val, arg, data| arg.include?(val)},
    format: lambda {|val, arg, data| val =~ arg},
    is_integer: lambda {|val, arg, data| val.is_a?(Integer) || val =~ /\A[+-]?\d+\Z/},
    is_float: lambda {|val, arg, data| val.is_a?(Float) || (!!Float(val) rescue false) },
    min_length: lambda {|val, arg, data| val.count >= arg},
    max_length: lambda {|val, arg, data| val.count <= arg},
    length_range: lambda {|val, arg, data| arg.cover?(val.count)},
    length_equals: lambda {|val, arg, data| val.count == arg},
    equals: lambda {|val, arg, data| val == arg},
    min: lambda {|val, arg, data| val >= arg},
    max: lambda {|val, arg, data| val <= arg},
    is_array: lambda {|val, arg, data| val.is_a?(Array)},
    is_hash: lambda {|val, arg, data| val.is_a?(Hash)},
    is_json: lambda {|val, arg, data| ParamValidation.is_valid_json?(val)},
    in_range: lambda {|val, arg, data| arg.cover?(val)},
    array_of_hashes: lambda {|val, arg, data| data.is_a?(Array) && data.map{|pair| ParamValidation.new(pair.to_h, arg)}.all?}
  }

  @@messages = {
    required: lambda {|h| "#{h[:key]} is required"},
    absent: lambda {|h| "#{h[:key]} must not be present"},
    not_included_in: lambda {|h| "#{h[:key]} must not be included in #{h[:arg].join(", ")}"},
    included_in: lambda {|h|"#{h[:key]} must be one of #{h[:arg].join(", ")}"},
    format: lambda {|h|"#{h[:key]} doesn't have the right format"},
    is_integer: lambda {|h|"#{h[:key]} should be an integer"},
    is_float: lambda {|h|"#{h[:key]} should be a float"},
    min_length: lambda {|h|"#{h[:key]} has a minimum length of #{h[:arg]}"},
    max_length: lambda {|h|"#{h[:key]} has a maximum length of #{h[:arg]}"},
    length_range: lambda {|h|"#{h[:key]} should have a length within #{h[:arg]}"},
    length_equals: lambda {|h|"#{h[:key]} should have a length of #{h[:arg]}"},
    equals: lambda {|h|"#{h[:key]} should equal #{h[:arg]}"},
    min: lambda {|h|"#{h[:key]} must be at least #{h[:min]}"},
    max: lambda {|h|"#{h[:key]} cannot be more than #{h[:max]}"},
    in_range: lambda {|h|"#{h[:key]} should be within #{h[:arg]}"},
    array_of_hashes: lambda {|h| "Please pass in an array of hashes"}
  }


  class Error < RuntimeError
    attr_accessor :key, :message, :val, :name
    def initialize(message, data)
      @data = data
      super(message)
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

