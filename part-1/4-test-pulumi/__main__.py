import pulumi
import pulumi_openstack as openstack

keypair = openstack.compute.Keypair("test-keypair",
    name="pulumi-test-keypair",
    public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBe0Ki8ApDIImieSPxVk4hZjgk0GzkDRuEd9dNeHMpZl"
)

instance = openstack.compute.Instance("test-instance",
    name="pulumi-test-instance",
    image_name="Ubuntu-22.04",
    flavor_name="m1.small",
    key_pair=keypair.name,
    networks=[openstack.compute.InstanceNetworkArgs(
        name="public",
    )],
    security_groups=["default"]
)

pulumi.export("instance_ip", instance.access_ip_v4)