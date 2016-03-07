require 'aws-sdk-core'
require 'thor'

require 'ec2-cli/instance'

class EC2Cli < Thor
  package_name "ec2-cli"
  default_command :list

  desc 'list', 'List instances'
  def list
    cli().describe_instances.reservations[0].instances.each do |i|
      name_tags = i.tags.select { |t| t.key == 'Name' }
      puts [
        name_tags[0].value, i.instance_id, i.state.name,
        i.private_ip_address, i.public_ip_address
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
  end

  desc 'stop', 'Stop an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def stop
    cli().stop_instances({
      instance_ids: [options['instance-id']],
      dry_run:      options['dry-run'],
    })
  end

  desc 'create-ami', 'Create AMI from an instance'
  option 'instance-id', :required => true, :aliases => 'i'
  option 'dry-run', :type => :boolean, :default => false, :aliases => 'n'
  def create_ami
    instance = EC2Cli::Instance.fetch(
      cli: cli(),
      id:  options['instance-id'],
    )
    t = Time.now
    image_name  = instance.name + t.strftime('.%Y%m%d_%H%M')
    description = 'Created from %s at %s'%[instance.name, t.to_s]
    cli().create_image({
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
  end

  private

  def cli
    @cli ||= Aws::EC2::Client.new
  end
end
