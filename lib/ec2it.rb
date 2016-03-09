require 'aws-sdk-core'
require 'ostruct'
require 'thor'
require 'toml'

require 'ec2it/ami'
require 'ec2it/config'
require 'ec2it/instance'

class EC2It < Thor
  package_name "ec2it"
  default_command :list

  desc 'list', 'List instances'
  option 'role', :aliases => 'r'
  option 'group', :aliases => 'g'
  def list
    instances = EC2It::Instance.fetch(cli: cli(), role: options['role'], group: options['group'])
    instances.each do |i|
      puts [
        i.instance_id,
        '%s:%s(%s){%s}'%[i.name, i.status, i.role, i.group],
        i.ipaddress, i.public_ipaddress,
      ].join("\t")
    end
  end

  desc 'start', 'Start an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def start
    cli().start_instances({
      instance_ids: [options['instance-id']],
      dry_run:      options['dry-run'],
    })
    puts 'Successfully started instance.'
  end

  desc 'stop', 'Stop an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def stop
    cli().stop_instances({
      instance_ids: [options['instance-id']],
      dry_run:      options['dry-run'],
    })
    puts 'Successfully stopped instance.'
  end

  desc 'launch', 'Run Instance from an AMI'
  option 'ami-id', :required => true, :aliases => 'i'
  option 'name', :required => true, :aliases => 'N'
  option 'instance-type', :aliases => 't'
  option 'availability-zone', :aliases => 'az'
  option 'security-groups', :type => :array, :aliases => 'sg'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def launch
    config = Config.new
    instance_type = options['instance-type'] || config.instance['default_instance_type']
    az = options['availability-zone'] || config.vpc['default_availability_zone']
    sec_groups = [ config.instance['default_security_group'] ]
    sec_groups.concat(options['security-groups']) if options['security-groups']

    resp = cli().run_instances({
      image_id:           options['ami-id'],
      instance_type:      instance_type,
      security_group_ids: sec_groups,
      min_count: 1,
      max_count: 1,
      dry_run: options['dry-run'],
    })
    instance_id = resp.instances[0].instance_id
    puts "Launched instance. ID=#{instance_id}"

    cli().create_tags({
      resources: [ instance_id ],
      tags: [
        { key: 'Name', value: options['name'] },
      ],
    })
    puts "Added tag: { Name => '#{options['name']}' }"
    puts 'Done.'
  end

  desc 'terminate', 'Terminate an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def terminate
    cli().terminate_instances({
      instance_ids: [options['instance-id']],
      dry_run:      options['dry-run'],
    })
    puts 'Successfully terminateped instance.'
  end

  desc 'create-ami', 'Create AMI from an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def create_ami
    instance = EC2It::Instance.fetch_by_id(
      cli: cli(),
      id:  options['instance-id'],
    )
    t = Time.now
    image_name  = instance.name + t.strftime('.%Y%m%d_%H%M')
    description = 'Created from %s at %s'%[instance.name, t.to_s]
    created = cli().create_image({
      instance_id: options['instance-id'],
      name:        image_name,
      description: description,
      no_reboot:   true,
      dry_run:     options['dry-run'],
      block_device_mappings: [
        { device_name: '/dev/sdm', virtual_name: 'ephemeral0' },
        { device_name: '/dev/sdn', virtual_name: 'ephemeral1' },
        { device_name: '/dev/sdo', virtual_name: 'ephemeral2' },
        { device_name: '/dev/sdp', virtual_name: 'ephemeral3' },
      ],
    })
    image_id = created.image_id
    puts "Created AMI. ID=#{image_id}, name=#{image_name}"

    tags = [{ key: 'Name', value: image_name}]
    tags.concat(
      instance.described.tags.select {|t| t.key != 'Name' },
    )
    cli().create_tags({
      resources: [ image_id ],
      tags: tags,
    })
    puts 'Added tags for AMI.'

    snapshot_id = nil
    try = 0
    begin
      cli().describe_images(
        image_ids: [image_id],
      ).images[0].block_device_mappings.each do |bdm|
        next unless bdm.ebs
        snapshot_id = bdm.ebs.snapshot_id
      end
      unless snapshot_id
        raise %q[Can't find Snapshot for AMI!]
      end
    rescue => e
      try += 1
      case try
      when 1..10
        puts "Waiting for snapshot to be available ... #{try}"
        sleep 30
        retry
      else
        raise e.class, e.message
      end
    end

    cli().create_tags({
      resources: [ snapshot_id ],
      tags: tags,
    })
    puts "Added tags for snapshot. ID=#{snapshot_id}"
  end

  desc 'list-ami', 'List AMIs'
  option 'role', :aliases => 'r'
  option 'group', :aliases => 'g'
  def list_ami
    images = EC2It::AMI.fetch(cli: cli(), role: options['role'], group: options['group'])
    images.each do |i|
      puts [
        i.image_id,
        '%s:%s(%s){%s}'%[i.name || i.image_name, i.status, i.role, i.group],
        i.described.creation_date,
      ].join("\t")
    end
  end

  private

  def cli
    @cli ||= Aws::EC2::Client.new
  end
end
