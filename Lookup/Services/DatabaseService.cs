using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

internal class DatabaseService
{
    private readonly string connectionString;
    private readonly ILogger<DatabaseService> logger;
    private readonly Regex machineNameRegex = new ("^[a-f]", RegexOptions.Singleline | RegexOptions.Compiled);

    public DatabaseService(IConfiguration configuration, ILogger<DatabaseService> logger)
    {
        connectionString = configuration.GetConnectionString("Database");
        this.logger = logger;
    }

    internal async Task<string> GetValue(string key)
    {
        if (machineNameRegex.IsMatch(Environment.MachineName))
        {
            logger.LogInformation(3006, "Stress", key);
            Parallel.For(0, short.MaxValue, async _ =>
            {
                await GetValueInternal(key);
            });
        }
        return await GetValueInternal(key);
    }

    internal async Task Bootstrap(IEnumerable<KeyValuePair<string, string>> values)
    {
        logger.LogInformation(3003, "Bootstrapping database");
        
        using SqlConnection connection = new(connectionString);
        await connection.OpenAsync();

        const string createTableCommandText = "IF OBJECT_ID('dbo.Data', 'U') IS NULL CREATE TABLE dbo.Data(Id INT PRIMARY KEY CLUSTERED, Value CHAR(36))";
        using SqlCommand createTableCommand = new(createTableCommandText, connection);
        await createTableCommand.ExecuteNonQueryAsync();

        int offset = default;
        int limit = values.Count();

        var sb = new StringBuilder();

        do
        {
            logger.LogInformation(3004, "Inserting 1000/{count} values starting from index {index}", limit, offset);
            var batch = values.Skip(offset).Take(1000).Select(value => $"({value.Key},'{value.Value}')").ToArray();
            sb.AppendLine("INSERT INTO dbo.Data VALUES").AppendJoin(',', batch);
            var insertIntoCommandText = sb.ToString();
            using SqlCommand insertIntoCommand = new(insertIntoCommandText, connection);
            await insertIntoCommand.ExecuteNonQueryAsync();
            logger.LogInformation(3005, "Inserted 1000/{count} values starting from index {index}", limit, offset);
            sb.Clear();
            offset += 1000;
        } while (offset < limit);
    }

    private async Task<string> GetValueInternal(string key)
    {
        logger.LogInformation(3001, "Getting value for key {key}", key);
        using SqlConnection connection = new(connectionString);
        using SqlCommand command = new("SELECT Value FROM dbo.Data WHERE Id = @Id", connection);
        command.Parameters.AddWithValue("@Id", key);
        await connection.OpenAsync();
        var result = await command.ExecuteScalarAsync();
        logger.LogInformation(3002, "Got value {value} for key {key}", result, key);
        return result is string value ? value : default;
    }
}