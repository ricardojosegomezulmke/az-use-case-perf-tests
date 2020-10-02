# Configure the Azure Provider
provider "azurerm" {
  version = "=2.0.0"

  features {}
}

# Create a resource group
resource "azurerm_resource_group" "sdkperf_az_resgrp" {
  count = var.az_resgrp_name == "" ? 1 : 0

  name     = "${var.tag_name_prefix}-sdkperf_resgrp"
  location = var.az_region
  
  tags = {
    Name    = "${var.tag_name_prefix}-sdkperf_az_resgrp"
    Owner   = var.tag_owner
    Purpose = "sdkperf benchmarking"
    Days    = var.tag_days
  }
}

# Proximity placement group keeps VMs in close proxmity to reduce network latency and jitter
resource "azurerm_proximity_placement_group" "sdkperf_az_ppgrp" {
  name                = "${var.tag_name_prefix}-sdkperf-ppgrp"
  location            =  azurerm_resource_group.sdkperf_az_resgrp[0].location
  resource_group_name =  azurerm_resource_group.sdkperf_az_resgrp[0].name 

 tags = {
    Name    = "${var.tag_name_prefix}-sdkperf_az_ppgrp"
    Owner   = var.tag_owner
    Purpose = "sdkperf benchmarking"
    Days    = var.tag_days
  }
}

#Query the AZ Res Group location for the specified AZ Res Group Name
data "azurerm_resource_group" "input_resgroup" {
  count = var.az_resgrp_name == "" ? 0 : 1
  
  name = var.az_resgrp_name
}


