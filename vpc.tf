///////////////////////
// provider resource
///////////////////////

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

///////////////////////
// vpc resources
///////////////////////

resource "aws_vpc" "primary" {
    instance_tenancy = "dedicated"
    cidr_block = "${var.cidr_base}.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags {
        Name = "vpc-${var.cidr_base}-${var.aws_region}"
    }
}

output "datacenter_id" {
    value = "${aws_vpc.primary.id}"
}

output "datacenter_network" {
    value = "${aws_vpc.primary.cidr_block}"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.primary.id}"
}

output "datacenter_igw_id" {
    value = "${aws_internet_gateway.igw.id}"
}

///////////////////////
// subnet resources
///////////////////////

// DMZ

resource "aws_subnet" "dmzA" {
    vpc_id = "${aws_vpc.primary.id}"
    availability_zone = "${var.aws_region}a"
    cidr_block = "${var.cidr_base}.0/26"
    map_public_ip_on_launch = "true"
    tags {
        Name = "vpc-${var.cidr_base}-subnet-dmzA"
    }
}

output "datacenter_subnet_dmzA_id" {
    value = "${aws_subnet.dmzA.id}"
}

// Batteries not included!
//resource "aws_route_table_association" "dmzA-dmz" {
//    subnet_id = "${aws_subnet.dmzA.id}"
//    route_table_id = "${aws_route_table.dmz.id}"
//}

resource "aws_subnet" "dmzB" {
    vpc_id = "${aws_vpc.primary.id}"
    availability_zone = "${var.aws_region}b"
    cidr_block = "${var.cidr_base}.64/26"
    map_public_ip_on_launch = "true"
    tags {
        Name = "vpc-${var.cidr_base}-subnet-dmzB"
    }
}

output "datacenter_subnet_dmzB_id" {
    value = "${aws_subnet.dmzB.id}"
}

// Batteries not included!
//resource "aws_route_table_association" "dmzB-dmz" {
//    subnet_id = "${aws_subnet.dmzB.id}"
//    route_table_id = "${aws_route_table.dmz.id}"
//}

// NAT

resource "aws_subnet" "natA" {
    vpc_id = "${aws_vpc.primary.id}"
    availability_zone = "${var.aws_region}a"
    cidr_block = "${var.cidr_base}.128/26"
    map_public_ip_on_launch = "false"
    tags {
        Name = "vpc-${var.cidr_base}-subnet-natA"
    }
}

output "datacenter_subnet_natA_id" {
    value = "${aws_subnet.natA.id}"
}

// Batteries not included!
//resource "aws_route_table_association" "natA-nat" {
//    subnet_id = "${aws_subnet.natA.id}"
//    route_table_id = "${aws_route_table.nat.id}"
//}

resource "aws_subnet" "natB" {
    vpc_id = "${aws_vpc.primary.id}"
    availability_zone = "${var.aws_region}b"
    cidr_block = "${var.cidr_base}.192/26"
    map_public_ip_on_launch = "false"
    tags {
        Name = "vpc-${var.cidr_base}-subnet-natB"
    }
}

output "datacenter_subnet_natB_id" {
    value = "${aws_subnet.natB.id}"
}

// Batteries not included!
//resource "aws_route_table_association" "natB-nat" {
//    subnet_id = "${aws_subnet.natB.id}"
//    route_table_id = "${aws_route_table.nat.id}"
//}

// Security Groups
resource "aws_security_group" "jenkins" {
    name = "vpc-${var.cidr_base}-JENKINS"
    description = "Whitelist Allow access to the HTTP Alternate Listener for Jenkins"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        self = "true"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "jenkins_sg" {
    value = "${aws_security_group.jenkins.id}"
}

resource "aws_security_group" "mesos" {
    name = "vpc-${var.cidr_base}-MESOS"
    description = "Whitelist Mesos Master-Worker Comms"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = "true"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "mesos_sg" {
    value = "${aws_security_group.mesos.id}"
}

resource "aws_security_group" "cachec" {
    name = "vpc-${var.cidr_base}-CACHE-Clients"
    description = "Whitelist Redis (tcp 6379)"
    vpc_id = "${aws_vpc.primary.id}"
}

output "cache_client_sg" {
    value = "${aws_security_group.cachec.id}"
}

resource "aws_security_group" "cache" {
    name = "vpc-${var.cidr_base}-CACHE"
    description = "Allow Redis (tcp 6379)"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 6379
        to_port = 6379
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.cachec.id}"]
    }

    ingress {
        from_port = 49000
        to_port = 50000
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.cachec.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "cache_sg" {
    value = "${aws_security_group.cache.id}"
}

resource "aws_security_group" "searchc" {
    name = "vpc-${var.cidr_base}-SEARCH-Clients"
    description = "Whitelist Elasticsearch (tcp 9200)"
    vpc_id = "${aws_vpc.primary.id}"
}

output "search_client_sg" {
    value = "${aws_security_group.searchc.id}"
}

resource "aws_security_group" "search" {
    name = "vpc-${var.cidr_base}-SEARCH"
    description = "Allow Elasticsearch (tcp 9200)"
    vpc_id = "${aws_vpc.primary.id}"

    // Client Access

    ingress {
        from_port = 9200
        to_port = 9200
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.searchc.id}","${aws_security_group.natc.id}"]
    }

    ingress {
        from_port = 9300
        to_port = 9300
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.searchc.id}","${aws_security_group.natc.id}"]
    }

    // Cluster communication
    //      Allow the client SG to simplify the bootstrap

    ingress {
        from_port = 9400
        to_port = 9400
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.searchc.id}"]
    }

    ingress {
        from_port = 9500
        to_port = 9500
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.searchc.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    } 
}

output "search_sg" {
    value = "${aws_security_group.search.id}"
}

resource "aws_security_group" "web" {
    name = "vpc-${var.cidr_base}-WEB"
    description = "Allow HTTP and HTTPS from Any"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    } 
}

output "web_sg" {
    value = "${aws_security_group.web.id}"
}

resource "aws_security_group" "nagios" {
    name = "vpc-${var.cidr_base}-NAGIOS"
    description = "Whitelist Nagios servers"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = ["${aws_security_group.natc.id}", "${aws_security_group.vpn.id}"]
    }
}

output "nagios_sg" {
    value = "${aws_security_group.nagios.id}"
}

resource "aws_security_group" "ssh" {
    name = "vpc-${var.cidr_base}-SSH"
    description = "Allow SSH"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.sshc.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.natc.id}"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = ["${aws_security_group.nagios.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${var.my_ip}/32","192.168.0.0/16" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "ssh_sg" {
    value = "${aws_security_group.ssh.id}"
}

resource "aws_security_group" "sshc" {
    name = "vpc-${var.cidr_base}-SSH-Clients"
    description = "Whitelist SSH Clients"
    vpc_id = "${aws_vpc.primary.id}"
}

output "ssh_client_sg" {
    value = "${aws_security_group.sshc.id}"
}

resource "aws_security_group" "db" {
    name = "vpc-${var.cidr_base}-DB"
    description = "Allow Postgres"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        self = "true"
        security_groups = ["${aws_security_group.dbc.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "db_sg" {
    value = "${aws_security_group.db.id}"
}

resource "aws_security_group" "dbc" {
    name = "vpc-${var.cidr_base}-DB-Clients"
    description = "Whitelist Postgres Clients"
    vpc_id = "${aws_vpc.primary.id}"
}

output "db_client_sg" {
    value = "${aws_security_group.dbc.id}"
}

resource "aws_security_group" "egress" {
    name = "vpc-${var.cidr_base}-EGRESS"
    description = "Allow any to any"
    vpc_id = "${aws_vpc.primary.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "egress_sg" {
    value = "${aws_security_group.egress.id}"
}

///////////////////////
// vpn resources
///////////////////////

// Security Group
resource "aws_security_group" "vpn" {
    name = "vpc-${var.cidr_base}-VPN"
    description = "Allow VPN"
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 943
        to_port = 943
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 1194
        to_port = 1194
        protocol = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

output "vpn_sg" {
    value = "${aws_security_group.vpn.id}"
}

//// instance

resource "aws_instance" "vpn" {
    ami = "${lookup(var.aws_vpn_amis,var.aws_region)}"
    instance_type = "m3.medium"
    key_name = "${var.aws_key_name}"
    subnet_id = "${aws_subnet.dmzA.id}"
    vpc_security_group_ids = ["${aws_security_group.vpn.id}","${aws_security_group.ssh.id}","${aws_security_group.sshc.id}","${aws_security_group.mesos.id}","${aws_security_group.egress.id}"]
    tags {
        Name = "vpc-${var.cidr_base}-vpn"
        DoNotMonitor = "yes"
        PHI = "false"
        Environment = "dev"
    }

    // provisioning
    // requires connection block
    connection {
        user = "ubuntu"
        type = "ssh"
        agent = "true"
    }
    provisioner "remote-exec" {
        inline = [
            "curl -o /tmp/openvpn-as.deb https://swupdate.openvpn.org/as/openvpn-as-2.0.17-Ubuntu14.amd_64.deb",
            "sudo dpkg -i /tmp/openvpn-as.deb",
            "sudo apt-get update",
            "sudo apt-get install -f",
            "sudo apt-get update",
            "sudo apt-get install -y --no-install-recommends python python-dev gcc python-pip libpython2.7-stdlib git curl make automake libssl-dev zlibc libffi-dev",
            "sudo usermod -p ${var.vpn_passwd} -s /bin/false openvpn",
            "sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*",
            "sudo pip install ansible httplib2"
        ]
    }
}

resource "aws_eip" "vpn" {
    instance = "${aws_instance.vpn.id}"
    vpc = true
}

output "vpn_ip" {
    value = "${aws_eip.vpn.public_ip}"
}

///////////////////////
// nat resources
///////////////////////

// Security Group

resource "aws_security_group" "natc" {
    name = "vpc-${var.cidr_base}-NAT-Clients"
    description = "Used to whitelist clients to NAT host"
    vpc_id = "${aws_vpc.primary.id}"
}

output "nat_client_sg" {
    value = "${aws_security_group.natc.id}"
}

resource "aws_security_group" "nat" {
    name = "vpc-${var.cidr_base}-NAT"
    description = "Allow any HTTP, HTTPS and ICMP."
    vpc_id = "${aws_vpc.primary.id}"

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = ["${aws_security_group.natc.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

// Instance

resource "aws_instance" "nat" {
    ami = "${lookup(var.aws_nat_amis,var.aws_region)}"
    instance_type = "m3.medium"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = [ "${aws_security_group.nat.id}", "${aws_security_group.ssh.id}","${aws_security_group.egress.id}" ]
    subnet_id = "${aws_subnet.dmzA.id}"
    source_dest_check = false
    tags {
        Name = "vpc-${var.cidr_base}-nat"
    }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}

output "nat_id" {
    value = "${aws_instance.nat.id}"
}
