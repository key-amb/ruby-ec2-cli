class EC2Cli < Thor
  class Instance
    accessors = [:instance_id, :name, :status, :ipaddress, :public_ipaddress, :instance_type]
    accessors.each do |acsr|
      attr acsr
    end

    def initialize(params)
      params.each do |key, val|
        eval "@#{key} = val"
      end
    end

    def self.fetch_by_id(id: nil, cli: nil)
      raise 'No id specified!' unless id
      resp = cli.describe_instances({
        instance_ids: [id]
      })
      i = resp.reservations[0].instances[0]
      new( Util.prepare_instance_params(i) )
    end

    def self.fetch(cli: nil)
      results = []
      cli.describe_instances.reservations.each do |r|
        r.instances.each do |i|
          results.push(
            new( Util.prepare_instance_params(i) )
          )
        end
      end
      results
    end

    module Util
      def self.prepare_instance_params(instance)
        name_tags = instance.tags.select { |t| t.key == 'Name' }
        {
          instance_id:      instance.instance_id,
          name:             name_tags[0].value,
          status:           instance.state.name,
          ipaddress:        instance.private_ip_address,
          public_ipaddress: instance.public_ip_address,
          instance_type:    instance.instance_type,
        }
      end
    end
  end
end
