class EC2It < Thor
  class Config
    def initialize(path: ENV['EC2IT_CONFIG_PATH'] || 'config/ec2it.toml')
      @me ||= TOML.load_file(path)
    end

    def method_missing(method)
      unless @me.has_key?(method.to_s)
        raise "No such method: #{method}!"
      end
      return @me[method.to_s]
    end
  end
end
