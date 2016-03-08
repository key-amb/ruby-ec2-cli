class EC2Cli < Thor
  class Instance
    accessors = [:instance_id, :name, :role, :group, :status, :ipaddress, :public_ipaddress, :instance_type]
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
      new( Util.prepare_instance_params(i, EC2Cli::Config.new) )
    end

    def self.fetch(cli: nil, role: nil, group: nil)
      config = EC2Cli::Config.new

      args    = {}
      filters = []
      if role
        rls = role.split(/:/)
        config.tags['roles'].each do |key|
          filters.push({ name: "tag:#{key}", values: [rls.shift] })
          break if rls.empty?
        end
      end
      if group
        grps = group.split(/:/)
        config.tags['groups'].each do |key|
          filters.push({ name: "tag:#{key}", values: [grps.shift] })
          break if grps.empty?
        end
      end
      args['filters'] = filters if filters.length > 0

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
        name_tags = instance.tags.select { |t| t.key == 'Name' }

        tag_params = {}
        ['roles', 'groups'].each do |div|
          tag_params[div] = []
          config.tags[div].each do |tag_key|
            tlist = instance.tags.select { |t| t.key == tag_key }
            break if tlist.empty?
            tag_params[div].push(tlist[0].value)
          end
        end

        params = {
          instance_id:      instance.instance_id,
          name:             name_tags[0].value,
          role:             tag_params['roles'].join(':'),
          group:            tag_params['groups'].join(':'),
          status:           instance.state.name,
          ipaddress:        instance.private_ip_address,
          public_ipaddress: instance.public_ip_address,
          instance_type:    instance.instance_type,
        }
      end
    end
  end
end
