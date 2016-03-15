require 'ec2it'

class EC2It::AMI
  accessors = [
    :image_id, :image_name, :name, :role, :group, :status, :base_name,
    :disp_name, :disp_role, :disp_group, :disp_info, :described
  ]
  accessors.each do |acsr|
    attr acsr
  end

  def initialize(params)
    params.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
    @disp_name  = @name || @image_name
    @disp_role  = @role.length > 0 ? @role : 'nil'
    @disp_group = @group.length > 0 ? @group : 'nil'
    @disp_info  = '%s:%s(%s){%s}'%[@disp_name, @status, @disp_role, @disp_group]
  end

  def self.fetch_by_id(id, cli: nil)
    raise 'No id specified!' unless id
    resp = cli.describe_images({
      image_ids: [id]
    })
    i = resp.images[0]
    new( Util.prepare_image_params(i) )
  end

  def self.fetch(cli: nil, role: nil, group: nil)
    config = EC2It::Config.get_or_new

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
    module_function
    def prepare_image_params(image, config=nil)
      config ||= EC2It::Config.get_or_new
      params = config.tags2params(image.tags).merge({
        image_id:   image.image_id,
        image_name: image.name,
        status:     image.state,
        described:  image,
      })
    end
  end
end
