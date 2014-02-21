actions :request

attribute :path, :kind_of => String, :name_attribute => true
attribute :data, :kind_of => Hash, :default => {}
attribute :debug, :kind_of => [TrueClass, FalseClass], :default => false

def initialize(*args)
  super
  @action = :request
end
