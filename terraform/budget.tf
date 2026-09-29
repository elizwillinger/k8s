# =============================================================================
# AWS Budget — $20/month cost alert
# =============================================================================
#
# Terraform creates the budget using your local AWS credentials (STS, env
# vars, ~/.aws/credentials, etc.).  No extra IAM role is needed — your
# credentials just need the budgets:CreateBudget / budgets:UpdateBudget
# permissions (standard for any AWS admin).
# =============================================================================

resource "aws_budgets_budget" "cost_budget" {
  name              = "${var.project_name}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "20"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_refund             = false
    include_recurring          = true
    include_subscription       = true
    include_support            = true
    include_tax                = true
    use_blended                = false
  }

  # Alert when spend reaches 80% and 100%
  notification {
    notification_type              = "ACTUAL"
    comparison_operator            = "GREATER_THAN"
    threshold                      = 80
    threshold_type                 = "PERCENTAGE"
    subscriber_email_addresses     = [var.budget_email]
  }

  notification {
    notification_type              = "ACTUAL"
    comparison_operator            = "GREATER_THAN"
    threshold                      = 100
    threshold_type                 = "PERCENTAGE"
    subscriber_email_addresses     = [var.budget_email]
  }
}
