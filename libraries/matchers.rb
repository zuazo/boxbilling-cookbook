if defined?(ChefSpec)

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
