using Microsoft.Data.SqlClient;
using Azure.Identity;
using LogisticsApp.Models;

namespace LogisticsApp.Services;

public class LogisticsDbService
{
    private readonly string _server;
    private readonly string _database;
    private readonly ILogger<LogisticsDbService> _logger;

    public LogisticsDbService(IConfiguration config, ILogger<LogisticsDbService> logger)
    {
        _server = config["SQL_SERVER"] ?? throw new InvalidOperationException("SQL_SERVER not configured");
        _database = config["SQL_DATABASE"] ?? throw new InvalidOperationException("SQL_DATABASE not configured");
        _logger = logger;
    }

    private SqlConnection CreateConnection()
    {
        var credential = new DefaultAzureCredential();
        var token = credential.GetToken(
            new Azure.Core.TokenRequestContext(["https://database.windows.net/.default"]));

        var conn = new SqlConnection(
            $"Server=tcp:{_server},1433;Initial Catalog={_database};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;");
        conn.AccessToken = token.Token;
        return conn;
    }

    public async Task EnsureSchemaAsync()
    {
        try
        {
            await using var conn = CreateConnection();
            await conn.OpenAsync();

            var ddl = """
                IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Shipments')
                CREATE TABLE Shipments (
                    ShipmentId INT PRIMARY KEY IDENTITY,
                    Origin NVARCHAR(100) NOT NULL,
                    Destination NVARCHAR(100) NOT NULL,
                    Status NVARCHAR(50) NOT NULL,
                    ExpectedDelivery DATETIME2 NOT NULL,
                    CarrierId NVARCHAR(50) NOT NULL
                );
                IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Routes')
                CREATE TABLE Routes (
                    RouteId INT PRIMARY KEY IDENTITY,
                    Name NVARCHAR(100) NOT NULL,
                    WaypointCount INT NOT NULL,
                    EstimatedHours INT NOT NULL
                );
                IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Exceptions')
                CREATE TABLE Exceptions (
                    ExceptionId INT PRIMARY KEY IDENTITY,
                    ShipmentId INT NOT NULL,
                    Type NVARCHAR(50) NOT NULL,
                    Description NVARCHAR(500) NOT NULL,
                    ReportedAt DATETIME2 NOT NULL
                );
                """;

            await using var cmd = new SqlCommand(ddl, conn);
            await cmd.ExecuteNonQueryAsync();

            // Seed if empty
            var countCmd = new SqlCommand("SELECT COUNT(*) FROM Shipments", conn);
            var count = (int)(await countCmd.ExecuteScalarAsync() ?? 0);
            if (count == 0)
                await SeedDataAsync(conn);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Database not available — running in demo mode without SQL.");
        }
    }

    private static async Task SeedDataAsync(SqlConnection conn)
    {
        var seed = """
            INSERT INTO Routes (Name, WaypointCount, EstimatedHours) VALUES
                ('Amsterdam–Berlin Express', 3, 8),
                ('Rotterdam–Warsaw Freight', 5, 14),
                ('Hamburg–Milan Overnight', 4, 11);

            INSERT INTO Shipments (Origin, Destination, Status, ExpectedDelivery, CarrierId) VALUES
                ('Amsterdam', 'Berlin', 'In Transit', DATEADD(day, 2, GETDATE()), 'DHL-EU-001'),
                ('Rotterdam', 'Warsaw', 'Delayed', DATEADD(day, 5, GETDATE()), 'FEDX-EU-042'),
                ('Hamburg', 'Milan', 'On Time', DATEADD(day, 1, GETDATE()), 'UPS-EU-007'),
                ('Brussels', 'Vienna', 'Pending', DATEADD(day, 3, GETDATE()), 'DHL-EU-013'),
                ('Paris', 'Madrid', 'Delivered', DATEADD(day, -1, GETDATE()), 'FEDX-EU-099');

            INSERT INTO Exceptions (ShipmentId, Type, Description, ReportedAt) VALUES
                (2, 'Customs Hold', 'Package held at Polish customs — missing certificate of origin.', DATEADD(hour, -6, GETDATE())),
                (2, 'Delay Notification', 'Carrier reports 24-hour delay due to road closure on A2.', DATEADD(hour, -3, GETDATE()));
            """;

        await using var cmd = new SqlCommand(seed, conn);
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<List<Shipment>> GetShipmentsAsync()
    {
        var list = new List<Shipment>();
        try
        {
            await using var conn = CreateConnection();
            await conn.OpenAsync();
            await using var cmd = new SqlCommand(
                "SELECT ShipmentId, Origin, Destination, Status, ExpectedDelivery, CarrierId FROM Shipments ORDER BY ShipmentId", conn);
            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                list.Add(new Shipment
                {
                    ShipmentId = reader.GetInt32(0),
                    Origin = reader.GetString(1),
                    Destination = reader.GetString(2),
                    Status = reader.GetString(3),
                    ExpectedDelivery = reader.GetDateTime(4),
                    CarrierId = reader.GetString(5)
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not fetch shipments — returning demo data.");
            return GetDemoShipments();
        }
        return list;
    }

    public async Task<List<ShipmentException>> GetExceptionsAsync()
    {
        var list = new List<ShipmentException>();
        try
        {
            await using var conn = CreateConnection();
            await conn.OpenAsync();
            await using var cmd = new SqlCommand(
                "SELECT ExceptionId, ShipmentId, Type, Description, ReportedAt FROM Exceptions ORDER BY ReportedAt DESC", conn);
            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                list.Add(new ShipmentException
                {
                    ExceptionId = reader.GetInt32(0),
                    ShipmentId = reader.GetInt32(1),
                    Type = reader.GetString(2),
                    Description = reader.GetString(3),
                    ReportedAt = reader.GetDateTime(4)
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not fetch exceptions — returning demo data.");
        }
        return list;
    }

    private static List<Shipment> GetDemoShipments() =>
    [
        new() { ShipmentId = 1, Origin = "Amsterdam", Destination = "Berlin", Status = "In Transit",
                ExpectedDelivery = DateTime.UtcNow.AddDays(2), CarrierId = "DHL-EU-001" },
        new() { ShipmentId = 2, Origin = "Rotterdam", Destination = "Warsaw", Status = "Delayed",
                ExpectedDelivery = DateTime.UtcNow.AddDays(5), CarrierId = "FEDX-EU-042" },
        new() { ShipmentId = 3, Origin = "Hamburg", Destination = "Milan", Status = "On Time",
                ExpectedDelivery = DateTime.UtcNow.AddDays(1), CarrierId = "UPS-EU-007" }
    ];
}
