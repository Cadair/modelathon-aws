"""
Create and configure AWS instances for all the teams.

This script should do the following:

    * Start x instances, one per team
    * Configure y user accounts per instance, with a preconfigured password.
    * Return the public IP addresses for each team
    * Configure the Sheffield Uni VPN
    * Mount the uni filestore
"""

import boto3

teams = [{"name": "Team 1", "username": "", "password": "",
          "rats": "", "share": r""},
         {"name": "Team 2", "username": "", "password": "",
          "rats": "", "share": r""},
         {"name": "Team 3", "username": "", "password": "",
          "rats": "", "share": r""},
         {"name": "Team 4", "username": "", "password": "",
          "rats": "", "share": r""},
         {"name": "Team 5", "username": "", "password": "",
          "rats": "", "share": r""}]

with open("./ec2_configure.ps1") as afile:
    startup_script = "<powershell>\n"
    startup_script += afile.read()
    startup_script += "\n</powershell>"

# Create connection to EC2
ec2 = boto3.resource('ec2')

# List all running instances so we don't mess with them
instances = ec2.instances.filter(
    Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

print("-"*80, "Running Instances:", sep='\n')
running_ids = []
for instance in instances:
    running_ids.append(instance.id)
    name = ''
    if instance.tags:
        for tag in instance.tags:
            if tag['Key'] == 'Name':
                name = tag['Value']
    print("{:<15}".format(name), instance.id, instance.instance_type, sep=' | ')
print("-"*80)


running_ids = set(running_ids)


# Setup and configure teams
num_teams = 5
instances = []
for team in teams[:num_teams]:
    # Fire up a new instance
    inst = ec2.create_instances(ImageId='ami-a8592cdb',
                                MinCount=1,
                                MaxCount=1,
                                InstanceType='t2.nano',
                                KeyName='<KEYNAME>',
                                SubnetId='<SUBNET_ID>',
                                SecurityGroupIds=['<SECURITY_GROUP>'],
                                UserData=startup_script.format(team=team))
    ec2.create_tags(Resources=[i.id for i in inst], Tags=[{'Key': "Name",
                                                           'Value': team['name']}])
    instances += inst


for inst in instances:
    print("Waiting for instance {}".format(inst.id))
    inst.wait_until_running()
    inst.load()

print("-"*80,
      "Started Instances:", sep='\n')
for instance in instances:
    name = ''
    if instance.tags:
        for tag in instance.tags:
            if tag['Key'] == 'Name':
                name = tag['Value']
    print("{:<15}".format(name), instance.id,
          instance.public_ip_address, instance.instance_type, sep=' | ')

print("-"*80)

