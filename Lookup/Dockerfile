#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Lookup/Lookup.csproj", "Lookup/"]
RUN dotnet restore "Lookup/Lookup.csproj"
COPY . .
WORKDIR "/src/Lookup"
RUN dotnet build "Lookup.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Lookup.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Lookup.dll"]