namespace LogisticsApp.Models;

public class Shipment
{
    public int ShipmentId { get; set; }
    public string Origin { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime ExpectedDelivery { get; set; }
    public string CarrierId { get; set; } = string.Empty;
}

public class Route
{
    public int RouteId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int WaypointCount { get; set; }
    public int EstimatedHours { get; set; }
}

public class ShipmentException
{
    public int ExceptionId { get; set; }
    public int ShipmentId { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime ReportedAt { get; set; }
}
