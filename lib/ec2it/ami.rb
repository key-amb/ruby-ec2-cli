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
