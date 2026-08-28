using Azure;
using Azure.AI.Inference;
using Azure.Identity;

namespace LogisticsApp.Services;

public class AiFoundryService
{
    private readonly ChatCompletionsClient? _client;
    private readonly string _modelDeployment;
    private readonly ILogger<AiFoundryService> _logger;

    public AiFoundryService(IConfiguration config, ILogger<AiFoundryService> logger)
    {
        _logger = logger;
        _modelDeployment = config["AI_MODEL_DEPLOYMENT_NAME"] ?? "gpt-5.4-mini";
        var endpoint = config["AI_FOUNDRY_ENDPOINT"];
        if (!string.IsNullOrEmpty(endpoint))
        {
            _client = new ChatCompletionsClient(
                new Uri(endpoint),
                new DefaultAzureCredential(),
                new AzureAIInferenceClientOptions());
        }
        else
        {
            _logger.LogWarning("AI_FOUNDRY_ENDPOINT not configured — AI features disabled.");
        }
    }

    public async Task<string> QueryLogisticsAsync(string userQuestion, string shipmentsContext)
    {
        if (_client is null)
            return "AI Foundry endpoint not configured. Set AI_FOUNDRY_ENDPOINT to enable AI insights.";

        var systemPrompt = """
            You are a logistics operations AI assistant for a European freight company.
            You have access to the following current shipment data:

            """ + shipmentsContext + """

            Answer the user's question concisely (2-4 sentences). Focus on actionable insights,
            delays, exceptions, and delivery estimates. Be direct and professional.
            """;

        var request = new ChatCompletionsOptions
        {
            Model = _modelDeployment,
            Messages =
            {
                new ChatRequestSystemMessage(systemPrompt),
                new ChatRequestUserMessage(userQuestion)
            },
            MaxTokens = 300,
            Temperature = 0.3f
        };

        try
        {
            var response = await _client.CompleteAsync(request);
            return response.Value.Content ?? "No response from AI.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AI Foundry query failed");
            return $"AI query failed: {ex.Message}";
        }
    }
}
