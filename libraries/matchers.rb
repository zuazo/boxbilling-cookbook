if defined?(ChefSpec)

  if ChefSpec.respond_to?(:define_matcher)
    # ChefSpec >= 4.1
    ChefSpec.define_matcher :boxbilling_api
  elsif defined?(ChefSpec::Runner) &&
        ChefSpec::Runner.respond_to?(:define_runner_method)
    # ChefSpec < 4.1
    ChefSpec::Runner.define_runner_method :boxbilling_api
  end

  def request_boxbilling_api(path)
    ChefSpec::Matchers::ResourceMatcher.new(:boxbilling_api, :request, path)
  end

  def create_boxbilling_api(path)
    ChefSpec::Matchers::ResourceMatcher.new(:boxbilling_api, :create, path)
  end

  def update_boxbilling_api(path)
    ChefSpec::Matchers::ResourceMatcher.new(:boxbilling_api, :update, path)
  end

  def delete_boxbilling_api(path)
    ChefSpec::Matchers::ResourceMatcher.new(:boxbilling_api, :delete, path)
  end

end
