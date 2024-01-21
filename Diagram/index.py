from diagrams import Diagram, Cluster, custom
from diagrams.aws.network import Route53, ElbApplicationLoadBalancer, InternetGateway, VPC, NATGateway
from diagrams.aws.compute import ElasticContainerService, Fargate, EC2ContainerRegistryImage, EC2, EC2AutoScaling
from diagrams.aws.security import ACM, IdentityAndAccessManagementIamRole
from diagrams.aws.storage import S3
from diagrams.aws.database import RDS
from diagrams.aws.general  import Users

# Constantes
REGION = "eu-west-2"
VPC_CIDR = "10.0.0.0/16"
SUBNET_CIDRS = {
    "AZ1": {"PUBLIC": "10.0.0.0/24", "APP": "10.0.2.0/24", "DATA": "10.0.4.0/24"},
    "AZ2": {"PUBLIC": "10.0.1.0/24", "APP": "10.0.3.0/24", "DATA": "10.0.5.0/24"},
}

# Add class for Terraform
class TerraformIcon(custom.Custom):
    def __init__(self, label, icon_path, **kwargs):
        super().__init__(label, icon_path, **kwargs)

with Diagram("Web Service", show=False):
    terraform_icon = TerraformIcon("Terraform", "./terraform.png")
    clientes = Users("clientes")

    with Cluster(f"Region London({REGION})-{VPC_CIDR}"):
        vpc = VPC("VPC")
        ig = InternetGateway("Internet Gateway")
        iam = IdentityAndAccessManagementIamRole("Iam-Role")
        dns = Route53("dns")
        acm = ACM("ACM")
        s3 = S3("backend")

        with Cluster("Availability Zone us-east-1a"):
            with Cluster(f"Public Subnet AZ1 - {SUBNET_CIDRS['AZ1']['PUBLIC']}"):
                ec12 = EC2("Bastion Host")
                ng = NATGateway("Nat Gateway")
                ec12 - ng

            with Cluster(f"Private APP Subnet AZ1 - {SUBNET_CIDRS['AZ1']['APP']}"):
                img1 = EC2ContainerRegistryImage("Image")
                fg1 = Fargate("Fargate")
                ecs1 = ElasticContainerService("ECS")
                img1 - ecs1
                iam - img1

            with Cluster(f"Private Data Subnet AZ1 - {SUBNET_CIDRS['AZ1']['DATA']}"):
                rds1 = RDS("Amazon RDS Standby DB")

        with Cluster("Availability Zone us-east-1b"):
            with Cluster(f"Public Subnet AZ2 - {SUBNET_CIDRS['AZ2']['PUBLIC']}"):
                ec22 = EC2("Bastion Host")
                ng2 = NATGateway("Nat Gateway")
                ec22 - ng2

            with Cluster(f"Private APP Subnet AZ2 - {SUBNET_CIDRS['AZ2']['APP']}"):
                img2 = EC2ContainerRegistryImage("Image")
                fg2 = Fargate("Fargate")
                ecs2 = ElasticContainerService("ECS")
                img2 - ecs2
                iam - img2

            with Cluster(f"Private Data Subnet AZ2 - {SUBNET_CIDRS['AZ2']['DATA']}"):
                rds2 = RDS("Amazon RDS Master DB")

        with Cluster("Public Subnet Aplication Load Balancer"):
            alb = ElbApplicationLoadBalancer("ALB")

        with Cluster("AutoScaling App"):
            ag = EC2AutoScaling("Scaling Group")

    # Conexiones
    terraform_icon >> vpc
    terraform_icon - s3
    vpc >> ig >> alb
    ec12 >> alb
    ec22 >> alb
    ecs1 >> ag
    ecs2 >> ag
    rds1 >> rds2 >> rds1
    acm - alb >> dns
    dns - clientes
    rds2 >> ecs2 >> rds2
