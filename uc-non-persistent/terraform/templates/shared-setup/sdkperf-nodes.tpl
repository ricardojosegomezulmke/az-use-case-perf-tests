{
  "sdkperf_nodes":
  ${jsonencode(
    [
      for node in nodes: {
        "name": "${node.name}",
        "size": "${node.size}",
        "public_ip": "${node.public_ip_address}",
        "private_ip": "${node.private_ip_address}"
      }
    ]
    )}
}