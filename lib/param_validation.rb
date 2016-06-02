
class ParamValidation

  # Given a hash of data and a validation hash, check all the validations, raising an Error on the first invalid key
  def initialize(data, validations)
    validations.each do |key, validators|
      msg = validations[key][:message]
      validators.each do |name, arg|
        val = data[key]
        validator = @@vals[name]
        next unless validator
        is_valid = @@vals[name].call(val, arg, data)
        msg_proc = @@messages[name]
        msg ||= @@messages[name].call({key: key, data: data, val: val, arg: arg}) if msg_proc
        raise Error.new({key: key, val: val, name: name, message: msg}) unless is_valid
      end
    end
  end

  def self.messages; @@messages; end
  def self.set_message(name, &block)
    @@messages[name] = block
  end

  def self.validators; @@vals; end
  def self.add_validator(name, &block)
    @@vals[name] = block
  end

  @@vals = {
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
    in_range: Proc.new{|val, arg, data| arg.cover?(val)}
  }

  @@messages = {
    required: Proc.new {|h| "#{h[:key]} is required"},
    absent: Proc.new {|h| "#{h[:key]} must not be present"},
    not_included_in: Proc.new {|h| "#{h[:key]} must not be included in #{h[:arg].join(", ")}"},
    included_in: Proc.new {|h|"#{h[:key]} must be one of #{h[:arg].join(", ")}"},
    format: Proc.new {|h|"#{h[:key]} doesn't have the right format"},
    is_integer: Proc.new {|h|"#{h[:key]} "},
    is_float: Proc.new {|h|"#{h[:key]} is required"},
    min_length: Proc.new {|h|"#{h[:key]} is required"},
    max_length: Proc.new {|h|"#{h[:key]} is required"},
    length_range: Proc.new {|h|"#{h[:key]} is required"},
    length_equals: Proc.new {|h|"#{h[:key]} is required"},
    equals: Proc.new {|h|"#{h[:key]} is required"},
    min: Proc.new {|h|"#{h[:key]} is required"},
    max: Proc.new {|h|"#{h[:key]} is required"},
    in_range: Proc.new {|h|"#{h[:key]} is required"}
  }


  class Error < RuntimeError
    attr_accessor :key, :message, :val, :name
    def initialize(data)
      @message = data[:message]
      @key = data[:key]
      @val = data[:val]
      @name = data[:name]
    end

    def to_h
      {message: @message, key: @key, val: @val, name: @name}
    end
  end
end

