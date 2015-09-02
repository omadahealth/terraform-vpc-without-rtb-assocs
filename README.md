## Inputs
Input | Purpose
--- | --- |
`aws_access_key` | AWS Access Credentials
`aws_secret_key` | AWS Secret Credentials
`aws_key_name` | Name of key pair already loaded in AWS
`aws_region` | Region to deploy VPC to
`cidr_base` | First three octets of CIDR address for VPC
`vpn_passwd` | Encryped password for openvpn user on VPN host
`my_ip` | Your static IPv4 address

*N.B.* Please generate `cidr_base` with the following shell command so as to avoid collisions.
```
echo 10.$(( ( RANDOM % 250 )  + 1 )).$(( ( RANDOM % 254 )  + 1 ))
```

*N.B.* Please generate `vpn_passwd` with the following shell command. Substitute `<your-password>` with your password -- this password must be less than or equal to 8 characters.
```
export PASSWORD='<your-password>' \
openssl passwd -crypt $PASSWORD
```

## Outputs
Variable | Purpose
--- | --- |
`datacenter_id` | Logical datacenter ID
`datacenter_network` | Logical datacenter CIDR
`datacenter_subnet_dmzA_id` | Logical datacenter Demilitarized -- Public -- subnet id in availability zone A
`datacenter_subnet_dmzB_id` | Logical datacenter Demilitarized -- Public -- subnet id in availability zone B
`datacenter_subnet_natA_id` | Logical datacenter NAT -- Private -- subnet id in availability zone A
`datacenter_subnet_natB_id` | Logical datacenter NAT -- Private -- subnet id in availability zone B
`cache_client_sg` | Whitelist security group for redis servers. Any host that has this security group applied will be able to communicate on `tcpv4:6379` to hosts which have `cache_sg` applied.
`cache_sg` | Allow communication on `tcpv4:6379` for hosts with `cache_client_sg` applied.
`search_client_sg` | Whitelist security group for elastic servers. Any instance that has this security group applied will be able to communicate on `tcpv4:9200` and `tcpv4:9300` to instances which have `cache_sg` applied.
`search_sg` | Allow communication on `tcpv4:9200` and `tcpv4:9300` for hosts with `search_client_sg` applied.
`web_sg` | Allow communication on `tcpv4:80` and `tcpv4:443` from any.
`ssh_sg` | Allow communication on `tcpv4:22` for hosts with `ssh_client_sg` applied.
`ssh_client_sg` | Whitelist security group for ssh servers. Any host that has this security group applied will be able to communicate on `tcpv4:22` to hosts which have `ssh_sg` applied.
`db_sg` | Allow communcation on `tcpv4:5432` for hosts with `db_client_sg` applied.
`db_client_sg` | Whitelist security group for postgresql servers. Any host that has this security group applied will be able to communicate on `tcpv4:5432` to hosts which have `db_sg` applied .
`nat_client_sg` | Whitelist security group for nat servers. Any host that has this security group applied will be able to communicate on `tcpv4:25`, `tcpv4:80`, `tcpv4:443`, `tcpv4:587`, and `icmp:-1` to the NAT instance. This allows these communications to be translated to the public internet. If this security group is *not* applied, interfaces will not be able to communicate with the public internet.
`ipsec_public_ip` | Public ip address of IPSEC instance 
`ipsec_private_ip` | Private ip address of IPSEC instance

TODO:
- Make Environment tag a parameter to pass to the module
