class EC2Cli < Thor
  class Config
    def initialize(path: ENV['EC2CLI_CONFIG_PATH'] || 'config/ec2-cli.toml')
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
