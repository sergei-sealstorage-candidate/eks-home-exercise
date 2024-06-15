output "aws_vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "aws_subnet_ids" {
  value = aws_subnet.eks_subnet[*].id
}
