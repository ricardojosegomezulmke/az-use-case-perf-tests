
{
  "broker_nodes":
  ${jsonencode(
    [
      for node in nodes: {
        "cloud_provider": "aws",
        "location": "${node.availability_zone}",
        "name": "${node.host_id}",
        "size": "${node.instance_type}",
        "public_ip": "${node.public_ip}",
        "private_ip": "${node.private_ip}",
        "admin_username": "centos",
        "node_details": "${node}"
      }
    ])}

  }
