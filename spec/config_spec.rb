require 'ec2it/config'

require 'tempfile'
require 'toml'

toml_content = <<"EOS"
account_id = "123456789012"

[instance]
default_instance_type  = "t2.micro"
default_security_group = "sg-xxxxxxxx"

[vpc]
default_availability_zone = "ap-northeast-1c"

[tags]
roles  = [ "Feature", "Role"  ]
groups = [ "Service", "Group" ]
EOS

config_stash = TOML.parse(toml_content)

tmp = Tempfile.open('tmp') do |fp|
  fp.puts toml_content
  fp
end

class EC2It::Config
  def to_hash
    stash = {}
    self.instance_variables.each do |acc|
      key = acc.to_s[1, acc.length]
      stash[key] = instance_variable_get(acc)
    end
    stash
  end
end

describe 'EC2It::Config' do
  config = EC2It::Config.new(tmp.path)

  describe 'Config initialization' do
    it 'Match with TOML' do
      expect(config.to_hash).to match config_stash
    end

    describe 'Top level keys are readable accessors' do
      config_stash.each_pair do |key, value|
        it "key '#{key}'" do
          expect( config.send(key) ).to match value
        end
      end
    end
  end

  require 'ostruct'
  describe 'tags2params' do
    tags_hashes = [
      [ { key: 'Feature', value: 'web' } ],
      [
        { key: 'Feature', value: 'db' },
        { key: 'Role',    value: 'master' },
        { key: 'Service', value: 'myapp' },
      ],
    ]
    tags_list = []
    tags_hashes.each do |ths|
      tags = []
      ths.each do |i|
        tags.push(OpenStruct.new i)
      end
      tags_list.push(tags)
    end

    params = [
      { role: 'web',       group: '' },
      { role: 'db:master', group: 'myapp' },
    ]
    (0..1).each do |i|
      it params[i].to_s do
        expect(config.tags2params(tags_list[i])).to match(params[i])
      end
    end
  end

  describe 'params2tagfilters' do
    args_list = [
      { role: 'web',       group: '' },
      { role: 'db:master', group: 'myapp' },
    ]
    filters_list = [
      [ { name: 'tag:Feature', values: ['web'] } ],
      [
        { name: 'tag:Feature', values: ['db'] },
        { name: 'tag:Role',    values: ['master'] },
        { name: 'tag:Service', values: ['myapp'] },
      ],
    ]

    (0..1).each do |i|
      it args_list[i].to_s do
        expect(config.params2tagfilters(args_list[i])).to match(filters_list[i])
      end
    end
  end
end
