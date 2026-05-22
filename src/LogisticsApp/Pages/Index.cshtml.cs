using LogisticsApp.Models;
using LogisticsApp.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Text;

namespace LogisticsApp.Pages;

public class IndexModel : PageModel
{
    private readonly LogisticsDbService _db;
    private readonly AiFoundryService _ai;

    public List<Shipment> Shipments { get; private set; } = [];
    public List<ShipmentException> Exceptions { get; private set; } = [];

    [BindProperty]
    public string UserQuery { get; set; } = string.Empty;
    public string AiResponse { get; private set; } = string.Empty;
    public bool HasAiResponse { get; private set; }

    public IndexModel(LogisticsDbService db, AiFoundryService ai)
    {
        _db = db;
        _ai = ai;
    }

    public async Task OnGetAsync()
    {
        Shipments = await _db.GetShipmentsAsync();
        Exceptions = await _db.GetExceptionsAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        Shipments = await _db.GetShipmentsAsync();
        Exceptions = await _db.GetExceptionsAsync();

        if (!string.IsNullOrWhiteSpace(UserQuery))
        {
            var context = BuildContext(Shipments, Exceptions);
            AiResponse = await _ai.QueryLogisticsAsync(UserQuery, context);
            HasAiResponse = true;
        }

        return Page();
    }

    private static string BuildContext(List<Shipment> shipments, List<ShipmentException> exceptions)
    {
        var sb = new StringBuilder();
        sb.AppendLine("SHIPMENTS:");
        foreach (var s in shipments)
            sb.AppendLine($"  #{s.ShipmentId} {s.Origin}→{s.Destination} | {s.Status} | Due: {s.ExpectedDelivery:yyyy-MM-dd} | Carrier: {s.CarrierId}");
        sb.AppendLine("ACTIVE EXCEPTIONS:");
        foreach (var e in exceptions)
            sb.AppendLine($"  Shipment #{e.ShipmentId} [{e.Type}]: {e.Description} (reported {e.ReportedAt:yyyy-MM-dd HH:mm})");
        return sb.ToString();
    }
}
