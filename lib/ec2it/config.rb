require 'ec2it'

class EC2It::Config
  accessors = [ :account_id, :instance, :vpc, :tags ]
  accessors.each do |acc|
    attr acc
  end

  @@default_config = ENV['EC2IT_CONFIG_PATH'] || 'config/ec2it.toml'
  @@me = nil

  def initialize(path=@@default_config)
    TOML.load_file(path).each_pair do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def self.get_or_new(path=@@default_config)
    @@me ||= new(path)
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

  def params2tags(role: nil, group: nil)
    tags = []
    tags.concat( str2tags(key: 'roles', str: role) ) if role
    tags.concat( str2tags(key: 'groups', str: group) ) if group
    tags
  end

  def params2tagfilters(role: nil, group: nil)
    filters = []
    filters.concat( str2tagfilter(key: 'roles', str: role) ) if role
    filters.concat( str2tagfilter(key: 'groups', str: group) ) if group
    filters
  end

  private

  def str2tags(key: nil, str: nil)
    tags = []
    tagkeys = self.tags[key]
    i = 0
    str.split(/:/).each do |str|
      tags.push({ key: tagkeys[i], value: str })
      i += 1
    end
    tags
  end

  def str2tagfilter(key: nil, str: nil)
    filters = []
    tagkeys = self.tags[key]
    i = 0
    str.split(/:/).each do |str|
      filters.push({ name: "tag:#{tagkeys[i]}", values: [str] })
      i += 1
    end
    filters
  end
end
