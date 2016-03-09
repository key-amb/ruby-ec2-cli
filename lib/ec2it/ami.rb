class EC2It < Thor
  class AMI
    accessors = [
      :image_id, :image_name, :name, :role, :group,
      :status, :base_name, :described,
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
      resp = cli.describe_images({
        image_ids: [id]
      })
      i = resp.images[0]
      new( Util.prepare_image_params(i, EC2It::Config.new) )
    end

    def self.fetch(cli: nil, role: nil, group: nil)
      config = EC2It::Config.new

      args = {
        owners: [ config.account_id ],
      }
      config.params2tagfilters(role: role, group: group).tap do |f|
        args['filters'] = f if f.length > 0
      end

      results = []
      cli.describe_images(args).images.each do |i|
        results.push(
          new( Util.prepare_image_params(i, config) )
        )
      end

      results
    end

    def snapshot_id
      return @snapshot_id if @snapshot_id
      self.described.block_device_mappings.each do |bdm|
        next unless bdm.ebs
        return @snapshot_id = bdm.ebs.snapshot_id
      end
    end

    module Util
      def self.prepare_image_params(image, config)
        params = config.tags2params(image.tags).merge({
          image_id:   image.image_id,
          image_name: image.name,
          status:     image.state,
          described:  image,
        })
      end
    end
  end
end
