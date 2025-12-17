# Requirements

This deployment is designed to allow you to host an obsidian notes server using google cloud platform's infrastructure.

It is expected that you have a **google account**, are able to use **gcloud** to interact with your project and **terraform** as the main driving force. Additionally it is a requirement that you have some working knowledge of cloud infrastructure and terraform.

After enabling your google cloud platform account at https://console.cloud.google.com/ you can then follow this guide to install gcloud at https://docs.cloud.google.com/sdk/docs/install-sdk and then use this guide to install terraform https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

Login via cli: https://docs.cloud.google.com/sdk/docs/authorizing

You'll need to enable some services and have an active service account within gcp (google cloud platform). A shortcut to enabling the correct services is to run the terraform code and read the output for the exact services that need to be enabled.
https://docs.cloud.google.com/iam/docs/service-accounts-create

___
# Create a bucket

This command will create the bucket, feel free to rename it by changing the `state-obsidian-1` portion of the command to your desired bucket name. But keep in mind that you must follow up by changing the terraform deployment to match the new bucket name.
```sh
gcloud storage buckets create gs://state-obsidian-1 --location=us-central1
```

Enable versioning (reccomended):
```sh
gcloud storage buckets update gs://state-obsidian-1 --versioning-enabled
```
___
# Make modifications

There are two major parts of this deployment that should be modified:
1. TFVARS
    * You need to create a `terraform.tfvars` file in order for this deployment to run. Personalize it to your liking and add your ip/source range. Here's an example of what a successful one would look like. 
```sh
project = "our-first-project-2142025"
vpc = "obsidian-cloud"
region = "us-central1"
zone = "us-central1-a"
range = "10.200.0.0/24"
subnet = "obsidian-net"
allowed_source_ranges = ["8.8.8.8/32"]
```

2. Server username and password
    * Within the `startup-script.sh` of this deployment you'll find a username and password. It is reccomended to change this.
        * Find this on lines 170-171
___
# Run Terraform

Use these commands within the terraform folder:
```sh
terraform init
```
```sh
terraform apply
```
___
# Start setup

1. Once logged into the server via ssh you can watch the logs:
```sh
tail -f ../../log/startup-script.log
```

2. Reset the password after the logs are complete so that you can rdp into it:
```sh
sudo passwd $(whoami)
```
**Use the user 'ubuntu'**

3. Reboot system gracefully after resetting the password to cement all changes:
```sh
sudo shutdown -r now
```
4. Now you can RDP into the instance! **Use the user 'ubuntu'**
___
# Other commands

If you want a pinggy link use this command:
```sh
ssh -p 443 -R0:localhost:5984 free.pinggy.io
```

To see the message of the day:
```sh
sudo run-parts /etc/update-motd.d/
```

Verify that CouchDB is running and accessible via the web browser within your new instance:
```sh
http://localhost:5984
```
___
# Complete setup

### Initialize CouchDB
Visit this URL within your instance (**Use the user 'ubuntu'**):
```sh
http://localhost:5984/_utils
```
Log in using the credentials you specified in the Docker Compose file (username: `admin`, password: pass).
![[Screenshot-1.png]]

### Creating the Database

In the CouchDB admin interface:

1. Click “Create Database” in the sidebar
![[Screenshot-2.png]]
2. Name your database `obsidian` (or any name you prefer)
3. Leave “Partitioned” unchecked
4. Click “Create”

### Configuring Database Permissions

Now we need to give our new user access to the obsidian database:

1. Navigate to your `obsidian` database
2. Click on “Permissions” in the sidebar
3. Under “Members”, add `admin`, `obsidian_user` or what you set as your username to both “Names” fields (for read and write access)
![[Screenshot-3.png]]
4. Click “Save”

**Your CouchDB instance is now ready for Obsidian LiveSync!**
___
# Prepare Obsidian

1. Install obsidian:
https://help.obsidian.md/install

2. Install the LiveSync plugin through obsidian notes

    This link is here to show the livesync plugin:
    https://github.com/vrtmrz/obsidian-livesync

3. Use your instance's public IP to connect your Obsidian notes to your server

4. **Profit!**
___

You should now be able to connect multiple devices to your instance and they will share the same database for your notes.