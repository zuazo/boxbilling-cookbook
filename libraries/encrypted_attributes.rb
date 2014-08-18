require 'json'

module BoxBilling
  class EncryptedAttributeWrapper

    def self.encrypt(encrypt)
      @@encrypt = !!encrypt
    end

    def self.encrypt?
      @@encrypt
    end

    def attribute_read(attr_ary)
    end

    def attribute_create
      key = "server_#{user}_password"
      if Chef::Config['solo']
        if node['boxbilling']['mysql'][key].nil?
          password = secure_password
          node.set['boxbilling']['mysql'][key] = secure_password
        end
        node['boxbilling']['mysql'][key]
      else # chef_client

        if node['boxbilling']['encrypt-secrets']
          include_recipe 'encrypted_attributes'
          if Chef::EncryptedAttribute.exists?(node['boxbilling']['mysql'][key])
            Chef::EncryptedAttribute.update(node.set['boxbilling']['mysql'][key])
            password = Chef::EncryptedAttribute.load(node['boxbilling']['mysql'][key])
          else
            password = secure_password
            node.set['boxbilling']['mysql'][key] = Chef::EncryptedAttribute.create(password)
            node.save
            password
          end
        else
          if node['boxbilling']['mysql'].key?(key)
            password = node['boxbilling']['mysql'][key]
          else
            password = secure_password
            node.set['boxbilling']['mysql'][key] = password
            node.save
          end
        end
      end
    end
  end
end
