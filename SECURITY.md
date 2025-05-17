# Security Considerations for the Gemini Elixir Client

## API Key Security

The Gemini Elixir client handles API keys in a secure manner to prevent accidental exposure in logs or error messages.

### Secure Logging

- API keys are automatically masked in logs with only the first 5 characters displayed (`AIzaS*****`)
- This masking applies to all request logging, including query parameters, URLs, and request bodies
- The masking is performed by the `Gemini.SecureLogger` module which is automatically applied to all API requests

### API Key Configuration

For security, we recommend setting your API key using environment variables rather than hardcoding it:

```bash
export GEMINI_API_KEY=your_api_key_here
```

The client will automatically use this environment variable when making requests.

## Development Security Practices

When contributing to this project, please follow these security best practices:

1. Never commit API keys or secrets to source control
2. Use the provided `clean_logs.sh` script to sanitize any log files before sharing them
3. Always run tests with a test API key, not your production key
4. Report any potential security issues immediately

## Testing Without Exposing API Keys

For running tests that require an API key, use environment variables:

```bash
GEMINI_API_KEY=your_key mix test
```

This prevents the key from appearing in your shell history or logs.