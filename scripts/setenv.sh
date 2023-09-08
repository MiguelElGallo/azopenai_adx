export $(xargs < ./scripts/.azure/testadx/.env)

echo "Environment variables set."
echo $AZURE_ENV_NAME