using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Net.Http.Headers;
using StackExchange.Redis;
using System;
using System.Net;
using System.Net.Mime;
using System.Text;
using System.Threading.Tasks;

namespace Lookup
{
    public static class Program
    {
        public static async Task Main(params string[] args)
        {
            Random random = new();

            await WebHost.CreateDefaultBuilder(args).ConfigureServices((context, services) =>
            {
                services.AddHealthChecks()
                    .AddSqlServer(context.Configuration.GetConnectionString("Database"))
                    .AddRedis(context.Configuration.GetConnectionString("Redis"))
                    .AddApplicationInsightsPublisher();
                services.AddApplicationInsightsTelemetry()
                    .AddSingleton(ConnectionMultiplexer.Connect(context.Configuration.GetConnectionString("Redis")).GetDatabase())
                    .AddSingleton<CacheService>()
                    .AddSingleton<DatabaseService>()
                    .AddSingleton<LookupService>();
            })
            .Configure(app =>
            {
                app.UseHealthChecks("/healthz");
                app.UseRouting();
                app.UseEndpoints(endpoints =>
                {
                    endpoints.MapGet("/", async context =>
                    {
                        var lookupService = context.RequestServices.GetRequiredService<LookupService>();
                        var key = random.Next(0, short.MaxValue).ToString();
                        var value = await lookupService.GetValue(key);
                        context.Response.StatusCode = (int)HttpStatusCode.OK;
                        context.Response.Headers[HeaderNames.ContentType] = MediaTypeNames.Text.Plain;
                        await context.Response.BodyWriter.WriteAsync(new ReadOnlyMemory<byte>(Encoding.ASCII.GetBytes(value)));
                        await context.Response.BodyWriter.FlushAsync();
                    });

                    endpoints.MapPost("/", async context =>
                    {
                        var lookupService = context.RequestServices.GetRequiredService<LookupService>();
                        await lookupService.Bootstrap();
                        context.Response.StatusCode = (int)HttpStatusCode.NoContent;
                        await context.Response.BodyWriter.FlushAsync();
                    });
                });
            }).Build().RunAsync();
        }
    }
}