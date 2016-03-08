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

    def self.fetch(id: nil, cli: nil)
      raise 'No id specified!' unless id
      resp = cli.describe_instances({
        instance_ids: [id]
      })
      i = resp.reservations[0].instances[0]
      name_tags = i.tags.select { |t| t.key == 'Name' }
      new({
        instance_id:      id,
        name:             name_tags[0].value,
        status:           i.state.name,
        ipaddress:        i.private_ip_address,
        public_ipaddress: i.public_ip_address,
        instance_type:    i.instance_type,
      })
    end
  end
end
