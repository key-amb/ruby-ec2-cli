class EC2It < Thor
  class Instance
    accessors = [
      :instance_id, :name, :role, :group, :status, :ipaddress,
      :public_ipaddress, :instance_type, :described,
    ]
    accessors.each do |acsr|
      attr acsr
    end

    def initialize(params)
      params.each do |key, val|
        instance_variable_set("@#{key}", val)
      end
    end

    def self.fetch_by_id(id: nil, cli: nil)
      raise 'No id specified!' unless id
      resp = cli.describe_instances({
        instance_ids: [id]
      })
      i = resp.reservations[0].instances[0]
      new( Util.prepare_instance_params(i, EC2It::Config.new) )
    end

    def self.fetch(cli: nil, role: nil, group: nil)
      config = EC2It::Config.new

      args = {}
      config.params2tagfilters(role: role, group: group).tap do |f|
        args['filters'] = f if f.length > 0
      end

      results = []
      cli.describe_instances(args).reservations.each do |r|
        r.instances.each do |i|
          results.push(
            new( Util.prepare_instance_params(i, config) )
          )
        end
      end

      results
    end

    module Util
      def self.prepare_instance_params(instance, config)
        params = config.tags2params(instance.tags).merge({
          instance_id:      instance.instance_id,
          status:           instance.state.name,
          ipaddress:        instance.private_ip_address,
          public_ipaddress: instance.public_ip_address,
          instance_type:    instance.instance_type,
          described:        instance,
        })
      end
    end
  end
end
