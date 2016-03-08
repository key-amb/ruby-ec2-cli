# ec2-cli

Handy CLI for AWS EC2 operations.  
Mainly focused on instance operations.

```
# List instances
ec2-cli
ec2-cli list

# Start/Stop instance
ec2-cli start -i <INSTANCE_ID> [-n|--dry-run]
ec2-cli stop  -i <INSTANCE_ID> [-n|--dry-run]

# Create AMI
ec2-cli create-ami -i <INSTANCE_ID> [-n|--dry-run]
```

# LICENSE

The MIT License (MIT)

Copyright (c) 2016 YASUTAKE Kiyoshi

