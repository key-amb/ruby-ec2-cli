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

    def tags2params(tags)
      params = {}

      names = tags.select { |t| t.key == 'Name' }
      if names and names[0]
        params = { name: names[0].value }
      end

      tag_params = {}
      ['roles', 'groups'].each do |div|
        tag_params[div] = []
        self.tags[div].each do |tag_key|
          tlist = tags.select { |t| t.key == tag_key }
          break if tlist.empty?
          tag_params[div].push(tlist[0].value)
        end
      end

      params.merge({
        role:  tag_params['roles'].join(':'),
        group: tag_params['groups'].join(':'),
      })
    end

    def params2tagfilters(role: nil, group: nil)
      filters = []
      filters.concat( self.str2tagfilter(key: 'roles', str: role) ) if role
      filters.concat( self.str2tagfilter(key: 'groups', str: group) ) if group
      filters
    end

    private

    def str2tagfilter(key: nil, str: nil)
      filters = []
      tagkeys = self.tags[key]
      string.split(/:/).each do |str|
        filters.push({ name: "tag:#{tagkeys.shift}", values: str })
      end
      filters
    end
  end
end
