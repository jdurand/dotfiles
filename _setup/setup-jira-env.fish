#!/usr/bin/env fish

# Jira Environment Setup Script for Fish Shell
# This script helps you securely configure Jira credentials for the spec-driven development workflow

echo "🔧 Setting up Jira environment variables for spec-driven development"
echo "=================================================="
echo ""

# Check if we're being sourced
if status is-interactive
    # Get Jira base URL
    echo "📍 Enter your Jira base URL (e.g., https://your-company.atlassian.net):"
    read -P "URL: " JIRA_BASE_URL
    set -gx JIRA_BASE_URL $JIRA_BASE_URL

    # Get Jira email
    echo ""
    echo "📧 Enter your Jira email address:"
    read -P "Email: " JIRA_EMAIL
    set -gx JIRA_EMAIL $JIRA_EMAIL

    # Get Jira API token (hide input)
    echo ""
    echo "🔑 Enter your Jira API token (input will be hidden):"
    echo "💡 Create one at: https://id.atlassian.com/manage-profile/security/api-tokens"
    read -s -P "Token: " JIRA_API_TOKEN
    set -gx JIRA_API_TOKEN $JIRA_API_TOKEN

    echo ""
    echo "✅ Environment variables set for this session:"
    echo "   JIRA_BASE_URL=$JIRA_BASE_URL"
    echo "   JIRA_EMAIL=$JIRA_EMAIL"
    echo "   JIRA_API_TOKEN=***[hidden]***"
    echo ""
    echo "🔒 Security Notes:"
    echo "   - These variables are only set for this shell session"
    echo "   - Add them to your ~/.config/fish/config.fish for persistence"
    echo "   - Never commit API tokens to git repositories"
    echo ""
    echo "📝 To make permanent, add these lines to ~/.config/fish/config.fish:"
    echo "   set -gx JIRA_BASE_URL \"$JIRA_BASE_URL\""
    echo "   set -gx JIRA_EMAIL \"$JIRA_EMAIL\""
    echo "   set -gx JIRA_API_TOKEN \"$JIRA_API_TOKEN\""
    echo ""
    echo "🚀 You can now use the StartWork command (<leader>sw) in Neovim!"
else
    echo "⚠️  This script should be sourced in an interactive Fish shell."
    echo "💡 Run: source $argv[0]"
    exit 1
end