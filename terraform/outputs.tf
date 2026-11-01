output "outputs" {
  value = {
    "user-1-arn" = aws_iam_user.obaid.arn,
    "user-2-arn" = aws_iam_user.ijaz.arn
    "group_arn"  = aws_iam_group.developers.arn
  }
}