# Badge file via count
resource "local_file" "badge" {
  count    = length(var.team_members)
  filename = "${path.module}/out/badges/${var.team_members[count.index]}-badge.txt"
  content  = "Badge for ${var.team_members[count.index]}\nIndex: ${count.index}"
}

# Conditional docs (enable / disable) with bool
resource "local_file" "team_docs" {
  count    = var.enable_docs ? 1 : 0
  filename = "${path.module}/out/docs/README.txt"
  content  = "team docs are enabled"
}


resource "null_resource" "servicee" {
  for_each = var.services

  triggers = {
    service_name = each.key
  }
}

resource "local_file" "service_marker" {
  for_each = var.services

  filename = "${path.module}/out/services/${each.key}.txt"
  content  = "Service: ${each.key}\n"
}