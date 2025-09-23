output "printblock" {
  #value = "${ path.module }/data.txt"
  value = file("${ path.module }/data.txt")
}