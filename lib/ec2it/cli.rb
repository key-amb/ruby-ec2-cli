require 'aws-sdk-core'
require 'thor'
require 'toml'

require 'ec2it'
require 'ec2it/ami'
require 'ec2it/config'
require 'ec2it/instance'

class EC2It::CLI < Thor

  package_name "ec2it"
  default_command :list
  class_option 'config', :aliases => 'c'

  desc 'list', 'List instances'
  option 'role', :aliases => 'r'
  option 'group', :aliases => 'g'
  option 'status', :aliases => 's'
  option 'keys', :type => :array, :aliases => 'k'
  def list
    cfg = config(options['config'])
    instances = EC2It::Instance.fetch(
      cli:    cli(),
      role:   options['role'],
      group:  options['group'],
      status: options['status'],
    )
    keys = options['keys'] ? options['keys'] : default_instance_keys()
    instances.sort { |a,b|
      a.name <=> b.name
    }.each do |i|
      values = []
      keys.each do |k|
        values.push(i.send(k))
      end
      puts values.join("\t")
    end
  end

  desc 'show', 'Show an instance'
  option 'instance-id', :aliases => 'i'
  option 'name', :aliases => 'n'
  option 'keys', :type => :array, :aliases => 'k'
  def show
    cfg = config(options['config'])
    instance = EC2It::Instance.fetch_one(
      cli:  cli(),
      id:   options['instance-id'],
      name: options['name'],
    )
    keys = options['keys'] ? options['keys'] : default_instance_keys()
    values = []
    keys.each do |k|
      values.push(instance.send(k))
    end
    puts values.join("\t")
  end

  desc 'start', 'Start an instance'
  option 'instance-id', :aliases => 'i'
  option 'name', :aliases => 'n'
  option 'dry-run', :type => :boolean, :default => false
  def start
    instance = EC2It::Instance.fetch_one(
      cli:  cli(),
      id:   options['instance-id'],
      name: options['name'],
    )
    cli().start_instances({
      instance_ids: [instance.instance_id],
      dry_run:      options['dry-run'],
    })
    puts "Successfully started instance. #{instance.disp_info}"
  end

  desc 'stop', 'Stop an instance'
  option 'instance-id', :aliases => 'i'
  option 'name', :aliases => 'n'
  option 'dry-run', :type => :boolean, :default => false
  def stop
    cfg = config(options['config'])
    instance = EC2It::Instance.fetch_one(
      cli:  cli(),
      id:   options['instance-id'],
      name: options['name'],
    )
    cli().stop_instances({
      instance_ids: [instance.instance_id],
      dry_run:      options['dry-run'],
    })
    puts "Successfully stopped instance. #{instance.disp_info}"
  end

  desc 'launch', 'Run Instance from an AMI'
  option 'ami-id', :required => true, :aliases => 'i'
  option 'name', :required => true, :aliases => 'n'
  option 'instance-type', :aliases => 't'
  option 'availability-zone', :aliases => 'az'
  option 'security-groups', :type => :array, :aliases => 'sg'
  option 'dry-run', :type => :boolean, :default => false
  def launch
    cfg = config(options['config'])
    instance_type = options['instance-type'] || cfg.instance['default_instance_type']
    az = options['availability-zone'] || cfg.vpc['default_availability_zone']
    sec_groups = [ cfg.instance['default_security_group'] ]
    sec_groups.concat(options['security-groups']) if options['security-groups']

    image = EC2It::AMI.fetch_by_id(options['ami-id'], cli: cli())
    resp = cli().run_instances({
      image_id:           image.image_id,
      instance_type:      instance_type,
      security_group_ids: sec_groups,
      min_count: 1,
      max_count: 1,
      dry_run: options['dry-run'],
    })
    instance_id = resp.instances[0].instance_id
    puts "Launched instance. ID=#{instance_id}"

    tags = [{ key: 'Name', value: options['name'] }]
    tags.concat(
      image.described.tags.select {|t| t.key != 'Name' },
    )
    cli().create_tags({
      resources: [ instance_id ],
      tags: tags,
    })
    puts 'Added tags:'
    t_list = []
    tags.each do |t|
      key   = t['key']   || t[:key]
      value = t['value'] || t[:value]
      t_list.push('{%s => %s}'%[key, value])
    end
    p t_list.join(%q{,})
    puts 'Done.'
  end

  desc 'terminate', 'Terminate an instance'
  option 'instance-id', :aliases => 'i'
  option 'name', :aliases => 'n'
  option 'dry-run', :type => :boolean, :default => false
  def terminate
    cfg = config(options['config'])
    instance = EC2It::Instance.fetch_one(
      cli:  cli(),
      id:   options['instance-id'],
      name: options['name'],
    )
    cli().terminate_instances({
      instance_ids: [instance.instance_id],
      dry_run:      options['dry-run'],
    })
    puts "Successfully terminated instance. #{instance.disp_info}"
  end

  desc 'list-ami', 'List AMIs'
  option 'role', :aliases => 'r'
  option 'group', :aliases => 'g'
  def list_ami
    images = EC2It::AMI.fetch(cli: cli(), role: options['role'], group: options['group'])
    images.sort { |a,b|
      a.disp_name <=> b.disp_name
    }.each do |i|
      puts [i.image_id, i.disp_info, i.described.creation_date].join("\t")
    end
  end

  desc 'create-ami', 'Create AMI from an instance'
  option 'instance-id', :aliases => 'i'
  option 'name', :aliases => 'n'
  option 'dry-run', :type => :boolean, :default => false
  def create_ami
    cfg = config(options['config'])
    instance = EC2It::Instance.fetch_one(
      cli:  cli(),
      id:   options['instance-id'],
      name: options['name'],
    )
    t = Time.now
    image_name  = instance.name + t.strftime('.%Y%m%d_%H%M')
    description = 'Created from %s at %s'%[instance.name, t.to_s]
    created = cli().create_image({
      instance_id: instance.instance_id,
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

    tags = [{ key: 'Name', value: image_name }]
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
      snapshot_id = EC2It::AMI.fetch_by_id(image_id, cli: cli()).snapshot_id
      unless snapshot_id
        raise %q[Can't find Snapshot for AMI!]
      end
    rescue => e
      try += 1
      case try
      when 1..20
        puts "Waiting for snapshot to be available ... #{try}"
        sleep 10
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

  desc 'delete-ami', 'Delete an AMI'
  option 'ami-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false
  def delete_ami
    cfg = config(options['config'])
    image = EC2It::AMI.fetch_by_id(options['ami-id'], cli: cli())
    snapshot_id = image.snapshot_id or raise "Can't find snapshot_id for AMI #{image.image_id}"

    cli().deregister_image({
      image_id: image.image_id,
      dry_run:  options['dry-run'],
    })
    puts "Deregistered AMI. ID=#{image.image_id}, Name=#{image.image_name}"

    cli().delete_snapshot({
      snapshot_id: snapshot_id,
      dry_run:     options['dry-run'],
    })
    puts "Deleted Snapshot. ID=#{snapshot_id}"
  end

  desc 'set-role', 'Add or Overwrite role of Instance or AMI'
  option 'id', :aliases => 'i'
  option 'instance-name', :aliases => 'n'
  option 'role', :required => true, :aliases => 'r'
  option 'dry-run', :type => :boolean, :default => false
  def set_role
    cfg = config(options['config'])
    if id = options['id']
      # do nothing
    elsif name = options['instance-name']
      id = EC2It::Instance.fetch_by_name(
        options['instance-name'], cli: cli()).instance_id
    else
      raise 'Options are invalid! Please specify ID or Instance name'
    end
    unless id
    end
    tags = cfg.params2tags(role: options['role'])
    cli().create_tags({
      resources: [ id ],
      tags:      tags,
      dry_run:   options['dry-run'],
    })
    puts "Set role=#{options['role']} for resource:#{id}."
  end

  desc 'set-group', 'Add or Overwrite group of Instance or AMI'
  option 'id', :aliases => 'i'
  option 'instance-name', :aliases => 'n'
  option 'group', :required => true, :aliases => 'g'
  option 'dry-run', :type => :boolean, :default => false
  def set_group
    cfg = config(options['config'])
    if id = options['id']
      # do nothing
    elsif name = options['instance-name']
      id = EC2It::Instance.fetch_by_name(
        options['instance-name'], cli: cli()).instance_id
    else
      raise 'Options are invalid! Please specify ID or Instance name'
    end
    unless id
    end
    tags = cfg.params2tags(group: options['group'])
    cli().create_tags({
      resources: [ id ],
      tags:      tags,
      dry_run:   options['dry-run'],
    })
    puts "Set group=#{options['group']} for resource:#{id}."
  end

  private

  def cli
    @cli ||= Aws::EC2::Client.new
  end

  def config(path=nil)
    @config ||= proc {
      args = []
      args.push(path) if path
      EC2It::Config.get_or_new(*args)
    }.call
  end

  def default_instance_keys
    %w[instance_id disp_info ipaddress public_ipaddress]
  end
end
