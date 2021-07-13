using Microsoft.ApplicationInsights;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using System;
using System.Diagnostics;
using System.Threading.Tasks;

internal class CacheService
{
    private readonly IDatabase database;
    private readonly TelemetryClient telemetry;
    private readonly ILogger<CacheService> logger;
    private readonly string dependencyName;
    private const string dependencyType = "REDIS";

    public CacheService(IDatabase database, TelemetryClient telemetry, ILogger<CacheService> logger)
    {
        this.database = database;
        this.telemetry = telemetry;
        this.logger = logger;
        dependencyName = database.Multiplexer.Configuration[..database.Multiplexer.Configuration.IndexOf('.')];
    }

    internal async Task<string> GetValue(string key)
    {
        logger.LogInformation(2001, "Getting value for key {key}", key);
        var stopwatch = new Stopwatch();
        var timestamp = DateTimeOffset.UtcNow;
        stopwatch.Start();
        var value = await database.StringGetAsync(key);
        stopwatch.Stop();
        logger.LogInformation(2002, "Got value for key {key}: {value}", key, value);
        telemetry.TrackDependency(dependencyType, dependencyName, $"GET {key}", timestamp, TimeSpan.FromTicks(stopwatch.ElapsedTicks), true);
        return value;
    }

    internal async Task SetValue(string key, string value)
    {
        logger.LogInformation(2003, "Setting value {value} for key {key}", value, key);
        var timespan = TimeSpan.FromMinutes(1);
        var stopwatch = new Stopwatch();
        var timestamp = DateTimeOffset.UtcNow;
        stopwatch.Start();
        await database.StringSetAsync(key, value, timespan);
        stopwatch.Stop();
        telemetry.TrackDependency(dependencyType, dependencyName, $"SETEX {key} {timespan.TotalSeconds:F0} {value}", timestamp, TimeSpan.FromTicks(stopwatch.ElapsedTicks), true);
        logger.LogInformation(2004, "Set value {value} for key {key}", value, key);
    }
}