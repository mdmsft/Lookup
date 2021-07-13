using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

internal class LookupService
{
    private readonly DatabaseService database;
    private readonly CacheService cache;
    private readonly ILogger<LookupService> logger;

    public LookupService(DatabaseService database, CacheService cache, ILogger<LookupService> logger)
    {
        this.database = database;
        this.cache = cache;
        this.logger = logger;
    }

    internal async Task<string> GetValue(string key)
    {
        logger.LogInformation(1001, "Getting value for key {key}", key);
        var value = await cache.GetValue(key);
        if (value is not null)
        {
            logger.LogInformation(1002, "Got value {value} for key {key} from cache", value, key);
            return value;
        }

        logger.LogInformation(1003, "Value for key {key} is not in cache, getting it from database", key);

        value = await database.GetValue(key);
        if (value is not null)
        {
            logger.LogInformation(1004, "Got value {value} for key {key} from database, caching it", value, key);
            await cache.SetValue(key, value);
            logger.LogInformation(1005, "Cached value {value} for key {key}", value, key);
            return value;
        }

        logger.LogError(1006, "Value for key {key} not found", key);
        throw new Exception($"Value for key {key} not found");
    }

    internal async Task Bootstrap()
    {
        var bytes = Enumerable.Range(0, 8).Select(i => Convert.ToByte(i)).ToArray();
        var values = Enumerable.Range(0, short.MaxValue).Select(i => new KeyValuePair<string, string>(i.ToString(), new Guid(i, Convert.ToInt16(i), Convert.ToInt16(i), bytes).ToString()));
        await database.Bootstrap(values);
    }
}