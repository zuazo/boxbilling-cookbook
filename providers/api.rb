
def get_admin_api_token
  db = BoxBilling::Database.new({
    :database => node['boxbilling']['config']['db_name'],
    :user     => node['boxbilling']['config']['db_user'],
    :password => node['boxbilling']['config']['db_password'],
  })
  db.get_admin_api_token || begin
    db.generate_admin_api_token
    db.get_admin_api_token
  end
end

action :request do
  api_token = get_admin_api_token

  BoxBilling::API.request(
    :path => new_resource.path,
    :api_token => api_token,
    :referer => node['boxbilling']['config']['url'],
    :debug => new_resource.debug
  )
end
