# Part 1

## Local OpenStack Environment Setup

To set up a local OpenStack testing environment, I used **Multipass** to provision a virtual machine running Ubuntu 24.04 LTS.

Once the instance was up and running, I proceeded with the standard **DevStack** installation process.

Following the setup, I was able to access and log into **Horizon**, for the very first time using the instance's IP address (`192.168.252.3`). This confirms that the core OpenStack services are properly configured and ready for further infrastructure provisioning (such as running Terraform for the next step).

```
 ~/Documents/dev                                                                                               base py  20:12:06
> multipass list
Name                    State             IPv4             Image
openstack-devstack      Running           192.168.252.3    Ubuntu 24.04 LTS
                                          172.24.4.1
                                          192.168.122.1
```

## First Steps with Terraform and Google Cloud

After setting up the local infrastructure, I moved on **Terraform**. To get the basics of Infrastructure as Code (IaC) and test my setup, I wrote my first simple configuration file aimed at provisioning a free-tier Compute Engine virtual machine on Google Cloud Platform.

## Provisioning an Instance on OpenStack with Terraform

I then focused to my local OpenStack environment. In OpenStack's module **Nova** (Compute service).

I wrote the Terraform configuration to automate the deployment.

I had to simulate public ip as i am running this instance locally on a personal machine.

`> openstack floating ip create public`

`> openstack port create --network private --security-group allow-ssh-ping tf-instance-port`

```
ubuntu@openstack-devstack:/opt/stack/devstack$ openstack floating ip list
+---------------------+---------------------+------------------+---------------------+---------------------+---------------------+
| ID                  | Floating IP Address | Fixed IP Address | Port                | Floating Network    | Project             |
+---------------------+---------------------+------------------+---------------------+---------------------+---------------------+
| 44aeeacf-0892-4a68- | 172.24.4.91         | 10.0.0.5         | 0e196ef5-b158-4e56- | cbf4b98a-ea23-4f25- | 8f1016d5e4aa48b6834 |
| 9aee-264633364b52   |                     |                  | a959-0b7bb54b862e   | 9e90-7876619c90d8   | d98f5a0c83fa3       |
+---------------------+---------------------+------------------+---------------------+---------------------+---------------------+
ubuntu@openstack-devstack:/opt/stack/devstack$
```

https://excalidraw.com/#room=e50428f3f8ca51a4ab8f,uAqU4IEtGOl5vEFxS2RD0A

# Terraform Good Practices

## 1. Secure Remote State Storage

Never rely on local state files in a team environment.

- Store your state file securely in a cloud storage bucket (e.g., AWS S3, Google Cloud Storage, or OpenStack Swift).
- Make sure to wrap the storage resource in a `lifecycle` block with `prevent_destroy = true`. In order to prevent accidental deletion of the bucket holding your state file.

## 2. Split the Infrastructure into Files and Modules

Avoid dumping all your infrastructure code into a single, massive `main.tf` file.

- **File splitting:** Separate your configurations logically into `main.tf` (core resources), `variables.tf` (input declarations), `outputs.tf` (returned values), and `providers.tf` (provider configuration).
- **Modularity:** Group related resources (like networking components or compute clusters) into reusable modules to keep your codebase DRY (Don't Repeat Yourself) and easier to maintain.

## 3. Use a Secret Manager for Credentials

Never hardcode API keys, passwords, or database credentials directly into your Terraform configuration.

- Store sensitive information in a dedicated secret manager and fetch it dynamically during the Terraform run.
- For OpenStack environments, use **Barbican** to securely store and retrieve secrets. For other clouds, use tools like AWS Secrets Manager, GCP Secret Manager, or HashiCorp Vault.
