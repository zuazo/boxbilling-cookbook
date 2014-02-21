
module BoxBilling
  class Database

    ADMIN_SQL_WHERE = {
      :role => 'admin',
      :status => 'active'
    }

    def initialize(options={})
      @conn_string = options
      @conn_string[:adapter] = 'mysql'
      @conn_string[:logger] = Chef::Log
    end

    def connect(&block)
      Sequel.connect(@conn_string, &block)
    end

    def generate_admin_api_token
      # TODO UPDATE updated_at field ?
      api_token = generatepassword(32)
      connect do |db|
        db[:admin].where(ADMIN_SQL_WHERE).limit(1).update(:api_token => api_token)
      end
    end

    def get_admin_api_token
      connect do |db|
        begin
          db[:admin].select(:api_token).where(ADMIN_SQL_WHERE).first[:api_token]
        rescue Sequel::DatabaseError
          nil
        end
      end
    end

  protected

    def generatepassword(len=8)
      # Based on secure_password method from openssl cookbook
      pw = String.new
      while pw.length < len
        pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
      end
      pw[0, len]
    end

  end
end
