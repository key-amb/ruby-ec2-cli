class EC2It < Thor
  class Instance
    accessors = [
      :instance_id, :name, :role, :group, :status, :ipaddress, :public_ipaddress,
      :instance_type, :disp_name, :disp_role, :disp_group, :disp_info, :described,
    ]
    accessors.each do |acsr|
      attr acsr
    end

    def initialize(params)
      params.each do |key, val|
        instance_variable_set("@#{key}", val)
      end
      @disp_name  = @name.length > 0 ? @name : 'nil'
      @disp_role  = @role.length > 0 ? @role : 'nil'
      @disp_group = @group.length > 0 ? @group : 'nil'
      @disp_info  = '%s:%s(%s){%s}'%[@disp_name, @status, @disp_role, @disp_group]
    end

    def self.fetch_one(cli: nil, id: nil, name: nil)
      if id
        return fetch_by_id(cli: cli, id: id)
      elsif name
        return fetch_by_name(cli: cli, name: name)
      else
        raise 'No id nor name specified! Please specify one.'
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

    def self.fetch_by_name(name: nil, cli: nil)
      raise 'No name specified!' unless name
      resp = cli.describe_instances({
        filters: [{ name: 'tag:Name', values: [name] }],
      })
      i = resp.reservations[0].instances[0]
      new( Util.prepare_instance_params(i) )
    end

    def self.fetch(cli: nil, role: nil, group: nil, status: nil)
      config = EC2It::Config.instance

      args = {}
      filters = []
      config.params2tagfilters(role: role, group: group).tap do |f|
        filters.concat(f)
      end
      if status
        filters.push({ name: 'instance-state-name', values: [status] })
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
      module_function
      def prepare_instance_params(instance, config=nil)
        config ||= EC2It::Config.instance
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
