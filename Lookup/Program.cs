using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Net.Http.Headers;
using StackExchange.Redis;
using System;
using System.Net;
using System.Net.Mime;
using System.Text;
using System.Threading;

Random random = new();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration.GetConnectionString("Database"))
    .AddRedis(builder.Configuration.GetConnectionString("Redis"))
    .AddApplicationInsightsPublisher();
builder.Services.AddSingleton(ConnectionMultiplexer.Connect(builder.Configuration.GetConnectionString("Redis")).GetDatabase());
builder.Services.AddSingleton<CacheService>();
builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<LookupService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseHealthChecks("/healthz");
}

app.MapGet("/", async context =>
{
    var lookupService = context.RequestServices.GetRequiredService<LookupService>();
    var key = random.Next(0, short.MaxValue).ToString();
    var value = await lookupService.GetValue(key);
    context.Response.StatusCode = (int)HttpStatusCode.OK;
    context.Response.Headers[HeaderNames.ContentType] = MediaTypeNames.Text.Plain;
    await context.Response.BodyWriter.WriteAsync(new ReadOnlyMemory<byte>(Encoding.ASCII.GetBytes(value)));
    await context.Response.BodyWriter.FlushAsync();
});

app.MapPost("/", async context =>
{
    var lookupService = context.RequestServices.GetRequiredService<LookupService>();
    await lookupService.Bootstrap();
    context.Response.StatusCode = (int)HttpStatusCode.NoContent;
    await context.Response.BodyWriter.FlushAsync();
});

app.Run();
